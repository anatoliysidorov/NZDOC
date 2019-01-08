declare
  v_TaskId Integer;
  v_result number;
begin
  v_TaskId := :TaskId;
  begin
    select count(*) into v_result from tbl_task chldtsk2
    inner join tbl_tw_workitem chldtwi on chldtsk2.col_tw_workitemtask = chldtwi.col_id
    inner join tbl_map_taskstateinitiation chldmtsi on chldtsk2.col_id = chldmtsi.col_map_taskstateinittask
    inner join tbl_taskdependency td on chldmtsi.col_id = td.col_tskdpndchldtskstateinit and td.col_type = 'FSCA'
    inner join tbl_map_taskstateinitiation mtsi on td.col_tskdpndprnttskstateinit = mtsi.col_id
    inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
    inner join tbl_task tsk on mtsi.col_map_taskstateinittask = tsk.col_id
    inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
    where chldtsk2.col_id = v_TaskId
    and ((twi.col_activity <> dts.col_activity)
      or (case when td.col_processorcode is not null and twi.col_activity = dts.col_activity then f_DCM_invokeTaskProcessor2(td.col_processorcode, td.col_id)
               when chldmtsi.col_processorcode is not null and twi.col_activity = dts.col_activity then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode, chldmtsi.col_id)
               else 1 end) <> 1);
    exception
    when NO_DATA_FOUND then
      v_result := 1;
  end;
  if v_result > 0 then
    return 0;
  elsif nvl(v_result, 0) = 0 then
    return 1;
  end if;
end;