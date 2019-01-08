DECLARE 
  v_caseid                INTEGER; 
  v_casetitle             NVARCHAR2(255); 
  v_casetypeid            INTEGER; 
  v_casetypecode          NVARCHAR2(255); 
  v_casetypename          NVARCHAR2(255); 
  v_casetypeprocessorcode NVARCHAR2(255); 
  v_stateconfigid         INTEGER; 
  v_errorcode             NUMBER; 
  v_errormessage          NVARCHAR2(255); 
  v_affectedrows          NUMBER; 
  v_result                NUMBER; 
  v_CSisInCache           INTEGER;

BEGIN 
  v_caseid := :CaseId; 
  v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache

  --case not in new cache
  IF v_CSisInCache=0 THEN	 
    BEGIN 
        SELECT cs.col_casedict_casesystype 
        INTO   v_casetypeid 
        FROM   tbl_case cs 
        INNER JOIN TBL_CW_WORKITEM cwi  ON cs.col_cw_workitemcase = cwi.col_id 
        WHERE  cs.col_id = v_caseid; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_casetypeid := NULL;
          v_errorcode := 101; 
          v_errormessage := 'Case type for case ' || To_char(v_caseid) || ' not found'; 
          RETURN -1; 
    END; 
  END IF;


  --case in new cache
  IF v_CSisInCache=1 THEN	 
    BEGIN 
        SELECT cs.col_casedict_casesystype 
        INTO   v_casetypeid 
        FROM   tbl_cscase cs 
        INNER JOIN TBL_CSCW_WORKITEM cwi  ON cs.col_cw_workitemcase = cwi.col_id 
        WHERE  cs.col_id = v_caseid; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_casetypeid := NULL;
          v_errorcode := 101; 
          v_errormessage := 'Case type for case ' || To_char(v_caseid) || ' not found'; 
          RETURN -1; 
    END; 
  END IF;

  BEGIN 
      SELECT col_code, 
             col_name, 
             col_processorcode, 
             col_stateconfigcasesystype 
      INTO   v_casetypecode, v_casetypename, v_casetypeprocessorcode, 
             v_stateconfigid 
      FROM   tbl_dict_casesystype 
      WHERE  col_id = v_casetypeid; 
  EXCEPTION 
      WHEN no_data_found THEN 
        v_errorcode := 102; 
        v_errormessage := 'Case type not found'; 

        RETURN -1; 
  END; 

  --GENERATE CASE TITLE 
  IF v_casetypeprocessorcode IS NOT NULL THEN 
    v_casetitle := F_dcm_invokecaseidgenproc(caseid => v_caseid, processorname => v_casetypeprocessorcode);  
  ELSE 
    v_casetitle:='CASE' || '-' || TO_CHAR(SYSDATE, 'YYYY')|| '-' || TO_CHAR(v_caseid); 
  END IF; 

     --case not in new cache
  IF v_CSisInCache=0 THEN
    UPDATE TBL_CASE 
    SET    COL_CASEID = v_casetitle 
    WHERE  COL_ID = v_caseid; 
  END IF;	 

     --case in new cache
  IF v_CSisInCache=1 THEN
    UPDATE TBL_CSCASE 
    SET    COL_CASEID = v_casetitle 
    WHERE  COL_ID = v_caseid; 
  END IF;

  :CaseTitle := v_casetitle; 
END; 
