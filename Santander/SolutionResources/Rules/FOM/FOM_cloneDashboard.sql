DECLARE
  v_DashboardId        TBL_FOM_DASHBOARD.COL_ID%TYPE;
  v_Name               TBL_FOM_DASHBOARD.COL_NAME%TYPE;
  v_Code               TBL_FOM_DASHBOARD.COL_CODE%TYPE;
  v_Config             TBL_FOM_DASHBOARD.COL_CONFIG%TYPE;
  v_Description        TBL_FOM_DASHBOARD.COL_DESCRIPTION%TYPE;
  v_IsSystem           TBL_FOM_DASHBOARD.COL_ISSYSTEM%TYPE;
  v_CaseworkerId       TBL_FOM_DASHBOARD.COL_DASHBOARDCASEWORKER%TYPE;
  v_UielementId        NUMBER;
  v_UielementCode      TBL_FOM_UIELEMENT.COL_CODE%TYPE;
  v_FromCaseManagement NUMBER;
  v_AccessObjectId     NUMBER;
  v_MaskOld            NVARCHAR2(50);
  v_MaskNew            NVARCHAR2(50);
  v_aotype             INT;

  --standard
  v_ErrorCode    NUMBER := 0;
  v_ErrorMessage NVARCHAR2(255 CHAR) := '';
  v_Return       NUMBER;
  --
  CURSOR cur_Dashboard(p_DashboardId IN TBL_FOM_DASHBOARD.COL_ID%TYPE) IS
    SELECT d.COL_ID          AS ID,
           d.COL_NAME        AS NAME,
           d.COL_CODE        AS CODE,
           d.COL_DESCRIPTION AS DESCRIPTION,
           d.COL_CONFIG      AS CONFIG,
           d.COL_ISDEFAULT   AS ISDEFAULT,
           d.COL_ISSYSTEM    AS ISSYSTEM
      FROM TBL_FOM_DASHBOARD d
     WHERE d.COL_ID = p_DashboardId;

  CURSOR cur_UiELement(p_DashboardId IN TBL_FOM_UIELEMENT.COL_UIELEMENTDASHBOARD%TYPE) IS
    SELECT u.COL_ID                 AS ELEMENTID,
           u.COL_JSONDATA           AS JSONDATA,
           u.COL_UIELEMENTDASHBOARD AS UIELEMENTDASHBOARD,
           u.COL_UIELEMENTWIDGET    AS UIELEMENTWIDGET,
           u.COL_ISEDITABLE         AS ISEDITABLE,
           u.COL_FORMIDLIST         AS FORMIDLIST,
           u.COL_CODE               AS UIELEMENTCODE,
           u.COL_CODEDPAGEIDLIST    AS CODEDPAGEIDLIST
      FROM TBL_FOM_UIELEMENT u
      LEFT JOIN TBL_AC_ACCESSOBJECT ao
        ON ao.COL_ACCESSOBJECTUIELEMENT = u.COL_ID
     WHERE u.COL_UIELEMENTDASHBOARD = p_DashboardId;
BEGIN
  v_DashboardId        := :DashboardId;
  v_Name               := :NAME;
  v_Code               := :Code;
  v_Description        := :Description;
  v_FromCaseManagement := :FromCaseManagement;
  :SuccessResponse     := EMPTY_CLOB();

  ---check input params
  IF (v_DashboardId IS NULL) THEN
    v_ErrorMessage := 'DashboardId can not be empty';
    v_ErrorCode    := 101;
    GOTO cleanup;
  END IF;

  BEGIN
    BEGIN
      FOR rec IN cur_Dashboard(v_DashboardId) LOOP
        --check if clone from case management
        IF (v_FromCaseManagement = 1) THEN
          v_IsSystem := 0;
        ELSE
          v_IsSystem := rec.ISSYSTEM;
        END IF;
      
        --system dashboard cannot 
        IF (v_IsSystem = 1) THEN
          v_CaseworkerId := NULL;
        ELSE
          v_CaseworkerId := F_DCM_GETCASEWORKERID();
        END IF;
      
        INSERT INTO TBL_FOM_DASHBOARD
          (COL_NAME, COL_CODE, COL_DESCRIPTION, COL_ISDEFAULT, COL_ISSYSTEM, COL_DASHBOARDCASEWORKER)
        VALUES
          (v_Name, v_Code, v_Description, rec.ISDEFAULT, v_IsSystem, v_CaseworkerId)
        RETURNING COL_ID INTO :recordId;
        v_Return      := LOC_i18n(MessageText   => 'Dashboard {{MESS_NAME}} was cloned to dashboard {{MESS_CLONE_NAME}}',
                                  MessageResult => :SuccessResponse,
                                  MessageParams => NES_TABLE(Key_Value('MESS_NAME', rec.NAME), Key_Value('MESS_CLONE_NAME', v_Name)));
        :affectedRows := 1;
        -- get old CONFIG for update
        v_Config := rec.CONFIG;
      END LOOP;
    END;
  
    --clone uielements
    BEGIN
      FOR el IN cur_UiELement(v_DashboardId) LOOP
        INSERT INTO TBL_FOM_UIELEMENT
          (COL_JSONDATA, COL_UIELEMENTDASHBOARD, COL_UIELEMENTWIDGET, COL_ISEDITABLE, COL_CODE, COL_FORMIDLIST, COL_CODEDPAGEIDLIST)
        VALUES
          (el.JSONDATA, :recordId, el.UIELEMENTWIDGET, el.ISEDITABLE, SYS_GUID(), el.FORMIDLIST, el.CODEDPAGEIDLIST)
        RETURNING COL_ID, COL_CODE INTO v_UielementId, v_UielementCode;
        -- create substring with old and new configId for replace
        v_MaskOld := '"configId":"' || TO_CHAR(el.UIELEMENTCODE) || '"';
        v_MaskNew := '"configId":"' || TO_CHAR(v_UielementCode) || '"';
        v_Config  := REPLACE(v_Config, v_MaskOld, v_MaskNew);
      
        -- AC_AccessObject
        v_aotype := f_util_getidbycode(code => 'DASHBOARD_ELEMENT', tablename => 'tbl_ac_accessobjecttype');
        INSERT INTO tbl_ac_accessobject
          (col_name, col_code, col_accessobjectuielement, col_accessobjaccessobjtype)
        VALUES
          ('Dashboard element ' || To_char(v_UIElementId),
           f_UTIL_calcUniqueCode('DASHBOARD_ELEMENT_' || to_char(v_UielementId), 'tbl_ac_accessobject'),
           v_UielementId,
           v_aotype)
        RETURNING col_id INTO v_AccessObjectId;
      
      END LOOP;
    END;
  
    -- update new Config
    UPDATE TBL_FOM_DASHBOARD SET COL_CONFIG = v_Config WHERE COL_ID = :recordId;
  
    -- clone KeySources
    INSERT INTO TBL_LOC_KEYSOURCES
      (COL_SOURCETYPE, COL_KEYID, COL_SOURCEID, COL_UCODE)
      SELECT COL_SOURCETYPE,
             COL_KEYID,
             :recordId,
             SYS_GUID()
        FROM TBL_LOC_KEYSOURCES
       WHERE lower(COL_SOURCETYPE) = lower('Dashboard')
         AND COL_SOURCEID = v_DashboardId;
  
  EXCEPTION
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_ErrorCode      := 102;
      v_ErrorMessage   := '$t(Exception:) ' || SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_ErrorCode;
  :errorMessage := v_ErrorMessage;
END;