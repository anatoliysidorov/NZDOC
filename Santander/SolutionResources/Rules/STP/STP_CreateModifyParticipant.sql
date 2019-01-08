DECLARE
  v_id               NUMBER;
  v_name             NVARCHAR2(255);
  v_code  		     NVARCHAR2(255);
  v_casesystype_id   NUMBER;
  v_procedure_id     NUMBER;
  v_unittype_id      NUMBER;
  v_unittype_code    NVARCHAR2(255);
  v_getprocessorcode NVARCHAR2(255);
  v_getprocessorcode2 NVARCHAR2(255);
  v_customconfig     NCLOB;
  v_description      NCLOB;
  v_allowmultiple    NUMBER;
  v_required         NUMBER;
  v_isdeleted        NUMBER;
  v_businessrole_id  NUMBER;
  v_caseworker_id    NUMBER;
  v_team_id          NUMBER;
  v_extparty_id      NUMBER;
  v_skill_id         NUMBER;
  v_isCreator         NUMBER;
  v_isSupervisor         NUMBER;
  v_IsCreatorOrSupervisor NUMBER;
  v_isId        	INT;
  v_result INT; 

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_id               := :Id;
  v_name             := :NAME;
  v_casesystype_id   := :CaseSysTypeId;
  v_procedure_id     := :ProcedureId;
  v_unittype_code    := :UnitTypeCode;
  v_getprocessorcode := :ProcessorCode;
  v_getprocessorcode2 := :ProcessorCode2;
  v_customconfig     := :CustomConfig;
  v_description      := :Description;
  v_businessrole_id  := :BusinessRoleId;
  v_caseworker_id    := :CaseWorkerId;
  v_team_id          := :TeamId;
  v_extparty_id      := :ExternalPartyId;
  v_skill_id         := :SkillId;

  v_isCreator         := :isCreator;
  v_isSupervisor         := :isSupervisor;
  v_IsCreatorOrSupervisor := :IsCreatorOrSupervisor;

  v_allowmultiple := nvl(:AllowMultiple, 0);
  v_required      := nvl(:Required, 0);
  v_isdeleted     := nvl(:IsDeleted, 0);

  :affectedRows  := 0;
  :SuccessResponse := EMPTY_CLOB();
  v_errorcode    := 0;
  v_errormessage := '';

  -- Input params check 
  IF (v_casesystype_id IS NULL AND v_procedure_id IS NULL) THEN
    v_errormessage := 'CaseSysTypeId or ProcedureId need have a value';
    v_errorcode    := 101;
    GOTO cleanup;
  END IF;

  -- validation on Id is Exist
  IF NVL(v_casesystype_id, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                           errormessage => v_errormessage,
                           id           => v_casesystype_id,
                           tablename    => 'TBL_DICT_CASESYSTYPE');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;
  
  IF NVL(v_procedure_id, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                           errormessage => v_errormessage,
                           id           => v_procedure_id,
                           tablename    => 'TBL_PROCEDURE');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;
  
  --set success message
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated participant';
  ELSE
    :SuccessResponse := 'Created participant';
  END IF;
  --:SuccessResponse := :SuccessResponse || ' participant';

  IF v_IsCreatorOrSupervisor IS NOT NULL AND v_IsCreatorOrSupervisor = 1 THEN
    v_isCreator := 1;
    v_isSupervisor := 0;
  ELSIF v_IsCreatorOrSupervisor IS NOT NULL AND v_IsCreatorOrSupervisor = 2 THEN
    v_isCreator := 0;
    v_isSupervisor := 1;
  ELSIF v_IsCreatorOrSupervisor IS NOT NULL AND v_IsCreatorOrSupervisor = 0 THEN
    v_isCreator := 0;
    v_isSupervisor := 0;
  END IF;

  BEGIN
    v_unittype_id := f_util_getidbycode(code => v_unittype_code, tablename => 'tbl_dict_participantunittype');
  
    IF v_unittype_id IS NOT NULL THEN
      --add new record
      IF v_id IS NULL THEN
		IF NVL(v_procedure_id, 0) > 0 THEN
			SELECT col_code INTO v_code
			FROM tbl_procedure
			WHERE col_id = v_procedure_id;
		ELSIF NVL(v_casesystype_id, 0) > 0 THEN
			SELECT col_code INTO v_code
			FROM tbl_dict_CaseSysType
			WHERE col_id = v_casesystype_id;
		END IF;
		
        INSERT INTO tbl_participant (col_isdeleted, col_code) VALUES (v_isdeleted, v_code || '_' || f_util_codify(v_name)) RETURNING col_id INTO v_id;
      END IF;
    
      -- update existing one 
      UPDATE tbl_participant
         SET col_participantcasesystype    = v_casesystype_id,
             col_participantprocedure      = v_procedure_id,
             col_getprocessorcode          = v_getprocessorcode,
             col_getprocessorcode2          = v_getprocessorcode2,
             col_participantdict_unittype  = v_unittype_id,
             col_customconfig              = v_customconfig,
             col_allowmultiple             = v_allowmultiple,
             col_required                  = v_required,
             col_isdeleted                 = v_isdeleted,
             col_name                      = v_name,
             col_description               = v_description,
             col_participantbusinessrole   = v_businessrole_id,
             col_participantppl_caseworker = v_caseworker_id,
             col_participantteam           = v_team_id,
             col_participantexternalparty  = v_extparty_id,

             col_isCreator = v_isCreator,
             col_isSupervisor = v_isSupervisor,
             col_participantppl_skill      = v_skill_id
       WHERE col_id = v_id;
    
      :affectedRows := SQL%ROWCOUNT;
      :recordId     := v_id;
    ELSE
      v_errormessage   := 'Participant Unit Type Code can not be empty';
      v_errorcode      := 102;
      :SuccessResponse := '';
    END IF;
  EXCEPTION
    WHEN dup_val_on_index THEN
        :affectedRows    := 0;
        v_errorcode      := 101;
        v_errormessage   := 'There already exists a participant with the code {{MESS_CODE}}';
		v_result := LOC_i18n(
			MessageText => v_errormessage,
			MessageResult => v_errormessage,
			MessageParams => NES_TABLE(
				Key_Value('MESS_CODE', v_code)
			)
		);        :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_errorcode      := 103;
      v_errormessage   := substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;