DECLARE
  v_casetypecode  NVARCHAR2(255);
  v_stateconfigid NUMBER;
  v_CaseSysTypeId NUMBER;
  v_initmethodid  NUMBER;
  v_result        NUMBER;
  v_isId          NUMBER;

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);

BEGIN

  --init
  v_CaseSysTypeId := CaseSysTypeId;
  v_casetypecode  := NULL;
  v_stateconfigid := NULL;
  v_initmethodid  := NULL;

  v_errorcode    := 0;
  v_errormessage := '';

  IF NVL(v_CaseSysTypeId, 0) <= 0 THEN
    v_errorcode    := -1;
    v_errormessage := 'A parameter CaseSysTypeId cannot be NULL.';
    GOTO cleanup;
  END IF;

  --Get CaseSysTypeCode and the Case Type's DICT_StateConfig
  BEGIN
    SELECT col_code, col_stateconfigcasesystype INTO v_casetypecode, v_stateconfigid FROM TBL_DICT_CASESYSTYPE WHERE col_id = v_CaseSysTypeId;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_errorcode    := -1;
      v_errormessage := 'Cant define a CaseSysType code for ID {{MESS_ID}}';
      v_result       := LOC_i18n(MessageText   => v_errormessage,
                                 MessageResult => v_errormessage,
                                 MessageParams => NES_TABLE(Key_Value('MESS_ID', TO_CHAR(v_CaseSysTypeId))));
      GOTO cleanup;
  END;

  IF NVL(v_stateconfigid, 0) = 0 THEN
    BEGIN
      --Get the Default Case DICT_StateConfig
      SELECT col_id
        INTO v_stateconfigid
        FROM TBL_DICT_STATECONFIG
       WHERE col_isdefault = 1
         AND lower(col_type) = 'case'
         AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_stateconfigid := 0;
    END;
  END IF;

  --Delete the Case Type's old MAP_CaseStateInitTmpl and map_casestateinitiation  records
  BEGIN
    DELETE FROM TBL_MAP_CASESTATEINITTMPL WHERE COL_CASESTATEINITTP_CASETYPE = v_CaseSysTypeId;
  EXCEPTION
    WHEN OTHERS THEN
      v_errorCode    := 100;
      v_errorMessage := SUBSTR(SQLERRM, 1, 200);
      GOTO cleanup;
  END;
  BEGIN
    DELETE FROM TBL_MAP_CASESTATEINITIATION WHERE COL_CASESTATEINIT_CASESYSTYPE = v_CaseSysTypeId;
  EXCEPTION
    WHEN OTHERS THEN
      v_errorCode    := 100;
      v_errorMessage := SUBSTR(SQLERRM, 1, 200);
      GOTO cleanup;
  END;

  --Create a record in MAP_CASESTATEINITTMPL and TBL_MAP_CASESTATEINITIATION 
  --for every DICT_CaseState in that DICT_StateConfig
  v_initmethodid := F_UTIL_GETIDBYCODE(Code => 'MANUAL', TableName => 'tbl_dict_initmethod');

  FOR rec IN (SELECT col_id, col_code, col_name FROM TBL_DICT_CASESTATE WHERE NVL(col_stateconfigcasestate, 0) = NVL(v_stateconfigid, 0)) LOOP
    BEGIN
      INSERT INTO TBL_MAP_CASESTATEINITIATION
        (col_casestateinit_casesystype, col_casestateinit_initmethod, col_map_csstinit_csst, col_code)
      VALUES
        (v_casesystypeid,
         v_initmethodid,
         rec.col_id,
         F_UTIL_CALCUNIQUECODE(BaseCode => v_casetypecode || '_' || rec.col_code, TableName => 'tbl_map_casestateinitiation'));
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        v_errormessage := 'Case State Initiation Code has to be unique!';
        v_errorcode    := 2;
        ROLLBACK;
        GOTO cleanup;
      WHEN OTHERS THEN
        v_errormessage := SUBSTR(SQLERRM, 1, 200);
        v_errorcode    := 3;
        ROLLBACK;
        GOTO cleanup;
    END;
    BEGIN
      INSERT INTO TBL_MAP_CASESTATEINITTMPL
        (col_casestateinittp_casetype, col_casestateinittp_initmtd, col_map_csstinittp_csst, col_code)
      VALUES
        (v_casesystypeid,
         v_initmethodid,
         rec.col_id,
         f_UTIL_calcUniqueCode(BaseCode => v_casetypecode || '_' || rec.col_code, TableName => 'tbl_map_casestateinittmpl'));
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        v_errormessage := 'Case State Initiatiation Template Code has to be unique!';
        v_errorcode    := 4;
        ROLLBACK;
        GOTO cleanup;
      WHEN OTHERS THEN
        v_errormessage := SUBSTR(SQLERRM, 1, 200);
        v_errorcode    := 5;
        ROLLBACK;
        GOTO cleanup;
    END;
  END LOOP; --eof LOOP

  <<cleanup>>
  errorCode    := v_errorcode;
  errorMessage := v_errormessage;
END;