declare
  v_queueParams nclob;
  v_UserAccessSubject nvarchar2(255);
  v_Domain nvarchar2(255);
  v_RuleCode nvarchar2(255);
  v_result number;
  v_isValid number;
  v_CaseId Integer;
  v_SlaEventId Integer;
  v_Message nclob;
  v_input nvarchar2(32767);
begin
  v_CaseId := :CaseId;
  v_SlaEventId := 0;
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
  for rec in (select saq.col_id as SaqId, saq.col_slaactionqueueslaaction as SaId, 
                     saq.col_slaactionqueueslaevent as SeId, sa.col_processorcode as ProcessorCode, 
                     tsk.col_id as TaskId,
                     se.col_attemptcount as AttemptCount, se.col_maxattempts as MaxAttempts
                   from tbl_slaactionqueue saq
                   inner join tbl_slaactioncc sa on saq.col_slaactionqueueslaaction = sa.col_id
                   inner join tbl_slaeventcc se on sa.col_slaactionccslaeventcc = se.col_id
                   inner join tbl_taskcc tsk on se.col_slaeventcctaskcc = tsk.col_id
                   where tsk.col_casecctaskcc = v_CaseId
                   and saq.col_slaactionqueueprocstatus = (select col_id from tbl_dict_processingstatus where col_code = 'NEW'))
  loop
    if (substr(rec.ProcessorCode, 1, 2) = 'f_') then
      v_input := '<CustomData><Attributes>';
      
      v_input := v_input ||'<CaseId>'||TO_CHAR(v_CaseId) || '</CaseId>';

      IF rec.TaskId IS NOT NULL THEN
        v_input := v_input ||'<TaskId>'||TO_CHAR(rec.TaskId) || '</TaskId>';
      END IF;
      
      for rec2 in (select col_paramcode as ParamCode, col_paramvalue as ParamValue from tbl_autoruleparamcc where col_autoruleparccslaactioncc = (select col_id from tbl_slaactioncc where col_id = rec.SaId))
      loop
        v_input := v_input || '<' || rec2.ParamCode || '>' || rec2.ParamValue || '</' || rec2.ParamCode || '>';
      end loop;
      v_input := v_input || '</Attributes></CustomData>';
      v_result := f_DCM_invokeslaprocessor2(Input => v_input, Message => v_Message, ProcessorName => rec.ProcessorCode, SlaActionId => rec.SaId, validationresult => v_isValid);
      update tbl_slaactionqueue set col_slaactionqueueprocstatus = (select col_id from tbl_dict_processingstatus where col_code = 'PROCESSED') where col_id = rec.SaqId;
    else
      v_queueParams := f_UTIL_JSONAutoRulePrmSlaCC(rec.SaId);
      v_result := f_UTIL_addToQueueFn(RuleCode => rec.ProcessorCode, Parameters => v_queueParams);
      update tbl_slaactionqueue set col_queueeventid = v_result, col_slaactionqueueprocstatus = (select col_id from tbl_dict_processingstatus where col_code = 'PROCESSED') where col_id = rec.SaqId;
    end if;
    if v_SlaEventId <> rec.SeId then
      update tbl_slaeventcc set col_attemptcount = col_attemptcount + 1 where col_id = rec.SeId;
      if (rec.AttemptCount + 1) < rec.MaxAttempts then
        delete from tbl_slaactionqueue where col_slaactionqueueslaevent = rec.SeId;
      end if;
      v_SlaEventId := rec.SeId;
    end if;
  end loop;
end;