DECLARE
  v_TaskId number;
  v_Body nvarchar2(255);
  v_phonenumber nvarchar2(255);
  v_errorCode number;
  v_errorMessage nvarchar2(255);
  v_queueParams nclob;
  v_UserAccessSubject nvarchar2(255);
  v_Domain nvarchar2(255);
  v_RuleCode nvarchar2(255);
  v_result number;
BEGIN
  v_errorCode := 0;
  v_errorMessage := '';
  v_TaskId := :TaskId;
  v_Body := 'Task '||v_Taskid ||' was assigned to you';
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
  BEGIN
  select  Usr.Phone
  into v_phonenumber
  from tbl_task t
  left join Tbl_Ppl_Workbasket wb on wb.col_id = T.Col_Taskppl_Workbasket
  left join Tbl_Ppl_Caseworker cw
  on cw.col_id = Wb.Col_Caseworkerworkbasket
  left join vw_users usr on Usr.Userid = Cw.Col_Userid
  left join Tbl_Dict_Workbaskettype wbt
  on wbt.col_id = Wb.Col_Workbasketworkbaskettype
  where  t.col_id = v_taskid and lower(Wbt.Col_Code) = 'personal';
  
  v_queueParams := '[{"Name":"PhoneNumber","Value":"'||v_phonenumber||'"},{"Name":"Message","Value":"'||v_Body||'"}]';
  v_result := f_UTIL_addToQueueFn(RuleCode => 'root_INT_TWLO_sendSMS', Parameters => v_queueParams);
  v_result := f_DCM_createTaskHistory(IsSystem => 0, TaskId => v_taskid, MessageCode =>'SMSEvent');
  EXCEPTION WHEN NO_DATA_FOUND THEN
  v_errorCode := 121;
  v_errorMessage := 'No information was found';
  END;
  <<cleanup>>
 
  dbms_output.put_line(v_errorMessage);
END;