DECLARE
  v_action           NVARCHAR2(255);
  v_caseid           NUMBER;
  v_workbasketid     NUMBER;
  v_workbasketid_old NUMBER;
  v_workbasketname   NVARCHAR2(255);
  v_note             NVARCHAR2(2000);
  v_result           NUMBER;
  v_casepartyid      NUMBER;
  v_unitid           NUMBER;
  v_unittype         NVARCHAR2(255);
  v_casepartyname    NVARCHAR2(255);

  v_historyMsg       NCLOB;
  v_errormessage     NCLOB;
  v_validationresult NUMBER;
  v_Attributes       NCLOB;
  v_StateId          NUMBER;
  v_CSisInCache      INTEGER;
  v_isInCache        INTEGER;
  v_outData          CLOB;
  v_isId             INTEGER;

  --standard
  v_message   NCLOB;
  v_errorcode NUMBER;

BEGIN
  v_action       := UPPER(:Action);
  v_caseid       := :Case_Id;
  v_workbasketid := :WorkBasket_Id;
  v_casepartyid  := :CaseParty_Id;
  v_note         := :Note;
  v_message      := '';
  v_outData      := NULL;

  v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid); --new cache
  v_isInCache   := f_DCM_isCaseInCache(v_caseid);

  --standard
  v_errorcode    := 0;
  v_errormessage := '';

  -- BASIC ERROR CHECKS
  IF v_action NOT IN ('UNASSIGN', 'ASSIGN_TO_ME', 'ASSIGN_TO_PARTY', 'ASSIGN') THEN
    v_errorcode := 101;
    v_message   := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: The action needs to be either UNASSIGN, ASSIGN_TO_ME, ASSIGN_TO_PARTY, or ASSIGN');
    GOTO cleanup;
  END IF;

  IF v_caseid IS NULL THEN
    v_errorcode := 102;
    v_message   := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: Case ID can not be empty');
    GOTO cleanup;
  ELSE
    -- validation on Case_Id is Exist
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_caseid, tablename => 'TBL_CASE');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  IF v_workbasketid IS NULL AND v_action = 'ASSIGN' THEN
    v_errorcode := 103;
    v_message   := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: Work Basket ID can not be empty if using action ASSIGN');
    GOTO cleanup;
  END IF;

  IF v_casepartyid IS NULL AND v_action = 'ASSIGN_TO_PARTY' THEN
    v_errorcode := 106;
    v_message   := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: Case Party ID can not be empty if using action ASSIGN_TO_PARTY');
    GOTO cleanup;
  END IF;

  -- CALCULATE WORKBASKET IF "ASSIGN TO ME"
  IF v_action = 'ASSIGN_TO_ME' THEN
    v_workbasketid := f_DCM_getMyPersonalWorkbasket();
    IF NVL(v_workbasketid, 0) = 0 THEN
      v_errorcode := 107;
      v_message   := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: Your user does not have an associated Work Basket');
      GOTO cleanup;
    END IF;
  END IF;

  -- GET OLD WORKBASKET_ID
  SELECT col_caseppl_workbasket INTO v_workbasketid_old FROM tbl_case WHERE col_id = v_caseid;

  -- CALCULATE WORKBASKET IF "ASSIGN TO PARTY"
  IF v_action = 'ASSIGN_TO_PARTY' THEN
  
    --get assigned unit to this case party
    --not in new cache
    IF v_CSisInCache = 0 THEN
      BEGIN
        SELECT CALC_ID,
               PartyType_Code,
               NAME
          INTO v_unitid,
               v_unittype,
               v_casepartyname
          FROM vw_ppl_caseparty
         WHERE id = v_casepartyid;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_errorcode := 108;
          v_message   := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: Case Party record with ID' || TO_CHAR(v_casepartyid) || ' is missing');
          GOTO cleanup;
      END;
    END IF;
  
    --in new cache
    IF v_CSisInCache = 1 THEN
      BEGIN
        SELECT pt.COL_CODE,
               cp.COL_NAME,
               CASE LOWER(NVL(pt.COL_CODE, N'TEXT'))
                 WHEN N'external_party' THEN
                  cp.COL_CASEPARTYEXTERNALPARTY
                 WHEN N'caseworker' THEN
                  cp.COL_CASEPARTYPPL_CASEWORKER
                 WHEN N'team' THEN
                  cp.COL_CASEPARTYPPL_TEAM
                 WHEN N'businessrole' THEN
                  cp.COL_CASEPARTYPPL_BUSINESSROLE
                 WHEN N'skill' THEN
                  cp.COL_CASEPARTYPPL_SKILL
                 ELSE
                  0
               END
          INTO v_unittype,
               v_casepartyname,
               v_unitid
          FROM TBL_CSCASEPARTY cp
          LEFT JOIN TBL_DICT_PARTICIPANTUNITTYPE pt
            ON pt.COL_ID = cp.COL_CASEPARTYDICT_UNITTYPE
         WHERE cp.COL_ID = v_casepartyid;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_errorcode := 108;
          v_message   := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: Case Party record with ID ' || TO_CHAR(v_casepartyid) || ' is missing');
          GOTO cleanup;
      END;
    END IF;
  
    --check if anyone is actually assigned to the case party
    IF NVL(v_unitid, 0) = 0 OR TRIM(v_unittype) IS NULL THEN
      v_errorcode := 109;
      v_message   := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: the ' || v_casepartyname || ' has not been assigned yet');
      GOTO cleanup;
    END IF;
  
    --get the unit 
    v_workbasketid := f_PPL_getPrimaryWB(UnitId => v_unitid, UnitType => v_unittype);
    IF NVL(v_workbasketid, 0) = 0 THEN
      v_errorcode := 110;
      v_message   := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: the unit assigned to the Case Party ' || v_casepartyname || ' is missing a personal Work Basket');
      GOTO cleanup;
    END IF;
  
    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: attempting to assign to the ' || v_casepartyname);
  END IF;

  -- CHECK THAT THE SELECTED WORKBASKET EXISTS AND GET IT'S NAME
  IF v_action IN ('ASSIGN_TO_ME', 'ASSIGN_TO_PARTY', 'ASSIGN') THEN
    BEGIN
      SELECT CALCNAME INTO v_workbasketname FROM vw_PPL_SimpleWorkBasket WHERE id = v_workbasketid;
    
      v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: assigning to ' || v_workbasketname);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errorcode := 111;
        v_message   := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: unable to find Work Basket with ID ' || TO_CHAR(v_workbasketid));
        GOTO cleanup;
    END;
  ELSE
    v_workbasketid := NULL;
    v_message      := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: unassigning');
  END IF;

  --SET ASSUMED SUCCESS MESSAGE
  IF v_action = 'UNASSIGN' THEN
    :SuccessResponse := 'Case has been unassigned';
  ELSE
    :SuccessResponse := 'Case has been assigned to ' || v_workbasketname;
  END IF;

  v_validationresult := 1;
  --COLLECT INFORMATION FOR COMMON EVENTS
  v_Attributes := '<Action>' || TO_CHAR(v_action) || '</Action>' || '<CasePartyName>' || TO_CHAR(v_casepartyname) || '</CasePartyName>' || '<UnitType>' || TO_CHAR(v_unittype) || '</UnitType>' ||
                  '<UnitId>' || TO_CHAR(v_unitid) || '</UnitId>' || '<WorkbasketId>' || TO_CHAR(v_workbasketid) || '</WorkbasketId>' || '<WorkbasketName>' || TO_CHAR(v_workbasketname) ||
                  '</WorkbasketName>';

  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE 
  --ASSIGN_CASE- AND 
  --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM-- 
  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'ASSIGN_CASE',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
                                       eventtype        => 'VALIDATION',
                                       HistoryMessage   => v_historyMsg,
                                       procedureid      => NULL,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_validationresult);

  --write to history  
  IF v_historyMsg IS NOT NULL THEN
    v_result := f_HIST_createHistoryFn(AdditionalInfo => v_historyMsg, IsSystem => 0, Message => 'Validation Common event(s)', MessageCode => 'CommonEvent', TargetID => v_caseid, TargetType => 'CASE');
  END IF;

  IF Nvl(v_validationresult, 0) = 0 THEN
    v_errorcode := 114;
    v_message   := f_UTIL_addToMessage(originalMsg => v_message, newMsg => v_errormessage);
    GOTO cleanup;
  END IF;

  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'ASSIGN_CASE',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
                                       eventtype        => 'ACTION',
                                       HistoryMessage   => v_historyMsg,
                                       procedureid      => NULL,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_validationresult);

  BEGIN
  
    --UPDATE WORK BASKET
    IF v_isInCache = 1 THEN
      UPDATE TBL_CASECC SET COL_CASECCPPL_WORKBASKET = v_workbasketid WHERE col_id = v_caseid;
      v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: Case in cache has been updated');
    
      v_result := f_DCM_createCaseDateEvent(NAME => 'DATE_CASE_ASSIGNED', CaseId => v_caseid);
    END IF;
  
    IF v_CSisInCache = 1 THEN
      UPDATE TBL_CSCASE SET COL_CASEPPL_WORKBASKET = v_workbasketid WHERE col_id = v_caseid;
    
      v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: Case has been updated');
    
      BEGIN
        SELECT cs.COL_CASEDICT_STATE INTO v_StateId FROM TBL_CSCASE cs WHERE cs.col_id = v_CaseId;
      
        v_result := f_DCM_createCaseMSDateEvent(NAME => 'DATE_CASE_ASSIGNED', CASEID => v_CaseId, STATEID => v_StateId);
      
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_errorCode := 104;
          v_message   := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'Either the Case is missing or the current Milestone is invalid');
          GOTO cleanup;
      END;
    END IF;
  
    IF v_isInCache = 0 AND v_CSisInCache = 0 THEN
      UPDATE TBL_CASE SET COL_CASEPPL_WORKBASKET = v_workbasketid WHERE col_id = v_caseid;
      v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: Case has been updated');
    
      v_result := f_DCM_createCaseDateEvent(NAME => 'DATE_CASE_ASSIGNED', CaseId => v_caseid);
    END IF;
  
    IF v_note IS NOT NULL THEN
      IF v_action = 'UNASSIGN' THEN
        IF nvl(v_workbasketid_old, 0) = 0 THEN
          v_note := 'Case has been unassigned with message <br> ' || v_note;
        ELSE
          SELECT CALCNAME INTO v_workbasketname FROM vw_PPL_SimpleWorkBasket WHERE id = v_workbasketid_old;
          v_note := 'Case has been unassigned from ' || v_workbasketname || ' with message <br> ' || v_note;
        END IF;
      ELSE
        v_note := 'Case has been assigned to ' || v_workbasketname || ' with message <br> ' || v_note;
      END IF;
    
      INSERT INTO TBL_NOTE (COL_NOTE, COL_CASENOTE) VALUES (v_note, v_caseid);
    END IF;
  
    --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE 
    --ASSIGN_CASE- AND 
    --EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM-- 
    v_result := f_DCM_processCommonEvent(InData           => NULL,
                                         OutData          => v_outData,
                                         Attributes       => v_Attributes,
                                         code             => NULL,
                                         caseid           => v_caseid,
                                         casetypeid       => NULL,
                                         commoneventtype  => 'ASSIGN_CASE',
                                         errorcode        => v_errorcode,
                                         errormessage     => v_errormessage,
                                         eventmoment      => 'AFTER',
                                         eventtype        => 'ACTION',
                                         HistoryMessage   => v_historyMsg,
                                         procedureid      => NULL,
                                         taskid           => NULL,
                                         tasktypeid       => NULL,
                                         validationresult => v_validationresult);
  
    --write to history  
    IF v_historyMsg IS NOT NULL THEN
      v_result := f_HIST_createHistoryFn(AdditionalInfo => v_historyMsg, IsSystem => 0, Message => 'Action Common event(s)', MessageCode => 'CommonEvent', TargetID => v_caseid, TargetType => 'CASE');
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errorcode := 112;
      v_message   := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: ' || SQLERRM);
      GOTO cleanup;
  END;

  --WRITE HISTORY AND PROCESS ERRORS
  IF (NVL(v_errorcode, 0) = 0) THEN
    v_result := f_HIST_createHistoryFn(AdditionalInfo => SuccessResponse, IsSystem => 0, Message => NULL, MessageCode => 'CaseAssigned', TargetID => v_caseId, TargetType => 'CASE');
    RETURN v_workbasketid;
  ELSE
    GOTO cleanup;
  END IF;

  <<cleanup>>
  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR CODE: ' || v_errorcode);
  v_result  := f_HIST_createHistoryFn(AdditionalInfo => v_message, IsSystem => 0, Message => NULL, MessageCode => 'CaseAssignFailed', TargetID => v_caseid, TargetType => 'CASE');

  :errorCode       := v_errorcode;
  :errorMessage    := v_message;
  :SuccessResponse := '';
  RETURN 0;
END;
