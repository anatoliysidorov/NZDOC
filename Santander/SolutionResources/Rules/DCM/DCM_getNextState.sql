declare
  v_state nvarchar2(255);
  v_nextstate nvarchar2(255);
begin
  v_state := :TaskState;
  case
    when lower(v_state) = 'new' then v_nextstate := 'Started';
    when lower(v_state) = 'started' then v_nextstate := 'Assigned';
    when lower(v_state) = 'assigned' then v_nextstate := 'In Process';
    when lower(v_state) = 'in process' then v_nextstate := 'Resolved';
    when lower(v_state) = 'resolved' then v_nextstate := 'Closed';
    else v_nextstate := 'None';
  end case;
  return v_nextstate;
end;