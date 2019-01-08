declare
  v_activity nvarchar2(255);
  v_prevactivity nvarchar2(255);
  v_transition nvarchar2(255);
begin
  v_activity := :CaseActivity;
  v_transition := :Transition;
  case
    when v_activity = 'root_CS_Status_ASSIGNED' and v_transition = 'NEW_TO_ASSIGNED' then v_prevactivity := 'root_CS_Status_NEW';
    when v_activity = 'root_CS_Status_ASSIGNED' and v_transition = 'ASSIGNED_TO_ASSIGNED' then v_prevactivity := 'root_CS_Status_ASSIGNED';
    when v_activity = 'root_CS_Status_ASSIGNED' then v_prevactivity := 'root_CS_Status_NEW';
    when v_activity = 'root_CS_Status_IN_PROCESS' and v_transition = 'NEW_TO_IN_PROCESS' then v_prevactivity := 'root_CS_Status_NEW';
    when v_activity = 'root_CS_Status_IN_PROCESS' and v_transition = 'ASSIGNED_TO_IN_PROCESS' then v_prevactivity := 'root_CS_Status_ASSIGNED';
    when v_activity = 'root_CS_Status_IN_PROCESS' and v_transition = 'FIXED_TO_IN_PROCESS' then v_prevactivity := 'root_CS_Status_FIXED';
    when v_activity = 'root_CS_Status_IN_PROCESS' and v_transition = 'CLOSED_TO_IN_PROCESS' then v_prevactivity := 'root_CS_Status_CLOSED';
    when v_activity = 'root_CS_Status_IN_PROCESS' then v_prevactivity := 'root_CS_Status_NEW';
    when v_activity = 'root_CS_Status_FIXED' and v_transition = 'IN_PROCESS_TO_FIXED' then v_prevactivity := 'root_CS_Status_IN_PROCESS';
    when v_activity = 'root_CS_Status_FIXED' then v_prevactivity := 'root_CS_Status_IN_PROCESS';
    when v_activity = 'root_CS_Status_RESOLVED' and v_transition = 'FIXED_TO_RESOLVED' then v_prevactivity := 'root_CS_Status_FIXED';
    when v_activity = 'root_CS_Status_RESOLVED' then v_prevactivity := 'root_CS_Status_FIXED';
    when v_activity = 'root_CS_Status_CLOSED' and v_transition = 'RESOLVED_TO_CLOSED' then v_prevactivity := 'root_CS_Status_RESOLVED';
    when v_activity = 'root_CS_Status_CLOSED' and v_transition = 'FIXED_TO_CLOSED' then v_prevactivity := 'root_CS_Status_FIXED';
    when v_activity = 'root_CS_Status_CLOSED' then v_prevactivity := 'root_CS_Status_RESOLVED';
    else v_prevactivity := 'NONE';
  end case;
  return v_prevactivity;
end;