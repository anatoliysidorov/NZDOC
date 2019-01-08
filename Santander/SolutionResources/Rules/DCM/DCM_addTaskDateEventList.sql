declare
  v_TaskId Integer;
  v_state nvarchar2(255);
  v_result number;
begin
  v_TaskId := :TaskId;
  v_state := :state;
  for rec in
  (select ts.col_id as TaskStateId, ts.col_code as TaskStateCode, ts.col_name as TaskStateName, ts.col_activity as TaskStateActivity,
          det.col_id as DateEventTypeId, det.col_code as DateEventTypeCode, det.col_name as DateEventTypeName
   from tbl_dict_taskstate ts
   inner join tbl_dict_tskst_dtevtp tsdet on ts.col_id = tsdet.col_tskst_dtevtptaskstate
   inner join tbl_dict_dateeventtype det on tsdet.col_tskst_dtevtpdateeventtype = det.col_id
   where ts.col_activity = v_state)
   loop
     v_result := f_DCM_createTaskDateEvent (Name => rec.DateEventTypeCode, TaskId => v_TaskId);
   end loop;
end;