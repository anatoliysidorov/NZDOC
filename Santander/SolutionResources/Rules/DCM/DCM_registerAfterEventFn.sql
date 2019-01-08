declare
  v_TaskId Integer;
  v_TaskEventMoment nvarchar2(255);
  v_result number;
begin
  v_TaskId := :TaskId;
  v_TaskEventMoment := 'after';
  begin
    insert into tbl_taskeventqueue (col_taskeventqueuetaskevent, col_taskeventqueueprocstatus)
     (select te.col_id, (select col_id from tbl_dict_processingstatus where col_code = 'NEW')
        from tbl_taskevent te
        inner join tbl_dict_taskeventmoment dtem on te.col_taskeventmomenttaskevent = dtem.col_id
        inner join tbl_dict_taskeventtype dtet on te.col_taskeventtypetaskevent = dtet.col_id
        inner join tbl_map_taskstateinitiation mtsi on te.col_taskeventtaskstateinit = mtsi.col_id
        inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
        inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinit_initmtd = dim.col_id
        inner join tbl_task tsk on mtsi.col_map_taskstateinittask = tsk.col_id
        inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id and twi.col_activity = dts.col_activity
        where lower(dtem.col_code) = lower(v_TaskEventMoment)
        --ONLY REGULAR RULES (NOT FUNCTIONS) ARE QUEUED FOR EXECUTION
        and lower(substr(te.col_processorcode, 1, 5)) = 'root_'
        and tsk.col_id = v_TaskId);
    exception
      when DUP_VAL_ON_INDEX then
        return -1;
  end;
  v_result := f_DCM_taskEventQueueProc2(TaskId => v_TaskId);
end;