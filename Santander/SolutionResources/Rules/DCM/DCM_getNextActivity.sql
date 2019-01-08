declare
  v_activity nvarchar2(255);
  v_nextactivity nvarchar2(255);
begin
  v_activity := :TaskActivity;
  case
    when v_activity = 'root_TSK_Status_NEW' then v_nextactivity := 'root_TSK_Status_STARTED';
    when v_activity = 'root_TSK_Status_STARTED' then v_nextactivity := 'root_TSK_Status_ASSIGNED';
    when v_activity = 'root_TSK_Status_ASSIGNED' then v_nextactivity := 'root_TSK_Status_IN_PROCESS';
    when v_activity = 'root_TSK_Status_IN_PROCESS' then v_nextactivity := 'root_TSK_Status_RESOLVED';
    when v_activity = 'root_TSK_Status_RESOLVED' then v_nextactivity := 'root_TSK_Status_CLOSED';
    else v_nextactivity := 'NONE';
  end case;
  return v_nextactivity;
end;