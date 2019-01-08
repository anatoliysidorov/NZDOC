DECLARE
  v_casetypename         NVARCHAR2(255);
  v_casetypecode         NVARCHAR2(255);
  v_iconcode             NVARCHAR2(255);
  v_casetypecolorcode    NVARCHAR2(7);
  v_description          NCLOB;
  v_ShowInPortal         NUMBER;
  v_stateconfigid        NUMBER;
  v_casesystypeid        NUMBER;
  v_procedureid          NUMBER;
  v_ResolutionCodeIds_SV NCLOB;
  v_result               NUMBER;
  v_errormessage         NVARCHAR2(255);
  v_errorcode            NUMBER;
  v_aotid                NUMBER;
  v_PriorityId           NUMBER;
  v_milestoneid          NUMBER;
  v_modelid              NUMBER;

  v_IsDraftModeAvail       NUMBER;
  v_DebugMode              NUMBER;
  v_DefaultDocFolder       NUMBER;
  v_DefaultPortalDocFolder NUMBER;
  v_DefaultMailFolder      NUMBER;
  v_UseDataModel           NUMBER;

  v_Input           CLOB;
  v_SuccessResponse CLOB;
  v_tmpNUM          NUMBER;

  --events
  v_CUSTOMDATAPROCESSOR      NVARCHAR2(255);
  v_UPDATECUSTDATAPROCESSOR  NVARCHAR2(255);
  v_PROCESSORCODE            NVARCHAR2(255);
  v_RETCUSTDATAPROCESSOR     NVARCHAR2(255);
  v_CUSTOMVALIDATOR          NVARCHAR2(255);
  v_CUSTOMVALRESULTPROCESSOR NVARCHAR2(255);
  v_customcountdataprocessor NVARCHAR2(255);

BEGIN
  v_casetypename         := :NAME;
  v_casetypecode         := :Code;
  v_iconcode             := NVL(:IconCode, 'cubes');
  v_casetypecolorcode    := :ColorCode;
  v_description          := :Description;
  v_ShowInPortal         := :ShowInPortal;
  v_ResolutionCodeIds_SV := :RESOLUTIONCODES_IDS;
  v_IsDraftModeAvail     := :ISDRAFTMODEAVAIL;
  v_DebugMode            := :DEBUGMODE;
  v_stateconfigid        := :StateConfig_Id;
  v_procedureid          := :Procedure_Id;
  v_modelid              := :DataModel_Id;
  v_PriorityId           := :Priority_Id;
  v_UseDataModel         := :UseDataModel;

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

  --common
  v_errormessage    := '';
  v_errorcode       := 0;
  v_Input           := NULL;
  v_tmpNUM          := NULL;
  v_SuccessResponse := EMPTY_CLOB();

  :SuccessResponse := '';

  --CREATE CASE SYSTEM TYPE
  BEGIN
    INSERT INTO tbl_dict_casesystype
      (col_name,
       col_code,
       col_colorcode,
       col_description,
       col_showinportal,
       col_customdataprocessor,
       COL_UPDATECUSTDATAPROCESSOR,
       col_processorcode,
       col_retcustdataprocessor,
       col_customvalidator,
       col_CUSTOMVALRESULTPROCESSOR,
       col_CUSTOMCOUNTDATAPROCESSOR,
       col_IsDraftModeAvail,
       col_DebugMode,
       col_DefaultDocFolder,
       col_DefaultPortalDocFolder,
       col_DefaultMailFolder,
       col_isdeleted,
       col_casetypepriority,
       col_iconcode,
       col_usedatamodel)
    VALUES
      (v_casetypename,
       v_casetypecode,
       v_casetypecolorcode,
       v_description,
       v_showinportal,
       v_customdataprocessor,
       v_UPDATECUSTDATAPROCESSOR,
       v_processorcode,
       v_retcustdataprocessor,
       v_customvalidator,
       v_CUSTOMVALRESULTPROCESSOR,
       v_customcountdataprocessor,
       v_IsDraftModeAvail,
       v_DebugMode,
       v_DefaultDocFolder,
       v_DefaultPortalDocFolder,
       v_DefaultMailFolder,
       0,
       v_PriorityId,
       v_iconcode,
       v_UseDataModel)
    RETURNING col_id INTO v_casesystypeid;
    :CaseTypeId := v_CaseSysTypeId;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      v_errormessage := 'Case Type Code has to be unique';
      v_errorcode    := 1;
      ROLLBACK;
      GOTO cleanup;
    WHEN OTHERS THEN
      v_errormessage := substr(SQLERRM, 1, 200);
      v_errorcode    := 2;
      ROLLBACK;
      GOTO cleanup;
  END;

  --FIND 'MANUAL' INITIATION METHOD
  IF NVL(v_stateconfigid, 0) = 0 THEN
    BEGIN
      SELECT col_id
        INTO v_stateconfigid
        FROM tbl_dict_StateConfig
       WHERE col_isdefault = 1
         AND lower(col_type) = 'case'
         AND ROWNUM = 1;
    EXCEPTION
      WHEN OTHERS THEN
        v_stateconfigid := 0;
    END;
  END IF;

  --CREATE PROCEDURE IF EMPTY
  IF NVL(v_procedureid, 0) = 0 THEN
    -- CREATE PROCEDURE RECORD
    BEGIN
      INSERT INTO tbl_procedure
        (col_name, col_description, col_isdefault, col_isdeleted, col_code, col_proceduredict_casesystype)
      VALUES
        (v_casetypename,
         v_description || ' Automatically created when Case Type ' || v_casetypename || ' was created',
         0,
         0,
         f_UTIL_calcUniqueCode(BaseCode => v_casetypecode, TableName => 'tbl_procedure'),
         v_CaseSysTypeId)
      RETURNING col_id INTO v_procedureid;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        v_errormessage := 'Procedure Code has to be unique!';
        v_errorcode    := 5;
        ROLLBACK;
        GOTO cleanup;
      WHEN OTHERS THEN
        v_errormessage := substr(SQLERRM, 1, 200);
        v_errorcode    := 6;
        ROLLBACK;
        GOTO cleanup;
    END;
    -- CREATE ROOT TASK TEMPLATE FOR PROCEDURE
    BEGIN
      INSERT INTO tbl_tasktemplate
        (col_name, col_taskid, col_leaf, col_parentttid, col_taskorder, col_depth, col_icon, col_description, col_proceduretasktemplate, col_systemtype, col_code)
      VALUES
        ('Root', 'root', 0, 0, 1, 0, 'folder', v_description, v_procedureid, 'Root', f_UTIL_calcUniqueCode(BaseCode => v_casetypecode || '_' || 'ROOT', TableName => 'tbl_procedure'));
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        v_errormessage := 'Task Template Code has to be unique!';
        v_errorcode    := 7;
        ROLLBACK;
        GOTO cleanup;
      WHEN OTHERS THEN
        v_errormessage := substr(SQLERRM, 1, 200);
        v_errorcode    := 8;
        ROLLBACK;
        GOTO cleanup;
    END;
  END IF;

  --CREATE CUSTOM DATA MODEL
  IF NVL(v_UseDataModel, 0) = 1 AND NVL(v_modelid, 0) = 0 THEN
    BEGIN
      INSERT INTO TBL_MDM_MODEL
        (COL_CODE, COL_NAME, COL_DESCRIPTION, COL_ISDELETED, COL_USEDFOR)
      VALUES
        (v_casetypecode, v_casetypename, ' Automatically created when Case Type ' || v_casetypename || ' was created', 0, 'CASE_TYPE')
      RETURNING col_id INTO v_modelid;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        v_errormessage := 'Data Model Name has to be unique!';
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
  IF NVL(v_UseDataModel, 0) = 0 THEN
    v_modelid := NULL;
  END IF;

  --LINK PROCEDURE, DATA MODEL TO CASE TYPE
  UPDATE tbl_DICT_CaseSysType
     SET COL_CASESYSTYPEPROCEDURE   = v_procedureid,
         COL_CASETYPEPROCINCASETYPE = f_UTIL_getIdByCode(Code => 'shared_single', TableName => 'tbl_DICT_PROCEDUREINCASETYPE'),
         COL_STATECONFIGCASESYSTYPE = v_stateconfigid,
         COL_CASESYSTYPEMODEL       = v_modelid
   WHERE col_id = v_casesystypeid;

  --CREATE CUSTOM MILESTONE  
  --first, try to convert a default case state machine to custom milestone
  IF NVL(v_stateconfigid, 0) <> 0 THEN
    v_result := f_STP_CreateMSfromDefaultFn(CASESYSTYPEID     => NULL,
                                            DEFSTATECONFIGID  => v_stateconfigid,
                                            ERRORCODE         => v_errorcode,
                                            NEW_CUSTOMCONFIG  => v_Input,
                                            ERRORMESSAGE      => v_errormessage,
                                            NEW_STATECONFIGID => v_tmpNUM);
  
    IF NVL(v_errorcode, 0) <> 0 THEN
      v_Input := NULL;
    END IF;
    --no other error(s) handling needs
  END IF;

  --second, create a custom milestone
  v_result := f_STP_ModifyCaseStateDetailFn(SUCCESSRESPONSE   => v_SuccessResponse,
                                            casesystypeid     => v_casesystypeid,
                                            code              => v_casetypecode,
                                            errorcode         => v_errorcode,
                                            errormessage      => v_errormessage,
                                            iconcode          => v_iconcode,
                                            input             => v_Input,
                                            NAME              => v_casetypename,
                                            new_stateconfigid => v_milestoneid,
                                            CREATIONMODE      => 'MULTIPLE_VER');

  IF v_errorcode <> 0 THEN
    ROLLBACK;
    GOTO cleanup;
  END IF;

  --CREATE CASESTATEINITIATION RECORDS FOR CREATED ABOVE CASE SYSTEM TYPE
  v_result := F_STP_SYNCCASESTATEINITTMPLSFN(v_casesystypeid, v_errorcode, v_errormessage);
  IF v_errorcode <> 0 THEN
    GOTO cleanup;
  END IF;

  --CREATE LINKS TO RESOLUTION CODES
  FOR rec IN (SELECT TO_NUMBER(regexp_substr(v_resolutioncodeids_sv, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS resolutioncodeid
                FROM dual
              CONNECT BY dbms_lob.getlength(regexp_substr(v_resolutioncodeids_sv, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) LOOP
    INSERT INTO tbl_casesystyperesolutioncode (col_casetyperesolutioncode, col_tbl_dict_casesystype) VALUES (rec.resolutioncodeid, v_casesystypeid);
  END LOOP;

  -- CREATE ACCESS OBJECT FOR THE CASE TYPE
  v_aotid := f_UTIL_getIdByCode(Code => 'CASE_TYPE', TableName => 'tbl_ac_accessobjecttype');

  BEGIN
    INSERT INTO tbl_ac_accessobject
      (col_name, col_code, col_accessobjectcasesystype, col_accessobjaccessobjtype)
    VALUES
      ('Case Type ' || v_casetypename, F_util_calcuniquecode(basecode => v_casetypecode || '_' || 'CASE_TYPE', tablename => 'tbl_ac_accessobject'), v_casesystypeid, v_aotid);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      v_errormessage := 'Access Object Code has to be unique!';
      v_errorcode    := 9;
      ROLLBACK;
      GOTO cleanup;
    WHEN OTHERS THEN
      v_errorcode    := 10;
      v_errormessage := substr(SQLERRM, 1, 200);
      ROLLBACK;
      GOTO cleanup;
  END;

  --GENERATE SECURITY CACHE FOR THIS CASE TYPE
  v_result := f_DCM_createCTAccessCache();

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

  --FINISH
  --:SuccessResponse := 'Created '||v_casetypecode|| ' case type';
  v_result := LOC_i18n(MessageText => 'Created {{MESS_NAME}} case type', MessageResult => :SuccessResponse, MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_casetypecode)));
  <<cleanup>>
  :ErrorMessage := v_ErrorMessage;
  :ErrorCode    := v_errorcode;
END;
