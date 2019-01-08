DECLARE
  --input
  v_id              NUMBER;
  v_name            NVARCHAR2(255);
  v_description     NCLOB;
  v_allowdelete     INT;
  v_caseid          NUMBER;
  v_externalpartyid NUMBER;
  v_caseworkerid    NUMBER;
  v_businessroleid  NUMBER;
  v_teamid          NUMBER;
  v_skillid         NUMBER;
  v_partytypeid     NUMBER;
  v_partytypecode   NVARCHAR2(255);

  --standard
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);

BEGIN
  --input
  v_id            := :ID;
  v_name          := :Name;
  v_description   := :Description;
  v_allowdelete   := :AllowDelete;
  v_caseid        := :Case_Id;
  v_partytypecode := :PartyType_Code;

  --standard
  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';

  -- get parameters
  SELECT decode(:ExternalParty_Id, 0, NULL, :ExternalParty_Id) INTO v_externalpartyid FROM dual;
  SELECT decode(:CaseWorker_Id, 0, NULL, :CaseWorker_Id) INTO v_caseworkerid FROM dual;
  SELECT decode(:BusinessRole_Id, 0, NULL, :BusinessRole_Id) INTO v_businessroleid FROM dual;
  SELECT decode(:Team_Id, 0, NULL, :Team_Id) INTO v_teamid FROM dual;
  SELECT decode(:Skill_Id, 0, NULL, :Skill_Id) INTO v_skillid FROM dual;

  --Input params check
  IF v_caseid IS NULL THEN
    v_errormessage := 'CaseId can not be empty';
    v_errorcode    := 101;
    GOTO cleanup;
  END IF;

  IF v_externalpartyid IS NULL AND v_caseworkerid IS NULL AND v_businessroleid IS NULL AND v_teamid IS NULL AND v_skillid IS NULL THEN
    v_errormessage := 'ID of Unit can not be empty';
    v_errorcode    := 102;
    GOTO cleanup;
  END IF;

  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated';
  ELSE
    :SuccessResponse := 'Created';
  END IF;
  :SuccessResponse := :SuccessResponse || ' "' || v_name || '" case party';

  --create case party record if one doesn't exist yet
  IF v_id IS NULL THEN
    -- get PartyType_Id
    v_partytypeid := f_UTIL_getIdByCode(Code => v_partytypecode, TableName => 'tbl_dict_participantunittype');
    INSERT INTO tbl_caseparty
      (col_allowdelete, col_casepartycase, col_casepartydict_unittype)
    VALUES
      (v_allowdelete, v_caseid, v_partytypeid)
    RETURNING col_id INTO v_id;
  END IF;
  --update the values in the record
  BEGIN
    UPDATE tbl_caseparty
       SET col_name                      = v_name,
           col_description               = v_description,
           col_casepartyppl_caseworker   = v_caseworkerid,
           col_casepartyexternalparty    = v_externalpartyid,
           col_casepartyppl_businessrole = v_businessroleid,
           col_casepartyppl_skill        = v_skillid,
           col_casepartyppl_team         = v_teamid
     WHERE col_id = v_id;
  
    :affectedRows := 1;
    :recordId     := v_id;
  EXCEPTION
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_errorcode      := 103;
      v_errormessage   := Substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;

END;