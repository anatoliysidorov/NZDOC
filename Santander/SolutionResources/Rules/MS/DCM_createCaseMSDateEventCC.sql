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

  IF (v_MultipleAllowed IS NULL) OR (v_MultipleAllowed = 0) THEN
    BEGIN
      SELECT col_id INTO v_DateEventId 
      FROM TBL_DATEEVENTCC 
      WHERE COL_DATEEVENTCCCASECC = v_CaseId 
            AND UPPER(COL_DATENAME) = UPPER(v_name) 
            AND COL_DATEEVENTCCDICT_STATE=v_StateId;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_DateEventId := NULL;
      WHEN TOO_MANY_ROWS THEN
        DELETE FROM TBL_DATEEVENTCC 
        WHERE COL_DATEEVENTCCCASECC = v_CaseId 
        AND UPPER(COL_DATENAME) = UPPER(v_name)
        AND COL_DATEEVENTCCDICT_STATE=v_StateId;

        v_DateEventId := NULL;
    END;
  ELSE
    v_DateEventId := null;
  END IF;


  IF v_DateEventId IS NULL THEN
    INSERT INTO TBL_DATEEVENTCC (col_dateeventcccasecc, col_datename, 
                                 col_datevalue, col_performedby, 
                                 col_dateeventccppl_caseworker, 
                                 col_dateeventcc_dateeventtype,
                                 COL_DATEEVENTCCDICT_STATE)
    VALUES (v_CaseId, UPPER(v_name), 
            v_date, v_performedby, 
            v_CaseworkerId, 
            v_EventTypeId,
            v_StateId);

  ELSIF (v_DateEventId IS NOT NULL) 
        AND (v_MultipleAllowed IS NOT NULL) AND (v_MultipleAllowed = 1) THEN
      INSERT INTO TBL_DATEEVENTCC (col_dateeventcccasecc, col_datename, 
                                   col_datevalue, col_performedby, 
                                   col_dateeventccppl_caseworker, 
                                   col_dateeventcc_dateeventtype,
                                   COL_DATEEVENTCCDICT_STATE)
      VALUES (v_CaseId, UPPER(v_name), 
              v_date, v_performedby, 
              v_CaseworkerId, 
              v_EventTypeId,
              v_StateId);

  ELSIF (v_DateEventId IS NOT NULL) 
        AND ((v_MultipleAllowed IS NULL) OR (v_MultipleAllowed = 0)) 
        AND (v_CanOverwrite IS NOT NULL) AND (v_CanOverwrite = 1) THEN
    UPDATE TBL_DATEEVENTCC 
      SET col_datevalue = v_date, 
      col_performedby = v_performedby, 
      col_dateeventccppl_caseworker = v_CaseworkerId 
      WHERE col_dateeventcccasecc = v_CaseId 
            AND UPPER(col_datename) = UPPER(v_name)
            AND COL_DATEEVENTCCDICT_STATE=v_StateId;
  END IF;

END;