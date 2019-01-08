DECLARE 
    v_workbasketid        INTEGER; 
    v_cwWB 			      INTEGER; 
    v_result              NUMBER; 
    v_query               VARCHAR2(2000); 
    v_cur                 SYS_REFCURSOR; 
    v_caseworkerid        INTEGER; 
    v_numberofrecords     INTEGER; 
    v_rownumber           INTEGER; 
    v_taskid              INTEGER; 
    v_tasktypeid              INTEGER; 
    v_processorcode       NVARCHAR2(255); 
    v_errorcode           NUMBER; 
    v_errormessage        NCLOB; 
    v_SuccessResponse      NVARCHAR2(255); 
    v_validationresult    NUMBER; 
    v_CaseId              NUMBER;
    v_historyMsg          NCLOB;
    v_outData CLOB;
    v_Attributes       NVARCHAR2(4000);
    
BEGIN 
    v_workbasketid := :WorkbasketId; 
    v_caseworkerid := :CaseworkerId; 
    v_cwWB := f_PPL_getPrimaryWB(UnitId => v_caseworkerid, UnitType=>'CASEWORKER');
    v_numberofrecords := NVL(:NumberOfRecords, 0); 
    
    v_CaseId := NULL;
    v_outData      := NULL;
    

    IF ( v_processorcode IS NULL ) OR (v_processorcode = '') THEN 
      v_processorcode := 'f_DCM_getTasksByRating';
    END IF; 
	
	IF (NVL(v_cwWB, 0) = 0) THEN 
      v_errorcode := 106; 
      v_errormessage := 'There is no case worker or the case worker does not have a work basket'; 
      :ErrorCode := v_errorcode; 
      :ErrorMessage := v_errormessage; 
      RETURN -1; 
    END IF;
    
     v_Attributes:='<WorkbasketId>'||TO_CHAR(v_workbasketid)||'</WorkbasketId>'||                  
                   '<CaseworkerId>'||TO_CHAR(v_caseworkerid)||'</CaseworkerId>'||
                   '<PrimaryWB>'||TO_CHAR(v_cwWB)||'</PrimaryWB>'||
                   '<NumberOfRecords>'||TO_CHAR(v_numberofrecords)||'</NumberOfRecords>';    

    v_query := 
		'select ID from table('
		|| v_processorcode 
		|| '(Caseworkerid=>' 
		|| v_caseworkerid 
		|| ',WorkbasketId=>' 
		|| v_workbasketid 
		|| ',NumberOfRecords=>' 
		|| v_numberofrecords 
		|| '))'; 

OPEN v_cur FOR v_query; 

LOOP 
    FETCH v_cur INTO v_taskid;
	  EXIT WHEN v_cur%NOTFOUND; 

    BEGIN 
        SELECT col_taskdict_tasksystype 
        INTO   v_tasktypeid 
        FROM   tbl_task 
        WHERE  col_id = v_taskid; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_errorcode := 105; 
          v_errormessage := 'Task ' || To_char(v_taskid) || ' not found'; 
          :ErrorCode := v_errorcode; 
          :ErrorMessage := v_errormessage; 
          exit; 
    END;

    --FIND Case Id for processing common events
    BEGIN
      SELECT COL_CASETASK
      INTO v_CaseId
      FROM tbl_task
      WHERE col_id = v_TaskId;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_CaseId := NULL;
    END;    
              
    v_validationresult := 1; 
    v_historyMsg :=NULL;

    --CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE 
    --PULL_TASK_FROM_GROUP_WORKBASKET- AND 
    --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM-- 
    v_result := f_DCM_processCommonEvent(InData           => NULL,
                                         OutData          => v_outData, 
                                        Attributes =>v_Attributes,
                                        code => NULL, 
                                        caseid => v_caseid, 
                                        casetypeid => NULL, 
                                        commoneventtype => 'PULL_TASK_FROM_GROUP_WORKBASKET', 
                                        errorcode => v_errorcode, 
                                        errormessage => v_errormessage, 
                                        eventmoment => 'BEFORE', 
                                        eventtype => 'VALIDATION', 
                                        HistoryMessage =>v_historyMsg,
                                        procedureid => NULL, 
                                        taskid => v_TaskId, 
                                        tasktypeid => v_tasktypeid, 
                                        validationresult => v_validationresult); 
                
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

    IF Nvl(v_validationresult, 0) = 0 THEN 
      :ErrorCode := v_errorcode; 
      :ErrorMessage := v_errormessage; 
      exit; 
    END IF; 
    
    IF v_validationresult = 1 THEN 
      --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE 
      --PULL_TASK_FROM_GROUP_WORKBASKET- AND 
      --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM-- 
      v_result := f_DCM_processCommonEvent(InData           => NULL,
                                           OutData          => v_outData, 
                                          Attributes =>v_Attributes,
                                          code => NULL, 
                                          caseid => v_caseid, 
                                          casetypeid => NULL, 
                                          commoneventtype => 'PULL_TASK_FROM_GROUP_WORKBASKET', 
                                          errorcode => v_errorcode, 
                                          errormessage => v_errormessage, 
                                          eventmoment => 'BEFORE', 
                                          eventtype => 'ACTION', 
                                          HistoryMessage =>v_historyMsg,
                                          procedureid => NULL, 
                                          taskid => v_TaskId, 
                                          tasktypeid => v_tasktypeid, 
                                          validationresult => v_validationresult); 
                  
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


      v_result := F_DCM_assignTaskFn(
        Action => 'ASSIGN', 
        CaseParty_Id => NULL,
        errorCode => v_errorCode, 
        errorMessage => v_errorMessage, 
        Note => NULL, 
        SuccessResponse => v_SuccessResponse, 
        Task_Id => v_taskid, 
        WorkBasket_Id => v_cwWB
        );

      --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE 
      --PULL_TASK_FROM_GROUP_WORKBASKET- AND 
      --EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--
      v_result := f_DCM_processCommonEvent(InData   => NULL,
                                           OutData  => v_outData, 
                                           Attributes =>v_Attributes, 
                                           Code=>NULL, 
                                           CaseId => v_CaseId, 
                                           CaseTypeId => null, 
                                           CommonEventType => 'PULL_TASK_FROM_GROUP_WORKBASKET', 
                                           ErrorCode => v_ErrorCode, 
                                           ErrorMessage => v_ErrorMessage, EventMoment => 'AFTER', 
                                           EventType => 'ACTION',
                                           HistoryMessage =>v_historyMsg,
                                           ProcedureId => null, TaskId => v_TaskId, 
                                           TaskTypeId => v_TaskTypeId, 
                                           ValidationResult => v_validationresult);

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
      
    END IF; 
END LOOP; 

CLOSE v_cur; 
END; 