DECLARE
    v_procStateID INT;
BEGIN
    BEGIN
      SELECT COL_ID 
      INTO v_procStateID
      FROM TBL_DICT_PROCESSINGSTATUS
      WHERE lower(COL_CODE) = 'processed';
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN v_procStateID := NULL;
    END;  
    IF v_procStateID = NULL THEN RETURN; END IF;
    
    DELETE FROM TBL_MSSLAQUEUE WHERE col_Id in (
        SELECT q.col_Id
        FROM TBL_MSSLAQUEUE q
            INNER JOIN tbl_Case cs on cs.col_Id = q.COL_MSSLAQUEUECASE
            INNER JOIN tbl_Dict_CaseState cs_st ON cs_st.col_Id = cs.col_CaseDict_CaseState
        WHERE q.COL_SLAQUEUEDICT_PROCSTATUS = v_procStateID
            AND cs_st.col_IsFinish = 1
    );
END;    