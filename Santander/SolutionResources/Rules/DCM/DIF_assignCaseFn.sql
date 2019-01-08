DECLARE
  v_action         NVARCHAR2(255);
  v_caseid         NUMBER;
  v_workbasketid   NUMBER;
  v_PrevWorkbasketId   NUMBER;
  v_workbasketname NVARCHAR2(255);
  v_note           NVARCHAR2(2000);
  v_result         NUMBER;
  v_casepartyid    NUMBER;
  v_unitid         NUMBER;
  v_unittype       NVARCHAR2(255);
  v_casepartyname  NVARCHAR2(255);
  
  v_historyMsg    NCLOB;
  v_errormessage  NVARCHAR2(255);
  v_casetypeid    NUMBER;
  v_validationresult    NUMBER;  
  v_Context       NVARCHAR2(255);
  v_CEAttributes        NVARCHAR2(4000);
  
  --standard
  v_message      NCLOB; 
  v_errorcode    NUMBER;  
  
BEGIN
  
  v_action       := UPPER(:Action);
  v_caseid       := :Case_Id;
  v_workbasketid := :WorkBasket_Id;
  v_casepartyid  := :CaseParty_Id;
  v_note         := :Note;
  v_Context      := NVL(:Context, 'ASSIGN_CASE');
    
  v_PrevWorkbasketId := f_DCM_getMyPersonalWorkbasket();
  v_message      := '';
  v_casetypeid   := NULL;
  
  --standard
  v_errorcode    := 0;

  -- BASIC ERROR CHECKS
  IF v_action NOT IN ('UNASSIGN', 'ASSIGN_TO_ME', 'ASSIGN_TO_PARTY', 'ASSIGN') THEN
    v_errorcode    := 101;
	  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: The action needs to be either UNASSIGN, ASSIGN_TO_ME, ASSIGN_TO_PARTY, or ASSIGN');
    GOTO cleanup;
  END IF;

  IF v_caseid IS NULL THEN
    v_errorcode := 102;
	  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: Case ID can not be empty');
    GOTO cleanup;
  END IF;

  IF v_workbasketid IS NULL AND v_action = 'ASSIGN' THEN
    v_errorcode := 103;
	  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: Work Basket ID can not be empty if using action ASSIGN');
    GOTO cleanup;
  END IF;

  IF v_casepartyid IS NULL AND v_action = 'ASSIGN_TO_PARTY' THEN
    v_errorcode := 106;
	  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: Case Party ID can not be empty if using action ASSIGN_TO_PARTY');
    GOTO cleanup;
  END IF;

  -- CALCULATE WORKBASKET IF "ASSIGN TO ME"
  IF v_action = 'ASSIGN_TO_ME' THEN
    v_workbasketid := v_PrevWorkbasketId;
  	IF NVL(v_workbasketid, 0) = 0 THEN
  		v_errorcode := 107;
  		v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: Your user does not have an associated Work Basket');
  		GOTO cleanup;
  	END IF;	
  END IF;

  -- CALCULATE WORKBASKET IF "ASSIGN TO PARTY"
  IF v_action = 'ASSIGN_TO_PARTY' THEN  
    --get assigned unit to this case party
	BEGIN
		SELECT CALC_ID, PartyType_Code, Name  
		INTO v_unitid, v_unittype, v_casepartyname 
		FROM vw_ppl_caseparty 
		WHERE id = v_casepartyid;
	EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_errorcode    := 108;
      v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: Case Party record with ID' || TO_CHAR(v_casepartyid) || ' is missing');
      GOTO cleanup;		
	END;
	
	--check if anyone is actually assigned to the case party
	IF NVL(v_unitid, 0) = 0 OR TRIM(v_unittype) IS NULL THEN
		v_errorcode    := 109;
		v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: the ' || v_casepartyname || ' has not been assigned yet');
		GOTO cleanup;
	END IF;
	
	--get the unit 
    v_workbasketid := f_PPL_getPrimaryWB(UnitId => v_unitid, UnitType => v_unittype);	
	IF NVL(v_workbasketid, 0) = 0 THEN
		v_errorcode := 110;
		v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: the unit assigned to the Case Party ' || v_casepartyname || ' is missing a personal Work Basket');
		GOTO cleanup;
	END IF;	
	
	v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: attempting to assign to the ' || v_casepartyname);
  END IF;

  -- CHECK THAT THE SELECTED WORKBASKET EXISTS AND GET IT'S NAME
  IF v_action IN ('ASSIGN_TO_ME', 'ASSIGN_TO_PARTY', 'ASSIGN') THEN
    BEGIN
      SELECT CALCNAME INTO v_workbasketname 
	  FROM vw_PPL_SimpleWorkBasket 
	  WHERE id = v_workbasketid;
	  
	  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: assigning to ' || v_workbasketname);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errorcode    := 111;
        v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: unable to find Work Basket with ID ' || TO_CHAR(v_workbasketid));
        GOTO cleanup;
    END;
  ELSE
    v_workbasketid := NULL;
	v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: unassigning');
  END IF;

  --SET ASSUMED SUCCESS MESSAGE
  IF v_action = 'UNASSIGN' THEN
    SuccessResponse := 'Case has been unassigned';
  ELSE
    SuccessResponse := 'Case has been assigned to ' || v_workbasketname;
  END IF;
  
  
  BEGIN
    SELECT COL_CASEDICT_CASESYSTYPE INTO v_casetypeid
      FROM TBL_CASE
      WHERE COl_ID=v_caseid;
  EXCEPTION
    WHEN no_data_found THEN
      v_casetypeid :=NULL;
  END;    

  v_CEAttributes := '<Action>'||TO_CHAR(v_action)||'</Action>'||  
                    '<CasepartyId>'||TO_CHAR(v_casepartyid)||'</CasepartyId>'||                                                                         
                    '<CasePartyName>'||TO_CHAR(v_casepartyname)||'</CasePartyName>'||
                    '<UnitType>'||TO_CHAR(v_unittype)||'</UnitType>'||
                    '<UnitId>'||TO_CHAR(v_unitid)||'</UnitId>'||
                    '<WorkbasketId>'||TO_CHAR(v_workbasketid)||'</WorkbasketId>'||
                    '<WorkbasketName>'||TO_CHAR(v_workbasketname)||'</WorkbasketName>'||
                    '<PrevWorkbasketId>'||TO_CHAR(v_PrevWorkbasketId)||'</PrevWorkbasketId>'||
                    '<Context>' || TO_CHAR(v_Context) || '</Context>'||
                    '<Note>' || TO_CHAR(v_Note) || '</Note>';

  v_validationresult := 1;
  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE 
  --ASSIGN_CASE- AND 
  --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM-- 
  v_result := f_DCM_processCommonEvent(
              Attributes        => v_CEAttributes,
              code              => NULL, 
              caseid            => v_caseid, 
              casetypeid        => NULL, 
              commoneventtype   => 'ASSIGN_CASE', 
              errorcode         => v_errorcode, 
              errormessage      => v_errormessage, 
              eventmoment       => 'BEFORE', 
              eventtype         => 'VALIDATION', 
              HistoryMessage    => v_historyMsg,
              procedureid       => NULL, 
              taskid            => NULL, 
              tasktypeid        => NULL, 
              validationresult  => v_validationresult); 
              
  --write to history  
  IF v_historyMsg IS NOT NULL THEN
     v_result := f_HIST_createHistoryFn(
      AdditionalInfo => v_historyMsg,  
      IsSystem=>0, 
      Message=> 'Validation Common event(s)',
      MessageCode => 'CommonEvent', 
      TargetID => v_caseid, 
      TargetType=>'CASE'
     );
  END IF; 

  IF Nvl(v_validationresult, 0) = 0 THEN     
    v_errorcode    := 114;
    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => v_errormessage);
    GOTO cleanup;     
  END IF;  
  
  
  v_validationresult := 1;
  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE 
  --ASSIGN_CASE- AND 
  --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM-- 
  v_result := f_DCM_processCommonEvent(
              Attributes        => v_CEAttributes,
              code              => NULL, 
              caseid            => v_caseid, 
              casetypeid        => NULL, 
              commoneventtype   => 'ASSIGN_CASE', 
              errorcode         => v_errorcode, 
              errormessage      => v_errormessage, 
              eventmoment       => 'BEFORE', 
              eventtype         => 'ACTION', 
              HistoryMessage    => v_historyMsg,
              procedureid       => NULL, 
              taskid            => NULL, 
              tasktypeid        => NULL, 
              validationresult  => v_validationresult); 
              
  --write to history  
  IF v_historyMsg IS NOT NULL THEN
     v_result := f_HIST_createHistoryFn(
      AdditionalInfo => v_historyMsg,  
      IsSystem=>0, 
      Message=> 'Action Common event(s)',
      MessageCode => 'CommonEvent', 
      TargetID => v_caseid, 
      TargetType=>'CASE'
     );
  END IF; 

  
  BEGIN
    --UPDATE WORK BASKET
	IF f_DCM_isCaseInCache(v_caseid)=1 THEN
		UPDATE tbl_caseCC 
		SET COL_CASECCPPL_WORKBASKET = v_workbasketid
		WHERE col_id = v_caseid;
		v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: Case in cache has been updated');
	ELSE
		UPDATE tbl_case 
		SET COL_CASEPPL_WORKBASKET = v_workbasketid
		WHERE col_id = v_caseid;
		v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: Case has been updated');
	END IF;
    
  v_result := f_DCM_createCaseDateEvent(NAME => 'DATE_CASE_ASSIGNED', CaseId => v_caseid);

  IF v_note IS NOT NULL THEN
    IF v_action = 'UNASSIGN' THEN
      v_note := 'Case ' || ' has been unassigned from ' || v_workbasketname || ' with message <br> ' || v_note;
    ELSE
      v_note := 'Case ' || ' has been assigned to ' || v_workbasketname || ' with message <br> ' || v_note;
    END IF;
  
    INSERT INTO tbl_note (col_note, col_casenote) VALUES (v_note, v_caseid);
  END IF;
  
  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE 
  --ASSIGN_CASE- AND 
  --EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM-- 
  v_result := f_DCM_processCommonEvent(
              Attributes        => v_CEAttributes,
              code              => NULL, 
              caseid            => v_caseid, 
              casetypeid        => NULL, 
              commoneventtype   => 'ASSIGN_CASE', 
              errorcode         => v_errorcode, 
              errormessage      => v_errormessage, 
              eventmoment       => 'AFTER', 
              eventtype         => 'ACTION', 
              HistoryMessage    => v_historyMsg,
              procedureid       => NULL, 
              taskid            => NULL, 
              tasktypeid        => NULL, 
              validationresult  => v_validationresult); 
              
  --write to history  
  IF v_historyMsg IS NOT NULL THEN
     v_result := f_HIST_createHistoryFn(
      AdditionalInfo => v_historyMsg,  
      IsSystem=>0, 
      Message=> 'Action Common event(s)',
      MessageCode => 'CommonEvent', 
      TargetID => v_caseid, 
      TargetType=>'CASE'
     );
  END IF;  
  
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errorcode    := 112;
	    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: ' || SQLERRM);
      GOTO cleanup;
  END;
  
  --WRITE HISTORY AND PROCESS ERRORS
  IF (NVL(v_errorcode, 0) = 0) THEN
	v_result := f_HIST_createHistoryFn(
		AdditionalInfo=>SuccessResponse, 
		IsSystem=>0, 
		Message=> NULL,
		MessageCode => 'CaseAssigned', 
		TargetID => v_caseId, 
		TargetType=>'CASE'
	);
  
	:ERRORCODE       := 0;
	:ERRORMESSAGE    := NULL;  
  
	RETURN v_workbasketid;
  ELSE
    GOTO cleanup;
  END IF;
 
  <<cleanup>>  
	v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR CODE: ' || v_errorcode);
	v_result := f_HIST_createHistoryFn(
		AdditionalInfo=>v_message, 
		IsSystem=>0, 
		Message=> NULL,
		MessageCode => 'CaseAssignFailed', 
		TargetID => v_caseid, 
		TargetType=>'CASE'
	);		
	:errorCode       := v_errorcode;
	:errorMessage    := v_message;
	SuccessResponse := '';
  RETURN 0;
END;