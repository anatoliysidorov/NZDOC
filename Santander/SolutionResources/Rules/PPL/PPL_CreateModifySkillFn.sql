DECLARE
  v_id               NUMBER;
  v_name             NVARCHAR2(255);
  v_code             NVARCHAR2(255);
  v_description      NCLOB;
  v_errorCode        NUMBER;
  v_errorMessage     NVARCHAR2(255);
  v_uniquecode       NVARCHAR2(255);
  v_resultId         NUMBER;
  v_accesssubject_id NUMBER;
  v_res              NUMBER;
  v_objectprefix     NVARCHAR2(255);
BEGIN
  v_id           := NVL(:ID, 0);
  v_name         := :NAME;
  v_code         := :Code;
  v_description  := :Description;
  v_errorCode    := 0;
  v_errorMessage := '';
  v_ResultId     := 0;
  :ErrorCode     := v_errorCode;
  :ErrorMessage  := v_ErrorMessage;
  :ResultId      := v_resultId;
  v_objectprefix := 'SKILL_';

  IF v_id = 0 THEN
    /*--Create skill record*/
    BEGIN
      INSERT INTO TBL_PPL_SKILL (col_name, col_code, col_description) VALUES (v_name, v_code, v_description) RETURNING COL_ID INTO v_id;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        v_errorCode    := 122;
        v_errorMessage := 'Skill Code must be unique';
        ROLLBACK;
        GOTO cleanup;
    END;
  
    BEGIN
      v_uniquecode := f_UTIL_calcUniqueCode(BaseCode => v_objectprefix || v_code, TableName => 'TBL_AC_ACCESSSUBJECT');
      INSERT INTO TBL_AC_ACCESSSUBJECT
        (col_type, col_name, col_code)
      VALUES
        ('SKILL', v_name, v_uniquecode)
      RETURNING COL_ID INTO v_accesssubject_id;
      UPDATE TBL_PPL_SKILL SET col_skillaccesssubject = v_accesssubject_id WHERE col_id = v_id;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        v_errorCode    := 123;
        v_errorMessage := 'Access Subject already exists for the Skill';
        ROLLBACK;
        GOTO cleanup;
    END;
  ELSE
    /*-- validation on Id is Exist*/
    IF v_id > 0 THEN
      v_res := f_UTIL_getId(errorcode => v_errorCode, errormessage => v_errorMessage, id => v_id, tablename => 'TBL_PPL_SKILL');
      IF v_errorCode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    UPDATE TBL_PPL_SKILL SET col_name = v_name, col_description = v_description WHERE col_id = v_id;
    UPDATE TBL_AC_ACCESSSUBJECT SET col_name = v_name WHERE col_id IN (SELECT col_skillaccesssubject FROM tbl_ppl_skill WHERE col_id = v_id);
  END IF;
  :ResultId := v_id;
  <<cleanup>>
  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;
  --  dbms_output.put_line(v_errorMessage);
END;