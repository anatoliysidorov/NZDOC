--CHECK IF CURRENT TASK CAN BE CLOSED
--TASK CLOSING IS BASED ON FF DEPENDENCY TYPE
--CHECK IF CURRENT TASK HAS DEPENDENCIES OF FF TYPE ON OTHER UNCLOSED TASKS
--IF UNCLOSED PARENT TASKS ARE FOUND CURRENT TASK (SPECIFIED AS INPUT PARAMETER) CANNOT BE CLOSED
declare
  v_TaskId Integer;
  v_count Integer;
  v_result number;
begin
  v_TaskId := :TaskId;
  begin
    --FIND PARENT TASKS FOR CURRENT TASK THAT ARE NOT CLOSED
    select count(*) into v_count
      from
        (select tskp.col_id, td.col_tskdpndchldtskstateinit
           from tbl_taskdependency td
           inner join tbl_map_taskstateinitiation tsip on td.col_tskdpndprnttskstateinit = tsip.col_id
           inner join tbl_task tskp on tsip.col_map_taskstateinittask = tskp.col_id
           inner join tbl_map_taskstateinitiation tsic on td.col_tskdpndchldtskstateinit = tsic.col_id
           inner join tbl_task tskc on tsic.col_map_taskstateinittask = tskc.col_id
           where tskc.col_id = v_TaskId
           and td.col_type = 'FF'
           and tskc.col_dateclosed is null);
	exception
	  when NO_DATA_FOUND then
	    v_count := null;
  end;
  if (v_count is not null) and (v_count > 0) then
    v_result := -1;
  else
    v_result := 0;
  end if;
  :result := v_result;
end;