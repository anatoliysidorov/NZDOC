DECLARE 
	v_maxLogRecords INTEGER;
        v_count                Integer;
BEGIN

  INSERT INTO TBL_UTIL_Log(
    COL_MESSAGE
  )
  VALUES (
    :MESSAGE
  );
  
  -- Clean log if needed
  v_maxLogRecords:= to_number(f_dcm_getscalarsetting(p_name=>'MAX_LOG_RECORDS', defaultresult=>'0'));

  select count(*) into v_count from tbl_util_log;

  if (v_count > v_maxLogRecords) then
    delete from tbl_util_log
    where col_id in
    (SELECT col_id from (SELECT oLog.col_Id, oLog.rownumber
                        FROM (SELECT col_Id, rownum as rownumber
                              FROM TBL_UTIL_Log 
                              ORDER BY col_Id) oLog
                        WHERE ROWNUMBER >= 1 and ROWNUMBER < v_count - v_maxLogRecords + 1
                        order by oLog.col_id));
  end if;

END;