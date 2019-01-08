declare
  v_result nvarchar2(255);
begin
  begin
    select col_code into v_result from tbl_dict_dateeventtype where col_isslastart = 1;
    exception
      when NO_DATA_FOUND then
        v_result := 'DATE_TASK_IN_PROCESS';
      when TOO_MANY_ROWS then
        v_result := 'DATE_TASK_IN_PROCESS';
  end;
  RETURN v_result;
end;