declare
  v_state nvarchar2(255);
begin
  begin
    select col_activity into v_state from tbl_dict_casestate where col_isdefaultoncreate2 = 1;
    exception
      when NO_DATA_FOUND then
        v_state := 'root_CS_Status_IN_PROCESS';
      when TOO_MANY_ROWS then
        v_state := 'root_CS_Status_IN_PROCESS';
  end;
  return v_state;
end;