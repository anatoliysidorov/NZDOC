declare
  v_stateid Integer;
begin
  begin
    select col_id into v_stateid from tbl_dict_taskstate where col_isfinish = 1 and nvl(col_stateconfigtaskstate,0) = nvl(:StateConfigId,0);
    exception
      when NO_DATA_FOUND then
        v_stateid := null;
      when TOO_MANY_ROWS then
        v_stateid := null;
  end;
  return v_stateid;
end;