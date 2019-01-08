DECLARE
  --INPUT
  v_CaseId INTEGER;
  v_TargetMilestoneActivity NVARCHAR2(255);
  v_WorkbasketId INTEGER;
  v_ResolutionId INTEGER;
  
  --INTERNAL	
  v_MilestoneActivity     NVARCHAR2(255);
  v_NextMilestoneActivity NVARCHAR2(255);
  v_CurrentMilestoneID  INTEGER;
  v_NextMilestoneID     INTEGER;
  v_TransitionCode      NVARCHAR2(255);
  v_TransitionUCode     NVARCHAR2(255);
  v_MilestoneDiagramID  INTEGER;
  v_CurrentSysStateID   INTEGER;
  v_NextSysStateID      INTEGER;
  v_NextSysStateActivity NVARCHAR2(255);
  v_NextSysStateIsFinish INTEGER;
  v_CaseWorkItem     INTEGER;
  v_CurrentOwnerWB   INTEGER;
  v_result           INTEGER;
  v_messageCode      NVARCHAR2(255);
  v_assignAction     NVARCHAR2(255);
  v_TransitionId     NUMBER;
  v_CurrTransitionId NUMBER;

  v_NextActivityName    NVARCHAR2(255);
  v_CurrActivityName    NVARCHAR2(255);
  v_Attributes          NVARCHAR2(4000);
  v_CEAttributes        NVARCHAR2(4000);
  v_Context             NVARCHAR2(255);
  v_Note                NVARCHAR2(4000);
  
  --errors variables
  v_errorCode INTEGER;
  v_errorMessage NCLOB;
  v_successresponse  NCLOB;

  v_CanRoute INTEGER;
  v_CanClose INTEGER;
  v_IsValid INTEGER;
  v_historymsg NCLOB;  

BEGIN
  --INPUT
  v_CaseId       := :CaseId;
  v_TargetMilestoneActivity := :Target;
  v_WorkbasketId := NVL(:WorkbasketId, 0);
  v_ResolutionId := :ResolutionId;
  v_TransitionId := :TransitionId;  
  v_Note         := :Note;
  v_Context      := NVL(:Context, 'CASE_MS_ROUTE');
  
  --INTERNAL
  v_errorMessage := NULL;
  v_errorCode := 0;
  
  v_NextActivityName     := NULL;
  v_CurrActivityName     := NULL;
  v_historymsg           := NULL; 
  v_Attributes           := NULL;
  v_CEAttributes         := NULL;
  v_TransitionUCode      := NULL;  
  v_CurrTransitionId     := NULL;  
        
  IF v_CaseId IS NULL THEN
    v_errorCode :=101;
    v_errorMessage :='A CaseId value cannot be NULL or empty';
    GOTO cleanup;
  END IF;
  
  IF v_TransitionId IS NULL THEN
    v_errorCode :=101;
    v_errorMessage :='A TransitionId value cannot be NULL or empty';
    GOTO cleanup;
  END IF;
  
  IF v_TargetMilestoneActivity IS NULL THEN
    v_errorCode :=101;
    v_errorMessage :='A Target Activity value cannot be NULL or empty';
    GOTO cleanup;
  END IF;

  --define a XML aka "parameters"
  v_Attributes:='<ResolutionId>'||TO_CHAR(v_ResolutionId)||'</ResolutionId>'||
                '<WorkbasketId>'||TO_CHAR(v_WorkbasketId)||'</WorkbasketId>'||
                '<TransitionId>'||TO_CHAR(v_TransitionId)||'</TransitionId>'||
                '<Context>'||TO_CHAR(v_Context)||'</Context>';
        
  --GET INFORMATION ABOUT THE CASE AND CURRENT MILESTONE
  BEGIN
    SELECT cs.col_milestoneactivity,
           cs.col_cw_workitemcase,
           cs.COL_CASEDICT_CASESTATE,
           cs.COL_CASEPPL_WORKBASKET,
           s.COL_ID,
           s.COL_STATESTATECONFIG,
           s.COL_NAME,
           cs.COL_CASE_MSCURRTRANS
    INTO  v_MilestoneActivity,
          v_CaseWorkItem,
          v_CurrentSysStateID,
          v_CurrentOwnerWB,
          v_CurrentMilestoneID,
          v_MilestoneDiagramID,
          v_CurrActivityName,
          v_CurrTransitionId
    FROM  TBL_CASE cs
    LEFT JOIN TBL_DICT_STATE s ON s.col_ID =cs.COL_CASEDICT_STATE
    WHERE     cs.col_id = v_CaseId;  
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_errorCode := 104;
    v_errorMessage := 'Either the Case is missing or the current Milestone is invalid';
    GOTO cleanup;
  END;
    
  --define a next activity name
  BEGIN
    SELECT COL_NAME INTO v_NextActivityName 
    FROM TBL_DICT_STATE 
    WHERE UPPER(col_activity) = UPPER(v_TargetMilestoneActivity)
          AND NVL(col_statestateconfig,0) = v_MilestoneDiagramID;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN 
      v_errorCode := 104;
      v_errorMessage := 'Target Milestone (Code is: "'||v_TargetMilestoneActivity||'") not found or invalid';
      GOTO cleanup;
  END;    
  
  --GET INFORMATION ABOUT THE TRANSITION FOR THE TARGET MILESTONE
  v_result := f_DCM_getMSTransitionData(TRANSITIONID =>v_TransitionId,
                                        CASEID=>NULL,
                                        SOURCE=>v_MilestoneActivity,
                                        STATECONFIGID =>v_MilestoneDiagramID,
                                        TARGET=>v_TargetMilestoneActivity,
                                        ERRORCODE =>v_errorCode, -- output
                                        ERRORMESSAGE=>v_errorMessage, --output
                                        NEXTACTIVITY=>v_NextMilestoneActivity, -- output
                                        NEXTSTATEID => v_NextMilestoneID, -- output
                                        TRANSITION=>v_TransitionCode -- output
                                       );
  
  IF NVL(v_errorCode, 0) > 0 THEN GOTO cleanup; END IF;
  
  IF (v_TransitionCode = 'NONE') THEN
    IF(v_CurrentMilestoneID = v_NextMilestoneID) THEN
        v_errorCode := 105;
        v_errorMessage := 'The Case is already in the target milestone "'||v_NextActivityName||
                          '". Please reload the page.';
    ELSE
        v_errorCode := 105;
        v_errorMessage := 'Transition between the 2 milestones is not found.'||
        '(From "'||v_CurrActivityName||'" to "'||v_NextActivityName||'").'||
        ' Try to reload the page or contact your System Administrator.';
    END IF;
    GOTO cleanup;
  ELSE
    BEGIN
      SELECT COL_COMMONCODE INTO v_TransitionUCode 
      FROM TBL_DICT_TRANSITION
      WHERE COL_ID=NVL(v_TransitionId,0);
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN
        v_TransitionUCode := NULL;          
      WHEN TOO_MANY_ROWS THEN
        v_TransitionUCode := NULL;          
    END;
  END IF;
  
  IF NVL(v_NextMilestoneID,0) = 0 THEN
    v_errorCode := 105;
    v_errorMessage := 'The target milestone "'||v_NextActivityName||'" is not valid.'||
    ' Try to reload the page or contact your System Administrator.';
    GOTO cleanup;
  END IF;
    
  --GET INFORMATION ABOUT THE SYSTEM STATE THAT IS LINKED TO THE TARGET MILESTONE
  BEGIN
    SELECT st.COL_STATECASESTATE, cs.COL_ACTIVITY, cs.COL_ISFINISH
    INTO   v_NextSysStateID, v_NextSysStateActivity, v_NextSysStateIsFinish
    FROM   TBL_DICT_STATE st
    LEFT JOIN TBL_DICT_CASESTATE cs ON cs.col_id = st.COL_STATECASESTATE
    WHERE  st.col_id=v_NextMilestoneID;  
  EXCEPTION
    WHEN NO_DATA_FOUND then
      v_errorCode := 105;
      v_errorMessage := 'Target Milestone (Code is: "'||v_TargetMilestoneActivity||'") not found or invalid';
      GOTO cleanup;
  END; 
  
  --VALIDATE THAT A CASE IS NOT BLOCKED BY ANY RELATED CASES
  v_result := f_DCM_validateCaseLinks(TRANSITIONID =>v_TransitionId,
                                      CASE_ID =>v_CaseId,
                                      ERRORCODE =>v_errorCode,
                                      ERRORMESSAGE =>v_errorMessage,
                                      TARGET => v_NextMilestoneActivity,
                                      CANROUTE => v_CanRoute,
                                      CANCLOSE => v_CanClose);
  
  IF NVL(v_errorCode,0) >0 OR v_CanRoute = 0 OR v_CanClose = 0 THEN GOTO cleanup; END IF;   

  --define an attributes for custom event(s)
  v_CEAttributes :='<MilestoneActivity>' || TO_CHAR(v_MilestoneActivity) || '</MilestoneActivity>'||
                   '<MilestoneStateId>' || TO_CHAR(v_CurrentMilestoneID) || '</MilestoneStateId>'||
                   '<SystemStateId>' || TO_CHAR(v_CurrentSysStateID) || '</SystemStateId>'||
                   '<TargetMilestoneActivity>' || TO_CHAR(v_TargetMilestoneActivity) || '</TargetMilestoneActivity>'||
                   '<TargetMilestoneStateId>' || TO_CHAR(v_NextMilestoneID) || '</TargetMilestoneStateId>'||
                   '<TargetSystemStateId>' || TO_CHAR(v_NextSysStateID) || '</TargetSystemStateId>'||
                   '<TargetSystemStateIsFinish>' || TO_CHAR(v_NextSysStateIsFinish) || '</TargetSystemStateIsFinish>'||                                                             
                   '<TransitionUCode>' || TO_CHAR(v_TransitionUCode) || '</TransitionUCode>'||
                   '<TransitionCode>' || TO_CHAR(v_TransitionCode) || '</TransitionCode>'||
                   '<TransitionId>' || TO_CHAR(v_TransitionId) || '</TransitionId>'||
                   '<CurrentOwnerWBId>' || TO_CHAR(v_CurrentOwnerWB) || '</CurrentOwnerWBId>'||
                   '<TargetOwnerWBId>' || TO_CHAR(v_WorkbasketId) || '</TargetOwnerWBId>'|| 
                   '<Context>' || TO_CHAR(v_Context) || '</Context>'||
                   '<Note>' || TO_CHAR(v_Note) || '</Note>';
                   
  /*CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -CASE_MS_ROUTE- AND
    EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM
   */
  v_IsValid := 1;
  v_result := f_DCM_processCommonEvent(Attributes       => v_CEAttributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'CASE_MS_ROUTE',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
                                       eventtype        => 'VALIDATION',
                                       historymessage   => v_historymsg,
                                       procedureid      => NULL,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_IsValid);

  /*--write to history*/
  IF v_historymsg IS NOT NULL THEN
    v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                       issystem       => 0,
                                       MESSAGE        => 'Validation Common event(s)',
                                       messagecode    => 'CommonEvent',
                                       targetid       => v_caseid,
                                       targettype     => 'CASE');
  END IF;

  IF NVL(v_IsValid, 0) = 0 THEN
    v_errorCode := v_errorCode;
    v_errorMessage := v_errorMessage;
    GOTO cleanup;
  END IF;
  
  --BEFORE ROUTING VALIDATION EVENTS
  BEGIN
    v_result := f_DCM_processMSStateEvents(ATTRIBUTES =>v_Attributes,
                                           CASEID=> v_CaseId,
                                           ERRORCODE=>v_errorCode,
                                           ERRORMESSAGE =>v_errorMessage,
                                           EVTMOMENT=>'BEFORE',
                                           EVTSTATE=>v_NextMilestoneActivity,
                                           EVTTYPE=>'VALIDATION',
                                           ISVALID=>v_IsValid,
                                           STATECONFIGID=>v_MilestoneDiagramID);
    
    IF v_IsValid <> 1 THEN
      v_errorCode := v_errorCode;
      v_errorMessage := v_errorMessage;
      GOTO cleanup;
    END IF;
  EXCEPTION
  WHEN OTHERS then
    v_errorCode := 105;
    v_errorMessage := 'There was an error executing validation events before entering the new milestone';
    GOTO cleanup;
  END;
    
  --PROCESS EVENTS BEFORE ENTERING THE MILESTONE
  BEGIN
    v_result := f_DCM_processMSStateEvents(ATTRIBUTES =>v_Attributes,
                                           CASEID=> v_CaseId,
                                           ERRORCODE=>v_errorCode,
                                           ERRORMESSAGE =>v_errorMessage,
                                           EVTMOMENT=>'BEFORE',
                                           EVTSTATE=>v_NextMilestoneActivity,
                                           EVTTYPE=>'ACTION',
                                           ISVALID=>v_IsValid,
                                           STATECONFIGID=>v_MilestoneDiagramID);
    IF v_IsValid=0 THEN GOTO cleanup; END IF;
  EXCEPTION
  WHEN OTHERS then
    v_errorCode := 105;
    v_errorMessage := 'There was an error executing events before entering the new milestone';
    GOTO cleanup;
  END; 
  	
	--ROUTE CASE STATE IF THE SYSTEM STATE IF NEEDED
	IF v_CurrentSysStateID <> v_NextSysStateID THEN
	  v_result := f_DCM_caseRouteManualFn(CASEID => v_caseid,
                    									  ERRORCODE    => v_errorCode,
                    									  ERRORMESSAGE => v_errorMessage,
                    									  RESOLUTIONID => NULL, --taken care of manually
                    									  TARGET       => v_NextSysStateActivity,
                    									  WORKBASKETID => NULL); --taken care of manually
									  
		IF NVL(v_errorCode,0) >0 THEN GOTO cleanup; END IF;
  END IF;
	      
  --RESET THE RESOLUTION CODE IF ROUTING TO A NONE FINISH SYSTEM STATE
	IF NVL(v_NextSysStateIsFinish, 0) = 0 THEN v_ResolutionId := NULL; END IF;
	
	--UPDATE THE CASE AND CW_WORKITEM TABLE WITH THE NEW MILESTONE/STATE
  UPDATE TBL_CASE
  SET    COL_MILESTONEACTIVITY = v_NextMilestoneActivity,
         COL_CASEDICT_STATE = v_NextMilestoneID,
         COL_PREVMSACTIVITY = v_MilestoneActivity,
         COL_PREVCASEDICT_STATE = v_CurrentMilestoneID,
         COL_STP_RESOLUTIONCODECASE = v_ResolutionId,
         COL_CASE_MSCURRTRANS = v_TransitionId,
         COL_CASE_MSPREVTRANS = v_CurrTransitionId
  WHERE  COl_ID=v_CaseId;
  
  UPDATE TBL_CW_WORKITEM
  SET    col_PrevMSActivity = col_MilestoneActivity,
         col_PrevCWIDICT_State = col_CWIDICT_State,
         col_MilestoneActivity = v_NextMilestoneActivity,
         col_CWIDICT_State = v_NextMilestoneID
  WHERE  col_id = v_CaseWorkItem;
	  
  --SET DATE EVENTS FOR MILESTONE ROUTE
  v_result := f_DCM_addCaseMSDateEventList(CASEID => v_CaseId,
                                           STATECONFIGID=>v_MilestoneDiagramID);    
  
  --PROCESS EVENTS AFTER ENTERING THE MILESTONE
  v_result := f_DCM_processMSStateEvents(ATTRIBUTES =>v_Attributes,
                                         CASEID=> v_CaseId,
                                         ERRORCODE=>v_errorCode,
                                         ERRORMESSAGE =>v_errorMessage,
                                         EVTMOMENT=>'AFTER',
                                         EVTSTATE=>v_NextMilestoneActivity,
                                         EVTTYPE=>'ACTION',
                                         ISVALID=>v_IsValid,
                                         STATECONFIGID=>v_MilestoneDiagramID);
  
  IF v_IsValid=0 THEN GOTO cleanup; END IF;


  --ADD NOTE TO CASE IF NEEDED
  IF v_Note IS NOT NULL THEN
    INSERT INTO TBL_NOTE(COL_NOTENAME, COL_NOTE, COL_VERSION, COL_CASENOTE)
    VALUES('Routing note', v_Note, 1, v_CaseId);  
  END IF;
        
  /*CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CASE_MS_ROUTE- AND
    EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM
  */
  v_IsValid := 1;  
  v_result := f_DCM_processCommonEvent(Attributes       => v_CEAttributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'CASE_MS_ROUTE',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'AFTER',
                                       eventtype        => 'ACTION',
                                       historymessage   => v_historymsg,
                                       procedureid      => NULL,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_IsValid);

  /*--write to history*/
  IF v_historymsg IS NOT NULL THEN
    v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                       issystem       => 0,
                                       MESSAGE        => 'Action Common event(s)',
                                       messagecode    => 'CommonEvent',
                                       targetid       => v_caseid,
                                       targettype     => 'CASE');
  END IF;

  IF NVL(v_IsValid, 0) = 0 THEN
    v_errorCode := v_errorCode;
    v_errorMessage := v_errorMessage;
    GOTO cleanup;
  END IF;
  
	--ASSIGN A NEW OWNER TO THE CASE IF NEEDED
	IF NVL(v_CurrentOwnerWB, 0) <> v_WorkbasketId THEN
		IF v_WorkbasketId = 0 THEN v_assignAction := 'UNASSIGN';
		ELSE v_assignAction := 'ASSIGN';
		END IF;
		
		v_result := f_DIF_assignCaseFn(Context    => 'ASSIGN_CASE',
                                   ACTION     => v_assignAction, 
                            			 CASE_ID    => v_caseid, 
                            			 CASEPARTY_ID => NULL, 
                            			 ERRORCODE    => v_errorcode, 
                            			 ERRORMESSAGE => v_errormessage, 
                            			 NOTE         => NULL, 
                            			 SUCCESSRESPONSE => v_successresponse, 
                            			 WORKBASKET_ID  => v_workbasketid); 	
                                                                    
		IF NVL(v_errorCode,0) >0 THEN GOTO cleanup; END IF;		
	END IF; 

	--WRITE HISTORY THAT MILESTONE WAS ROUTED
	IF NVL(v_ResolutionId, 0) > 0 THEN v_messageCode := 'CaseMilestoneRoutedWithResolution';
	ELSE v_messageCode := 'CaseMilestoneRouted';
	END IF;

  v_result := F_hist_createhistoryfn( additionalinfo => NULL,
                                      issystem => 0,
                                      message => NULL,
                                      messagecode => v_messageCode,
                                      targetid => v_CaseId,
                                      targettype => 'CASE' );
  
  --END
  :ErrorCode := 0;
  :ErrorMessage := NULL;
  RETURN 0;
  
  --error block
  <<cleanup>> 
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;	
  v_result := F_hist_createhistoryfn( additionalinfo => NULL,
                                      issystem => 0,
                                      message => NULL,
                                      messagecode => 'GenericError',
                                      targetid => v_CaseId,
                                      targettype => 'CASE' );
  RETURN -1;
END;