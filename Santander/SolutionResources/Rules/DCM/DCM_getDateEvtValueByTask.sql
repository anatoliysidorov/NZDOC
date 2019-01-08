DECLARE 
    v_result date; 
BEGIN 
    BEGIN 
      SELECT MAX(de2.COL_DATEVALUE) INTO v_result 
      FROM tbl_dateevent de2 
      WHERE de2.col_dateeventtask=:TaskId AND
            de2.col_dateevent_dateeventtype=:EventTypeId;
    EXCEPTION 
        WHEN no_data_found THEN 
          v_result := NULL; 
    END; 

    RETURN v_result; 
END;