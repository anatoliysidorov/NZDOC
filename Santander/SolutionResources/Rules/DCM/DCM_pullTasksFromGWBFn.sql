DECLARE 
    v_workbasketid        INTEGER; 
    v_privateworkbasketid INTEGER; 
    v_result              NUMBER; 
    v_query               VARCHAR2(2000); 
    v_cur                 SYS_REFCURSOR; 
    v_id                  INTEGER; 
    v_caseworkerid        INTEGER; 
    v_numberofrecords     INTEGER; 
    v_rating              INTEGER; 
    v_taskactivity        NVARCHAR2(255); 
    v_rownumber           INTEGER; 
    v_taskid              INTEGER; 
    v_tasktypeid          INTEGER; 
    v_taskname            NVARCHAR2(255); 
    v_wiid                INTEGER; 
    v_processorcode       NVARCHAR2(255); 
    v_errorcode           NUMBER; 
    v_errormessage        NCLOB; 
    v_validationresult    NUMBER;
    v_CaseId              NUMBER;
    v_historyMsg          NCLOB;
    v_outData CLOB;
           
BEGIN 
    v_workbasketid := :WorkbasketId; 
    v_caseworkerid := :CaseworkerId; 
    v_numberofrecords := :NumberOfRecords;
    v_CaseId := NULL;
    v_outData      := NULL;
    
    IF ( v_processorcode IS NULL ) OR (v_processorcode = '') THEN 
      v_errorcode := 102; 
      v_errormessage := 'No processor for task extraction from group workbasket exists'; 
      :ErrorCode := v_errorcode; 
      :ErrorMessage := v_errormessage; 
      RETURN -1; 
    END IF; 

    BEGIN 
        SELECT wb.col_id 
        INTO   v_privateworkbasketid 
        FROM   tbl_ppl_workbasket wb 
               inner join tbl_dict_workbaskettype wbt 
                       ON wb.col_workbasketworkbaskettype = wbt.col_id 
        WHERE  wb.col_caseworkerworkbasket = v_caseworkerid 
               AND wb.col_isdefault = 1 
               AND wbt.col_code = 'PERSONAL'; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_errorcode := 103; 
          v_errormessage := 'Default personal workbasket not found'; 
          :ErrorCode := v_errorcode; 
          :ErrorMessage := v_errormessage; 

          RETURN -1; 
        WHEN too_many_rows THEN 
          v_errorcode := 104; 
          v_errormessage := 'More than one default personal workbasket found'; 
          :ErrorCode := v_errorcode; 
          :ErrorMessage := v_errormessage; 

          RETURN -1; 
    END;

    v_query := 
		'select Id, CaseworkerId, TaskActivity, RowNumber, TaskId, TaskName, WIId, Rating from table('
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
    FETCH v_cur INTO v_id, v_caseworkerid, v_taskactivity, v_rownumber, v_taskid , v_taskname, v_wiid, v_rating;
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
    v_result := f_DCM_processCommonEvent(
                InData           => NULL,
                OutData          => v_outData,     
                Attributes =>NULL,
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
      UPDATE tbl_task 
      SET    col_taskpreviousworkbasket = col_taskppl_workbasket, 
             col_taskppl_workbasket = v_privateworkbasketid 
      WHERE  col_id = v_taskid; 

      --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE 
      --PULL_TASK_FROM_GROUP_WORKBASKET- AND 
      --EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--
      v_result := f_DCM_processCommonEvent(
                InData           => NULL,
                OutData          => v_outData,           
                 Attributes =>NULL,Code=>NULL, 
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