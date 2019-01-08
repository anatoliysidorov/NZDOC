DECLARE
  v_userid           NUMBER;
  v_caseworker_id    NUMBER;
  v_accesssubject_id NUMBER;
  v_workbasket_id    NUMBER;
  v_username         NVARCHAR2(255);
  v_name             NVARCHAR2(255);
  v_code             NVARCHAR2(255);
  v_personal_wb_type NUMBER;
  v_uniquecode       NVARCHAR2(255);
  v_uniqueACCode     NVARCHAR2(255);
  v_uniquename       NVARCHAR2(255);
  v_externalid       NVARCHAR2(255);
  v_res              NUMBER;
  v_objectprefix     NVARCHAR2(255);
  -- Output params
  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);
BEGIN
  v_userid       := UserId;
  v_externalid   := ExternalId;
  v_errorCode    := 0;
  v_errorMessage := '';
  ErrorCode      := v_errorCode;
  ErrorMessage   := v_errorMessage;
  v_objectprefix := 'CASEWORKER_';

  IF NVL(v_userid, 0) = 0 THEN
    v_errorCode    := 120;
    v_errorMessage := 'Validation: ''User id'' is required field';
    ErrorCode      := v_errorCode;
    ErrorMessage   := v_errorMessage;
    RETURN - 1;
  END IF;

  --DETERMINE IF SUCH A USER EXISTS IN APPBASE   
  BEGIN
    SELECT login, NAME INTO v_username, v_name FROM vw_users WHERE userid = v_userid;
    IF v_username IS NULL THEN
      v_errorCode    := 121;
      v_errorMessage := 'AppBase User with  UserId# {{MESS_USERID}} was not found';
      v_res          := LOC_i18n(MessageText   => v_errormessage,
                                 MessageResult => v_errormessage,
                                 MessageParams => NES_TABLE(Key_Value('MESS_USERID', v_userid)));
      ErrorCode      := v_errorCode;
      ErrorMessage   := v_errorMessage;
      RETURN - 1;
    END IF;
  EXCEPTION
    WHEN no_data_found THEN
      NULL;
  END;

  --DETERMINE IF A CASEWORKER EXIST WITH SUCH EXTERNAL_ID
  BEGIN
    IF v_externalid IS NOT NULL THEN
      SELECT col_id
        INTO v_caseworker_id
        FROM tbl_ppl_caseworker
       WHERE col_extsysid = v_externalid
         AND col_userid <> v_userid;
    
      IF v_caseworker_id IS NOT NULL THEN
        v_errorCode    := 128;
        v_errorMessage := 'Caseworker with Extermal ID {{MESS_EXTERNALID}} already exists';
        v_res          := LOC_i18n(MessageText   => v_errormessage,
                                   MessageResult => v_errormessage,
                                   MessageParams => NES_TABLE(Key_Value('MESS_EXTERNALID', v_externalid)));
        ErrorCode      := v_errorCode;
        ErrorMessage   := v_errorMessage;
        RETURN - 1;
      END IF;
    END IF;
  EXCEPTION
    WHEN no_data_found THEN
      NULL;
  END;

  --DETERMINE IF USER IS ALREADY A CASE WORKER
  v_caseworker_id := NULL;
  BEGIN
    SELECT col_id INTO v_caseworker_id FROM tbl_ppl_caseworker WHERE col_userid = v_userid;
  EXCEPTION
    WHEN no_data_found THEN
      NULL;
  END;

  --DETERMINE IF WORKBASKET TYPE "PERSONAL" EXISTS   
  v_personal_wb_type := F_util_getidbycode(code => 'personal', tablename => 'tbl_dict_workbaskettype');

  IF NVL(v_personal_wb_type, 0) = 0 THEN
    v_errorCode    := 122;
    v_errorMessage := 'Workbasket type not found';
    ErrorCode      := v_errorCode;
    ErrorMessage   := v_errorMessage;
    RETURN - 1;
  END IF;

  IF NVL(v_caseworker_id, 0) = 0 THEN
    --CREATE CASE WORKER   
    v_uniquecode := v_objectprefix || v_userid;
    INSERT INTO tbl_ppl_caseworker
      (col_code, col_userid, col_name, col_isdeleted, col_extsysid)
    VALUES
      (v_uniquecode, v_userid, v_name, 0, v_externalid)
    RETURNING col_id INTO v_caseworker_id;
  
  ELSE
  
    --UPDATE ADDITIONAL INFO ABOUT CASE WORKER 
    UPDATE tbl_ppl_caseworker SET col_extsysid = v_externalid, col_name = v_name WHERE col_id = v_caseworker_id;
  
    -- GET ACCESSSUBJECT_ID AND WORKBASKET_ID
    SELECT wb.col_id, acs.col_id
      INTO v_workbasket_id, v_accesssubject_id
      FROM tbl_ppl_caseworker cw
      LEFT JOIN tbl_ac_accesssubject acs
        ON cw.col_caseworkeraccesssubject = acs.col_id
      LEFT JOIN tbl_ppl_workbasket wb
        ON wb.col_caseworkerworkbasket = cw.col_id
     WHERE cw.COL_ID = v_caseworker_id;
  
  END IF;

  --CREATE ACCESS SUBJECT FOR CASE WORKER AND LINK TO CASE WORKER   
  IF NVL(v_accesssubject_id, 0) = 0 THEN
    BEGIN
      v_uniquecode := f_UTIL_calcUniqueCode(BaseCode => v_objectprefix || v_userid, TableName => 'tbl_ac_accesssubject');
      INSERT INTO tbl_ac_accesssubject
        (col_type, col_name, col_code)
      VALUES
        ('CASEWORKER', v_name, v_uniquecode)
      RETURNING col_id INTO v_accesssubject_id;
    
      UPDATE tbl_ppl_caseworker SET col_caseworkeraccesssubject = v_accesssubject_id WHERE col_id = v_caseworker_id;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        ErrorCode    := v_errorCode;
        ErrorMessage := v_errorMessage;
        RETURN - 1;
    END;
  ELSE
    UPDATE tbl_ac_accesssubject SET col_name = v_name WHERE col_id = v_accesssubject_id;
  END IF;

  --CREATE PERSONAL WORKBASKET FOR CASE WORKER   
  v_uniquecode := f_UTIL_calcUniqueCode(BaseCode => v_objectprefix || v_userid, TableName => 'tbl_ppl_caseworker');
  v_res        := f_PPL_CreateModifyWBFn(CaseWorkerOwner    => v_caseworker_id,
                                         ExternalPartyOwner => NULL,
                                         BusinessRoleOwner  => NULL,
                                         SkillOwner         => NULL,
                                         TeamOwner          => NULL,
                                         NAME               => v_name,
                                         Code               => v_uniquecode,
                                         Description        => 'Automatically created workbasket for the' || ' ''' || v_name || ''' Case Worker',
                                         IsDefault          => 1,
                                         IsPrivate          => 1,
                                         WorkBasketType     => 'PERSONAL',
                                         Id                 => v_workbasket_id,
                                         ResultId           => v_userid,
                                         ErrorCode          => v_errorCode,
                                         ErrorMessage       => v_errorMessage);

  IF (v_errorCode <> 0) THEN
    ROLLBACK;
    ErrorCode    := v_errorCode;
    ErrorMessage := v_errorMessage;
    RETURN - 1;
  END IF;

  --RETURN v_caseworker_id TO INDICATE EVERYTHING IS OK
  RETURN v_caseworker_id;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    v_errorCode    := 127;
    v_errorMessage := 'Access Subject with code {{MESS_UNIQCODE}} already exists';
    v_res          := LOC_i18n(MessageText   => v_errormessage,
                               MessageResult => v_errormessage,
                               MessageParams => NES_TABLE(Key_Value('MESS_UNIQCODE', v_uniquecode)));
    RETURN - 1;
  
END;