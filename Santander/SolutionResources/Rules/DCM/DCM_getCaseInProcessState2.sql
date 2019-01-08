declare
  v_stateid Integer;
  v_state nvarchar2(255);
  v_stateconfigid Integer;
begin
  v_stateconfigid := :StateConfigId;
  begin
    select col_id, col_activity into v_stateid, v_state from tbl_dict_casestate where col_isdefaultoncreate2 = 1 and nvl(col_stateconfigcasestate,0) = nvl(v_stateconfigid,0);
    exception
      when NO_DATA_FOUND then
        v_state := 'root_CS_Status_IN_PROCESS';
      when TOO_MANY_ROWS then
        v_state := 'root_CS_Status_IN_PROCESS';
  end;
  return v_state;
end;