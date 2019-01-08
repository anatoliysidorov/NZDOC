DECLARE
  v_Id NUMBER;
  v_TableName nvarchar2(255);
  v_Code nvarchar2(255);
  v_query varchar(2000);
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
BEGIN

  v_TableName := :TableName;
  v_Code := :Code;
  v_ErrorCode := 0;
  v_ErrorMessage := '';

  v_query := 'begin ' || 'SELECT col_id INTO :' || 'bind_id FROM ' || v_TableName || ' WHERE  Lower(col_code) = Lower(:' || 'bind_code); end;';
  BEGIN
	EXECUTE IMMEDIATE v_query using out v_Id, v_Code;
  EXCEPTION
	WHEN NO_DATA_FOUND THEN
		v_Id := null;
		v_ErrorCode := 101;
		v_ErrorMessage := 'Code not found';
--		return -1;  --use this when need callback
    WHEN TOO_MANY_ROWS THEN
	    v_Id := null;
		v_ErrorCode := 101;
		v_ErrorMessage := 'Found more then one Code';
--		return -2;  --use this when need callback
  END;  
  return v_Id;
END;