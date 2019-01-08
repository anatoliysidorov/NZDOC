declare
  v_NextTaskName nvarchar2(255);
  v_NextTaskOwnerName nvarchar2(255);
  v_NextTaskId Integer;
begin
  v_NextTaskId := :NextTaskId;
  begin
    select tsk.col_name,
           u.name
      into v_NextTaskName, v_NextTaskOwnerName
      from tbl_task tsk
      left join vw_users u ON u.accesssubjectcode = tsk.col_owner
      where tsk.col_id = v_NextTaskId;
      exception
        when no_data_found then
          v_NextTaskOwnerName := null;
          v_NextTaskName := null;
  end;
  :NextTaskName := v_NextTaskName;
  :NextTaskOwnerName := v_NextTaskOwnerName;
end;
