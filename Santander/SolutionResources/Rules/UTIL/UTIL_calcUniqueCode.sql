DECLARE
  indx number;
  hits number;
  newCode nvarchar2(255);
  v_code nvarchar2(255);
  v_TableName nvarchar2(255);
  v_query varchar(4000);
BEGIN
  indx := 0;
  v_Code := upper(:BaseCode);
  newCode :=  v_Code;
  v_TableName := :TableName; 
  v_query := 'begin ' || 'SELECT count(1) INTO :'||'bind_count FROM ' || v_TableName || ' WHERE  Lower(col_code) = Lower(:'||'bind_code); end;';
LOOP
  BEGIN
    if indx = 0 then
     EXECUTE IMMEDIATE v_query using out hits,  v_Code;
    else
      newCode := upper(:BaseCode) || '_' || indx;
      EXECUTE IMMEDIATE v_query using out hits,  newCode;
   end if;
    indx := indx +1;
   EXCEPTION WHEN OTHERS THEN
   --dbms_output.put_line(SQLCODE);
   exit;
   return newcode;
  END;
   EXIT WHEN hits = 0;
END LOOP;
return newcode;

END;