DECLARE
  --calculated
  v_Result INTEGER;
  v_stNewId NUMBER;
  v_stProcessedId NUMBER;
  v_queueId NUMBER;
  v_isFound INTEGER;
  v_SLAName NVARCHAR2(255);
  --errors variables
  v_isValid NUMBER;
  v_errorCode NUMBER;
  v_errorMessage NVARCHAR2(255);
  v_Domain NVARCHAR2(255);

BEGIN
  v_errorMessage := NULL;
  v_errorCode := NULL;
  v_isValid := 1;
  v_stNewId := NULL;
  v_stProcessedId := NULL;
  v_queueId := NULL;
  v_isFound := NULL;
  v_SLAName := 'Unknown';

  v_Domain := f_UTIL_getDomainFn();
  --GET PROCESSING STATUS
  v_stNewId := f_UTIL_getIdByCode(TableName => 'TBL_DICT_PROCESSINGSTATUS',
                                  Code => 'NEW');
  v_stProcessedId := f_UTIL_getIdByCode(TableName => 'TBL_DICT_PROCESSINGSTATUS',
                                        Code => 'PROCESSED');
  
  IF NVL(v_stNewId,0) = 0 OR NVL(v_stProcessedId,0) = 0 THEN
      v_errorMessage := 'Missing values from DICT_PROCESSINGSTATUS';
      v_errorCode := 101;
      GOTO cleanup;
  END IF;

  --MAIN QUERY
  FOR rec IN(SELECT  s2.CaseId as CaseId,
                  s2.StateId,
                  s2.SSEID,
                  s2.DateEvtType,
                  s2.DateValue_Latest,
                  s2.DateValue_Curr,
                  s2.ATTEMPTCOUNT AS ATTEMPTCOUNT,
                  s2.MAXATTEMPTS AS MAXATTEMPTS,
                  sse2.COL_SERVICETYPE AS SERVICETYPE,
                  sse2.COL_SERVICESUBTYPE AS SERVICESUBTYPE,
                  EXTRACT(second FROM TO_DSINTERVAL(sse2.COL_INTERVALDS)) AS S,
                  EXTRACT(hour FROM TO_DSINTERVAL(sse2.COL_INTERVALDS)) AS H,
                  EXTRACT(minute FROM TO_DSINTERVAL(sse2.COL_INTERVALDS)) AS M,
                  EXTRACT(DAY FROM TO_DSINTERVAL(sse2.COL_INTERVALDS)) AS D,
                  EXTRACT(MONTH FROM TO_YMINTERVAL(sse2.COL_INTERVALYM)) AS MO,
                  EXTRACT(YEAR FROM TO_YMINTERVAL(sse2.COL_INTERVALYM)) AS Y,
                  NVL(sse2.COL_STSLAEVT_TRANS,0) AS SLATRANSITIONID,
                  NVL(cs2.COL_CASE_MSCURRTRANS,0) AS CSTRANSITIONID
  FROM
    --query for calculate a date value+interval begin ---------------------------------------
    (SELECT s1.CaseId,
            s1.SSEID AS SSEID,
            sse1.COL_STATESLAEVENTDICT_STATE AS StateId,
            s1.DateEvtType,
            s1.DateValue_Latest,
            sse1.COL_ATTEMPTCOUNT AS ATTEMPTCOUNT,
            --sse1.COL_CODE AS SLAEvtCode,
            sse1.COL_INTERVALDS AS INTERVALDS,
            sse1.COL_INTERVALYM AS INTERVALYM,
            sse1.COL_MAXATTEMPTS AS MAXATTEMPTS,
            (
            CASE
              WHEN CASESLADATETIME IS NULL THEN s1.DateValue_Latest +(CASE WHEN sse1.COL_INTERVALDS IS NOT NULL THEN TO_DSINTERVAL(sse1.COL_INTERVALDS) ELSE TO_DSINTERVAL('0 0:0:0') END) +(CASE WHEN sse1.COL_INTERVALYM IS NOT NULL THEN TO_YMINTERVAL(sse1.COL_INTERVALYM) ELSE TO_YMINTERVAL('0-0') END) 
              ELSE s1.CASESLADATETIME 
            END) AS DateValue_Curr
    FROM
      --core query begin ---------------------------------------------------------------------
      (--part 1: get other (invisible) SLAs. We use old mechanizm with dateevent value(s)
       SELECT    cs.col_id AS CaseId,
                 sse.col_id AS SSEID,
                 dte.COL_DATEEVENT_DATEEVENTTYPE AS DateEvtType,
                 MAX(dte.COL_DATEVALUE) AS DateValue_Latest,
                 NULL AS CASESLADATETIME
      FROM       TBL_DICT_STATESLAEVENT sse
      INNER JOIN TBL_DICT_STATE st           ON sse.COL_STATESLAEVENTDICT_STATE = st.COL_ID
      INNER JOIN TBL_CASE cs                 ON cs.COL_CASEDICT_STATE = st.COL_ID
      INNER JOIN TBL_DATEEVENT dte           ON dte.COL_DATEEVENTCASE = cs.COL_ID AND dte.COL_DATEEVENTDICT_STATE = sse.COL_STATESLAEVENTDICT_STATE
      LEFT JOIN  TBL_DICT_DATEEVENTTYPE dtet ON dte.COL_DATEEVENT_DATEEVENTTYPE = dtet.COL_ID
      WHERE      NVL(dtet.COL_ISCASEMAINFLAG,0) = 1 AND
                 UPPER(sse.COL_SERVICETYPE) NOT IN ('GOAL', 'DEADLINE') AND
                 UPPER(sse.COL_SERVICESUBTYPE) NOT IN ('GOAL', 'DEADLINE')             
      GROUP BY   sse.COL_ID,cs.COL_ID,dte.COL_DATEEVENT_DATEEVENTTYPE
      
      UNION ALL
       
      --part 2: get deadline SLAs. We use new mechanizm with value from Case
      SELECT     csD.col_id AS CaseId,
                 sseD.col_id AS SSEID,                       
                 0 AS DateEvtType,
                 csD.COL_DATEEVENTVALUE AS DateValue_Latest,
                 csD.COL_DLINESLADATETIME AS CASESLADATETIME
      FROM       TBL_DICT_STATESLAEVENT sseD
      INNER JOIN TBL_DICT_STATE stD           ON sseD.COL_STATESLAEVENTDICT_STATE = stD.COL_ID
      INNER JOIN TBL_CASE csD                 ON csD.COL_CASEDICT_STATE = stD.COL_ID
      WHERE csD.COL_DLINESLADATETIME <=SYSDATE AND
            sseD.COL_SERVICETYPE='deadline' AND
            sseD.COL_SERVICESUBTYPE='deadline'   
  
      UNION ALL
       
      --part 3: get goal SLAs. We use new mechanizm with value from Case
      SELECT     csG.col_id AS CaseId,
                 sseG.col_id AS SSEID,
                 0 AS DateEvtType,
                 csG.COL_DATEEVENTVALUE AS DateValue_Latest,
                 csG.COL_DLINESLADATETIME AS CASESLADATETIME
      FROM       TBL_DICT_STATESLAEVENT sseG
      INNER JOIN TBL_DICT_STATE stG           ON sseG.COL_STATESLAEVENTDICT_STATE = stG.COL_ID
      INNER JOIN TBL_CASE csG                 ON csG.COL_CASEDICT_STATE = stG.COL_ID
      WHERE csG.COL_GOALSLADATETIME <=SYSDATE AND
            sseG.COL_SERVICETYPE='goal' AND
            sseG.COL_SERVICESUBTYPE='goal'   
  
      ) s1
      LEFT OUTER JOIN TBL_DICT_STATESLAEVENT sse1 ON sse1.COL_ID = s1.SSEID) s2

  INNER JOIN TBL_DICT_STATE st2 ON s2.StateId = st2.COL_ID
  LEFT OUTER JOIN TBL_DICT_STATESLAEVENT sse2 ON sse2.COL_ID = s2.SSEID
  LEFT OUTER JOIN TBL_CASE cs2 ON s2.CaseId=cs2.COL_ID
  WHERE           s2.DateValue_Curr <= SYSDATE
                  AND s2.ATTEMPTCOUNT < s2.MAXATTEMPTS
  ORDER BY        s2.CaseId ASC,
                  s2.DateEvtType ASC)
  LOOP     

    IF rec.SLATRANSITIONID NOT IN (rec.CSTRANSITIONID, 0) THEN CONTINUE; END IF;

    DELETE FROM TBL_MSSLAQUEUE
    WHERE  COL_MSSLAQUEUECASE = rec.CaseId
           AND COL_SLAQUEUEDICT_STSLAEVENT = rec.SSEID
           AND COL_DATECURR < rec.DateValue_Curr
           AND COL_SLAQUEUEDICT_PROCSTATUS = v_stProcessedId 
           AND NVL(COL_DATAFLAG,0)=0;
      
    v_queueId := NULL;
    v_isFound := NULL;
    BEGIN
      SELECT COl_ID INTO   v_queueId
      FROM TBL_MSSLAQUEUE
      WHERE  COL_MSSLAQUEUECASE = rec.CaseId
             AND COL_SLAQUEUEDICT_STSLAEVENT = rec.SSEID
             AND COL_DATECURR = rec.DateValue_Curr
             AND NVL(COL_DATAFLAG,0)=0;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_isFound := NULL;
    WHEN TOO_MANY_ROWS THEN
        v_isFound := 1;
    END;

    IF v_queueId IS NOT NULL THEN v_isFound := 1; END IF;

    --push data into queue
    IF v_isFound IS NULL THEN
      INSERT INTO TBL_MSSLAQUEUE(COL_MSSLAQUEUECASE,
                  COL_SLAQUEUEDICT_PROCSTATUS,
                  COL_SLAQUEUEDICT_STSLAEVENT,
                  COL_DATECURR)
             VALUES(rec.CaseId,
                    v_stNewId,
                    rec.SSEID,
                    rec.DateValue_Curr);
      
      --write to history
      v_result := f_HIST_createHistoryContextFn(additionalinfo => NULL,
                                                issystem => 0,
                                                message => NULL,
                                                messagecode => 'SLA_CaseMilestonePassed',
                                                targetid => rec.SSEID,
                                                targettype => 'slamsevent',
                                                AttachTargetId => rec.CaseId,
                                                AttachTargetType => 'case');
    END IF;
  END LOOP;

  --process all queue records
  v_result := f_DCM_processMSSLAQueue(ERRORCODE =>v_errorCode,
                                      ERRORMESSAGE =>v_errorMessage,
                                      ISVALID =>v_isValid,
                                      PDOMAIN =>v_Domain,
                                      PUSERACCESSSUBJECT =>sys_context('CLIENTCONTEXT','AccessSubject'));
  IF NVL(v_errorCode,0) > 0 THEN
      GOTO cleanup;
  END IF;

  --successful block
  v_errorCode := NULL;
  v_errorMessage := NULL;
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
  v_result := f_util_createsyslogfn(MESSAGE => 'FOR CASES: SLAs and auto-routing scheduler executed');

  RETURN;
  --error block
  <<cleanup>> :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
  v_result := f_util_createsyslogfn(MESSAGE => 'FOR CASES: SLAs and auto-routing scheduler executed with errors<br>' || v_errorMessage);

EXCEPTION
WHEN OTHERS THEN
  :errorCode := 101;
  :errorMessage := SQLERRM;
  v_result := f_util_createsyslogfn(MESSAGE => 'FOR CASES: SLAs and auto-routing scheduler executed with errors<br>' || SQLERRM);
END;