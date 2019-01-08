declare
  v_result number;
  v_CaseId Integer;
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
begin
  v_CaseId := :CaseId;
  for rec in (select tsk.col_id as TaskId, tsk.col_casetask as CaseId, se.col_id as SlaEventId, se.col_intervalds as IntervalDS, se.col_intervalym as IntervalYM
    from tbl_task tsk
    inner join tbl_slaevent se on tsk.col_id = se.col_slaeventtask
    where tsk.col_casetask = v_CaseId)
  loop
    v_result := f_SLA_taskClearHoldFn(ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, TaskId => rec.TaskId);
    :ErrorCode := v_ErrorCode;
    :ErrorMessage := v_ErrorMessage;
  end loop;
end;