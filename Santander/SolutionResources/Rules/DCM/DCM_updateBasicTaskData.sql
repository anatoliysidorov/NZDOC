DECLARE
    v_TaskId INTEGER;
    v_TaskTypeId INTEGER;
    v_Name NVARCHAR2(255);
    v_Description NCLOB;
    v_Result INTEGER;
    v_customdataprocessor NVARCHAR2(255);
    v_CustomData NCLOB;
    v_PrevCustomData NCLOB;
    v_SubmittedCustomData NCLOB;
    v_RecordIdExt INTEGER;
    v_CustomDataXML XMLTYPE;
    v_validationresult number;
    v_ErrorCode number;
    v_ErrorMessage NCLOB;
    v_CaseId NUMBER;
    v_historyMsg NCLOB;
    v_Attributes NVARCHAR2(4000);
    v_outData CLOB; 
    
BEGIN
    --COMMON ATTRIBUTES
    v_TaskId := :ID;
    V_name := :NAME;
    v_Description := :DESCRIPTION;
    v_SubmittedCustomData := :CUSTOMDATA;
    v_CaseId := NULL;
    v_historyMsg := NULL;
    v_outData      := NULL;
    
    IF v_CustomData IS NULL THEN
        v_CustomData := '<CustomData><Attributes></Attributes></CustomData>';
    END IF;
    v_PrevCustomData := f_DCM_getTaskCustomData(TaskId => v_TaskId);
    v_CustomData := f_FORM_mergeCustomData(Input => v_PrevCustomData,
                                           Input2 => v_SubmittedCustomData);
 
    --FIND TASK TYPE AND GET ANY CUSTOM PROCESSORS
    BEGIN
        SELECT COL_TASKDICT_TASKSYSTYPE
        INTO
               v_TaskTypeId
        FROM   tbl_task
        WHERE  col_id = v_TaskId;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_TaskTypeId := NULL;
    END;
    --FIND Case Id for processing common events
    BEGIN
        SELECT COL_CASETASK
        INTO
               v_CaseId
        FROM   tbl_task
        WHERE  col_id = v_TaskId;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_CaseId := NULL;
    END;
    
    v_validationresult := 1;
    v_historyMsg := NULL;
    
    v_Attributes := '<Name>'||TO_CHAR(V_name) ||'</Name>';
    
    --CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -UPDATE_TASK_DATA-
    --AND EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--
    v_result := f_DCM_processCommonEvent(InData           => NULL,
                                         OutData          => v_outData, 
                                         Attributes => v_Attributes,
                                         Code => NULL,
                                         CaseId => v_CaseId,
                                         CaseTypeId => null,
                                         CommonEventType => 'UPDATE_TASK_DATA',
                                         ErrorCode => v_ErrorCode,
                                         ErrorMessage => v_ErrorMessage,
                                         EventMoment => 'BEFORE',
                                         EventType => 'VALIDATION',
                                         HistoryMessage => v_historyMsg,
                                         ProcedureId => null,
                                         TaskId => v_TaskId,
                                         TaskTypeId => v_TaskTypeId,
                                         ValidationResult => v_validationresult);
/*
  --write to history
  IF v_historyMsg IS NOT NULL THEN
     v_result := f_HIST_createHistoryFn(
      AdditionalInfo => v_historyMsg,
      IsSystem=>0,
      Message=> 'Validation Common event(s)',
      MessageCode => 'CommonEvent',
      TargetID => v_TaskId,
      TargetType=>'TASK'
     );
  END IF;
 */
    if nvl(v_validationresult,0) = 0 then GOTO cleanup; end if;
    
    --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -UPDATE_TASK_DATA-
    --AND EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--
    v_result := f_DCM_processCommonEvent(InData           => NULL,
                                         OutData          => v_outData, 
                                         Attributes => v_Attributes,
                                         Code => NULL,
                                         CaseId => v_CaseId,
                                         CaseTypeId => null,
                                         CommonEventType => 'UPDATE_TASK_DATA',
                                         ErrorCode => v_ErrorCode,
                                         ErrorMessage => v_ErrorMessage,
                                         EventMoment => 'BEFORE',
                                         EventType => 'ACTION',
                                         HistoryMessage => v_historyMsg,
                                         ProcedureId => null,
                                         TaskId => v_TaskId,
                                         TaskTypeId => v_TaskTypeId,
                                         ValidationResult => v_validationresult);
  /*
  --write to history
  IF v_historyMsg IS NOT NULL THEN
     v_result := f_HIST_createHistoryFn(
      AdditionalInfo => v_historyMsg,
      IsSystem=>0,
      Message=> 'Action Common event(s)',
      MessageCode => 'CommonEvent',
      TargetID => v_TaskId,
      TargetType=>'TASK'
     );
  END IF;
*/

    BEGIN
        SELECT COL_UPDATECUSTDATAPROCESSOR
        INTO
               v_customdataprocessor
        FROM   tbl_dict_tasksystype
        WHERE  col_id = v_tasktypeid;
    
    EXCEPTION
    WHEN no_data_found THEN
        v_customdataprocessor := NULL;
    END;
    UPDATE tbl_task
    SET    Col_Description = v_Description,
           Col_name = V_name
    WHERE  col_id = v_taskid;
    
    --EXECUTE CUSTOM PROCESSORS IF NEEDED
    IF v_customdataprocessor IS NOT NULL THEN
        v_RecordIdExt := f_dcm_invokeTaskCusDataProc3(TaskId => v_TaskId,
                                                      Input => v_CustomData,
                                                      ProcessorName => v_customdataprocessor);
        v_CustomDataXML := XMLTYPE(v_CustomData); --set custom data even if it's been processed by the custom processor
    ELSE
        v_RecordIdExt := NULL;
        v_CustomDataXML := XMLTYPE(v_CustomData);
    END IF;
    --
    UPDATE tbl_task
    SET    Col_Description = v_Description,
           --Col_name             = V_name,
           col_CustomData = v_CustomDataXML
    WHERE  col_id = v_taskid;
    
    --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -UPDATE_TASK_DATA- AND
    --EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--
    v_result := f_DCM_processCommonEvent(InData           => NULL,
                                         OutData          => v_outData, 
                                         Attributes => v_Attributes,
                                         Code => NULL,
                                         CaseId => v_CaseId,
                                         CaseTypeId => null,
                                         CommonEventType => 'UPDATE_TASK_DATA',
                                         ErrorCode => v_ErrorCode,
                                         ErrorMessage => v_ErrorMessage,
                                         EventMoment => 'AFTER',
                                         EventType => 'ACTION',
                                         HistoryMessage => v_historyMsg,
                                         ProcedureId => null,
                                         TaskId => v_TaskId,
                                         TaskTypeId => v_TaskTypeId,
                                         ValidationResult => v_validationresult);
    --write to history
    v_result := f_HIST_createHistoryFn(AdditionalInfo => NULL,
                                       IsSystem => 0,
                                       Message => NULL,
                                       MessageCode => 'TaskModified',
                                       TargetID => v_TaskId,
                                       TargetType => 'TASK');
                                       

   v_errorcode := 0;
   v_errormessage := ''; 
                                         
   <<cleanup>>      
   :errorCode := v_errorcode;
   :errorMessage := v_errormessage;
   
   RETURN; 
END;