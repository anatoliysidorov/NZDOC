DECLARE
 v_ErrorCode        NUMBER;
 v_ErrorMessage     NVARCHAR2(255);
 v_CaseID           NUMBER;
 v_ProcedureId      NUMBER;
 v_col_owner        NVARCHAR2(255);
 v_col_taskid       NVARCHAR2(255);
 v_Result           NUMBER;
 v_col_createdby    NVARCHAR2(255);
 v_col_createddate  DATE;
 v_col_modifiedby   NVARCHAR2(255);
 v_col_modifieddate DATE;
 v_Recordid         INTEGER;
 v_prefix           NVARCHAR2(255);
 v_validationresult NUMBER;
 v_historyMsg       NCLOB;
 v_TaskId           NUMBER;
 v_Attributes       NVARCHAR2(4000);
 v_CSisInCache      INTEGER; 
 v_taskTitle        NVARCHAR2(255);
 v_taskTypeProcessorCode NVARCHAR2(255);
 v_outData CLOB;
 
  BEGIN

 --OUT 
 :affectedRows := 0;
 :recordId := 0;
 

 --IN 
 v_CaseId         := :CaseId;
 v_ProcedureId    := :ProcedureId;
 v_col_owner      := :owner;
 v_col_createdby  := :TOKEN_USERACCESSSUBJECT;
 v_prefix         := NVL(:Prefix, 'TASK');

 --INIT
 v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache

 v_col_createddate := sysdate;
 v_col_modifiedby := v_col_createdby;
 v_col_modifieddate := v_col_createddate;
 
 v_validationresult:=1;
 v_historyMsg :=NULL;
 v_TaskId:=NULL; 
  
  --case not in new cache
  IF v_CSisInCache=0 THEN	 
    DELETE FROM tbl_task WHERE  col_casetask = v_caseid;
  END IF;

  --case in new cache
  IF v_CSisInCache=1 THEN	 
    DELETE FROM TBL_CSTASK WHERE COL_CASETASK = v_caseid;
  END IF;

  --main iteration 
 FOR rec IN 
 (SELECT tt.COL_ID, tt.COL_TYPE, tt.COL_PARENTTTID, tt.COL_DESCRIPTION, tt.COL_NAME, tt.COL_TASKID, tt.COL_DEPTH, 
         tt.COL_ICONCLS, tt.COL_ICON, tt.COL_LEAF, tt.COL_TASKORDER, tt.COL_REQUIRED, tt.COL_TASKTMPLDICT_TASKSYSTYPE,
         tt.COL_PROCESSORCODE, tt.COL_EXECMETHODTASKTEMPLATE, tt.COL_PAGECODE,
         tst.COL_PROCESSORCODE AS TST_PROCESSORCODE, tt.COL_ISHIDDEN AS ISHIDDENTASK
  FROM   TBL_TASKTEMPLATE tt
  LEFT OUTER JOIN TBL_DICT_TASKSYSTYPE  tst ON tt.COL_TASKTMPLDICT_TASKSYSTYPE=tst.COL_ID
  WHERE  tt.COL_PROCEDURETASKTEMPLATE = v_procedureid 
  ORDER  BY tt.COL_DEPTH, tt.COL_PARENTTTID, tt.COL_TASKORDER, tt.COL_ID)

  LOOP

    --GET NEW ID
    SELECT gen_tbl_Task.nextval INTO v_TaskId FROM dual;

    --GET TASk TITLE BY DEFAULT
    IF rec.TST_PROCESSORCODE IS NOT NULL THEN
      v_taskTitle := f_dcm_invokeTaskIdGenProc(ProcessorName => rec.TST_PROCESSORCODE, TaskId => v_taskid);
    ELSE
      v_taskTitle := v_prefix || '-' || TO_CHAR(v_TaskId);
    END IF;

   --TASK IS NOT A ROOT 
   IF NVL(rec.COL_PARENTTTID, 0)<>0 AND  UPPER(NVL(rec.COL_TASKID, ' ')) <>'ROOT' AND 
      rec.COL_TASKTMPLDICT_TASKSYSTYPE IS NOT NULL THEN

     v_Attributes:='<ProcedureId>'||TO_CHAR(v_ProcedureId)||'</ProcedureId>'||                  
                   '<Owner>'||TO_CHAR(v_col_owner)||'</Owner>'||
                   '<Prefix>'||TO_CHAR(v_prefix)||'</Prefix>'||
                   '<StrTaskId>'||TO_CHAR(rec.COL_TASKID)||'</StrTaskId>';

     --COPY RECORDS FROM DESIGNTIME BO INTO RUNTIME BO
     v_result :=f_DCM_copyCommonEvents(CASEID       =>v_CaseId, 
                                       CASETYPEID   =>NULL, 
                                       CODE         =>NULL,  
                                       PROCEDUREID  =>NULL, 
                                       TASKTYPEID   =>rec.COL_TASKTMPLDICT_TASKSYSTYPE, 
                                       TASKID       =>NULL);

     --CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE 
     --CREATE_TASK- AND EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--
     v_validationresult := 1;
     v_historyMsg :=NULL;
     v_result := f_DCM_processCommonEvent(InData           => NULL,
                                          OutData          => v_outData,      
                                          Attributes        => v_Attributes,
                                          Code              => NULL, 
                                          CaseId            => v_CaseId, 
                                          CaseTypeId        => null, 
                                          CommonEventType   => 'CREATE_TASK', 
                                          ErrorCode         => v_ErrorCode, 
                                          ErrorMessage      => v_ErrorMessage, 
                                          EventMoment       => 'BEFORE', 
                                          EventType         => 'VALIDATION',
                                          HistoryMessage    => v_historyMsg,
                                          ProcedureId       => NULL, 
                                          TaskId            => NULL, 
                                          TaskTypeId        => rec.COL_TASKTMPLDICT_TASKSYSTYPE, 
                                          ValidationResult  => v_validationresult);

    --write to history  
    IF v_historyMsg IS NOT NULL THEN
       v_result := f_HIST_createHistoryFn(
        AdditionalInfo => v_historyMsg,  
        IsSystem=>0, 
        Message=> 'Before create a task "'||rec.col_name||'" Validation Common event(s)',
        MessageCode => 'CommonEvent', 
        TargetID => v_CaseId, 
        TargetType=>'CASE'
       );
    END IF;
    
    IF v_validationresult = 0 THEN
      --UPDATE RECORDS INSIDE RUNTIME BO (link to created task)
      UPDATE TBL_COMMONEVENT SET COL_COMMONEVENTTASK = 0 
      WHERE COL_COMMONEVENTCASE=v_CaseId AND 
            COL_COMMONEVENTTASKTYPE=rec.COL_TASKTMPLDICT_TASKSYSTYPE AND
            COL_COMMONEVENTTASK IS NULL;      
            
      GOTO cleanup;            
    END IF;
    
    
    IF v_validationresult = 1 THEN

       --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE 
       --CREATE_TASK- AND EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--
       v_validationresult := 1;
       v_historyMsg :=NULL;
       v_result := f_DCM_processCommonEvent(InData           => NULL,
                                            OutData          => v_outData,      
                                            Attributes       => v_Attributes,
                                            Code             => NULL, 
                                            CaseId           => v_CaseId, 
                                            CaseTypeId       => null, 
                                            CommonEventType  => 'CREATE_TASK', 
                                            ErrorCode        => v_ErrorCode, 
                                            ErrorMessage     => v_ErrorMessage, 
                                            EventMoment      => 'BEFORE', 
                                            EventType        => 'ACTION',
                                            HistoryMessage   => v_historyMsg,
                                            ProcedureId      => null, 
                                            TaskId           => null, 
                                            TaskTypeId       => rec.COL_TASKTMPLDICT_TASKSYSTYPE, 
                                            ValidationResult => v_validationresult);
  
      --write to history  
      IF v_historyMsg IS NOT NULL THEN
         v_result := f_HIST_createHistoryFn(
          AdditionalInfo => v_historyMsg,  
          IsSystem=>0, 
          Message=> 'Before create a task "'||rec.col_name||'" Action Common event(s)',
          MessageCode => 'CommonEvent', 
          TargetID => v_CaseId, 
          TargetType=>'CASE'
         );
      END IF;

      --case not in new cache
      IF v_CSisInCache=0 THEN	         
        INSERT INTO TBL_TASK(COL_ID, COL_ID2, COL_CREATEDBY, COL_CREATEDDATE, COL_MODIFIEDBY, COL_MODIFIEDDATE,
                             COL_OWNER, COL_TYPE,  COL_PARENTID, COL_DESCRIPTION, COL_NAME, COL_TASKID, 
                             COL_DEPTH, COL_ICONCLS, COL_ICON,  COL_LEAF, COL_TASKORDER, COL_REQUIRED, 
                             COL_CASETASK, COL_TASKDICT_TASKSYSTYPE, COL_PROCESSORNAME, 
                             COL_TASKDICT_EXECUTIONMETHOD, COL_PAGECODE, COL_ISHIDDEN)
        VALUES (v_TaskId, rec.col_id, v_col_createdby, v_col_createddate, v_col_modifiedby, v_col_modifieddate, 
                v_col_owner,  rec.col_type, rec.col_parentttid, rec.col_description,  rec.col_name, v_taskTitle, 
                rec.col_depth, rec.col_iconcls, rec.col_icon, rec.col_leaf, rec.col_taskorder, rec.col_required, 
                v_caseid, rec.col_tasktmpldict_tasksystype, rec.col_processorcode,
                rec.col_execmethodtasktemplate, rec.col_pagecode, rec.ISHIDDENTASK);
       END IF;

      --case in new cache
      IF v_CSisInCache=1 THEN	          
        INSERT INTO TBL_CSTASK(COL_ID, COL_ID2, COL_CREATEDBY, COL_CREATEDDATE, COL_MODIFIEDBY, COL_MODIFIEDDATE,
                               COL_OWNER, COL_TYPE,  COL_PARENTID, COL_DESCRIPTION, COL_NAME, COL_TASKID, 
                               COL_DEPTH, COL_ICONCLS, COL_ICON,  COL_LEAF, COL_TASKORDER, COL_REQUIRED, 
                               COL_CASETASK, COL_TASKDICT_TASKSYSTYPE, COL_PROCESSORNAME, 
                               COL_TASKDICT_EXECUTIONMETHOD, COL_PAGECODE, COL_ISHIDDEN)
        VALUES (v_TaskId, rec.col_id, v_col_createdby, v_col_createddate, v_col_modifiedby, v_col_modifieddate, 
                v_col_owner,  rec.col_type, rec.col_parentttid, rec.col_description,  rec.col_name, v_taskTitle, 
                rec.col_depth, rec.col_iconcls, rec.col_icon, rec.col_leaf, rec.col_taskorder, rec.col_required, 
                v_caseid, rec.col_tasktmpldict_tasksystype, rec.col_processorcode,
                rec.col_execmethodtasktemplate, rec.col_pagecode, rec.ISHIDDENTASK);
       END IF;

      --UPDATE RECORDS INSIDE RUNTIME BO (link to created task)
      UPDATE TBL_COMMONEVENT SET COL_COMMONEVENTTASK = v_TaskId 
      WHERE COL_COMMONEVENTCASE=v_CaseId AND 
            COL_COMMONEVENTTASKTYPE=rec.COL_TASKTMPLDICT_TASKSYSTYPE AND
            COL_COMMONEVENTTASK IS NULL;
      
      --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CREATE_TASK- AND 
      --EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--
        v_result := f_DCM_processCommonEvent(InData           => NULL,
                                             OutData          => v_outData,      
                                             Attributes       => v_Attributes,
                                             Code             => NULL, 
                                             CaseId           => v_CaseId, 
                                             CaseTypeId       => NULL, 
                                             CommonEventType  => 'CREATE_TASK', 
                                             ErrorCode        => v_ErrorCode, 
                                             ErrorMessage     => v_ErrorMessage, 
                                             EventMoment      => 'AFTER', 
                                             EventType        => 'ACTION',
                                             HistoryMessage   => v_historyMsg,
                                             ProcedureId      => NULL, 
                                             TaskId           => v_TaskId, 
                                             TaskTypeId       => rec.COL_TASKTMPLDICT_TASKSYSTYPE, 
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
    END IF;--v_validationresult = 1
   END IF;--eo task is not a root

  --task is a root
  IF NVL(rec.COL_PARENTTTID, 0)=0 AND UPPER(NVL(rec.COL_TASKID, ' '))='ROOT' AND 
     rec.COL_TASKTMPLDICT_TASKSYSTYPE IS NULL THEN
     
      v_taskTitle :='root';

      --case not in new cache
      IF v_CSisInCache=0 THEN
       INSERT INTO TBL_TASK(COL_ID, COL_ID2, COL_CREATEDBY, COL_CREATEDDATE, COL_MODIFIEDBY, COL_MODIFIEDDATE,
                            COL_OWNER, COL_TYPE,  COL_PARENTID, COL_DESCRIPTION, COL_NAME, COL_TASKID, 
                            COL_DEPTH, COL_ICONCLS, COL_ICON,  COL_LEAF, COL_TASKORDER, COL_REQUIRED, 
                            COL_CASETASK, COL_TASKDICT_TASKSYSTYPE, COL_PROCESSORNAME, 
                            COL_TASKDICT_EXECUTIONMETHOD, COL_PAGECODE, COL_ISHIDDEN)
       VALUES (v_TaskId, rec.col_id, v_col_createdby, v_col_createddate, v_col_modifiedby, v_col_modifieddate, 
               v_col_owner,  rec.col_type, rec.col_parentttid, rec.col_description,  rec.col_name, v_taskTitle, 
               rec.col_depth, rec.col_iconcls, rec.col_icon, rec.col_leaf, rec.col_taskorder, rec.col_required, 
               v_caseid, rec.col_tasktmpldict_tasksystype, rec.col_processorcode,
               rec.col_execmethodtasktemplate, rec.col_pagecode, rec.ISHIDDENTASK);
     END IF;                       

      --case  in new cache
      IF v_CSisInCache=1 THEN
       INSERT INTO TBL_CSTASK(COL_ID, COL_ID2, COL_CREATEDBY, COL_CREATEDDATE, COL_MODIFIEDBY, COL_MODIFIEDDATE,
                            COL_OWNER, COL_TYPE,  COL_PARENTID, COL_DESCRIPTION, COL_NAME, COL_TASKID, 
                            COL_DEPTH, COL_ICONCLS, COL_ICON,  COL_LEAF, COL_TASKORDER, COL_REQUIRED, 
                            COL_CASETASK, COL_TASKDICT_TASKSYSTYPE, COL_PROCESSORNAME, 
                            COL_TASKDICT_EXECUTIONMETHOD, COL_PAGECODE, COL_ISHIDDEN)
       VALUES (v_TaskId, rec.col_id, v_col_createdby, v_col_createddate, v_col_modifiedby, v_col_modifieddate, 
               v_col_owner,  rec.col_type, rec.col_parentttid, rec.col_description,  rec.col_name, v_taskTitle, 
               rec.col_depth, rec.col_iconcls, rec.col_icon, rec.col_leaf, rec.col_taskorder, rec.col_required, 
               v_caseid, rec.col_tasktmpldict_tasksystype, rec.col_processorcode,
               rec.col_execmethodtasktemplate, rec.col_pagecode, rec.ISHIDDENTASK);
     END IF;
  END IF;--eo task is a root
 END LOOP;--eo main iteration   


 --case not in new cache
 IF v_CSisInCache=0 THEN
   UPDATE TBL_TASK tt1 
   SET    COL_PARENTID = (SELECT COL_ID FROM   TBL_TASK tt2 
                          WHERE  tt2.COL_ID2 = tt1.COL_PARENTID  AND tt2.COL_CASETASK = v_caseid) 
   WHERE  COL_CASETASK = v_caseid; 

   UPDATE TBL_TASK SET COL_PARENTID = 0 WHERE COL_CASETASK = v_CaseId AND COL_PARENTID IS NULL;
 END IF;
 
 --case in new cache
 IF v_CSisInCache=1 THEN
   UPDATE TBL_CSTASK tt1 
   SET    COL_PARENTID = (SELECT COL_ID FROM   TBL_CSTASK tt2 
                          WHERE  tt2.COL_ID2 = tt1.COL_PARENTID  AND tt2.COL_CASETASK = v_caseid) 
   WHERE  COL_CASETASK = v_caseid; 

   UPDATE TBL_CSTASK SET COL_PARENTID = 0 WHERE COL_CASETASK = v_CaseId AND COL_PARENTID IS NULL;
 END IF;

  :ErrorCode := 0;
  :ErrorMessage := NULL;
  RETURN 0;
 
  <<cleanup>>
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  RETURN -1;

END;