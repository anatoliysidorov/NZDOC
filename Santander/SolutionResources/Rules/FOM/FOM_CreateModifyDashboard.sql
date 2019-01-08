DECLARE
  --custom 
  v_Id               tbl_FOM_Dashboard.COL_ID%TYPE;
  v_col_Name         tbl_FOM_Dashboard.COL_NAME%TYPE;
  v_col_Code         tbl_FOM_Dashboard.COL_CODE%TYPE;
  v_col_IsDeleted    tbl_FOM_Dashboard.COL_ISDELETED%TYPE;
  v_col_IsSystem     tbl_FOM_Dashboard.COL_ISSYSTEM%TYPE;
  v_col_IsDefault    tbl_FOM_Dashboard.COL_ISDEFAULT%TYPE;
  v_col_CaseWorkerId tbl_FOM_Dashboard.COL_DASHBOARDCASEWORKER%TYPE;
  v_col_Description  tbl_FOM_Dashboard.COL_DESCRIPTION%TYPE;
  v_col_Config       tbl_FOM_Dashboard.COL_CONFIG%TYPE;
  --standard      
  v_IsId            NUMBER;
  v_IsCaseWorker    NUMBER;
  v_IsAdministrator NUMBER;
  v_ListRoles       NCLOB;
  v_ErrorCode       NUMBER := 0;
  v_ErrorMessage    NVARCHAR2(255 CHAR) := '';
  v_affectedRows    NUMBER := 0;
  v_Result          NUMBER;
  v_DASHBOARDORDER  TBL_FOM_DASHBOARDCW.COL_DASHBOARDORDER%TYPE;
BEGIN
  --custom 
  v_Id               := :ID;
  v_col_Name         := :NAME;
  v_col_Code         := :CODE;
  v_col_isDeleted    := nvl(:ISDELETED, 0);
  v_col_isDefault    := nvl(:ISDEFAULT, 0);
  v_col_isSystem     := nvl(:ISSYSTEM, 0);
  v_col_CaseWorkerId := :CASEWORKERID;
  v_col_Description  := :DESCRIPTION;
  v_col_Config       := :CONFIG;
  v_DASHBOARDORDER   := :DASHBOARDORDER;
  --standard 
  :affectedRows := 0;

  -- validation on Id is Exist
  IF (NVL(v_Id, 0) > 0) THEN
    v_isId := f_UTIL_getId(errorCode => v_ErrorCode, errorMessage => v_ErrorMessage, Id => v_Id, TableName => 'TBL_FOM_DASHBOARD');
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;

  --check permission for update/delete
  SELECT list_collect(CAST(COLLECT(to_char(t1.localCode) ORDER BY to_char(t1.localCode)) AS split_tbl), ',', 1)
    INTO v_ListRoles
    FROM (SELECT usr_roles.USERID AS userid,
                 role.localCode   AS localCode
            FROM @TOKEN_SYSTEMDOMAINUSER@.asf_userrole usr_roles
            LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_role role
              ON usr_roles.roleid = role.roleid
           WHERE usr_roles.roleid IN (SELECT rl.roleid FROM @TOKEN_SYSTEMDOMAINUSER@.asf_role rl WHERE rl.envid = '@TOKEN_DOMAIN@')
          UNION
          SELECT usr_groups.userid AS userid,
                 role.localCode    AS localCode
            FROM @TOKEN_SYSTEMDOMAINUSER@.asf_usergroup usr_groups
            LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_grouprole group_role
              ON usr_groups.groupid = group_role.groupid
            LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_role role
              ON group_role.roleid = role.roleid
           WHERE group_role.roleid IN (SELECT rl.roleid FROM @TOKEN_SYSTEMDOMAINUSER@.asf_role rl WHERE rl.envid = '@TOKEN_DOMAIN@')) t1
   WHERE t1.userid = (SELECT users_view.userid FROM vw_users users_view WHERE users_view.accesssubjectcode = sys_context('CLIENTCONTEXT', 'AccessSubject'))
   GROUP BY t1.userid;

  SELECT COUNT(*)
    INTO v_IsAdministrator
    FROM (SELECT to_char(regexp_substr(v_ListRoles, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS NAME FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(v_ListRoles, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) s
   WHERE s.name = 'root_administrator';

  SELECT COUNT(*)
    INTO v_IsCaseWorker
    FROM (SELECT to_char(regexp_substr(v_ListRoles, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS NAME FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(v_ListRoles, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) s
   WHERE s.name = 'root_caseworker';

  IF (v_Id IS NOT NULL AND v_isAdministrator >= 1 AND v_isCaseWorker = 0 AND v_col_isSystem = 0) THEN
    v_ErrorCode    := 103;
    v_ErrorMessage := 'Sorry, you dont have permission for this act';
    GOTO cleanup;
  END IF;

  IF (v_Id IS NOT NULL AND v_isCaseWorker >= 1 AND v_isAdministrator = 0 AND v_col_isSystem = 1) THEN
    v_ErrorCode    := 103;
    v_ErrorMessage := 'Sorry, you dont have permission for this act';
    GOTO cleanup;
  END IF;

  IF (v_col_CaseWorkerId IS NULL) AND (v_col_isSystem = 0) THEN
    v_col_CaseWorkerId := f_dcm_getcaseworkerId();
  END IF;

  BEGIN
    IF (v_Id IS NULL) THEN
      INSERT INTO tbl_FOM_Dashboard
        (col_Code, col_Name, col_isDeleted, col_isDefault, col_isSystem, col_DashboardCaseWorker, col_Description, col_Config)
      VALUES
        (v_col_Code, v_col_Name, v_col_isDeleted, v_col_isDefault, v_col_isSystem, v_col_CaseWorkerId, v_col_Description, v_col_Config)
      RETURNING col_id INTO v_Id;
    
      IF (v_col_isSystem = 0) THEN
        INSERT INTO TBL_FOM_DASHBOARDCW (COL_CASEWORKER, COL_DASHBOARD, COL_DASHBOARDORDER) VALUES (v_col_CaseWorkerId, v_Id, v_DASHBOARDORDER);
      END IF;
    
      :SuccessResponse := 'Created {{MESS_NAME}} dashboard';
    ELSE
      UPDATE tbl_FOM_Dashboard
         SET COL_NAME                = v_col_Name,
             COL_ISDELETED           = v_col_isDeleted,
             COL_ISDEFAULT           = v_col_isDefault,
             COL_ISSYSTEM            = v_col_isSystem,
             COL_DASHBOARDCASEWORKER = v_col_CaseWorkerId,
             COL_DESCRIPTION         = v_col_Description,
             COL_CONFIG              = v_col_Config
       WHERE COL_ID = v_Id;
      :SuccessResponse := 'Updated {{MESS_NAME}} dashboard';
    END IF;
    :affectedRows := SQL%ROWCOUNT;
    :recordId     := v_Id;
    v_Result      := LOC_i18n(MessageText => :SuccessResponse, MessageResult => :SuccessResponse, MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_col_Name)));
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      :affectedRows    := 0;
      v_ErrorCode      := 101;
      v_Result         := LOC_i18n(MessageText   => 'There already exists a dashboard with the code {{MESS_CODE}}',
                                   MessageResult => v_ErrorMessage,
                                   MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_col_Code)));
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_ErrorCode      := 102;
      v_ErrorMessage   := '$t(Exception:) ' || substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;
  <<cleanup>>
  :errorCode    := v_ErrorCode;
  :errorMessage := v_ErrorMessage;
END;
