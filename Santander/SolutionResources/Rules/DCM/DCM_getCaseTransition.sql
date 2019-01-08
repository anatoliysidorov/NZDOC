declare
  v_Source nvarchar2(255);
  v_Target nvarchar2(255);
  v_Transition nvarchar2(255);
begin
  v_Source := :Source;
  v_Target := :Target;
  case
    when v_Source = 'root_CS_Status_NEW' and v_Target = 'root_CS_Status_ASSIGNED' then v_Transition := 'NEW_TO_ASSIGNED';
    when v_Source = 'root_CS_Status_NEW' and v_Target = 'root_CS_Status_IN_PROCESS' then v_Transition := 'NEW_TO_IN_PROCESS';
    when v_Source = 'root_CS_Status_ASSIGNED' and v_Target = 'root_CS_Status_IN_PROCESS' then v_Transition := 'ASSIGNED_TO_IN_PROCESS';
    when v_Source = 'root_CS_Status_ASSIGNED' and v_Target = 'root_CS_Status_ASSIGNED' then v_Transition := 'ASSIGNED_TO_ASSIGNED';
    when v_Source = 'root_CS_Status_IN_PROCESS' and v_Target = 'root_CS_Status_FIXED' then v_Transition := 'IN_PROCESS_TO_FIXED';
    when v_Source = 'root_CS_Status_FIXED' and v_Target = 'root_CS_Status_RESOLVED' then v_Transition := 'FIXED_TO_RESOLVED';
    when v_Source = 'root_CS_Status_FIXED' and v_Target = 'root_CS_Status_IN_PROCESS' then v_Transition := 'FIXED_TO_IN_PROCESS';
    when v_Source = 'root_CS_Status_RESOLVED' and v_Target = 'root_CS_Status_CLOSED' then v_Transition := 'RESOLVED_TO_CLOSED';
    when v_Source = 'root_CS_Status_CLOSED' and v_Target = 'root_CS_Status_IN_PROCESS' then v_Transition := 'CLOSED_TO_IN_PROCESS';
    else v_Transition := 'NONE';
  end case;
  return v_Transition;
end;