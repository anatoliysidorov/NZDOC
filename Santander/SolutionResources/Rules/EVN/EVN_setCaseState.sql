DECLARE
  v_taskIdFromAttribute INTEGER;
  v_taskid              INTEGER;
  v_caseid              INTEGER;
  
  v_case_state_activity NVARCHAR2(255);
  v_case_state_flag     NVARCHAR2(255);
  v_resolution_code     NVARCHAR2(255);
  v_resolution_id       INTEGER;

  v_result              NUMBER;
  v_TaskTemplateId      NUMBER;
  v_input               NCLOB;

  v_message           NCLOB;
  v_validationresult  NUMBER;

  --temp variables for returns 
  v_tempErrMsg       NCLOB; 
  v_tempErrCd       INTEGER;

  v_CustomData               NCLOB;
  v_casetypeid               INTEGER;
  v_routecustomdataprocessor NVARCHAR2(255);
 
BEGIN
  v_taskid := :TaskId;
  v_input  := :Input;
  v_CustomData := NULL;

  v_validationresult := 1;
  v_message          := '';
  v_case_state_flag := NULL;
  v_resolution_code := NULL;
  v_resolution_id   := NULL;
  v_TaskTemplateId  := NULL;
  
  v_taskIdFromAttribute := NULL;

  v_taskIdFromAttribute := f_FORM_getParamByName(v_input, 'TaskId');
  IF v_taskIdFromAttribute IS NOT NULL THEN
    v_taskid := v_taskIdFromAttribute;
  END IF;  

  --INSERT INTO TBL_LOG (col_data1, col_bigdata1) values(TO_CHAR(v_taskid), v_input);
      IF (v_taskid IS NULL) THEN  
    v_validationresult := 0;    
    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'TaskId can not be empty');
    GOTO cleanup;
  END IF;

  v_caseid := f_DCM_getCaseIdByTaskId(taskid => v_taskid);  

  IF v_caseid IS NULL THEN
    v_validationresult := 0;    
    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'CaseId can not be empty');
    GOTO cleanup; 
  END IF;

  BEGIN
    SELECT col_caseccdict_casesystype INTO v_casetypeid FROM TBL_CASECC WHERE col_id = v_caseid;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_casetypeid        := NULL; 
      v_validationresult  := 0;      
      v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'CaseTypeId can not be empty');
      GOTO cleanup;
  END;
     
  BEGIN 
    SELECT COL_ID2 INTO v_TaskTemplateId FROM TBL_TASKCC WHERE COL_ID=v_TaskId;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_TaskTemplateId    := NULL;  
      v_validationresult  := 0;
      v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'TaskTemplateId can not be empty');
      GOTO cleanup; 
  END;

  --get case state
  v_case_state_flag := f_FORM_getParamByName(v_input, 'CaseState');

  IF v_case_state_flag IS NULL THEN
    BEGIN 
      SELECT arp.col_paramvalue INTO v_case_state_flag 
      FROM TBL_AUTORULEPARAMTMPL arp
      INNER JOIN tbl_map_taskstateinittmpl tsi on arp.col_RuleParTp_TaskStateInitTp = tsi.col_id 
      WHERE tsi.col_MAP_TaskStInitTplTaskTpl=v_TaskTemplateId  AND
            arp.col_AutoRuleParamTpCaseType=v_casetypeid   AND
            UPPER(arp.col_paramcode)='CASESTATE';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_case_state_flag := NULL;
      WHEN TOO_MANY_ROWS THEN    
        v_case_state_flag := NULL;
    END;
  END IF;
 
  --get current case state
  IF v_case_state_flag ='DONTCHANGE' THEN
    BEGIN
      SELECT dts.col_code INTO v_case_state_flag
      FROM tbl_casecc c
      LEFT JOIN tbl_dict_casestate dts ON c.col_caseccdict_casestate = dts.col_id
      WHERE c.col_id=v_caseid;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_case_state_flag := NULL;
    END;
  END IF;
   
    --INSERT INTO TBL_LOG (col_data1) values('v_caseid='||TO_CHAR(v_caseid));
    --INSERT INTO TBL_LOG (col_data1) values('v_case_state_flag='||v_case_state_flag);

  IF v_case_state_flag IS NULL THEN
    v_validationresult := 0;    
    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'Case State Code can not be empty');
    GOTO cleanup; 
  END IF;

  --get case activity
  v_case_state_activity := f_DCM_getCaseStateActivity2(caseid => v_caseid, statecode => v_case_state_flag);

 --INSERT INTO TBL_LOG (col_data1) values('v_case_state_activity='||v_case_state_activity);

  IF v_case_state_activity IS NULL THEN
    v_validationresult := 0;    
    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'A target case Activity can not be defined');
    GOTO cleanup; 
  END IF;

  --get resolution code
  v_resolution_code := f_FORM_getParamByName(v_input, 'ResolutionCode');

  IF v_resolution_code IS NULL THEN
    BEGIN 
      SELECT arp.col_paramvalue INTO v_resolution_code 
      FROM TBL_AUTORULEPARAMTMPL arp
      INNER JOIN tbl_map_taskstateinittmpl tsi on arp.col_RuleParTp_TaskStateInitTp = tsi.col_id 
      WHERE tsi.col_MAP_TaskStInitTplTaskTpl=v_TaskTemplateId  AND
            arp.col_AutoRuleParamTpCaseType=v_casetypeid   AND
            UPPER(arp.col_paramcode)='RESOLUTIONCODE';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_resolution_code := NULL;
      WHEN TOO_MANY_ROWS THEN    
        v_resolution_code := NULL;
    END;
  END IF;

  IF v_resolution_code IS NULL THEN
    v_validationresult := 0;    
    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'Resolution Code can not be empty');
    GOTO cleanup; 
  END IF;


  IF v_resolution_code='DONTCHANGE' THEN
    SELECT col_stp_resolutioncodecasecc INTO v_resolution_id 
    FROM TBL_CASECC 
    WHERE col_id=v_caseid;
  ELSE
    v_resolution_id   := f_util_getidbycode(code => v_resolution_code, tablename => 'tbl_stp_resolutioncode');
  END IF;
  
  IF v_resolution_code='RESET' THEN
    v_resolution_id :=NULL;
  END IF;  
          
 
    --INSERT INTO TBL_LOG (col_data1) values('v_resolution_code='||v_resolution_code);    
    --INSERT INTO TBL_LOG (col_data1) values('v_resolution_id='||TO_CHAR(NVL(v_resolution_id,0)));



  v_result := f_DCM_caseRouteValidateCC(ErrorCode => v_validationresult, 
                                      ErrorMessage => v_message, 
                                      Target => v_case_state_activity, 
                                      CaseId => v_CaseId);
--INSERT INTO TBL_LOG (col_data1, col_bigdata1) values('f_DCM_caseRouteValidate= '||TO_CHAR(v_validationresult), v_message); 
  IF (v_validationresult IS NOT NULL) THEN
    v_validationresult := 0;    
    GOTO cleanup;
  END IF;


--INSERT INTO TBL_LOG (col_data1, col_bigdata1) values('before f_DCM_caseRouteManualFn v_tempErrCd '||TO_CHAR(v_tempErrCd), ''); 
   
  v_result := f_DCM_caseRouteManualCCFn(caseid       => v_caseid,
                                      errorcode    => v_tempErrCd,
                                      errormessage => v_tempErrMsg,
                                      resolutionid => v_resolution_id,
                                      target       => v_case_state_activity,
                                      workbasketid => NULL);

  --INSERT INTO TBL_LOG (col_data1, col_bigdata1) values('afetr f_DCM_caseRouteManualFn  '||TO_CHAR(v_validationresult), v_message); 
  --INSERT INTO TBL_LOG (col_data1, col_bigdata1) values('afetr f_DCM_caseRouteManualFn v_result '||TO_CHAR(v_result), ''); 
  --INSERT INTO TBL_LOG (col_data1, col_bigdata1) values('afetr f_DCM_caseRouteManualFn v_tempErrCd '||TO_CHAR(v_tempErrCd), ''); 
        

 --DETERMINE IF ROUTING WAS SUCCESSFUL
 IF (v_result = 0) AND (NVL(v_tempErrCd, 0) = 0) THEN
  ValidationResult := 1;
  Message := 'Success';
  v_message :='Success';
 ELSE
  GOTO cleanup;  
 END IF; 
  
  --CALL CUSTOM PROCESSOR IF ONE EXISTS
  begin 
    select col_routecustomdataprocessor
    into   v_routecustomdataprocessor
    from tbl_dict_casesystype
    where col_id = v_casetypeid;
    exception
    when NO_DATA_FOUND then
    v_routecustomdataprocessor := null;
  end;
  if v_CustomData is not null and v_routecustomdataprocessor is not null then
    v_result := f_dcm_invokeCaseCusDataProc(CaseId => v_CaseId, Input => v_CustomData, ProcessorName => v_routecustomdataprocessor);
  elsif v_CustomData is not null then
    --set custom data XML if no special processor passed
    update tbl_caseext
    set col_customdata = XMLTYPE(v_CustomData)
    where col_caseextcase = v_CaseId;
  end if;


  RETURN 0;
  
 --ERROR BLOCK
 <<cleanup>>  
 
 v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'WARNING: something went wrong');
 v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR CODE: ' || v_tempErrCd);
 v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR MESSAGE: ' || v_tempErrMsg);
 
 --INSERT INTO TBL_LOG (col_data1, col_bigdata1) values('ERROR BLOCK  ', v_message); 

 v_result := f_HIST_createHistoryFn(
  AdditionalInfo => v_message,  
  IsSystem=>0, 
  Message=> NULL,
  MessageCode => 'GenericEventFailure', 
  TargetID => v_caseid, 
  TargetType=>'CASE'
 );  
 
 :ValidationResult := 0;
 :Message := v_tempErrMsg;
 RETURN -1;

END;