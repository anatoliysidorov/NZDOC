DECLARE
  v_caseid Integer;
  v_casetypeid Integer;
  v_procedureid Integer;
  v_taskid Integer;
  v_tasktypeid Integer;
  v_owner nvarchar2(255);
  v_commonEventCode nvarchar2(255);
  v_CommonEventType nvarchar2(255);
	
BEGIN
  v_caseid      := :CaseId;
  v_casetypeid  := :CaseTypeId;
  v_procedureid := :ProcedureId;
  v_tasktypeid  := :TaskTypeId;
  v_commonEventCode := :Code;
  v_CommonEventType := :CommonEventType;
  v_taskid := :TaskId;
  
  v_owner := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  
  BEGIN
      INSERT INTO TBL_COMMONEVENT(    
      COL_CODE
     ,COL_EVENTORDER
     ,COL_NAME
     ,COL_OWNER
     ,COL_PROCESSORCODE
     ,COL_COMEVENTCOMEVENTTYPE
     ,COL_COMMONEVENTCASE
     ,COL_COMMONEVENTCASETYPE
     ,COL_COMMONEVENTEVENTMOMENT
     ,COL_COMMONEVENTEVENTSYNCTYPE
     ,COL_COMMONEVENTPROCEDURE
     ,COL_COMMONEVENTTASK
     ,COL_COMMONEVENTTASKEVENTTYPE
     ,COL_COMMONEVENTTASKTMPL
     ,COL_COMMONEVENTTASKTYPE
     ,COL_ISPROCESSED
    )
	SELECT 
		v_commonEventCode AS CODE, 
		ce.COL_EVENTORDER AS EVENTORDER, 
		ce.COL_NAME AS NAME,
		v_owner AS OWNER,
        ce.COL_PROCESSORCODE AS PROCESSORCODE, 
		ce.COL_COMEVENTTMPLCOMEVENTTYPE AS EventTypeId,
		v_caseid AS CASEID,
        ce.COL_COMMONEVENTTMPLCASETYPE AS CaseTypeId,
		ce.COL_COMEVTTMPLEVTMMNT AS EventMomentId, 
		ce.COL_COMEVTTMPLEVTSYNCT AS EventSyncTypeId,
        ce.COL_COMMONEVENTTMPLPROCEDURE AS ProcedureId,
		v_taskid AS TASKID,		
		ce.COL_COMEVTTMPLTASKEVTT AS TaskEventTypeId, 
        ce.COL_COMMONEVENTTMPLTASKTMPL AS TaskTemplateId,
        ce.COL_COMMONEVENTTMPLTASKTYPE AS TaskTypeId,
		NULL
    FROM TBL_COMMONEVENTTMPL ce
    INNER JOIN TBL_DICT_COMMONEVENTTYPE cet on ce.COL_COMEVENTTMPLCOMEVENTTYPE = cet.COL_ID
    WHERE ((CASE WHEN v_casetypeid IS NOT NULL THEN ce.COL_COMMONEVENTTMPLCASETYPE
                 WHEN v_procedureid IS NOT NULL THEN ce.COL_COMMONEVENTTMPLPROCEDURE
                 WHEN v_tasktypeid IS NOT NULL THEN ce.COL_COMMONEVENTTMPLTASKTYPE
                 ELSE 1 
            END) = NVL(v_casetypeid, NVL(v_procedureid, NVL(v_tasktypeid, 1))))
    AND ((CASE WHEN v_CommonEventType IS NOT NULL THEN TO_CHAR(cet.COL_CODE)
              ELSE TO_CHAR(' ')
         END) = NVL(v_CommonEventType, TO_CHAR(' ')));
  
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        :ErrorCode := 100;
      WHEN OTHERS THEN
        :ErrorCode := 100;
  END;

END;