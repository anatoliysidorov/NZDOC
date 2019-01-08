declare
  v_result nvarchar2(255);
begin
  begin
    select col_code into v_result from tbl_dict_dateeventtype where col_isslaend = 1;
    exception
      when NO_DATA_FOUND then
        v_result := 'DATE_TASK_CLOSED';
      when TOO_MANY_ROWS then
        v_result := 'DATE_TASK_CLOSED';
  end;
  RETURN v_result;
end;