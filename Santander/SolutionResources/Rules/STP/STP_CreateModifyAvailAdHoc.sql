DECLARE 
    v_id           NUMBER; 
    v_procedure    NUMBER; 
    v_casesystype  NUMBER; 
    v_tasksystype  NUMBER; 
    v_targettype   NVARCHAR2(255); 
    v_targetid     NUMBER; 
	v_isId		   INT;
    v_errorcode    NUMBER; 
    v_errormessage NVARCHAR2(255);
	v_text		   NVARCHAR2(255); 
	v_result	   NUMBER;
BEGIN 
    v_id := :Id; 
    v_procedure := null; 
    v_tasksystype := null; 
    v_casesystype := :Casesystype; 
    v_targettype := :TargetType; 
    v_targetid := :TargetId; 
    :affectedRows := 0; 
    v_errorcode := 0; 
    v_errormessage := ''; 
    :SuccessResponse := EMPTY_CLOB();

  -- validation on Id is Exist
    -- tbl_stp_availableadhoc
    IF NVL(v_id, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_id,
                             tablename    => 'TBL_STP_AVAILABLEADHOC');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    -- CaseSysTypeId
    IF NVL(v_casesystype, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_casesystype,
                             tablename    => 'TBL_DICT_CASESYSTYPE');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
	IF( lower(v_targettype) = 'procedure' ) THEN 
		-- procedure
		IF NVL(v_targetid, 0) > 0 THEN
		  v_isId := f_UTIL_getId(errorcode    => v_errorcode,
								 errormessage => v_errormessage,
								 id           => v_targetid,
								 tablename    => 'TBL_PROCEDURE');
		  IF v_errorcode > 0 THEN
			GOTO cleanup;
		  END IF;
		END IF;
		v_procedure := v_targetid; 
	ELSIF( lower(v_targettype) = 'tasksystype' ) THEN 
		-- TaskSysTypeId
		IF NVL(v_targetid, 0) > 0 THEN
		  v_isId := f_UTIL_getId(errorcode    => v_errorcode,
								 errormessage => v_errormessage,
								 id           => v_targetid,
								 tablename    => 'TBL_DICT_TASKSYSTYPE');
		  IF v_errorcode > 0 THEN
			GOTO cleanup;
		  END IF;
		END IF;
		v_tasksystype := v_targetid; 
	END IF; 
  
  
    BEGIN 
        IF( lower(v_targettype) = 'procedure' ) THEN 
          v_procedure := v_targetid; 
        ELSIF( lower(v_targettype) = 'tasksystype' ) THEN 
          v_tasksystype := v_targetid; 
        END IF; 

        IF( v_id IS NULL ) THEN 
          INSERT INTO tbl_stp_availableadhoc 
                      (col_procedure, 
                       col_tasksystype, 
                       col_casesystype,
                       col_code) 
          VALUES     ( v_procedure, 
                      v_tasksystype, 
                      v_casesystype,
                      sys_guid()); 

          v_text := 'Created {{MESS_NAME}} type record'; 

          SELECT gen_tbl_stp_availableadhoc.CURRVAL 
          INTO   :recordId 
          FROM   dual; 

          :affectedRows := 1; 
        ELSE 
          UPDATE tbl_stp_availableadhoc 
          SET    col_procedure = v_procedure, 
                 col_tasksystype = v_tasksystype 
          WHERE  col_id = v_id; 

          :affectedRows := 1; 
          :recordId := v_id; 
          v_text := 'Updated {{MESS_NAME}} type record'; 
        END IF; 

		v_result := LOC_i18n(
			MessageText => v_text,
			MessageResult => :SuccessResponse,
			MessageParams => NES_TABLE(
				Key_Value('MESS_NAME', v_targettype)
			)
		);
        --:SuccessResponse := :SuccessResponse || ' ' || v_targettype || ' type record'; 
    EXCEPTION 
        WHEN dup_val_on_index THEN 
          :affectedRows := 0; 
          v_errorcode := 101; 
          v_errormessage := 'There already exists record with the Id ' || To_char(v_id); 
			v_result := LOC_i18n(
				MessageText => 'There already exists record with the Id {{MESS_ID}}',
				MessageResult => v_errormessage,
				MessageParams => NES_TABLE(
					Key_Value('MESS_ID', To_char(v_id))
				)
			);

          :SuccessResponse := ''; 
        WHEN OTHERS THEN 
          :affectedRows := 0; 
          v_errorcode := 102; 
          v_errormessage := Substr(SQLERRM, 1, 200); 
          :SuccessResponse := ''; 
    END; 

  <<cleanup>>
    :errorCode := v_errorcode; 
    :errorMessage := v_errormessage; 
END; 