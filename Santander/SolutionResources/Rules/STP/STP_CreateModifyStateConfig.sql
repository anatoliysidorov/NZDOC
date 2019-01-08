DECLARE
  v_id                 NUMBER;
  v_name               NVARCHAR2(255);
  v_code               NVARCHAR2(255);
  v_isdeleted          NUMBER;
  v_iconcode           NVARCHAR2(255);
  v_config             NCLOB;
  v_isId               NUMBER;
  v_isUpdateOnlyConfig INTEGER;
  v_errorcode          NUMBER;
  v_errormessage       NVARCHAR2(255);
  v_type               VARCHAR2(255);
  v_isdefault          INTEGER;
  v_isdefault2         INTEGER;
  v_count              NUMBER;
  v_result             NUMBER;
BEGIN
  v_id                 := :Id;
  v_name               := :NAME;
  v_code               := :Code;
  v_isdeleted          := :IsDeleted;
  v_iconcode           := :Iconcode;
  v_config             := :Config;
  v_type               := :STATETYPE;
  v_isUpdateOnlyConfig := :ISUPDATECONFIG;
  v_isdefault          := :IsDefault;
  v_count              := 0;

  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';

  -- validation on Id is Exist
  IF NVL(v_id, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_id, tablename => 'TBL_DICT_STATECONFIG');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  --set success message
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated';
  ELSE
    :SuccessResponse := 'Created';
  END IF;
  :SuccessResponse := :SuccessResponse || ' ' || v_name || ' ' || ' state config';

  BEGIN
  
    --set isDefault to only 1 item 
    IF v_isdefault = 1 THEN
      UPDATE tbl_dict_stateconfig
         SET col_isdefault = 0
       WHERE col_isdefault = 1
         AND col_type = v_type;
    ELSE
      -- check on IsDefault is present
      SELECT COUNT(col_id)
        INTO v_count
        FROM tbl_dict_stateconfig
       WHERE col_isdefault = 1
         AND col_type = v_type;
    
      IF (v_count = 0 AND v_id IS NULL) THEN
        v_errorcode    := 103;
        v_errormessage := 'There should be at least one Default Milestone for ' || lower(v_type) || 's';
        GOTO cleanup;
      END IF;
      IF (v_count = 1 AND v_id IS NOT NULL) THEN
        BEGIN
          SELECT col_isdefault INTO v_isdefault2 FROM tbl_dict_stateconfig WHERE col_id = v_id;
          IF (v_isdefault2 = 1) THEN
            v_errorcode    := 103;
            v_errormessage := 'There should be at least one Default Milestone for ' || lower(v_type) || 's';
            GOTO cleanup;
          END IF;
        EXCEPTION
          WHEN no_data_found THEN
            NULL;
        END;
      END IF;
    END IF;
  
    --add new record or update existing one 
    IF v_id IS NULL THEN
      INSERT INTO tbl_dict_stateconfig
        (col_code, col_name, col_isdeleted, col_iconcode, col_type, col_isdefault, col_stateconfstateconftype)
      VALUES
        (v_code, v_name, 0, v_iconcode, v_type, v_isdefault, f_util_getidbycode(code => v_type, tablename => 'TBL_DICT_STATECONFIGTYPE'))
      RETURNING col_id INTO :recordId;
    ELSE
    
      IF (v_isUpdateOnlyConfig IS NOT NULL) THEN
        UPDATE tbl_dict_stateconfig SET col_config = v_config WHERE col_id = v_id;
      
        FOR rec IN (SELECT cst.col_id
                      FROM tbl_dict_casesystype cst
                     WHERE cst.col_stateconfigcasesystype = v_id
                       AND (SELECT COUNT(*) FROM tbl_Case c WHERE c.col_casedict_casesystype = cst.col_Id) = 0) LOOP
        
          v_result := f_stp_synccasestateinittmplsfn(rec.col_id, v_errorcode, v_errormessage);
        
          IF v_errorcode <> 0 THEN
            GOTO cleanup;
          END IF;
        END LOOP;
      
      ELSE
      
        UPDATE tbl_dict_stateconfig
           SET col_code      = v_code,
               col_name      = v_name,
               col_iconcode  = v_iconcode,
               col_isdeleted = v_isdeleted,
               col_config    = v_config,
               col_isdefault = v_isdefault
         WHERE col_id = v_id;
      
        UPDATE tbl_dict_casestate SET col_isdeleted = v_isdeleted WHERE col_stateconfigcasestate = v_id;
      
      END IF;
    
      :recordId := v_id;
    END IF;
  
    :affectedRows := SQL%ROWCOUNT;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows    := 0;
      v_errorcode      := 101;
      v_errormessage   := 'There already exists a state config with the code ' || to_char(v_code);
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_errorcode      := 102;
      v_errormessage   := substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;

END;