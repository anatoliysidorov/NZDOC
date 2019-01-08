declare
  v_CaseId Integer;
  v_TaskId Integer;
  v_CaseworkerId Integer;
  v_CWAccessSubjectCode nvarchar2(255);
  v_NotificationTypeCode nvarchar2(255);
  v_MessageCode nvarchar2(255);
  v_ObjectCode nvarchar2(255);
  v_NotificationTypeId Integer;
  v_result nclob;
begin
  v_CaseId := :CaseId;
  v_TaskId := :TaskId;
  if v_CaseId is null then
    begin
      select col_casetask into v_CaseId from tbl_task where col_id = v_TaskId;
      exception
      when NO_DATA_FOUND then
        return -1;
    end;
  end if;
  v_CWAccessSubjectCode :=  sys_context('CLIENTCONTEXT','AccessSubject');
  v_NotificationTypeCode := :NotificationTypeCode;
  begin
    select nt.col_id, msg.col_code, nob.col_code into v_NotificationTypeId, v_MessageCode, v_ObjectCode
    from tbl_dict_notificationtype nt
    inner join tbl_message msg on nt.col_notificationtypemessage = msg.col_id
    inner join tbl_dict_notificationobject nob on nt.col_notifictypenotifobject = nob.col_id
    where nt.col_code = v_NotificationTypeCode;
    exception
    when NO_DATA_FOUND then
      return -1;
    when TOO_MANY_ROWS then
      return -1;
  end;
  for rec in (
  select ss.col_id as SubscriptionId, ss.col_code as SubscriptionCode, ss.col_name as SubscriptionName, ss.col_subscriptioncase as CaseId
  from tbl_subscription ss
  inner join tbl_caseworkersubscription cws on ss.col_id = cws.col_cwsubscripsubscription
  inner join vw_ppl_activecaseworkersusers cwu on cws.col_cwsubscriptioncaseworker = cwu.id
  where ss.col_subscriptioncase = v_CaseId /*cwu.accode = v_CWAccessSubjectCode*/)
  loop
    if v_ObjectCode = 'CASE' then
      v_result := f_HIST_genMsgFromTplFn(TargetType=>'case', TargetId=>v_caseid, MessageCode=> v_messagecode)	;
    elsif v_ObjectCode = 'TASK' then
      v_result := f_HIST_genMsgFromTplFn(TargetType=>'task', TargetId=>v_TaskId, MessageCode=> v_MessageCode);
    end if;      
    insert into tbl_notification(col_description,col_notifnotiftype,col_notificationsubscription)
                          values(v_result,v_NotificationTypeId,rec.SubscriptionId);
  end loop;
end;