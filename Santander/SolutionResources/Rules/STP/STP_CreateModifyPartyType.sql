DECLARE
  v_id                  NUMBER;
  v_isdeleted           NUMBER;
  v_issystem            NUMBER;
  v_name                NVARCHAR2(255);
  v_code                NVARCHAR2(255);
  v_description         NCLOB;
  v_participant_id      NUMBER;
  v_participant_code    NVARCHAR2(255);
  v_subpartytypesids_sv NCLOB;
  v_result              NUMBER;
  v_Text                NVARCHAR2(255);

  --custom processor codes 
  v_retcustdataprocessor    NVARCHAR2(255);
  v_updatecustdataprocessor NVARCHAR2(255);
  v_customdataprocessor     NVARCHAR2(255);
  v_delcustdataprocessor    NVARCHAR2(255);
  v_isId                    INT;
  v_disablemanagement       NUMBER;

  --standard fields
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_id                  := :Id;
  v_code                := :Code;
  v_isdeleted           := :IsDeleted;
  v_name                := :NAME;
  v_participant_id      := :ParticipantId;
  v_participant_code    := :ParticipantCode;
  v_description         := :Description;
  v_subpartytypesids_sv := :SubPartyTypes;

  --custom processor codes 
  v_retcustdataprocessor    := :RETCUSTDATAPROCESSOR;
  v_updatecustdataprocessor := :UPDATECUSTDATAPROCESSOR;
  v_customdataprocessor     := :CUSTOMDATAPROCESSOR;
  v_delcustdataprocessor    := :DELCUSTDATAPROCESSOR;
  v_disablemanagement       := :disablemanagement;

  --standard fields
  :affectedRows    := 0;
  v_errorcode      := 0;
  v_errormessage   := '';
  :SuccessResponse := EMPTY_CLOB();
  -- validation on Id is Exist
  IF NVL(v_id, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_id, tablename => 'TBL_DICT_PARTYTYPE');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  BEGIN
    --set assumed success message 
    IF v_id IS NOT NULL THEN
      v_Text := 'Updated {{MESS_NAME}} party type';
    ELSE
      v_Text := 'Created {{MESS_NAME}} party type';
    END IF;
    --:SuccessResponse := :SuccessResponse || ' "' || v_name || '" party type'; 
    v_result := LOC_i18n(MessageText => v_Text, MessageResult => :SuccessResponse, MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_name)));
    --get participant type
    IF NVL(v_participant_id, 0) = 0 THEN
      v_participant_id := f_UTIL_getIdByCode(CODE => v_participant_code, TableName => 'tbl_dict_participanttype');
    END IF;
  
    IF NVL(v_participant_id, 0) = 0 THEN
      NULL;
      /*GO TO ERROR*/
    END IF;
  
    --create record if needed 
    IF v_id IS NULL THEN
      INSERT INTO tbl_dict_partytype (col_isdeleted, col_issystem, col_code, col_partytypeparticiptype, col_disablemanagement) VALUES (0, 0, v_code, v_participant_id, v_disablemanagement);
    
      SELECT gen_tbl_dict_partytype.CURRVAL INTO v_id FROM dual;
    END IF;
  
    :affectedRows := 1;
  
    --update values in record 
    SELECT col_issystem INTO v_issystem FROM tbl_dict_partytype WHERE col_id = v_id;
  
    IF v_issystem <> 1 THEN
      --update record 
      UPDATE tbl_dict_partytype
         SET col_name                    = v_name,
             col_code                    = v_code,
             col_description             = v_description,
             col_isdeleted               = v_isdeleted,
             col_retcustdataprocessor    = v_retcustdataprocessor,
             col_updatecustdataprocessor = v_updatecustdataprocessor,
             col_customdataprocessor     = v_customdataprocessor,
             col_delcustdataprocessor    = v_delcustdataprocessor,
             col_disablemanagement       = v_disablemanagement
       WHERE col_id = v_id;
    
      --set the MAP record 
      SELECT Upper(col_code) INTO v_participant_code FROM tbl_dict_participanttype WHERE col_id = v_participant_id;
    
      IF (v_participant_code = 'EXTERNAL') THEN
        DELETE FROM tbl_map_partytype WHERE col_parentpartytype = v_id;
      
        FOR rec IN (SELECT TO_NUMBER(regexp_substr(v_subpartytypesids_sv, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS partytypeid
                      FROM dual
                    CONNECT BY dbms_lob.getlength(regexp_substr(v_subpartytypesids_sv, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) LOOP
          INSERT INTO tbl_map_partytype (col_parentpartytype, col_childpartytype, col_allowcreate) VALUES (v_id, rec.partytypeid, 1);
        
          :affectedRows := :affectedRows + 1;
        END LOOP;
      END IF;
    ELSE
      v_errorcode    := 103;
      v_errormessage := 'This Party Type cannot be modified because it''s a system record';
      :affectedRows  := 0;
      :recordId      := v_id;
    END IF;
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows  := 0;
      v_errorcode    := 101;
      v_errormessage := 'There already exists a party type with this code';
    WHEN OTHERS THEN
      :affectedRows  := 0;
      v_errorcode    := 102;
      v_errormessage := Substr(SQLERRM, 1, 200);
  END;

  <<cleanup>>
  :recordId     := v_id;
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;
