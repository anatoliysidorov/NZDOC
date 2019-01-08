DECLARE
  v_caseid       NUMBER;
  v_casetypeid   NUMBER;
  v_procedureid  NUMBER;
  v_taskid       NUMBER;
  v_tasktypeid   NUMBER;
  v_CEId NUMBER;
  v_owner           NVARCHAR2(255);
  v_commonEventCode NVARCHAR2(255); 
  
BEGIN
  v_caseid      := :CaseId;
  v_casetypeid  := :CaseTypeId;
  v_procedureid := :ProcedureId;
  v_tasktypeid  := :TaskTypeId;
  v_commonEventCode := :Code;  
  v_taskid          := :TaskId;
  
  v_owner := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');

  FOR rec IN
  (
    SELECT ce.COL_CODE AS CODE, ce.COL_EVENTORDER AS EVENTORDER, ce.COL_NAME AS NAME,
           ce.COL_PROCESSORCODE AS PROCESSORCODE, ce.COL_COMEVENTTMPLCOMEVENTTYPE AS EventTypeId,
           ce.COL_COMMONEVENTTMPLCASETYPE AS CaseTypeId,ce.COL_COMEVTTMPLEVTMMNT AS EventMomentId, ce.COL_COMEVTTMPLEVTSYNCT AS EventSyncTypeId,
           ce.COL_COMMONEVENTTMPLPROCEDURE AS ProcedureId, ce.COL_COMEVTTMPLTASKEVTT AS TaskEventTypeId, 
           ce.COL_COMMONEVENTTMPLTASKTMPL AS TaskTemplateId,
           ce.COL_COMMONEVENTTMPLTASKTYPE AS TaskTypeId,
           ce.COL_ID AS ID, NVL(ce.COL_REPEATINGEVENT,1) AS RepeatingEvent
    FROM TBL_COMMONEVENTTMPL ce    
    WHERE ((CASE WHEN v_casetypeid IS NOT NULL THEN ce.COL_COMMONEVENTTMPLCASETYPE
                 WHEN v_procedureid IS NOT NULL THEN ce.COL_COMMONEVENTTMPLPROCEDURE
                 WHEN v_tasktypeid IS NOT NULL THEN ce.COL_COMMONEVENTTMPLTASKTYPE
                 ELSE 1 
            END) = NVL(v_casetypeid, NVL(v_procedureid, NVL(v_tasktypeid, 1))))
  )
  LOOP
    INSERT INTO TBL_COMMONEVENT(COL_LINKCODE, COL_CODE, COL_EVENTORDER, COL_NAME, COL_OWNER,
                                COL_PROCESSORCODE, COL_COMEVENTCOMEVENTTYPE, COL_COMMONEVENTCASE,
                                COL_COMMONEVENTCASETYPE, COL_COMMONEVENTEVENTMOMENT,
                                COL_COMMONEVENTEVENTSYNCTYPE, COL_COMMONEVENTPROCEDURE,
                                COL_COMMONEVENTTASK, COL_COMMONEVENTTASKEVENTTYPE,
                                COL_COMMONEVENTTASKTMPL, COL_COMMONEVENTTASKTYPE, COL_ISPROCESSED,
                                COL_REPEATINGEVENT, COL_UCODE)
    VALUES(v_commonEventCode, rec.CODE, rec.EVENTORDER, rec.NAME, v_owner,
           rec.PROCESSORCODE, rec.EventTypeId, v_caseid,
           rec.CaseTypeId, rec.EventMomentId, rec.EventSyncTypeId,
           rec.ProcedureId, v_taskid, rec.TaskEventTypeId, 
           rec.TaskTemplateId, rec.TaskTypeId, NULL,
           rec.RepeatingEvent, SYS_GUID()) RETURNING COL_ID INTO v_CEId;
    
    INSERT INTO TBL_AUTORULEPARAMETER(COL_PARAMVALUE, COL_PARAMCODE, COL_CODE, COL_AUTORULEPARAMCOMMONEVENT)
    (SELECT COL_PARAMVALUE, COL_PARAMCODE, SYS_GUID(), v_CEId
     FROM TBL_AUTORULEPARAMTMPL
     WHERE COL_ARPTMPL_CETMPL=rec.ID);
  END LOOP;

END;