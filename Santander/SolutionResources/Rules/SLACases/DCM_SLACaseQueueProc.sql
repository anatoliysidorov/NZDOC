DECLARE
    --calculated
    v_Result INTEGER;
    v_stNewId NUMBER;
    v_stProcessedId NUMBER;
    v_queueId NUMBER;
    v_isFound INTEGER;
    v_message NVARCHAR2(255);    
	
    --errors variables
    v_isValid NUMBER;
    v_errorCode NUMBER;
    v_errorMessage NVARCHAR2(255);
    v_Domain NVARCHAR2(255);
BEGIN

  v_errorMessage  := NULL;
  v_errorCode     := NULL;
  v_isValid       := 1;
  v_stNewId       := NULL;
  v_stProcessedId := NULL;
  v_queueId       := NULL;
  v_isFound       := NULL;
  v_message       := NULL;
    
  v_Domain := f_UTIL_getDomainFn();

  --GET PROCESSING STATUS
  v_stNewId := f_UTIL_getIdByCode(TableName => 'TBL_DICT_PROCESSINGSTATUS',Code => 'NEW');
  v_stProcessedId := f_UTIL_getIdByCode(TableName => 'TBL_DICT_PROCESSINGSTATUS',Code => 'PROCESSED');
  
  IF NVL(v_stNewId,0) = 0 OR NVL(v_stProcessedId,0) = 0 THEN
      v_errorMessage := 'Missing values from DICT_PROCESSINGSTATUS';
      v_errorCode := 101;
      GOTO cleanup;
  END IF;

  FOR rec IN
  (
  --main query begin ---------------------------------------------------------------------
  SELECT s2.SEID AS SEID,
         s2.CASEID AS CASEID,
         s2.DATEEVTTYPE AS DATEEVTTYPE,
         s2.DATEVALUE_LATEST AS  DATEVALUE_LATEST,
         s2.ATTEMPTCOUNT AS ATTEMPTCOUNT, 
         --s2.SLAEVTCODE AS SLAEVTCODE,      
         s2.INTERVALDS AS INTERVALDS,
         s2.INTERVALYM AS INTERVALYM,
         s2.MAXATTEMPTS AS MAXATTEMPTS,
         s2.DATEVALUE_CURR AS DATEVALUE_CURR
  FROM
    --query for calculate a date value+interval begin ---------------------------------------
    (SELECT s1.SEID AS SEID,
            s1.CASEID AS CASEID,
            s1.DATEEVTTYPE AS DATEEVTTYPE,
            s1.DATEVALUE_LATEST AS  DATEVALUE_LATEST,
            se1.COL_ATTEMPTCOUNT AS ATTEMPTCOUNT,
            se1.COL_CODE AS SLAEVTCODE,
            se1.COL_INTERVALDS AS INTERVALDS,
            se1.COL_INTERVALYM AS INTERVALYM,
            se1.COL_MAXATTEMPTS AS MAXATTEMPTS,
            s1.DATEVALUE_LATEST +
            (
            CASE 
              WHEN se1.COL_INTERVALDS IS NOT NULL THEN TO_DSINTERVAL(se1.COL_INTERVALDS) 
              ELSE TO_DSINTERVAL('0 0:0:0') 
            END
            ) +
            (
            CASE 
              WHEN se1.COL_INTERVALYM IS NOT NULL THEN TO_YMINTERVAL(se1.COL_INTERVALYM) 
              ELSE TO_YMINTERVAL('0-0') 
            END
            ) AS DATEVALUE_CURR
    FROM
      --core query begin ---------------------------------------------------------------------
      (SELECT  se.COL_ID AS SEID,
              se.COL_SLAEVENTSLACASE AS CASEID,
              dte.COL_DATEEVENT_DATEEVENTTYPE AS DATEEVTTYPE,
              MAX(dte.COL_DATEVALUE) AS DATEVALUE_LATEST
      FROM TBL_SLAEVENT se
      INNER JOIN TBL_DATEEVENT dte ON dte.COL_DATEEVENTCASE = se.COL_SLAEVENTSLACASE AND 
                                      se.COL_SLAEVENT_DATEEVENTTYPE=dte.COL_DATEEVENT_DATEEVENTTYPE
      LEFT JOIN  TBL_DICT_DATEEVENTTYPE dtet ON dte.COL_DATEEVENT_DATEEVENTTYPE = dtet.COL_ID
      LEFT OUTER JOIN TBL_CASE cs ON se.COL_SLAEVENTSLACASE=cs.COL_ID
      LEFT OUTER JOIN TBL_DICT_CASESYSTYPE cst ON cs.COL_CASEDICT_CASESYSTYPE=cst.COL_ID
      WHERE  NVL(dtet.COL_ISCASEMAINFLAG,0) = 1 AND
             --not in CLOSED system state
             cs.COL_ACTIVITY <>f_DCM_getCaseClosedState2(STATECONFIGID => cst.COL_STATECONFIGCASESYSTYPE)   
      GROUP BY se.COL_ID, se.COL_SLAEVENTSLACASE,  dte.COL_DATEEVENT_DATEEVENTTYPE) s1
      --core query end  ---------------------------------------------------------------------
    LEFT OUTER JOIN TBL_SLAEVENT se1 ON s1.SEID=se1.COL_ID
    WHERE se1.COL_ATTEMPTCOUNT < se1.COL_MAXATTEMPTS) s2
    --query for calculate a date value+interval end ---------------------------------------
  WHERE s2.DATEVALUE_CURR <= SYSDATE
  ORDER BY s2.CASEID ASC, s2.DATEEVTTYPE ASC,  s2.SEID ASC
  --main query end -----------------------------------------------------------------------
  ) 
  --main query loop start
  LOOP 
    DELETE
    FROM   TBL_CASESLAEVTQUEUE
    WHERE  COL_CASESLAEVTQCASE = rec.CASEID
           AND COL_CASESLAEVTQSLAEVENT = rec.SEID
           AND COL_DATECURR < rec.DATEVALUE_CURR
           AND COL_CASESLAEVTQ_PROCST = v_stProcessedId;
    
    v_queueId := NULL;
    v_isFound := NULL;

    BEGIN
        SELECT COl_ID INTO v_queueId
        FROM TBL_CASESLAEVTQUEUE
        WHERE  COL_CASESLAEVTQCASE = rec.CASEID
               AND COL_CASESLAEVTQSLAEVENT = rec.SEID
               AND COL_DATECURR = rec.DATEVALUE_CURR;    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN v_isFound := NULL;
      WHEN TOO_MANY_ROWS THEN v_isFound := 1;
    END;

    IF v_queueId IS NOT NULL THEN
        v_isFound := 1;
    END IF;

    --push data into queue
    IF v_isFound IS NULL THEN
        INSERT INTO TBL_CASESLAEVTQUEUE(COL_CASESLAEVTQCASE, COL_CASESLAEVTQ_PROCST, COL_CASESLAEVTQSLAEVENT,
                                        COL_DATECURR) 
         VALUES(rec.CASEID, v_stNewId, rec.SEID, rec.DATEVALUE_CURR);
        
        --write to history
        v_message := '';
        v_message := f_util_addtomessage(originalmsg => v_message, newmsg => 'INFO: ' || 'Executing events if present');
        v_result := f_HIST_createHistoryFn(additionalinfo => v_message,
                                           issystem => 0,
                                           MESSAGE => NULL,
                                           messagecode => 'SLA_CaseMilestonePassed',
                                           targetid => rec.SEID,
                                           targettype => 'slamsevent');
    END IF;
  END LOOP;--main query loop end

  --process all queue records
  v_result := f_DCM_processSLACaseQueue(ERRORCODE =>v_errorCode,        --output
                                        ERRORMESSAGE =>v_errorMessage,  --output
                                        ISVALID =>v_isValid,            --output 
                                        PDOMAIN =>v_Domain,
                                        PUSERACCESSSUBJECT =>sys_context('CLIENTCONTEXT','AccessSubject'));
    
	IF NVL(v_errorCode,0) > 0 THEN GOTO cleanup; END IF;


  --successful block
  v_errorCode := NULL;
  v_errorMessage := NULL;
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
  v_result := f_util_createsyslogfn(MESSAGE => 'FOR CASES: SLAs and auto-routing scheduler executed');
  RETURN;
    
	--error block
  <<cleanup>> 
	:ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
  v_result := f_util_createsyslogfn(MESSAGE => 'FOR CASES: SLAs and auto-routing scheduler executed with errors<br>' || v_errorMessage);

EXCEPTION 
    WHEN OTHERS THEN 
      :errorCode := 101; 
      :errorMessage := SQLERRM; 
      v_result := f_util_createsyslogfn(MESSAGE => 'FOR CASES: SLAs and auto-routing scheduler executed with errors<br>' || SQLERRM);
END;