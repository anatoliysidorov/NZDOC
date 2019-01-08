DECLARE
  v_id                  INTEGER;
  v_Ids                 NVARCHAR2(32767);
  v_count               INTEGER;
  v_countDeletedRecords INTEGER;
  v_result              NUMBER;
  v_type                NVARCHAR2(255);

BEGIN
  v_id                  := :Id;
  v_Ids                 := :Ids;
  :affectedRows         := 0;
  :ErrorCode            := 0;
  :ErrorMessage         := '';
  :SuccessResponse := EMPTY_CLOB();
  v_count               := 0;
  v_countDeletedRecords := 0;

  -- Input params check 
  IF v_Ids IS NULL AND v_Id IS NULL THEN
    :ErrorMessage := 'Id can not be empty';
    :ErrorCode    := 101;
    RETURN;
  END IF;

  IF (v_Id IS NOT NULL) THEN
    v_Ids := TO_CHAR(v_id);
  END IF;

  -- check on IsDefault is present
  SELECT col_type
    INTO v_type
    FROM tbl_dict_stateconfig
   WHERE col_id IN (SELECT TO_NUMBER(COLUMN_VALUE) AS id FROM TABLE(ASF_SPLIT(v_Ids, ',')))
     AND rownum = 1;

  SELECT COUNT(col_id)
    INTO v_count
    FROM tbl_dict_stateconfig
   WHERE col_isdefault = 1
     AND col_type = v_type
     AND col_id NOT IN (SELECT TO_NUMBER(COLUMN_VALUE) AS id FROM TABLE(ASF_SPLIT(v_Ids, ',')));

  IF v_count = 0 THEN
    :ErrorCode    := 102;
    :ErrorMessage := 'There should be at least one Default Milestone for ' || lower(v_type) || 's';
    RETURN;
  END IF;

  -- Check on Exist in CaseType
  SELECT COUNT(col_id)
    INTO v_count
    FROM tbl_dict_casesystype
   WHERE col_stateconfigcasesystype IN (SELECT to_number(column_value) AS id FROM TABLE(asf_split(v_Ids, ',')));

  IF v_count > 0 THEN
    :ErrorMessage := 'There are Milestones linked to Case Types';
    :ErrorCode    := 103;
    RETURN;
  END IF;

  FOR recStateConfig IN (SELECT col_Id AS ID
                           FROM tbl_dict_stateconfig
                          WHERE col_id IN (SELECT TO_NUMBER(COLUMN_VALUE) AS id FROM TABLE(ASF_SPLIT(v_Ids, ',')))) LOOP
    -- Remove all states/transitions
    v_result := f_stp_destroycasestatedetail(errorcode => :ErrorCode, errormessage => :ErrorMessage, stateconfig => recStateConfig.ID);
  
    IF :ErrorCode = 0 THEN
    
      -- TBL_DICT_STATECONFIG
      DELETE tbl_dict_stateconfig WHERE col_id = recStateConfig.ID;
    
      v_countDeletedRecords := v_countDeletedRecords + 1;
    END IF;
  
    :ErrorCode    := 0;
    :ErrorMessage := '';
  END LOOP;

  :affectedRows := SQL%ROWCOUNT;
  v_result      := LOC_I18N(MessageText   => 'Deleted {{MESS_COUNT}} items',
                            MessageResult => :SuccessResponse,
                            MessageParams => NES_TABLE(Key_Value('MESS_COUNT', v_countDeletedRecords)));

END;