declare
  v_processedstatus number;
  v_errorstatus number;
  v_stateResolved nvarchar2(255);
  v_CaseId Integer;
  v_result number;
begin
  v_stateResolved := f_dcm_getTaskResolvedState();
  for rec in (select col_id,col_queueeventid,col_taskeventqueuetask from tbl_taskeventqueue where col_queueeventid is not null)
  loop
    begin
      select processedstatus,errorstatus into v_processedstatus,v_errorstatus from queue_event where queueid = rec.col_queueeventid;
      exception
        when NO_DATA_FOUND then
          continue;
    end;
    if v_processedstatus < 8 then
      begin
        select col_casecctaskcc into v_CaseId from tbl_taskcc where col_id = rec.col_taskeventqueuetask;
        exception
        when NO_DATA_FOUND then
          v_CaseId := null;
      end;
      --INVALIDATE CASE WHERE TASKS CHANGED THEIR STATE
      if v_CaseId is not null then
        v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
      end if;
      continue;
    end if;
    if v_errorstatus = 1 then
      update tbl_tw_workitemcc set col_activity = v_stateResolved, col_tw_workitemccprevtaskst = col_tw_workitemccdict_taskst, col_tw_workitemccdict_taskst = (select col_id from tbl_dict_taskstate where col_activity = v_stateResolved)
        where col_id = (select col_tw_workitemcctaskcc from tbl_taskcc where col_id = rec.col_taskeventqueuetask);
      --SET TASK DATE EVENT
      v_result := f_DCM_createTaskDateEventCC (Name => 'DATE_TASK_RESOLVED', TaskId => rec.col_taskeventqueuetask);
      delete from tbl_taskeventqueue where col_id = rec.col_id;
      begin
        select col_casecctaskcc into v_CaseId from tbl_taskcc where col_id = rec.col_taskeventqueuetask;
        exception
        when NO_DATA_FOUND then
          v_CaseId := null;
      end;
      --INVALIDATE CASE WHERE TASKS CHANGED THEIR STATE
      if v_CaseId is not null then
        v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
      end if;
    elsif v_errorstatus > 1 then
      --PROCESS ERROR IN QUEUE EVENT PROCESSING
      delete from tbl_taskeventqueue where col_id = rec.col_id;
    end if;
  end loop;
end;