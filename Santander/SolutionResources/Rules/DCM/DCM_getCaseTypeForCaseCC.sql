DECLARE 
    v_casetypeid INTEGER; 
BEGIN 
    BEGIN 
        SELECT COL_CASECCDICT_CASESYSTYPE 
        INTO   v_casetypeid 
        FROM   tbl_caseCC 
        WHERE  col_id = :CaseId; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_casetypeid := NULL; 
    END; 

    RETURN v_casetypeid; 
END; 