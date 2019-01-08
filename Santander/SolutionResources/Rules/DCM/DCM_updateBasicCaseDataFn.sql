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
  v_ErrorMessage NCLOB;
  v_historyMsg          nclob;
  v_extractedvalue NCLOB;
  v_Attributes NCLOB;
  v_outData CLOB;
  
BEGIN

  v_historyMsg := NULL;
  v_outData      := NULL;

  --COMMON ATTRIBUTES
  v_CaseId        := :ID;
  v_Summary       := :SUMMARY;
  v_Description   := :DESCRIPTION;
  v_SubmittedCustomData    := :CUSTOMDATA;
  v_Priority_id    := :PRIORITY_ID;
  v_Draft    := :DRAFT;
  v_JustCustomData := NVL(:JustCustomData, 0);

  IF v_SubmittedCustomData IS NULL THEN
    v_SubmittedCustomData  := '<CustomData><Attributes></Attributes></CustomData>';
  END IF;

  v_PrevCustomData := f_DCM_getCaseCustomData(CaseId => v_CaseId);

  begin
    select extract(xmltype(v_SubmittedCustomData), '/CustomData/Attributes/Form').getClobVal() into v_extractedvalue from dual;
    exception
    when NO_DATA_FOUND then
    v_extractedvalue := null;
  end;

  --v_CustomData := f_FORM_mergeCustomData(Input => v_PrevCustomData, Input2 => v_SubmittedCustomData);
  if v_extractedvalue is not null then
    v_CustomData := f_FORM_mergeCustomData(Input => v_PrevCustomData, Input2 => v_SubmittedCustomData);
  else
    v_CustomData := v_SubmittedCustomData;
  end if;
 
  IF v_JustCustomData = 0 THEN
	v_CustomData := f_FORM_appendProperty(Input => v_CustomData, ParamName => 'SUMMARY', ParamValue => v_Summary);
	v_CustomData := f_FORM_appendNclobProperty(Input => v_CustomData, ParamName => 'DESCRIPTION', ParamValue => v_Description);
	v_CustomData := f_FORM_appendProperty(Input => v_CustomData, ParamName => 'PRIORITY_ID', ParamValue => v_Priority_Id);
	v_CustomData := f_FORM_appendProperty(Input => v_CustomData, ParamName => 'DRAFT', ParamValue => v_Draft);
  END IF;
  --FIND CASE TYPE AND GET ANY CUSTOM PROCESSORS
  BEGIN
    SELECT COL_CASEDICT_CASESYSTYPE
    INTO v_CaseTypeId
    FROM tbl_case
    WHERE col_id = v_CaseId;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_CaseTypeId := NULL;
  END;
      
  v_Attributes:='<PriorityId>'||TO_CHAR(v_priority_id)||'</PriorityId>'|| 
                '<Draft>'||TO_CHAR(v_draft)||'</Draft>'||
                '<JustCustomData>'||TO_CHAR(v_justcustomdata)||'</JustCustomData>'||
				  '<PreviousData>' || f_UTIL_extractXmlAsTextFn(INPUT => utl_i18n.unescape_reference(v_PrevCustomData), PATH=>'/CustomData/Attributes/*') ||'</PreviousData>'||
				  '<NewData>' || f_UTIL_extractXmlAsTextFn(INPUT => v_customdata, PATH=>'/CustomData/Attributes/*')  ||'</NewData>';
                  
  v_validationresult := 1;
  
  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -UPDATE_CASE_DATA- AND 
  --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--   
  v_result := f_DCM_processCommonEvent(
                                        InData           => NULL,
                                        OutData          => v_outData,   
                                        Attributes =>v_Attributes,
                                        code => NULL, 
                                        caseid => v_caseid, 
                                        casetypeid => v_casetypeid, 
                                        commoneventtype => 'UPDATE_CASE_DATA', 
                                        errorcode => v_errorcode, 
                                        errormessage => v_errormessage, 
                                        eventmoment => 'BEFORE', 
                                        eventtype => 'VALIDATION', 
                                        HistoryMessage =>v_historyMsg,
                                        procedureid => NULL, 
                                        taskid => NULL, 
                                        tasktypeid => NULL, 
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
  
  if nvl(v_validationresult,0) = 0 then GOTO cleanup; end if;
  
  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -UPDATE_CASE_DATA- AND 
  --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--   
  v_result := f_DCM_processCommonEvent(
                                        InData           => NULL,
                                        OutData          => v_outData,   
                                        Attributes =>v_Attributes,
                                        code => NULL, 
                                        caseid => v_caseid, 
                                        casetypeid => v_casetypeid, 
                                        commoneventtype => 'UPDATE_CASE_DATA', 
                                        errorcode => v_errorcode, 
                                        errormessage => v_errormessage, 
                                        eventmoment => 'BEFORE', 
                                        eventtype => 'ACTION', 
                                        HistoryMessage =>v_historyMsg,
                                        procedureid => NULL, 
                                        taskid => NULL, 
                                        tasktypeid => NULL, 
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
  v_CustomDataXML := XMLTYPE(v_CustomData);  
  UPDATE TBL_CASEEXT
  SET col_CustomData = v_CustomDataXML,
      Col_Description   = v_Description
  WHERE col_caseextcase = v_caseid;

  --CALL CUSTOM PROCESSOR IF ONE EXISTS
  BEGIN
    SELECT COL_UPDATECUSTDATAPROCESSOR INTO v_customdataprocessor
    FROM tbl_dict_casesystype
    WHERE col_id = v_casetypeid;
  EXCEPTION
  WHEN no_data_found THEN
    v_customdataprocessor := NULL;
  END;

  --EXECUTE CUSTOM PROCESSORS IF NEEDED
  v_RecordIdExt := NULL;
  IF v_customdataprocessor IS NOT NULL THEN
    v_RecordIdExt := f_dcm_invokeCaseCusDataProc3(CaseId => v_CaseId, Input => v_CustomData, ProcessorName => v_customdataprocessor);  
  END IF;

  --UPDATE OTHER CASE DATA IF NEEDED
  --IF v_JustCustomData = 0 THEN
  UPDATE tbl_case
  SET
    Col_Summary       = V_Summary,
    COL_STP_PRIORITYCASE = v_Priority_id,
    COL_DRAFT = v_Draft
  WHERE col_id = v_CaseId;
  --END IF;

  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -UPDATE_CASE_DATA- AND 
  --EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--  
  v_result := f_DCM_processCommonEvent(
                                        InData           => NULL,
                                        OutData          => v_outData,   
                                        Attributes =>v_Attributes,
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
  
   

   :SuccessResponse := 'Update was successfull';   
   :errorCode := v_errorcode;
   :errorMessage := v_errormessage;
   
   --RECORD CASE HISTORY
	v_result := F_hist_createhistoryfn(
			additionalinfo => null,
			issystem       => 0,
			MESSAGE        => null,
			messagecode    => 'CaseModified',
			targetid       => v_CaseId,
			targettype     => 'CASE'
	   );		   
   RETURN 0;
   
   <<cleanup>>   
   :SuccessResponse := '';   
   :errorCode := v_errorcode;
   :errorMessage := v_errormessage;
   
   --RECORD CASE HISTORY
   	v_result := F_hist_createhistoryfn(
			additionalinfo => errorMessage,
			issystem       => 0,
			MESSAGE        => null,
			messagecode    => 'GenericError',
			targetid       => v_CaseId,
			targettype     => 'CASE'
	   );
   RETURN -1;   
END;