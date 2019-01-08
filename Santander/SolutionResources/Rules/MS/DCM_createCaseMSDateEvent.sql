DECLARE
  v_date          DATE;
  v_performedby   NVARCHAR2(255);
  v_CaseworkerId  NUMBER;
  v_CaseId        NUMBER;
  v_StateId       NUMBER;
  v_name          NVARCHAR2(255); 
  v_EventTypeId   NUMBER;
  v_EventTypeCode NVARCHAR2(255);
  v_DateEventId   NUMBER;
  v_MultipleAllowed NUMBER;
  v_CanOverwrite    NUMBER;
  v_newId           NUMBER;

BEGIN
  v_StateId :=  :StateId;
  v_CaseId :=   :CaseId;
  v_name :=     :Name;
  
  v_date := sysdate;
  v_performedby := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');

  BEGIN
    SELECT id INTO v_CaseworkerId FROM vw_ppl_caseworkersusers WHERE accode = v_performedby;
    EXCEPTION 
    WHEN NO_DATA_FOUND THEN
      v_CaseworkerId := null;
  END;

  BEGIN
    SELECT col_id, col_code, col_multipleallowed, col_canoverwrite 
    INTO v_EventTypeId, v_EventTypeCode, v_MultipleAllowed, v_CanOverwrite 
    FROM TBL_DICT_DATEEVENTTYPE 
    WHERE UPPER(col_code) = UPPER(v_name);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_EventTypeId     := NULL;
      v_EventTypeCode   := NULL;
      v_MultipleAllowed := NULL;
      v_CanOverwrite    := NULL;
  END;

  IF v_EventTypeId IS NULL THEN RETURN 0; END IF;


  IF f_DCM_CSisCaseInCache(v_CaseId)=0 THEN  
    IF (v_MultipleAllowed IS NULL) OR (v_MultipleAllowed = 0) THEN
      BEGIN
        SELECT col_id INTO v_DateEventId 
        FROM TBL_DATEEVENT 
        WHERE col_dateeventcase = v_CaseId 
              AND upper(col_datename) = upper(v_name) 
              AND COL_DATEEVENTDICT_STATE=v_StateId;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_DateEventId := NULL;
        WHEN TOO_MANY_ROWS THEN
          DELETE FROM TBL_DATEEVENT 
          WHERE col_dateeventcase = v_CaseId 
          AND upper(col_datename) = upper(v_name)
          AND COL_DATEEVENTDICT_STATE=v_StateId;
  
          v_DateEventId := NULL;
      END;
    ELSE
      v_DateEventId := null;
    END IF;
  
  
    IF v_DateEventId IS NULL THEN
      INSERT INTO TBL_DATEEVENT (col_dateeventcase, col_datename, col_datevalue, col_performedby, 
                                 col_dateeventppl_caseworker, col_dateevent_dateeventtype, COL_DATEEVENTDICT_STATE)
      VALUES (v_CaseId, upper(v_name), v_date, v_performedby, v_CaseworkerId, v_EventTypeId, v_StateId);
  
    ELSIF (v_DateEventId IS NOT NULL) 
          AND (v_MultipleAllowed IS NOT NULL) AND (v_MultipleAllowed = 1) THEN
      INSERT INTO TBL_DATEEVENT (col_dateeventcase, col_datename, col_datevalue, col_performedby, 
                                 col_dateeventppl_caseworker, col_dateevent_dateeventtype, COL_DATEEVENTDICT_STATE)
      VALUES (v_CaseId, upper(v_name), v_date, v_performedby, v_CaseworkerId, v_EventTypeId, v_StateId);
  
    ELSIF (v_DateEventId IS NOT NULL) 
          AND ((v_MultipleAllowed IS NULL) OR (v_MultipleAllowed = 0)) 
          AND (v_CanOverwrite IS NOT NULL) AND (v_CanOverwrite = 1) THEN
      UPDATE TBL_DATEEVENT 
      SET col_datevalue = v_date, 
           col_performedby = v_performedby, 
           col_dateeventppl_caseworker = v_CaseworkerId,
           COL_DATEEVENTDICT_STATE = v_StateId
           WHERE col_dateeventcase = v_CaseId 
                 AND upper(col_datename) = upper(v_name)
                 AND COL_DATEEVENTDICT_STATE=v_StateId;
    END IF;
  END IF;--not in cache


  IF f_DCM_CSisCaseInCache(v_CaseId)=1 THEN
    IF (v_MultipleAllowed IS NULL) OR (v_MultipleAllowed = 0) THEN
      BEGIN
        SELECT col_id INTO v_DateEventId 
        FROM TBL_CSDATEEVENT 
        WHERE col_dateeventcase = v_CaseId 
              AND upper(col_datename) = upper(v_name) 
              AND COL_DATEEVENTDICT_STATE=v_StateId;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_DateEventId := NULL;
        WHEN TOO_MANY_ROWS THEN

          DELETE FROM TBL_DATEEVENT  
          WHERE col_dateeventcase = v_CaseId 
          AND upper(col_datename) = upper(v_name)
          AND COL_DATEEVENTDICT_STATE=v_StateId;

          DELETE FROM TBL_CSDATEEVENT 
          WHERE col_dateeventcase = v_CaseId 
          AND upper(col_datename) = upper(v_name)
          AND COL_DATEEVENTDICT_STATE=v_StateId;
  
          v_DateEventId := NULL;
      END;
    ELSE
      v_DateEventId := null;
    END IF;
  
  
    SELECT gen_tbl_DateEvent.nextval INTO v_newId FROM dual;

    IF v_DateEventId IS NULL THEN              
      INSERT INTO TBL_CSDATEEVENT (col_id, col_dateeventcase, col_datename, col_datevalue, col_performedby, 
                                 col_dateeventppl_caseworker, col_dateevent_dateeventtype, COL_DATEEVENTDICT_STATE)
      VALUES (v_newId, v_CaseId, upper(v_name), v_date, v_performedby, v_CaseworkerId, v_EventTypeId, v_StateId);
  
    ELSIF (v_DateEventId IS NOT NULL) 
          AND (v_MultipleAllowed IS NOT NULL) AND (v_MultipleAllowed = 1) THEN
      INSERT INTO TBL_CSDATEEVENT (col_id, col_dateeventcase, col_datename, col_datevalue, col_performedby, 
                                 col_dateeventppl_caseworker, col_dateevent_dateeventtype, COL_DATEEVENTDICT_STATE)
      VALUES (v_newId, v_CaseId, upper(v_name), v_date, v_performedby, v_CaseworkerId, v_EventTypeId, v_StateId);
  
    ELSIF (v_DateEventId IS NOT NULL) 
          AND ((v_MultipleAllowed IS NULL) OR (v_MultipleAllowed = 0)) 
          AND (v_CanOverwrite IS NOT NULL) AND (v_CanOverwrite = 1) THEN
      UPDATE TBL_CSDATEEVENT 
      SET col_datevalue = v_date, 
           col_performedby = v_performedby, 
           col_dateeventppl_caseworker = v_CaseworkerId,
           COL_DATEEVENTDICT_STATE = v_StateId
           WHERE col_dateeventcase = v_CaseId 
                 AND upper(col_datename) = upper(v_name)
                 AND COL_DATEEVENTDICT_STATE=v_StateId;
    END IF;
  END IF;--in cache


END;
