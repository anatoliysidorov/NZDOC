declare
  v_result NUMBER;
  v_code nvarchar2(255);
begin
  v_code := :Code;
  begin
    select Col_id into v_result 
      from TBL_DICT_PARTICIPANTTYPE 
      where UPPER(col_code) = UPPER(v_code);
    exception
      when  NO_DATA_FOUND then
        return -1;
      when TOO_MANY_ROWS then
        return -1;
  end;
  return v_result;
end;