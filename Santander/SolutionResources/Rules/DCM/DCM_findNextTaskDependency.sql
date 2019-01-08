declare
  v_TaskId Integer;
  v_NextTaskId Integer;
  v_count Integer;
  v_result number;
  v_affectedRows Integer;
begin
  v_TaskId := :TaskId;
  begin
    --FIND ALL DEPENDENT TASKS FROM CURRENT TASK
	--SELECT TASKS THAT ARE NOT STARTED (DATE ASSIGNED IS NULL)
    for rec in (select col_id from tbl_task
                  where col_id in
                    (select td.col_tskdpndchldtskstateinit from tbl_taskdependency td
                       inner join tbl_map_taskstateinitiation tsi on td.col_tskdpndchldtskstateinit = tsi.col_id
                       inner join tbl_map_taskstateinitiation tsi2 on td.col_tskdpndprnttskstateinit = tsi2.col_id
                       inner join tbl_task tsk on tsi.col_map_taskstateinittask = tsk.col_id
                       inner join tbl_task tsk2 on tsi2.col_map_taskstateinittask = tsk2.col_id
                       where tsk2.col_id = v_TaskId
					   and tsk2.col_dateclosed is not null)
                  and col_id not in
                    (select td.col_tskdpndchldtskstateinit from tbl_taskdependency td
                       inner join tbl_map_taskstateinitiation tsi on td.col_tskdpndchldtskstateinit = tsi.col_id
                       inner join tbl_map_taskstateinitiation tsi2 on td.col_tskdpndprnttskstateinit = tsi2.col_id
                       inner join tbl_task tsk on tsi.col_map_taskstateinittask = tsk.col_id
                       inner join tbl_task tsk2 on tsi2.col_map_taskstateinittask = tsk2.col_id
                       where tsk2.col_id = v_TaskId
					   and tsk2.col_dateclosed is null)
                  and col_enabled = 0 and col_dateassigned is null)
	  loop
	    --FIND PARENT TASKS FOR CURRENT CHILD TASK THAT IS NOT CLOSED YET
		--IF NOT CLOSED PARENT TASK EXISTS, CHILD TASK CANNOT BE ENABLED
	    select count(*) into v_count from tbl_task where col_id = rec.col_id and col_id in
          (select td.col_tskdpndchldtskstateinit
            from tbl_taskdependency td
            inner join tbl_map_taskstateinitiation tsi on td.col_tskdpndchldtskstateinit = tsi.col_id
            inner join tbl_task tsk on tsi.col_map_taskstateinittask = tsk.col_id
            where td.col_tskdpndprnttskstateinit in (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask <> v_TaskId)
            and tsk.col_dateclosed is null);
        --IF PARENT TASKS NOT FOUND, ENABLE CURRENT CHILD TASK
        if (v_count is null) or (v_count = 0) then
          v_NextTaskId := rec.col_id;
	      --INVOKE NEXT TASK INITIATION FUNCTION
		  --FUNCTION CALL WILL BE PLACED HERE WHEN FUNCTION IS READY
		  ----------------------------------------------------------
		  v_result := f_DCM_initNextTask(NextTaskId => v_NextTaskId);
		  ----------------------------------------------------------
        end if;
	  end loop;
  end;
end;
