declare
  v_queueParams nclob;
  v_UserAccessSubject nvarchar2(255);
  v_Domain nvarchar2(255);
  v_RuleCode nvarchar2(255);
  v_result number;
  v_TaskId Integer;
begin
  v_TaskId := :TaskId;
  --READ USER ACCESS SUBJECT FROM CLIENT CONTEXT
  begin
  v_RuleCode := '';
  select sys_context('CLIENTCONTEXT', 'AccessSubject') into v_UserAccessSubject from dual;
    exception
	  when NO_DATA_FOUND then
	    v_UserAccessSubject := null;
  end;
  --READ DOMAIN FROM CONFIGURATION
  v_Domain := f_UTIL_getDomainFn();
  --START TASKS FOR ALL CASES IN TASK EVENT QUEUE
  for rec in (select teq.col_id as TeqId, teq.col_taskeventqueuetaskevent as TeId, te.col_processorcode as ProcessorCode
                   from tbl_taskeventqueue teq
                   inner join tbl_taskevent te on teq.col_taskeventqueuetaskevent = te.col_id
                   inner join tbl_map_taskstateinitiation mtsi on te.col_taskeventtaskstateinit = mtsi.col_id
                   inner join tbl_task tsk on mtsi.col_map_taskstateinittask = tsk.col_id
                   where tsk.col_id = v_TaskId)
  loop
    v_queueParams := f_util_getJSONfromAutoRulePrm(rec.TeId);
    v_result := f_UTIL_addToQueueFn(RuleCode => rec.ProcessorCode, Parameters => v_queueParams);
    delete from tbl_taskeventqueue where col_id = rec.TeqId;
  end loop;
end;