DECLARE 
    v_casetypeid INTEGER; 
BEGIN 
    BEGIN 
        SELECT col_casedict_casesystype 
        INTO   v_casetypeid 
        FROM   tbl_case 
        WHERE  col_id = :CaseId; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_casetypeid := NULL; 
    END; 

    RETURN v_casetypeid; 
END; 