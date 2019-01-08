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
  v_SubmittedCustomData  := NVL(:CUSTOMDATA, '<CustomData><Attributes></Attributes></CustomData>');
  v_Priority_id    := :PRIORITY_ID;
  v_Draft    := :DRAFT;
  v_JustCustomData := NVL(:JUSTCUSTOMDATA, 0);
  v_Context := :Context;

  --INIT
  v_historyMsg  := NULL;
  v_CEAttributes := NULL;

  v_PrevCustomData := f_DCM_getCaseCustomData(CaseId => v_CaseId);

  BEGIN
    SELECT EXTRACT(XMLTYPE(v_SubmittedCustomData), '/CustomData/Attributes/Form').getClobVal() 
    INTO v_extractedvalue 
    FROM dual;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN v_extractedvalue := null;
  END;

  IF v_extractedvalue IS NOT NULL THEN
    v_CustomData := f_FORM_mergeCustomData(Input => v_PrevCustomData, Input2 => v_SubmittedCustomData);
  ELSE
    v_CustomData := v_SubmittedCustomData;
  END IF;
  
  IF v_JustCustomData = 0 THEN
  	v_CustomData := f_FORM_appendProperty(Input => v_CustomData, ParamName => 'SUMMARY', ParamValue => v_Summary);
  	v_CustomData := f_FORM_appendNclobProperty(Input => v_CustomData, ParamName => 'DESCRIPTION', ParamValue => v_Description);
  	v_CustomData := f_FORM_appendProperty(Input => v_CustomData, ParamName => 'PRIORITY_ID', ParamValue => v_Priority_Id);
  	v_CustomData := f_FORM_appendProperty(Input => v_CustomData, ParamName => 'DRAFT', ParamValue => v_Draft);
  END IF;

  --FIND CASE TYPE AND GET ANY CUSTOM PROCESSORS
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
  
  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -UPDATE_CUSTOM_CASE_DATA- AND 
  --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--   
  v_result := f_DCM_processCommonEvent(
              Attributes      =>v_CEAttributes,
              code            => NULL, 
              caseid          => v_caseid, 
              casetypeid      => v_casetypeid, 
              commoneventtype => 'UPDATE_CUSTOM_CASE_DATA', 
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

  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -UPDATE_CUSTOM_CASE_DATA- AND 
  --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--   
  v_result := f_DCM_processCommonEvent(
              Attributes      =>v_CEAttributes,
              code            => NULL, 
              caseid          => v_caseid, 
              casetypeid      => v_casetypeid, 
              commoneventtype => 'UPDATE_CUSTOM_CASE_DATA', 
              errorcode       => v_errorcode, 
              errormessage    => v_errormessage, 
              eventmoment     => 'BEFORE', 
              eventtype       => 'ACTION', 
              HistoryMessage  =>v_historyMsg,
              procedureid     => NULL, 
              taskid          => NULL, 
              tasktypeid      => NULL, 
              validationresult => v_validationresult); 
              
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
  
  --SET XML TO CASE(CASEEXT) FOR CACHE PURPOSES
  BEGIN
    v_CustomDataXML := XMLTYPE(v_CustomData);  
    UPDATE TBL_CASEEXT
    SET col_CustomData = v_CustomDataXML,
        Col_Description   = v_Description
    WHERE col_caseextcase = v_caseid;
  EXCEPTION 
    WHEN OTHERS THEN 
    v_errorcode:= 101;
    v_errormessage := 'Update was unsuccessfull';
    GOTO cleanup;
  END;

  --CALL CUSTOM PROCESSOR IF ONE EXISTS
  BEGIN
    SELECT COL_UPDATECUSTDATAPROCESSOR INTO v_customdataprocessor
    FROM TBL_DICT_CASESYSTYPE
    WHERE col_id = v_casetypeid;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_customdataprocessor := NULL;
  END;

  --EXECUTE CUSTOM PROCESSORS IF NEEDED
  v_RecordIdExt := NULL;
  IF v_customdataprocessor IS NOT NULL THEN
    v_RecordIdExt := f_dcm_invokeCaseCusDataProc3(CaseId => v_CaseId, Input => v_CustomData, ProcessorName => v_customdataprocessor);  
  END IF;

  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -UPDATE_CASE_DATA- AND 
  --EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--  
  v_result := f_DCM_processCommonEvent(
              Attributes =>v_CEAttributes,
              code => NULL, 
              caseid => v_caseid, 
              casetypeid => v_casetypeid, 
              commoneventtype => 'UPDATE_CUSTOM_CASE_DATA', 
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
  RETURN 0;
  
  <<cleanup>>  
  :errorCode     := v_errorcode;
  :errorMessage  := v_errormessage;	
  RETURN -1;

END;