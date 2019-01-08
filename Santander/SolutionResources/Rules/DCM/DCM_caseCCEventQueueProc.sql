declare
  v_queueParams nclob;
  v_UserAccessSubject nvarchar2(255);
  v_Domain nvarchar2(255);
  v_RuleCode nvarchar2(255);
  v_result number;
  v_CaseId Integer;
begin
  v_CaseId := :CaseId;
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
  for rec in (select ceq.col_id as CeqId, ceq.col_caseeventqueuecaseevent as CeId, ce.col_processorcode as ProcessorCode
                   from tbl_caseeventqueue ceq
                   inner join tbl_caseeventcc ce on ceq.col_caseeventqueuecaseevent = ce.col_id
                   inner join tbl_map_casestateinitcc mcsi on ce.col_caseeventcccasestinitcc = mcsi.col_id
                   inner join tbl_casecc cs on mcsi.col_map_casestateinitcccasecc = cs.col_id
                   where cs.col_id = v_CaseId)
  loop
    v_queueParams := f_util_getJSONCaseCCRulePrm(rec.CeId);
    v_result := f_UTIL_addToQueueFn(RuleCode => rec.ProcessorCode, Parameters => v_queueParams);
    delete from tbl_caseeventqueue where col_id = rec.CeqId;
  end loop;
end;