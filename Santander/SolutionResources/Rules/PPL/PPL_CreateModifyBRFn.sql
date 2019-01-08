DECLARE
  v_id               NUMBER;
  v_name             NVARCHAR2(255);
  v_code             NVARCHAR2(255);
  v_description      NCLOB;
  v_AppBaseRole      NUMBER;
  v_errorCode        NUMBER;
  v_errorMessage     NVARCHAR2(255);
  v_resultId         NUMBER;
  v_wb_type          NUMBER;
  v_wb_id            NUMBER;
  v_accesssubject_id NUMBER;
  v_res              NUMBER;
  v_uniquecode       NVARCHAR2(255);
  v_objectprefix     NVARCHAR2(255);
BEGIN
  v_id           := NVL(:ID, 0);
  v_name         := :NAME;
  v_code         := :Code;
  v_description  := :Description;
  v_AppBaseRole  := :AppBaseRole;
  v_errorCode    := 0;
  v_errorMessage := '';
  v_ResultId     := 0;
  :ErrorCode     := v_errorCode;
  :ErrorMessage  := v_ErrorMessage;
  :ResultId      := v_resultId;
  v_objectprefix := 'BUSINESSROLE_';

  IF v_id = 0 THEN
    --Check if we link a team to exisitng AppBase Group
    IF v_AppBaseRole IS NOT NULL THEN
      BEGIN
        SELECT roleid INTO v_res FROM vw_role WHERE roleid = v_AppBaseRole;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_errorCode    := 120;
          v_errorMessage := 'Could not find AppBase Role with id# {{MESS_APPBASEROLE}}';
          v_res          := LOC_i18n(MessageText   => v_errormessage,
                                     MessageResult => v_errormessage,
                                     MessageParams => NES_TABLE(Key_Value('MESS_APPBASEROLE', v_AppBaseRole)));
        
          GOTO cleanup;
      END;
    END IF;
    --Create team record
    BEGIN
      INSERT INTO TBL_PPL_BUSINESSROLE
        (col_name, col_code, col_description, col_roleid)
      VALUES
        (v_name, v_code, v_description, v_AppBaseRole)
      RETURNING COL_ID INTO v_id;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        v_errorCode    := 122;
        v_errorMessage := 'Business Role Code must be unique';
        ROLLBACK;
        GOTO cleanup;
    END;
  
    BEGIN
      v_uniquecode := f_UTIL_calcUniqueCode(BaseCode => v_objectprefix || v_code, TableName => 'TBL_AC_ACCESSSUBJECT');
      INSERT INTO TBL_AC_ACCESSSUBJECT
        (col_type, col_name, col_code)
      VALUES
        ('BUSINESSROLE', v_name, v_uniquecode)
      RETURNING COL_ID INTO v_accesssubject_id;
      UPDATE tbl_ppl_businessrole SET col_businessroleaccesssubject = v_accesssubject_id WHERE col_id = v_id;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        v_errorCode    := 123;
        v_errorMessage := 'Access Subject already exists for the Business Role';
        ROLLBACK;
        GOTO cleanup;
    END;
  ELSE
    -- validation on Id is Exist
    IF v_id > 0 THEN
      v_res := f_UTIL_getId(errorcode => v_errorCode, errormessage => v_errorMessage, id => v_id, tablename => 'TBL_PPL_BUSINESSROLE');
      IF v_errorCode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    UPDATE TBL_PPL_BUSINESSROLE SET col_name = v_name, col_description = v_description, col_roleid = v_AppbaseRole WHERE col_id = v_id;
    UPDATE TBL_AC_ACCESSSUBJECT
       SET col_name = v_name
     WHERE col_id IN (SELECT col_businessroleaccesssubject FROM tbl_ppl_businessrole WHERE col_id = v_id);
  END IF;
  :ResultId := v_id;
  <<cleanup>>
  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;
  --dbms_output.put_line(v_errorMessage);
END;