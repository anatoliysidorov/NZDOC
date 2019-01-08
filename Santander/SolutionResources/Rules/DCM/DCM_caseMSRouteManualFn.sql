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
  v_SysTransitionCode   NVARCHAR2(255);
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
  v_assignAction     NVARCHAR2(255);
  v_TransitionId     NUMBER;
  v_CurrTransitionId NUMBER;
  v_dateEventValue   DATE;

  v_NextActivityName        NVARCHAR2(255);
  v_CurrActivityName        NVARCHAR2(255);
  v_CurrSysActivityName     NVARCHAR2(255);
  v_Attributes              NVARCHAR2(4000);
  v_AttributesCE            NVARCHAR2(4000);    
  
  --errors variables
  v_errorCode INTEGER;
  v_errorMessage NCLOB;
  v_successresponse  NCLOB;

  v_CanRoute INTEGER;
  v_CanClose INTEGER;
  v_IsValid INTEGER;
  v_historymsg NCLOB;
  v_outData CLOB;

BEGIN
  --INPUT
  v_CaseId       := :CaseId;  
  v_WorkbasketId := NVL(:WorkbasketId, 0);
  v_ResolutionId := :ResolutionId;
  v_TransitionId := :TransitionId;
  v_TargetMilestoneActivity :=  :Target;  
  
  --INTERNAL
  v_errorMessage := NULL;
  v_errorCode := 0;
  
  v_CurrSysActivityName  := NULL;
  v_NextActivityName     := NULL;
  v_CurrActivityName     := NULL;
  v_historymsg           := NULL; 
  v_Attributes           := NULL;
  v_AttributesCE         := NULL;
  v_TransitionUCode      := NULL; 
  v_CurrTransitionId     := NULL;  
  v_SysTransitionCode    := NULL;  
  v_outData              := NULL;
    
  --define a XML aka "parameters"
  v_Attributes:='<ResolutionId>'||TO_CHAR(v_ResolutionId)||'</ResolutionId>'||
                '<WorkbasketId>'||TO_CHAR(v_WorkbasketId)||'</WorkbasketId>'||
                '<TransitionId>'||TO_CHAR(v_TransitionId)||'</TransitionId>'; 

 --COPY CASE INTO CACHE
 v_result := f_DCM_CSCUseCache(CASEID     =>v_CaseId, 
                               DIRECTION  =>'COPY_TO_CACHE', 
                               USEMODE    =>'CASE');
        
  --GET INFORMATION ABOUT THE CASE AND CURRENT MILESTONE
  BEGIN
      SELECT    cs.COL_MILESTONEACTIVITY,
                cs.COL_CW_WORKITEMCASE,
                cs.COL_CASEDICT_CASESTATE,
                cs.COL_CASEPPL_WORKBASKET,
                s.COL_ID,
                s.COL_STATESTATECONFIG,
                s.COL_NAME,
                cs.COL_CASE_MSCURRTRANS,
                cwi.COL_ACTIVITY
      INTO      v_MilestoneActivity,
                v_CaseWorkItem,
                v_CurrentSysStateID,
                v_CurrentOwnerWB,
                v_CurrentMilestoneID,
                v_MilestoneDiagramID,
                v_CurrActivityName,
                v_CurrTransitionId,
                v_CurrSysActivityName
      FROM      TBL_CSCASE cs
      LEFT JOIN TBL_DICT_STATE s ON s.col_ID =cs.COL_CASEDICT_STATE
      INNER JOIN TBL_CSCW_WORKITEM cwi ON CS.COL_CW_WORKITEMCASE = CWI.COL_ID
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
  
  IF NVL(v_errorCode, 0) > 0 THEN
      GOTO cleanup;
  END IF;
  
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
  WHEN NO_DATA_FOUND THEN
    v_errorCode := 105;
    v_errorMessage := 'Target Milestone (Code is: "'||v_TargetMilestoneActivity||'") not found or invalid';
    GOTO cleanup;
  END;  

  --GET INFORMATION ABOUT THE SYSTEM TRANSITION FOR THE TARGET MILESTONE
  v_SysTransitionCode := f_DCM_getCaseTransition3(CASEID => v_CaseId, 
                                                  SOURCE => v_CurrSysActivityName, 
                                                  TARGET => v_NextSysStateActivity);
  IF (v_SysTransitionCode = 'NONE') THEN
    v_errorCode := 105;
    v_errorMessage := 'Transition with system code "'||v_SysTransitionCode||'" is not allowed by System State Configuration.'||
                      'Please contact your System Administrator.';
    
    GOTO cleanup;
  END IF;
  
  --BEFORE ROUTING VALIDATION EVENTS  
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
  
  --VALIDATE THAT A CASE IS NOT BLOCKED BY ANY RELATED CASES
  v_result := f_DCM_validateCaseLinks(TRANSITIONID =>v_TransitionId,
                                      CASE_ID =>v_CaseId,
                                      ERRORCODE =>v_errorCode,
                                      ERRORMESSAGE =>v_errorMessage,
                                      TARGET => v_NextMilestoneActivity,
                                      CANROUTE => v_CanRoute,
                                      CANCLOSE => v_CanClose);
  
  IF NVL(v_errorCode,0) >0 OR v_CanRoute = 0 OR v_CanClose = 0 THEN
      GOTO cleanup;
  END IF;
  
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
      IF v_IsValid=0 THEN
          GOTO cleanup;
      END IF;
  EXCEPTION
  WHEN OTHERS then
      v_errorCode := 105;
      v_errorMessage := 'There was an error executing events before entering the new milestone';
      GOTO cleanup;
  END; 
  
  v_AttributesCE :='<MilestoneActivity>' || to_char(v_MilestoneActivity) || '</MilestoneActivity>'||
                   '<MilestoneStateId>' || to_char(v_CurrentMilestoneID) || '</MilestoneStateId>'||
                   '<SystemStateId>' || to_char(v_CurrentSysStateID) || '</SystemStateId>'||
                   '<TargetMilestoneActivity>' || to_char(v_TargetMilestoneActivity) || '</TargetMilestoneActivity>'||
                   '<TargetMilestoneStateId>' || to_char(v_NextMilestoneID) || '</TargetMilestoneStateId>'||
                   '<TargetSystemStateId>' || to_char(v_NextSysStateID) || '</TargetSystemStateId>'||
                   '<TargetSystemStateIsFinish>' || to_char(v_NextSysStateIsFinish) || '</TargetSystemStateIsFinish>'||                                                             
                   '<TransitionUCode>' || to_char(v_TransitionUCode) || '</TransitionUCode>'||
                   '<TransitionCode>' || to_char(v_TransitionCode) || '</TransitionCode>'||
                   '<TransitionId>' || to_char(v_TransitionId) || '</TransitionId>'||
                   '<ResolutionId>'||TO_CHAR(v_ResolutionId)||'</ResolutionId>'||
                   '<CurrentOwnerWBId>' || to_char(v_CurrentOwnerWB) || '</CurrentOwnerWBId>'||
                   '<TargetOwnerWBId>' || to_char(v_WorkbasketId) || '</TargetOwnerWBId>';
  
  
  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -CASE_MS_ROUTE- AND*/
  /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
  v_IsValid := 1;
  
  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData, 
                                       Attributes       => v_AttributesCE,
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


  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CASE_MS_ROUTE- AND*/
  /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
  v_IsValid := 1;

  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData, 
                                       Attributes       => v_AttributesCE,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'CASE_MS_ROUTE',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
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
 
	
	--UPDATE THE CASE AND CW_WORKITEM TABLE WITH THE NEW MILESTONE/STATE
  v_dateEventValue := SYSDATE;
  UPDATE TBL_CSCASE cs
  SET    --sys
         COL_ACTIVITY= v_NextSysStateActivity,
         COL_CASEDICT_CASESTATE=v_NextSysStateID,
         COL_DATEEVENTVALUE = v_dateEventValue,
         COL_GOALSLADATETIME = (case when (select sseg.col_intervalds from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = v_NextMilestoneID)
                                is null
                                and (select sseg.col_intervalym from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = v_NextMilestoneID)
                                is null then null
                                else v_dateEventValue end) + 
                                (case when (select sseg.col_intervalds from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = v_NextMilestoneID)
                                is not null then
                                (select  to_dsinterval(sseg.col_intervalds) from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = v_NextMilestoneID)
                                else to_dsinterval('0 000') end) +
                                (case when (select sseg.col_intervalym from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = v_NextMilestoneID)
                                is not null then
                                (select to_yminterval(sseg.col_intervalym) from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = v_NextMilestoneID)
                                else to_yminterval('0-0') end),
         COL_DLINESLADATETIME = (case when (select ssed.col_intervalds from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = v_NextMilestoneID)
                                 is null
                                 and (select ssed.col_intervalym from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = v_NextMilestoneID)
                                 is null then null
                                 else v_dateEventValue end) + 
                                 (case when (select ssed.col_intervalds from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = v_NextMilestoneID)
                                 is not null then
                                 (select  to_dsinterval(ssed.col_intervalds) from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = v_NextMilestoneID)
                                 else to_dsinterval('0 000') end) +
                                 (case when (select ssed.col_intervalym from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = v_NextMilestoneID)
                                 is not null then
                                 (select to_yminterval(ssed.col_intervalym) from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = v_NextMilestoneID)
                                 else to_yminterval('0-0') end),           
         --ms
         COL_MILESTONEACTIVITY = v_NextMilestoneActivity,
         COL_CASEDICT_STATE = v_NextMilestoneID,
         COL_PREVMSACTIVITY = v_MilestoneActivity,
         COL_PREVCASEDICT_STATE = v_CurrentMilestoneID,
         COL_STP_RESOLUTIONCODECASE = v_ResolutionId,
         COL_CASE_MSCURRTRANS = v_TransitionId,
         COL_CASE_MSPREVTRANS = v_CurrTransitionId
  WHERE  COl_ID=v_CaseId;
    
  UPDATE TBL_CSCW_WORKITEM
  SET    --sys
         COL_CW_WORKITEMPREVCASESTATE=COL_CW_WORKITEMDICT_CASESTATE,
         COL_ACTIVITY = v_NextSysStateActivity,
         COL_CW_WORKITEMDICT_CASESTATE=v_NextSysStateID,
         --ms
         COL_PREVMSACTIVITY = COL_MILESTONEACTIVITY,
         COL_PREVCWIDICT_STATE = COL_CWIDICT_STATE,
         COL_MILESTONEACTIVITY = v_NextMilestoneActivity,
         COL_CWIDICT_STATE = v_NextMilestoneID
  WHERE  COL_ID = v_CaseWorkItem;


  FOR rec2 IN
  (SELECT /*
          cs.col_id as CaseStateId, cs.col_code as CaseStateCode, cs.col_name as CaseStateName, cs.col_activity as CaseStateActivity,
          cst.col_id as CaseStateSetupId, cst.col_name as CaseStateSetupName, */
          
          cst.col_code as CaseStateSetupCode,
          cst.col_forcednull as ForcedNull,             
          cst.col_forcedoverwrite as ForcedOverwrite,
          cst.col_nulloverwrite as NullOverwrite /*, 
          
          cst.col_notnulloverwrite as NotNullOverwrite, cst.col_nulloverwrite as NullOverwrite
          */
   FROM TBL_DICT_CASESTATE cs
   INNER JOIN TBL_DICT_CASESTATESETUP cst on cs.col_id = cst.col_casestatesetupcasestate
   WHERE cs.col_activity = v_NextSysStateActivity)
  LOOP
    if rec2.casestatesetupcode = 'DATEASSIGNED' then
      if rec2.ForcedNull = 1 then
        update TBL_CSCASE set col_dateassigned = null where col_id = v_CaseId;
      elsif rec2.ForcedOverwrite = 1 then
        update TBL_CSCASE set col_dateassigned = SYSDATE where col_id = v_CaseId;
      elsif rec2.NullOverwrite = 1 then
        update TBL_CSCASE set col_dateassigned = SYSDATE where col_id = v_CaseId and col_dateassigned is null;
      end if;
    elsif rec2.casestatesetupcode = 'DATECLOSED' then
      update TBL_CSCASE set col_dateclosed = SYSDATE where col_id = v_CaseId;

    END IF;
  END LOOP;


	--WRITE HISTORY THAT MILESTONE WAS ROUTED
	IF NVL(v_ResolutionId, 0) > 0 THEN    
    v_result := F_hist_createhistoryfn( additionalinfo => NULL,
                                        issystem => 0,
                                        message => NULL,
                                        messagecode => 'CaseMilestoneRoutedWithResolution',
                                        targetid => v_CaseId,
                                        targettype => 'CASE' );

    v_result := f_DCM_createCaseHistory (MessageCode => 'CaseStateRoutedWithResolution', 
                                         CaseId => v_CaseId, 
                                         IsSystem => 0);
	ELSE
    
    v_result := F_hist_createhistoryfn( additionalinfo => NULL,
                                        issystem => 0,
                                        message => NULL,
                                        messagecode => 'CaseMilestoneRouted',
                                        targetid => v_CaseId,
                                        targettype => 'CASE' );

    v_result := f_DCM_createCaseHistory (MessageCode => 'CaseStateRouted', 
                                         CaseId => v_CaseId, 
                                         IsSystem => 0);
	END IF;

    
  --SET DATE EVENTS FOR MILESTONE ROUTE
  v_result := f_DCM_addCaseMSDateEventList(CASEID => v_CaseId,
                                           STATECONFIGID=>v_MilestoneDiagramID); 
                                             
                                             
                                             
  --ASSIGN A NEW OWNER TO THE CASE IF NEEDED
  IF NVL(v_CurrentOwnerWB, 0) <> v_WorkbasketId THEN
    IF v_WorkbasketId = 0 THEN v_assignAction := 'UNASSIGN';
    ELSE  v_assignAction := 'ASSIGN';
  END IF;
 
  v_result := f_DCM_assignCaseFn(ACTION         => v_assignAction, 
                                 CASE_ID        => v_caseid, 
                                 CASEPARTY_ID   => NULL, 
                                 ERRORCODE      => v_errorcode, 
                                 ERRORMESSAGE   => v_errormessage, 
                                 NOTE           => NULL, 
                                 SUCCESSRESPONSE  => v_successresponse, 
                                 WORKBASKET_ID    => v_workbasketid); 	

    IF NVL(v_errorCode,0) >0 THEN GOTO cleanup; END IF;		
  END IF; 
        
  --RESET THE RESOLUTION CODE IF ROUTING TO A NONE FINISH SYSTEM STATE
/*  
	IF NVL(v_NextSysStateIsFinish, 0) = 0 THEN
    v_ResolutionId := NULL;
	END IF;  
*/  
                                                
                                                
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
        
  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CASE_MS_ROUTE- AND*/
  /*--EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/
  v_IsValid := 1;

  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData, 
                                       Attributes       => v_AttributesCE,
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

  --CREATE NOTIFICATION
  v_result := f_DCM_createNotification(CaseId => v_CaseId, 
                                       NotificationTypeCode => 'CASE_MOVED', 
                                       TaskId => null);

  --INVALIDATE CASE WHERE CASE CHANGED ITS STATE
  v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
   
    

  --UPDATE CASE FROM CACHE
  v_result := f_DCM_CSCUseCache(CASEID     =>v_CaseId, 
                                DIRECTION  =>'UPDATE_FROM_CACHE', 
                                USEMODE    =>'CASE');  

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