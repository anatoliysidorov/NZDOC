DECLARE
  v_casetypename         NVARCHAR2(255);
  v_casetypecode         NVARCHAR2(255);
  v_iconcode             NVARCHAR2(255);
  v_casetypecolorcode    NVARCHAR2(7);
  v_description          NCLOB;
  v_ShowInPortal         NUMBER;
  v_casesystypeid        NUMBER;
  v_ResolutionCodeIds_SV NCLOB;
  v_isdeleted            NUMBER;
  v_debugmode            NUMBER;
  v_isdraftmodeavail     NUMBER;
  v_procedure_id         NUMBER;
  v_stateconfig_id       NUMBER;
  v_PriorityId           NUMBER;
  v_result               NUMBER;
  v_modelid              NUMBER;
  v_modelid_old          NUMBER;
  v_usedatamodel         INT;
  v_usedatamodel_old     INT;
  v_countCases           NUMBER;

  -- documents
  v_DefaultDocFolder       NUMBER;
  v_DefaultPortalDocFolder NUMBER;
  v_DefaultMailFolder      NUMBER;

  --events
  v_CUSTOMDATAPROCESSOR      NVARCHAR2(255);
  v_UPDATECUSTDATAPROCESSOR  NVARCHAR2(255);
  v_PROCESSORCODE            NVARCHAR2(255);
  v_RETCUSTDATAPROCESSOR     NVARCHAR2(255);
  v_CUSTOMVALIDATOR          NVARCHAR2(255);
  v_CUSTOMVALRESULTPROCESSOR NVARCHAR2(255);
  v_customcountdataprocessor NVARCHAR2(255);

  v_isId INT;
  --standard
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);

BEGIN
  v_CaseSysTypeId        := :Id;
  v_ShowInPortal         := :ShowInPortal;
  v_iconcode             := :IconCode;
  v_ResolutionCodeIds_SV := :RESOLUTIONCODES_IDS;
  v_isdeleted            := :IsDeleted;
  v_debugmode            := :DebugMode;
  v_isdraftmodeavail     := :IsDraftModeAvail;

  v_procedure_id   := :Procedure_Id;
  v_stateconfig_id := :StateConfig_Id;
  v_PriorityId     := :Priority_Id;
  v_usedatamodel   := :UseDataModel;
  v_modelid        := :DataModel_Id;

  v_casetypename      := :NAME;
  v_casetypecode      := :Code;
  v_casetypecolorcode := :ColorCode;
  v_description       := :Description;

  --events
  v_CUSTOMDATAPROCESSOR      := :CUSTOMDATAPROCESSOR;
  v_UPDATECUSTDATAPROCESSOR  := :UPDATECUSTDATAPROCESSOR;
  v_PROCESSORCODE            := :PROCESSORCODE;
  v_RETCUSTDATAPROCESSOR     := :RETCUSTDATAPROCESSOR;
  v_CUSTOMVALIDATOR          := :CUSTOMVALIDATOR;
  v_CUSTOMVALRESULTPROCESSOR := :CUSTOMVALRESULTPROCESSOR;
  v_customcountdataprocessor := :CUSTOMCOUNTDATAPROCESSOR;

  --documents
  v_DefaultDocFolder       := :DEFAULTDOCFOLDER;
  v_DefaultPortalDocFolder := :DEFAULTPORTALDOCFOLDER;
  v_DefaultMailFolder      := :DEFAULTMAILFOLDER;
  :SuccessResponse         := EMPTY_CLOB();
  v_errorcode              := 0;
  v_errormessage           := '';

  -- validation on Id is Exist
  IF NVL(v_casesystypeid, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_casesystypeid, tablename => 'TBL_DICT_CASESYSTYPE');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  -- get Data Model info
  SELECT col_casesystypemodel,
         col_usedatamodel
    INTO v_modelid_old,
         v_usedatamodel_old
    FROM tbl_dict_casesystype
   WHERE col_id = v_casesystypeid;

  IF NVL(v_usedatamodel, 0) = 0 THEN
    v_modelid := NULL;
  END IF;

  -- check on Case(s) is(are) exist for CaseType
  IF ((NVL(v_modelid, 0) <> NVL(v_modelid_old, 0)) AND NVL(v_usedatamodel, 0) = 0 AND NVL(v_usedatamodel_old, 0) = 1) OR
     ((NVL(v_modelid, 0) <> NVL(v_modelid_old, 0)) AND NVL(v_usedatamodel, 0) = 1 AND NVL(v_usedatamodel_old, 0) = 1) THEN
    SELECT COUNT(col_id) INTO v_countCases FROM TBL_CASE WHERE col_casedict_casesystype = v_casesystypeid;
    IF v_countCases > 0 THEN
      v_errormessage := 'You cannot change link to Data Model for this Case Type.' || '<br>There are one or more Cases referencing this Case Type.' || '<br>Remove these Cases and try again.';
      v_errorcode    := 10;
      GOTO cleanup;
    END IF;
  END IF;

  --CREATE CUSTOM DATA MODEL
  IF (NVL(v_usedatamodel, 0) = 1) AND (NVL(v_modelid, 0) = 0) THEN
    BEGIN
      INSERT INTO TBL_MDM_MODEL
        (COL_CODE, COL_NAME, COL_DESCRIPTION, COL_ISDELETED, COL_USEDFOR)
      VALUES
        (v_casetypecode, v_casetypename, ' Automatically created when Case Type ' || v_casetypename || ' was modified', 0, 'CASE_TYPE')
      RETURNING col_id INTO v_modelid;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        v_errormessage := 'Data Model Name has to be unique!' || chr(10) || 'Please select other Data Model.';
        v_errorcode    := 11;
        ROLLBACK;
        GOTO cleanup;
      WHEN OTHERS THEN
        v_errormessage := substr(SQLERRM, 1, 200);
        v_errorcode    := 12;
        ROLLBACK;
        GOTO cleanup;
    END;
  END IF;

  --find and update the Case Sys Type record
  BEGIN
    UPDATE tbl_dict_casesystype
       SET col_name                     = v_casetypename,
           col_code                     = v_casetypecode,
           col_colorcode                = v_casetypecolorcode,
           col_description              = v_description,
           col_showinportal             = v_ShowInPortal,
           col_CUSTOMDATAPROCESSOR      = v_CUSTOMDATAPROCESSOR,
           COL_UPDATECUSTDATAPROCESSOR  = v_UPDATECUSTDATAPROCESSOR,
           col_PROCESSORCODE            = v_PROCESSORCODE,
           col_RETCUSTDATAPROCESSOR     = v_RETCUSTDATAPROCESSOR,
           col_CUSTOMVALIDATOR          = v_CUSTOMVALIDATOR,
           col_CUSTOMVALRESULTPROCESSOR = v_CUSTOMVALRESULTPROCESSOR,
           col_CUSTOMCOUNTDATAPROCESSOR = v_customcountdataprocessor,
           col_isdeleted                = v_isdeleted,
           col_DefaultDocFolder         = v_DefaultDocFolder,
           col_DefaultPortalDocFolder   = v_DefaultPortalDocFolder,
           col_DefaultMailFolder        = v_DefaultMailFolder,
           COL_STATECONFIGCASESYSTYPE   = v_stateconfig_id,
           COL_CASESYSTYPEPROCEDURE     = v_procedure_id,
           COL_CASETYPEPRIORITY         = v_PriorityId,
           COL_DEBUGMODE                = v_debugmode,
           COL_ISDRAFTMODEAVAIL         = v_isdraftmodeavail,
           COL_ICONCODE                 = v_iconcode,
           COL_CASESYSTYPEMODEL         = v_modelid,
           COL_USEDATAMODEL             = v_usedatamodel
     WHERE col_id = v_casesystypeid;
  EXCEPTION
    WHEN no_data_found THEN
      :ErrorCode    := 103;
      :ErrorMessage := 'Case Type not found';
      RETURN;
    WHEN DUP_VAL_ON_INDEX THEN
      :ErrorCode    := 104;
      :ErrorMessage := 'There already exists a Case Type with this Code';
      RETURN;
    WHEN OTHERS THEN
      :ErrorCode    := 999;
      :ErrorMessage := 'An error was encountered - ' || SQLCODE || ' -ERROR- ' || SQLERRM;
      RETURN;
  END;

  --CREATE LINKS TO RESOLUTION CODES
  DELETE FROM tbl_casesystyperesolutioncode WHERE col_tbl_dict_casesystype = v_casesystypeid;
  FOR rec IN (SELECT TO_NUMBER(regexp_substr(v_resolutioncodeids_sv, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS resolutioncodeid
                FROM dual
              CONNECT BY dbms_lob.getlength(regexp_substr(v_resolutioncodeids_sv, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) LOOP
    INSERT INTO tbl_casesystyperesolutioncode (col_casetyperesolutioncode, col_tbl_dict_casesystype) VALUES (rec.resolutioncodeid, v_casesystypeid);
  END LOOP;

  --CREATE CASESTATEINITIATION RECORDS FOR CREATED ABOVE CASE SYSTEM TYPE
  v_result := F_STP_SYNCCASESTATEINITTMPLSFN(v_casesystypeid, v_errorcode, v_errormessage);
  IF v_errorcode <> 0 THEN
    GOTO cleanup;
  END IF;

  -- have to delete assoc forms for the old MDM model
  IF v_modelid <> v_modelid_old THEN
    DELETE FROM TBL_ASSOCPAGE
     WHERE COL_ASSOCPAGEDICT_CASESYSTYPE = v_casesystypeid
       AND COL_ASSOCPAGEMDM_FORM IS NOT NULL;
  END IF;

  -- CREATE AN ASSOC PAGE
  IF v_modelid IS NOT NULL THEN
    BEGIN
      INSERT INTO TBL_ASSOCPAGE
        (COL_TITLE, COL_ASSOCPAGEASSOCPAGETYPE, COL_DESCRIPTION, COL_CODE, COL_ASSOCPAGEMDM_FORM, COL_ASSOCPAGEDICT_CASESYSTYPE)
        SELECT t1.formName,
               PageType.COL_ID AS PageTypeID,
               'The record was added when an MDM Model was saved.',
               SYS_GUID(),
               t1.formID,
               v_casesystypeid
          FROM (SELECT f.COL_NAME AS formName,
                       f.col_id   AS formID
                  FROM TBL_MDM_FORM f
                 INNER JOIN TBL_DOM_OBJECT o
                    ON (f.COL_MDM_FORMDOM_OBJECT = o.COL_ID AND o.COL_ISROOT = 1 AND nvl(f.COL_ISDELETED, 0) = 0)
                 INNER JOIN TBL_DOM_MODEL m
                    ON o.COL_DOM_OBJECTDOM_MODEL = m.COL_ID
                 INNER JOIN TBL_MDM_MODEL mm
                    ON (m.COL_DOM_MODELMDM_MODEL = mm.COL_ID AND mm.COL_ID = v_modelid)
                 WHERE ROWNUM = 1) t1,
               (SELECT pt.COL_ID
                  FROM TBL_DICT_ASSOCPAGETYPE pt
                 WHERE pt.COL_CODE IN ('MDM_UPDATE_FORM', 'MDM_CREATE_FORM', 'MDM_DETAIL_FORM', 'MDM_UPDATE_PORTAL_FORM', 'MDM_CREATE_PORTAL_FORM', 'MDM_DETAIL_PORTAL_FORM')) PageType
         WHERE NOT EXISTS (SELECT NULL
                  FROM TBL_ASSOCPAGE asocPage
                 WHERE asocPage.COL_ASSOCPAGEDICT_CASESYSTYPE = v_casesystypeid
                      --AND asocPage.COL_ASSOCPAGEMDM_FORM = t1.formID
                   AND asocPage.COL_ASSOCPAGEASSOCPAGETYPE = PageType.COL_ID);
    EXCEPTION
      WHEN OTHERS THEN
        v_errorcode    := 10;
        v_errormessage := substr(SQLERRM, 1, 200);
        ROLLBACK;
        GOTO cleanup;
    END;
  END IF;

  v_result := LOC_i18n(MessageText => 'Updated {{MESS_NAME}} case type', MessageResult => :SuccessResponse, MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_casetypecode)));

  <<cleanup>>
  :ErrorCode    := v_errorcode;
  :ErrorMessage := v_errormessage;
END;
