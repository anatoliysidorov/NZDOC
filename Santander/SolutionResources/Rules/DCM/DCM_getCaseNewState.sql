declare
  v_state nvarchar2(255);
begin
  begin
    select col_activity into v_state from tbl_dict_casestate where col_isdefaultoncreate = 1;
    exception
      when NO_DATA_FOUND then
        v_state := 'root_CS_Status_NEW';
      when TOO_MANY_ROWS then
        v_state := 'root_CS_Status_NEW';
  end;
  return v_state;
end;