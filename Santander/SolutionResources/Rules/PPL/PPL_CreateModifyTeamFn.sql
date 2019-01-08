DECLARE
  v_id               NUMBER;
  v_name             NVARCHAR2(255);
  v_code             NVARCHAR2(255);
  v_description      NCLOB;
  v_AppBaseGroup     NUMBER;
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
  v_AppBaseGroup := :AppBaseGroup;
  v_errorCode    := 0;
  v_errorMessage := '';
  v_ResultId     := 0;
  :ErrorCode     := v_errorCode;
  :ErrorMessage  := v_ErrorMessage;
  :ResultId      := v_resultId;
  v_objectprefix := 'TEAM_';

  IF v_id = 0 THEN
    --Check if we link a team to exisitng AppBase Group
    IF v_AppBaseGroup IS NOT NULL THEN
      BEGIN
        SELECT col_id INTO v_res FROM vw_ppl_appbasegroup WHERE col_id = v_AppBaseGroup;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_errorCode    := 120;
          v_errorMessage := 'Could not find AppBase Group with id# {{MESS_APPBASEGROUP}}';
          v_res          := LOC_i18n(MessageText   => v_errormessage,
                                     MessageResult => v_errormessage,
                                     MessageParams => NES_TABLE(Key_Value('MESS_APPBASEGROUP', v_AppBaseGroup)));
          GOTO cleanup;
      END;
    END IF;
  
    --Create a new Team
    BEGIN
      INSERT INTO TBL_PPL_TEAM
        (col_name, col_code, col_description, col_groupid)
      VALUES
        (v_name, v_code, v_description, v_AppBaseGroup)
      RETURNING col_id INTO v_id;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        v_errorCode    := 122;
        v_errorMessage := 'Team Code must be unique';
        ROLLBACK;
        GOTO cleanup;
    END;
  
    BEGIN
      v_uniquecode := f_UTIL_calcUniqueCode(BaseCode => v_objectprefix || v_code, TableName => 'TBL_AC_ACCESSSUBJECT');
      INSERT INTO TBL_AC_ACCESSSUBJECT (col_type, col_name, col_code) VALUES ('TEAM', v_name, v_uniquecode) RETURNING COL_ID INTO v_accesssubject_id;
      UPDATE tbl_ppl_team SET col_teamaccesssubject = v_accesssubject_id WHERE col_id = v_id;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        v_errorCode    := 123;
        v_errorMessage := 'Access Subject already exists for the Team';
        ROLLBACK;
        GOTO cleanup;
    END;
  ELSE
    -- validation on Id is Exist
    IF v_id > 0 THEN
      v_res := f_UTIL_getId(errorcode => v_errorCode, errormessage => v_errorMessage, id => v_id, tablename => 'TBL_PPL_TEAM');
      IF v_errorCode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    UPDATE TBL_PPL_TEAM SET col_name = v_name, col_description = v_description, col_groupid = v_appbasegroup WHERE col_id = v_id;
    UPDATE TBL_AC_ACCESSSUBJECT SET col_name = v_name WHERE col_id IN (SELECT col_teamaccesssubject FROM tbl_ppl_team WHERE col_id = v_id);
  END IF;
  :ResultId := v_id;

  <<cleanup>>
  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;
--  dbms_output.put_line(v_errorMessage);
END;