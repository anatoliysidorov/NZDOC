DECLARE
  v_id                NUMBER;
  v_name              NVARCHAR2(255);
  v_code              NVARCHAR2(255);
  v_descr             NCLOB;
  v_isDefault         NUMBER;
  v_isPrivate         NUMBER;
  v_type              NVARCHAR2(255);
  v_cw_owner          NUMBER;
  v_ep_owner          NUMBER;
  v_br_owner          NUMBER;
  v_skill_owner       NUMBER;
  v_team_owner        NUMBER;
  v_type_id           NUMBER;
  v_tmp_id            NUMBER;
  v_cnt_owner         INTEGER;
  v_isId              INT;
  v_res               NUMBER;
  v_taskPullerFn      NVARCHAR2(255);
  v_casePullerFn      NVARCHAR2(255);
  v_caseTaskCounterFn NVARCHAR2(255);

  --Output variables
  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);
BEGIN
  v_id                := NVL(:Id, 0);
  v_name              := :NAME;
  v_code              := :Code;
  v_descr             := :Description;
  v_isDefault         := NVL(:IsDefault, 0);
  v_isPrivate         := NVL(:IsPrivate, 1);
  v_type              := lower(:WorkBasketType);
  v_cw_owner          := :CaseWorkerOwner;
  v_ep_owner          := :ExternalPartyOwner;
  v_br_owner          := :BusinessRoleOwner;
  v_skill_owner       := :SkillOwner;
  v_team_owner        := :TeamOwner;
  v_cnt_owner         := 0;
  v_tmp_id            := 0;
  v_taskPullerFn      := :TASKPULLERFN;
  v_casePullerFn      := :CASEPULLERFN;
  v_caseTaskCounterFn := :CASETASKCOUNTERFN;

  --Output variables
  v_errorCode    := 0;
  v_errorMessage := '';

  BEGIN
  
    --Check input data
    IF (v_type <> 'personal' AND v_type <> 'group') THEN
      v_errorCode    := 125;
      v_errorMessage := 'Workbasket type can either PERSONAL OR GROUP';
      GOTO cleanup;
    END IF;
  
    IF (v_cw_owner IS NOT NULL) THEN
      v_cnt_owner := v_cnt_owner + 1;
    END IF;
    IF (v_ep_owner IS NOT NULL) THEN
      v_cnt_owner := v_cnt_owner + 1;
    END IF;
    IF (v_team_owner IS NOT NULL) THEN
      v_cnt_owner := v_cnt_owner + 1;
    END IF;
    IF (v_skill_owner IS NOT NULL) THEN
      v_cnt_owner := v_cnt_owner + 1;
    END IF;
    IF (v_br_owner IS NOT NULL) THEN
      v_cnt_owner := v_cnt_owner + 1;
    END IF;
    IF (v_type = 'personal' AND v_cnt_owner <> 1) THEN
      v_errorCode    := 121;
      v_errorMessage := 'Only Caseworker Id or External Party Id or Team Id or Skill Id or Business Role Id must be not NULL';
      GOTO cleanup;
    END IF;
  
    IF v_code IS NULL THEN
      v_errorCode    := 122;
      v_errorMessage := 'Workbasket Code can not be empty';
      GOTO cleanup;
    END IF;
  
    IF (v_id = 0) THEN
      SELECT COUNT(1) INTO v_tmp_id FROM tbl_ppl_workbasket WHERE col_code = v_code;
      IF (v_tmp_id > 0) THEN
        v_errorCode    := 123;
        v_errorMessage := '{{MESS_CODE}} is NOT unique';
        v_res          := LOC_i18n(MessageText   => v_errorMessage,
                                   MessageResult => v_errorMessage,
                                   MessageParams => NES_TABLE(Key_Value('MESS_CODE', v_code)));
        GOTO cleanup;
      END IF;
    ELSE
      -- validation on Id is Exist
      v_isId := f_UTIL_getId(errorcode => v_errorCode, errormessage => v_errorMessage, id => v_id, tablename => 'tbl_ppl_workbasket');
      IF v_errorCode > 0 THEN
        GOTO cleanup;
      END IF;
    
    END IF;
  
    --get WB Type ID
    v_type_id := f_util_getidbycode(code => v_type, tablename => 'tbl_dict_workbaskettype');
  
    --add new record
    IF v_id = 0 THEN
      INSERT INTO tbl_ppl_workbasket (col_code, col_ucode) VALUES (v_code, v_code) RETURNING col_id INTO v_id;
    ELSE
      SELECT col_isdefault,
             col_isprivate,
             col_workbasketworkbaskettype,
             col_processorcode,
             col_processorcode2,
             col_processorcode3
        INTO v_isdefault,
             v_isprivate,
             v_type_id,
             v_taskPullerFn,
             v_casePullerFn,
             v_caseTaskCounterFn
        FROM tbl_ppl_workbasket
       WHERE col_id = v_id;
    END IF;
  
    --Every Unit must have exactly one WB that is PERSONAL and IsDefault.
    IF v_IsDefault = 1 AND v_type = 'personal' THEN
      IF (v_cw_owner IS NOT NULL) THEN
        UPDATE tbl_ppl_workbasket
           SET col_isdefault = 0
         WHERE col_id <> v_id
           AND col_caseworkerworkbasket = v_cw_owner
           AND col_workbasketworkbaskettype = v_type_id;
      ELSIF (v_ep_owner IS NOT NULL) THEN
        UPDATE tbl_ppl_workbasket
           SET col_isdefault = 0
         WHERE col_id <> v_id
           AND col_workbasketexternalparty = v_ep_owner
           AND col_workbasketworkbaskettype = v_type_id;
      ELSIF (v_br_owner IS NOT NULL) THEN
        UPDATE tbl_ppl_workbasket
           SET col_isdefault = 0
         WHERE col_id <> v_id
           AND col_workbasketbusinessrole = v_br_owner
           AND col_workbasketworkbaskettype = v_type_id;
      ELSIF (v_skill_owner IS NOT NULL) THEN
        UPDATE tbl_ppl_workbasket
           SET col_isdefault = 0
         WHERE col_id <> v_id
           AND col_workbasketskill = v_skill_owner
           AND col_workbasketworkbaskettype = v_type_id;
      ELSIF (v_team_owner IS NOT NULL) THEN
        UPDATE tbl_ppl_workbasket
           SET col_isdefault = 0
         WHERE col_id <> v_id
           AND col_workbasketteam = v_team_owner
           AND col_workbasketworkbaskettype = v_type_id;
      END IF;
    ELSE
      v_isDefault := 0;
    END IF;
  
    -- update existing one 
    UPDATE tbl_ppl_workbasket
       SET col_name                     = v_Name,
           col_description              = v_descr,
           col_isdefault                = v_isdefault,
           col_isprivate                = v_isprivate,
           col_workbasketworkbaskettype = v_type_id,
           col_caseworkerworkbasket     = v_cw_owner,
           col_workbasketexternalparty  = v_ep_owner,
           col_workbasketbusinessrole   = v_br_owner,
           col_workbasketskill          = v_skill_owner,
           col_workbasketteam           = v_team_owner,
           col_processorcode            = v_taskPullerFn,
           col_processorcode2           = v_casePullerFn,
           col_processorcode3           = v_caseTaskCounterFn
     WHERE col_id = v_id;
  
    :ResultId := v_id;
  EXCEPTION
    WHEN OTHERS THEN
      v_errorCode    := 103;
      v_errorMessage := substr(SQLERRM, 1, 200);
  END;

  <<cleanup>>
  :ErrorCode    := v_errorCode;
  :ErrorMessage := v_errorMessage;
END;