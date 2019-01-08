declare
  v_InputXML nclob; 
  v_ParentCode NVARCHAR2(255); 
  v_ParentId NVARCHAR2(255); 
  v_CaseTypeId Integer;
  v_caseid Integer;
  v_taskid Integer;
  v_summary nvarchar2(255);
  v_description nvarchar2(32767);
  v_priorityid Integer;
  v_draft number;
  v_ConfigId Integer;
  v_OutputXML nclob;
  v_foundError number;
  v_ErrorCode Number;
  v_ErrorMessage nclob;
  v_RuleLog nclob;
  v_AddInfo nclob;
  v_AddInfoTmpl nclob;
  v_MsgTmpl nclob;
  v_result number;
  v_SuccessResponce nclob;
  v_CreateConfigCode nvarchar2(255);
  v_CreateConfigId Integer;
  v_CreateConfigName nvarchar2(255);
  v_CreateModelId Integer;
  v_EditConfigCode nvarchar2(255);
  v_EditConfigId Integer;
  v_EditConfigName nvarchar2(255);
  v_EditModelId Integer;
  v_RootObjectId Integer;
  v_RootObjectName nvarchar2(255);
  v_session nvarchar2(255);
  v_HistoryMsgCode nvarchar2(255);
  
  v_outData CLOB;
  v_Attributes      NVARCHAR2(4000);
  v_historyMsg      NCLOB;
  v_validationresult NUMBER;
  
begin
  v_InputXML := :InputXML;
  --calculated fields
  v_CaseTypeId := null;
  v_caseId := null;
  v_summary := null;
  v_priorityId := null;
  v_description := null;            
  v_draft := null;
  v_ConfigId := null;
  v_OutputXML := 'TEMP';
  v_RootObjectId := :RootObjectId;
  v_RootObjectName := nvl(:RootObjectCode, 'CASE');
  v_foundError := 0;
  v_RuleLog := '=====RULE: MDM_UpdateCaseWithData=====' || CHR(10);
  v_outData :=NULL;
  
  --==PARAMETER PRE-CHECK==
  if (v_InputXML is null) then
    v_foundError := 1;
    v_ErrorMessage := 'ERROR: The InputXML is missing and can''t continue';
    v_RuleLog := v_RuleLog || v_ErrorMessage || CHR(10);
    GOTO validation;
  end if;
  
  if instr(v_InputXML, '<SUMMARY><![CDATA[') = 0 then
    v_InputXML := regexp_replace(v_InputXML, '<SUMMARY>(.+)</SUMMARY>', '<SUMMARY><![CDATA[\1]]></SUMMARY>');
  end if;
  
  if instr(v_InputXML, '<DESCRIPTION><![CDATA[') = 0 then
    v_InputXML := regexp_replace(v_InputXML, '<DESCRIPTION>(.+)</DESCRIPTION>', '<DESCRIPTION><![CDATA[\1]]></DESCRIPTION>');
  end if;
  
  --v_summary := f_UTIL_extract_value_xml(Input => xmltype(v_inputXML), Path => '//CustomData/Attributes/Object[@ObjectCode="CASE"]/Item/SUMMARY/text()');
  select SUMMARY into v_summary from xmltable('/CustomData/Attributes/Object/Item[OBJECTCODE="CASE"]' PASSING xmltype(v_InputXML) COLUMNS SUMMARY NCLOB PATH 'SUMMARY');
  v_priorityid := f_UTIL_extract_value_xml(Input => xmltype(v_inputXML), Path => '//CustomData/Attributes/Object[@ObjectCode="CASE"]/Item/PRIORITY_ID/text()');
  
  --v_description := f_UTIL_extract_value_xml(Input => xmltype(v_inputXML), Path => '//CustomData/Attributes/Object[@ObjectCode="CASE"]/Item/DESCRIPTION/text()');
  select DESCRIPTION into v_description from xmltable('/CustomData/Attributes/Object/Item[OBJECTCODE="CASE"]' PASSING xmltype(v_InputXML) COLUMNS DESCRIPTION NCLOB PATH 'DESCRIPTION');
  v_caseid := f_UTIL_extract_value_xml(Input => xmltype(v_inputXML), Path => '//CustomData/Attributes/Object[@ObjectCode="CASE"]/Item/ID/text()');
  v_draft := f_UTIL_extract_value_xml(Input => xmltype(v_inputXML), Path => '//CustomData/Attributes/Object[@ObjectCode="CASE"]/Item/DRAFT/text()');
  
  if (v_caseid is null) then
    v_foundError := 1;
    v_ErrorMessage := 'ERROR: The Input XML is missing the Case';
    v_RuleLog := v_RuleLog || v_ErrorMessage || CHR(10);
    GOTO validation;
  end if;
  
  /*if (v_summary is null) then
    v_foundError := 1;
    v_ErrorMessage := 'ERROR: The Input XML is missing the SUMMARY';
    v_RuleLog := v_RuleLog || v_ErrorMessage || CHR(10);
    GOTO validation;
  end if;
  
  if (v_priorityid is null) then
    v_foundError := 1;
    v_ErrorMessage := 'ERROR: The Input XML is missing the PRIORITY_ID';
    v_RuleLog := v_RuleLog || v_ErrorMessage || CHR(10);
    GOTO validation;
  end if;*/
  
  BEGIN
    SELECT COL_CASEDICT_CASESYSTYPE INTO v_CaseTypeId 
    FROM TBL_CASE WHERE COL_ID=v_caseid;
  EXCEPTION WHEN OTHERS THEN v_CaseTypeId :=NULL;    
  END;
  
  v_Attributes:='<Priorityid>'||TO_CHAR(v_priorityid)||'</Priorityid>'||
                '<Draft>'||TO_CHAR(v_draft)||'</Draft>'||
                '<RootObjectId>'||TO_CHAR(v_RootObjectId)||'</RootObjectId>'; 
  
  
  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -UPDATE_CASE_MDM- AND*/
  /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/  
    v_result := F_dcm_processcommonevent(InData           =>v_InputXML,
                                         OutData          =>v_outData,
                                         Attributes       => v_Attributes,
                                         code             => NULL,
                                         caseid           => v_caseid,
                                         casetypeid       => v_CaseTypeId,
                                         commoneventtype  => 'UPDATE_CASE_MDM',
                                         errorcode        => v_errorcode,
                                         errormessage     => v_errormessage,
                                         eventmoment      => 'BEFORE',
                                         eventtype        => 'VALIDATION',
                                         historymessage   => v_historymsg,
                                         procedureid      => NULL,
                                         taskid           => NULL,
                                         tasktypeid       => NULL,
                                         validationresult => v_validationresult);
    /*--write to history*/
    IF v_historymsg IS NOT NULL THEN
      v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                         issystem       => 0,
                                         MESSAGE        => 'Validation Common event(s)',
                                         messagecode    => 'CommonEvent',
                                         targetid       => v_caseid,
                                         targettype     => 'CASE');
    END IF; 
    
  if NVL(v_validationresult,0)<>1 then
    v_foundError := 1;
    v_RuleLog := v_RuleLog || v_ErrorMessage || CHR(10);
    GOTO validation;
  end if;    
  

  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -UPDATE_CASE_MDM- AND*/
  /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/  
    v_result := F_dcm_processcommonevent(InData           =>v_InputXML,
                                         OutData          =>v_outData,
                                         Attributes       => v_Attributes,
                                         code             => NULL,
                                         caseid           => v_caseid,
                                         casetypeid       => v_CaseTypeId,
                                         commoneventtype  => 'UPDATE_CASE_MDM',
                                         errorcode        => v_errorcode,
                                         errormessage     => v_errormessage,
                                         eventmoment      => 'BEFORE',
                                         eventtype        => 'ACTION',
                                         historymessage   => v_historymsg,
                                         procedureid      => NULL,
                                         taskid           => NULL,
                                         tasktypeid       => NULL,
                                         validationresult => v_validationresult);
    /*--write to history*/
    IF v_historymsg IS NOT NULL THEN
      v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                         issystem       => 0,
                                         MESSAGE        => 'Action Common event(s)',
                                         messagecode    => 'CommonEvent',
                                         targetid       => v_caseid,
                                         targettype     => 'CASE');
    END IF; 
 
  v_result := f_DCM_updateBasicCaseDataFn(CUSTOMDATA => v_InputXML, DESCRIPTION => v_description, DRAFT => v_draft, errorCode => v_ErrorCode, errorMessage => v_ErrorMessage,
                                          ID => v_caseid, justCustomData => 1, PRIORITY_ID => v_priorityId, SuccessResponse => v_SuccessResponce, SUMMARY => v_summary);

  if (v_ErrorCode != 0) then
    v_foundError := 1;
    v_ErrorMessage := 'ERROR: There was an error executing rule f_DCM_updateBasicCaseDataFn exiting with code ' || v_ErrorCode || ' => ' || v_ErrorMessage;
    v_RuleLog := v_RuleLog || v_ErrorMessage || CHR(10);
    GOTO validation;
  else
    v_RuleLog := v_RuleLog || 'INFO: ' || v_SuccessResponce || CHR(10);
  end if;    
  
  v_result := f_MDM_getCaseOrCTinfoFn(calc_CaseId => v_caseid, 
                                      calc_CaseTypeId => v_CaseTypeId, 
                                      calc_TaskId => v_taskid, 
                                      CaseID => v_caseid, 
                                      CaseTypeID => v_CaseTypeId,
                                      create_ConfigCode => v_CreateConfigCode, 
                                      create_ConfigId => v_CreateConfigId, 
                                      create_ConfigName => v_CreateConfigName, 
                                      create_ModelId => v_CreateModelId,
                                      edit_ConfigCode => v_EditConfigCode, 
                                      edit_ConfigId => v_EditConfigId, 
                                      edit_ConfigName => v_EditConfigName, 
                                      edit_ModelId => v_EditModelId,
                                      TaskId => null);

  if (v_CaseTypeId > 0) then
    v_RuleLog := v_RuleLog || 'INFO: Found Case Type = ' || v_CaseTypeId || CHR(10);
  /*else
    v_foundError = 1;
    v_ErrorMessage = 'ERROR Missing Case Type';
    v_RuleLog = v_RuleLog || v_ErrorMessage || CHR(10);*/
  end if;
  
  if (v_CreateConfigId > 0) then
    v_RuleLog := v_RuleLog || 'INFO: Found EDIT Config = ' || v_CreateConfigId || CHR(10);
  /*else
    v_foundError = 1;
    v_ErrorMessage = 'ERROR Missing EDIT Config';
    v_RuleLog = v_RuleLog || v_ErrorMessage || CHR(10);*/
  end if;
  
  v_ConfigId := v_EditConfigId;

  if (v_CaseTypeId > 0) and (v_CreateConfigId > 0) then
    v_result := f_DOM_populateDynUpdCache(ConfigId => v_ConfigId, Input => v_inputXML, RootObjectId => v_RootObjectId, RootObjectName => v_RootObjectName, Session => v_session);
    v_result := f_DOM_executeDynUpd(ConfigId => v_ConfigId, Session => v_session);
  end if;
  
  v_Attributes := v_Attributes ||
                  '<CreateConfigId>'||TO_CHAR(v_CreateConfigId)||'</CreateConfigId>'||
                  '<EditConfigId>'||TO_CHAR(v_EditConfigId)||'</EditConfigId>'||
                  '<CreateConfigCode>'||TO_CHAR(v_CreateConfigCode)||'</CreateConfigCode>'||
                  '<CreateConfigName>'||TO_CHAR(v_CreateConfigName)||'</CreateConfigName>'||
                  '<CreateModelId>'||TO_CHAR(v_CreateModelId)||'</CreateModelId>'||
                  '<EditConfigCode>'||TO_CHAR(v_EditConfigCode)||'</EditConfigCode>'||
                  '<EditConfigName>'||TO_CHAR(v_EditConfigName)||'</EditConfigName>'||
                  '<EditModelId>'||TO_CHAR(v_EditModelId)||'</EditModelId>';
  
  
  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -UPDATE_CASE_MDM- AND*/
  /*--EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/  
    v_result := F_dcm_processcommonevent(InData           =>v_InputXML,
                                         OutData          =>v_outData,
                                         Attributes       => v_Attributes,
                                         code             => NULL,
                                         caseid           => v_caseid,
                                         casetypeid       => v_CaseTypeId,
                                         commoneventtype  => 'UPDATE_CASE_MDM',
                                         errorcode        => v_errorcode,
                                         errormessage     => v_errormessage,
                                         eventmoment      => 'AFTER',
                                         eventtype        => 'ACTION',
                                         historymessage   => v_historymsg,
                                         procedureid      => NULL,
                                         taskid           => NULL,
                                         tasktypeid       => NULL,
                                         validationresult => v_validationresult);
    /*--write to history*/
    IF v_historymsg IS NOT NULL THEN
      v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                         issystem       => 0,
                                         MESSAGE        => 'Action Common event(s)',
                                         messagecode    => 'CommonEvent',
                                         targetid       => v_caseid,
                                         targettype     => 'CASE');
    END IF;   
  

<<validation>>
  v_AddInfoTmpl := '{[this.YELLOW_TABLE(''#one#'',''#two#'')]}' ;
  v_AddInfo := REPLACE(v_AddInfoTmpl, '#one#', v_InputXML);
  v_AddInfo := REPLACE(v_AddInfo, '#two#', v_OutputXML) || CHR(10);
  
  if (v_foundError = 1) then
    v_RuleLog := v_RuleLog || '--INPUT XML--' || CHR(10);
    :ERRORCODE := 101;
    :ERRORMESSAGE := v_RuleLog;
    :SUCCESSRESPONSE := '';
    v_AddInfo := v_AddInfo || '<p><b>ErrorCode:</b> 101</p>' || CHR(10);
    v_AddInfo := v_AddInfo || v_RuleLog || CHR(10);
    v_HistoryMsgCode := 'GenericError';
  else
    :ERRORCODE := 0;
    :ERRORMESSAGE := '';
    :SUCCESSRESPONSE := v_SuccessResponce;
    v_HistoryMsgCode := 'CaseModified';
  end if;

  v_result := f_HIST_createHistoryFn(AdditionalInfo => v_AddInfo, MessageCode => v_HistoryMsgCode, TargetType => 'CASE', TargetID => v_caseId, IsSystem => 0, Message => '');
  
end;