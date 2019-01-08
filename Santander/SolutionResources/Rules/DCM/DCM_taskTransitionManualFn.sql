DECLARE 
  v_taskid        INTEGER;
  v_caseid        INTEGER;
  v_target        NVARCHAR2(255) ;
  v_result        NUMBER;
  v_resolutionid  INTEGER;
  v_workbasketid  INTEGER;
  v_CustomData    NCLOB;
  v_routecustomdataprocessor NVARCHAR2(255) ;
  v_taskTypeId    INTEGER;
  v_errorcode     NUMBER;
  v_errormessage  NCLOB;
  v_IsValid       INTEGER;
  v_historymsg    NCLOB;
  v_Attributes NVARCHAR2(4000);
  v_outData CLOB;

BEGIN
  v_taskid := :TaskId;
  v_target := :Target;
  v_resolutionid := :ResolutionId;
  v_workbasketid := :WorkbasketId;
  v_CustomData := CUSTOMDATA;
  v_outData      := NULL;
  
  v_taskTypeId :=NULL; 

  BEGIN
    SELECT COL_CASETASK, COL_TASKDICT_TASKSYSTYPE
    INTO   v_caseid, v_taskTypeId
    FROM   TBL_TASK
    WHERE  COL_ID = v_taskid;  
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_taskTypeId :=NULL;
    v_ErrorCode := 101;
    v_ErrorMessage := 'Case for task ' || TO_CHAR(v_taskid) || ' not found';
    GOTO cleanup;
  END;
  
  v_Attributes :='<SourceTaskId>' || TO_CHAR(v_taskid) || '</SourceTaskId>'||
                 '<TargetActivity>' || TO_CHAR(v_target) || '</TargetActivity>'||
                 '<ResolutionId>' || TO_CHAR(v_resolutionid) || '</ResolutionId>'||
                 '<WorkbasketId>' || TO_CHAR(v_workbasketid) || '</WorkbasketId>';

  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -TASK_ROUTE- AND*/
  /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
  v_IsValid := 1;

  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData, 
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'TASK_ROUTE',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
                                       eventtype        => 'VALIDATION',
                                       historymessage   => v_historymsg,
                                       procedureid      => NULL,
                                       taskid           => v_taskid,
                                       tasktypeid       => v_taskTypeId,
                                       validationresult => v_IsValid);

  /*--write to history*/
  IF v_historymsg IS NOT NULL THEN
    v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                       issystem       => 0,
                                       MESSAGE        => 'Validation Common event(s)',
                                       messagecode    => 'CommonEvent',
                                       targetid       => v_taskid,
                                       targettype     => 'TASK');
  END IF;

  IF NVL(v_IsValid, 0) = 0 THEN
    v_errorCode := v_errorCode;
    v_errorMessage := v_errorMessage;
    GOTO cleanup;
  END IF; 
  
  
  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -TASK_ROUTE- AND*/
  /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
  v_IsValid := 1;

  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'TASK_ROUTE',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
                                       eventtype        => 'ACTION',
                                       historymessage   => v_historymsg,
                                       procedureid      => NULL,
                                       taskid           => v_taskid,
                                       tasktypeid       => v_taskTypeId,
                                       validationresult => v_IsValid);

  /*--write to history*/
  IF v_historymsg IS NOT NULL THEN
    v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                       issystem       => 0,
                                       MESSAGE        => 'Action Common event(s)',
                                       messagecode    => 'CommonEvent',
                                       targetid       => v_taskid,
                                       targettype     => 'TASK');
  END IF;  

  v_result := f_DCM_copyCaseToCache(CaseId => v_CaseId) ;
  v_result := f_DCM_taskCCRouteValidate(errorcode => v_errorcode,
                                        errormessage => v_errormessage,
                                        target => v_target,
                                        taskid => v_taskid) ;
  
  IF v_errorcode IS NOT NULL THEN
    v_result := f_DCM_clearCache(CaseId => v_CaseId) ;
    GOTO cleanup;
  END IF;
    
  v_result := f_DCM_taskCCRouteManualFn(errorcode => v_errorcode,
                                        errormessage => v_errormessage,
                                        resolutionid => v_resolutionid,
                                        target => v_target,
                                        taskid => v_taskid,
                                        workbasketid => v_workbasketid) ;
  --CALL CUSTOM PROCESSOR IF ONE EXISTS
  BEGIN
    SELECT col_routecustomdataprocessor
    INTO   v_routecustomdataprocessor
    FROM   tbl_dict_tasksystype
    WHERE  col_id = v_tasktypeid;  
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_routecustomdataprocessor := NULL;
  END;
  IF v_CustomData IS NOT NULL AND v_routecustomdataprocessor IS NOT NULL THEN
    v_result := f_dcm_invokeTaskCusDataProc(Input => v_CustomData,
                                            ProcessorName => v_routecustomdataprocessor,
                                            TaskId => v_TaskId) ;
  ELSIF v_CustomData IS NOT NULL THEN
    --set custom data XML if no special processor passed
    UPDATE
           tbl_taskcc
    SET    col_customdata = XMLTYPE(v_CustomData)
    WHERE  col_id = v_TaskId;  
  END IF;

  v_result := f_DCM_updateCaseFromCache(CaseId => v_CaseId) ;
  v_result := f_DCM_clearCache(CaseId => v_CaseId) ;

  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -TASK_ROUTE- AND*/
  /*--EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/  
  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'TASK_ROUTE',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'AFTER',
                                       eventtype        => 'ACTION',
                                       historymessage   => v_historymsg,
                                       procedureid      => NULL,
                                       taskid           => v_taskid,
                                       tasktypeid       => v_taskTypeId,
                                       validationresult => v_IsValid);

  /*--write to history*/
  IF v_historymsg IS NOT NULL THEN
    v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                       issystem       => 0,
                                       MESSAGE        => 'Action Common event(s)',
                                       messagecode    => 'CommonEvent',
                                       targetid       => v_taskid,
                                       targettype     => 'TASK');
  END IF;

  IF NVL(v_IsValid, 0) = 0 THEN
    v_errorCode := v_errorCode;
    v_errorMessage := v_errorMessage;
    GOTO cleanup;
  END IF;

  :ErrorCode := NULL;
  :ErrorMessage := NULL;
  RETURN 0;

  <<cleanup>>
  :ErrorCode := v_errorcode;
  :ErrorMessage := v_errormessage;
  RETURN -1;
END;