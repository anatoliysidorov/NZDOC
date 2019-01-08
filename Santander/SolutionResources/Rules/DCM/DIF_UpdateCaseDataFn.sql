DECLARE
  v_CaseId INTEGER;
  v_CaseTypeId INTEGER;
  v_Summary NVARCHAR2(255);
  v_Description NCLOB;
  v_Result INTEGER;
  v_customdataprocessor NVARCHAR2(255);
  v_CustomData NCLOB;
  v_PrevCustomData NCLOB;
  v_SubmittedCustomData NCLOB;
  v_RecordIdExt INTEGER;
  v_CustomDataXML XMLTYPE;
  v_Priority_id INTEGER;
  v_Draft INTEGER;
  v_JustCustomData INTEGER;
  v_validationresult number;
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
  v_historyMsg          nclob;
  v_extractedvalue NCLOB;
  v_Context NVARCHAR2(255);
  v_CEAttributes  NVARCHAR2(4000);   
  
BEGIN
  --INPUT
  v_CaseId        := :CASEID;
  v_Summary       := :SUMMARY;
  v_Description   := :DESCRIPTION;
  v_SubmittedCustomData  := :CUSTOMDATA;
  v_Priority_id    := :PRIORITY_ID;
  v_Draft    := :DRAFT;
  v_JustCustomData := :JUSTCUSTOMDATA;
  v_Context := NVL(:Context, 'UPDATE_CASE_DATA');

  --INIT
  v_historyMsg  := NULL;
  v_CEAttributes := NULL;

  IF v_caseid IS NULL THEN
    v_errorcode := 102;
	  v_ErrorMessage := 'ERROR: Case ID cannot be empty';
    GOTO cleanup;
  END IF;

  IF v_Summary IS NULL THEN
    v_errorcode := 102;
	  v_ErrorMessage := 'ERROR: Summary cannot be empty';
    GOTO cleanup;
  END IF;

  --FIND CASE TYPE
  BEGIN
    SELECT COL_CASEDICT_CASESYSTYPE INTO v_CaseTypeId
    FROM TBL_CASE
    WHERE col_id = v_CaseId;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_CaseTypeId := NULL;
  END;

  v_CEAttributes := '<Summary>'||TO_CHAR(v_Summary)||'</Summary>'||  
                    '<PriorityId>'||TO_CHAR(v_Priority_id)||'</PriorityId>'||                                                                         
                    '<Draft>'||TO_CHAR(v_Draft)||'</Draft>'||
                    '<Context>' || TO_CHAR(v_Context) || '</Context>';
      
  v_validationresult := 1;
  
  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -UPDATE_CASE_DATA- AND 
  --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--   
  v_result := f_DCM_processCommonEvent(
              Attributes      =>v_CEAttributes,
              code            => NULL, 
              caseid          => v_caseid, 
              casetypeid      => v_casetypeid, 
              commoneventtype => 'UPDATE_CASE_DATA', 
              errorcode       => v_errorcode, 
              errormessage    => v_errormessage, 
              eventmoment     => 'BEFORE', 
              eventtype       => 'VALIDATION', 
              HistoryMessage  => v_historyMsg,
              procedureid     => NULL, 
              taskid          => NULL, 
              tasktypeid      => NULL, 
              validationresult => v_validationresult); 
              
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
  
  IF NVL(v_validationresult,0) = 0 THEN GOTO cleanup; END IF;

  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -UPDATE_CASE_DATA- AND 
  --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--   
  v_result := f_DCM_processCommonEvent(
              Attributes      =>v_CEAttributes,
              code            => NULL, 
              caseid          => v_caseid, 
              casetypeid      => v_casetypeid, 
              commoneventtype => 'UPDATE_CASE_DATA', 
              errorcode       => v_errorcode, 
              errormessage    => v_errormessage, 
              eventmoment     => 'BEFORE', 
              eventtype       => 'ACTION', 
              HistoryMessage  => v_historyMsg,
              procedureid     => NULL, 
              taskid          => NULL, 
              tasktypeid      => NULL, 
              validationresult => v_validationresult); 
              
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
  
  --UPDATE BASIC DATA
  BEGIN
    v_Result := f_DIF_UpdateBasicCaseDataFn(CASEID        =>v_caseid, 
                                            CONTEXT       =>v_Context, 
                                            DRAFT         =>v_Draft, 
                                            ERRORCODE     =>v_errorcode, 
                                            ERRORMESSAGE  =>v_errormessage, 
                                            PRIORITY_ID   =>v_Priority_id, 
                                            SUMMARY       =>v_Summary);
    IF NVL(v_errorcode, 0)<>0 THEN GOTO cleanup; END IF;
  EXCEPTION 
    WHEN OTHERS THEN 
    v_errorcode := 102;
	  v_errormessage := 'ERROR: Cant update a basic case data';
    GOTO cleanup;    
  END;

  --UPDATE CUSTOM DATA
  BEGIN
    v_Result := f_DIF_UpdateCustomCaseDataFn(CASEID         =>v_caseid, 
                                             CONTEXT        =>v_Context,  
                                             CUSTOMDATA     =>v_SubmittedCustomData, 
                                             DESCRIPTION    =>v_Description, 
                                             DRAFT          =>v_Draft, 
                                             ERRORCODE      =>v_errorcode, 
                                             ERRORMESSAGE   =>v_errormessage,  
                                             JUSTCUSTOMDATA =>v_JustCustomData, 
                                             PRIORITY_ID    =>v_Priority_id,  
                                             SUMMARY        =>v_Summary);
    IF NVL(v_errorcode, 0)<>0 THEN GOTO cleanup; END IF;
  EXCEPTION 
    WHEN OTHERS THEN 
    v_errorcode := 102;
	  v_errormessage := 'ERROR: Cant update a custom case data';
    GOTO cleanup;    
  END;

  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -UPDATE_CASE_DATA- AND 
  --EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--  
  v_result := f_DCM_processCommonEvent(
              Attributes =>v_CEAttributes,
              code => NULL, 
              caseid => v_caseid, 
              casetypeid => v_casetypeid, 
              commoneventtype => 'UPDATE_CASE_DATA', 
              errorcode => v_errorcode, 
              errormessage => v_errormessage, 
              eventmoment => 'AFTER', 
              eventtype => 'ACTION',
              HistoryMessage =>v_historyMsg,                
              procedureid => NULL, 
              taskid => NULL, 
              tasktypeid => NULL, 
              validationresult => v_validationresult
              ); 
              
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
        
  :errorCode    := 0;
  :errorMessage := '';
  :SuccessResponse := 'Update was successfull'; 

  --RECORD CASE HISTORY
  v_result := f_DCM_createCaseHistoryFn(AdditionalInfo => '', 
                                        CaseId => v_CaseId, 
                                        IsSystem => 0,
                                        Message => 'Update Basic Case Data was successful'
                                        MessageCode => 'CaseModified',
                                        MessageTypeId => null);

  RETURN 0;
  
  <<cleanup>>  
  :errorCode     := v_errorcode;
  :errorMessage  := v_errormessage;	
  :SuccessResponse := '';

  --RECORD CASE HISTORY
  v_result := f_DCM_createCaseHistoryFn(AdditionalInfo => v_errormessage, 
                                        CaseId => v_CaseId, 
                                        IsSystem => 0,
                                        Message => v_errormessage
                                        MessageCode => 'CaseModifiedError',
                                        MessageTypeId => null);

  RETURN -1;

END;