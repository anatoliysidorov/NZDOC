declare
  v_state nvarchar2(255);
begin
  begin
    select col_activity into v_state from tbl_dict_taskstate where col_isresolve = 1;
    exception
      when NO_DATA_FOUND then
        v_state := 'root_TSK_Status_RESOLVED';
      when TOO_MANY_ROWS then
        v_state := 'root_TSK_Status_RESOLVED';
  end;
  return v_state;
end;