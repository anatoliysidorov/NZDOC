  declare
  v_minOrder Integer;
  v_maxOrder Integer;
  v_counter Integer;
  v_strFields nclob;
  v_valueStr nclob;
  v_value nvarchar2(255);
  v_value2 nvarchar2(255);
  ExtCode nvarchar2(255);
  ActivityCode nvarchar2(255);
  CaseId nvarchar2(255);
  ContactInfo nvarchar2(255);
  CreatedBy nvarchar2(255);
  CreatedDate date;
  CW_ActivityCode nvarchar2(255);
  CW_WorkflowCode nvarchar2(255);
  Description nclob;
  FirstTimeComm number;
  InfoFrom nvarchar2(255);
  OccuranceDate date;
  Owner nvarchar2(255);
  OwnerLogin nvarchar2(255);
  CaseOwner nvarchar2(255);
  Prefix nvarchar2(255);
  Priority nvarchar2(255);
  PriorityValue number;
  PriorityCase Integer;
  ProcedureId Integer;
  ProcedureName nvarchar2(255);
  Reason nvarchar2(255);
  ReportingReqs nvarchar2(255);
  Summary nvarchar2(255);
  Company nvarchar2(255);
  Location nclob;
  PrimaryContact nclob;
  ReportedDate date;
  ServiceDate date;
  InvolvedParty1 nclob;
  InvolvedParty2 nclob;
  OffSite number;
  TaskOwner nvarchar2(255);
  TOKEN_DOMAIN nvarchar2(255);
  TOKEN_USERACCESSSUBJECT nvarchar2(255);
  TOKEN_SYSTEMDOMAINUSER nvarchar2(255);
  TskPrefix nvarchar2(255);
  WorkflowCode nvarchar2(255);
  v_Return number;
  v_Result number;
  v_query varchar2(5000);
  affectedRows number;
  ErrorCode number;
  ErrorMessage nvarchar2(255);
  RecordId Integer;
  RecordIdExt Integer;
  begin
  v_minOrder := :minOrder;
  v_maxOrder := :maxOrder;
  v_strFields := :strFields;
  v_valueStr := :valueStr;
  TOKEN_DOMAIN := :p_TOKEN_DOMAIN;
  TOKEN_USERACCESSSUBJECT := :p_TOKEN_USERACCESSSUBJECT;
  TOKEN_SYSTEMDOMAINUSER := :p_TOKEN_SYSTEMDOMAINUSER;
  ExtCode := :p_ExtCode;
  ActivityCode := :p_ActivityCode;
  CW_ActivityCode := :p_CaseActivityCode;
  CW_WorkflowCode := :p_CaseWorkflowCode;
  WorkflowCode := :p_WorkflowCode;
  CreatedBy := :p_CreatedBy;
  CreatedDate := :p_CreatedDate;
  Prefix := :p_Prefix;
  TaskOwner := :p_TaskOwner;
  TskPrefix := :p_TaskPrefix;
  CaseId := :pi_CaseId;
  
  for v_counter in v_minOrder .. v_maxOrder
  loop
  v_Result := f_dcm_extractvaluebyposition(counter => v_counter, fieldName => v_value, fieldvalue => v_value2, strFields => v_strFields, valueStr => v_valueStr);
  if (v_value = 'TaskActivityCode') then
  ActivityCode := v_value2;
  dbms_output.put_line('ActivityCode:' || v_value2);
  elsif (v_value = 'CaseId') then
  CaseId := v_value2;
  dbms_output.put_line('CaseId:' || v_value2);
  elsif (v_value = 'ContactInfo') then
  ContactInfo := v_value2;
  dbms_output.put_line('ContactInfo:' || v_value2);
  elsif (v_value = 'CreatedBy') then
  CreatedBy := v_value2;
  dbms_output.put_line('CreatedBy:' || v_value2);
  elsif (v_value = 'CreatedDate') then
  CreatedDate := v_value2;
  dbms_output.put_line('CreatedDate:' || v_value2);
  elsif (v_value = 'CaseActivityCode') then
  CW_ActivityCode := v_value2;
  dbms_output.put_line('CW_ActivityCode:' || v_value2);
  elsif (v_value = 'CaseWorkflowCode') then
  CW_WorkflowCode := v_value2;
  dbms_output.put_line('CW_WorkflowCode:' || v_value2);
  elsif (v_value = 'Description') then
  Description := v_value2;
  dbms_output.put_line('Description:' || v_value2);
  elsif (v_value = 'FirstTimeComm') then
  FirstTimeComm := v_value2;
  dbms_output.put_line('FirstTimeComm:' || v_value2);
  elsif (v_value = 'InfoFrom') then
  InfoFrom := v_value2;
  dbms_output.put_line('InfoFrom:' || v_value2);
  elsif (v_value = 'OccuranceDate') then
  OccuranceDate := v_value2;
  dbms_output.put_line('OccuranceDate:' || v_value2);
  elsif (v_value = 'CaseOwner') then
  Owner := v_value2;
  dbms_output.put_line('Owner:' || v_value2);
  elsif (v_value = 'CaseOwnerLogin') then
  OwnerLogin := v_value2;
  dbms_output.put_line('OwnerLogin:' || v_value2);
  begin
  v_query := 'select uas.code from ' || TOKEN_SYSTEMDOMAINUSER || '.asf_accesssubject uas left join ' || TOKEN_SYSTEMDOMAINUSER || '.asf_user us on uas.accesssubjectid = us.accesssubjectid ' ||
  ' where lower(us.login) = lower(''' || OwnerLogin || ''')';
  execute immediate v_query into CaseOwner;
  exception
  when NO_DATA_FOUND then
  CaseOwner := null;
  end;
  if (CaseOwner is not null) then
  Owner := CaseOwner;
  dbms_output.put_line('Owner by Login:' || Owner);
  end if;
  elsif (v_value = 'CasePrefix') then
  Prefix := v_value2;
  dbms_output.put_line('Prefix:' || v_value2);
  elsif (v_value = 'Priority') then
  Priority := v_value2;
  dbms_output.put_line('Priority:' || v_value2);
  elsif (v_value = 'PriorityValue') then
  PriorityValue := v_value2;
  dbms_output.put_line('PriorityValue:' || v_value2);
  begin
  select col_id into PriorityCase from tbl_stp_priority where col_value = PriorityValue;
  exception
  when NO_DATA_FOUND then
  PriorityCase := null;
  end;
  elsif (v_value = 'PriorityCase') then
  PriorityCase := v_value2;
  dbms_output.put_line('PriorityCase:' || v_value2);
  elsif (v_value = 'ProcedureId') then
  ProcedureId := v_value2;
  dbms_output.put_line('ProcedureId:' || v_value2);
  elsif (v_value = 'ProcedureName') then
  ProcedureName := v_value2;
  dbms_output.put_line('ProcedureName:' || v_value2);
  begin
  select col_id into ProcedureId from tbl_procedure where col_name = ProcedureName;
  exception
  when NO_DATA_FOUND then
  ProcedureId := null;
  end;
  elsif (v_value = 'Reason') then
  Reason := v_value2;
  dbms_output.put_line('Reason:' || v_value2);
  elsif (v_value = 'ReportingReqs') then
  ReportingReqs := v_value2;
  dbms_output.put_line('ReportingReqs:' || v_value2);
  elsif (v_value = 'Summary') then
  Summary := v_value2;
  dbms_output.put_line('Summary:' || v_value2);
  elsif (v_value = 'Company') then
  Company := v_value2;
  dbms_output.put_line('Company:' || v_value2);
  elsif (v_value = 'Location') then
  Location := v_value2;
  dbms_output.put_line('Location:' || v_value2);
  elsif (v_value = 'TaskOwner') then
  TaskOwner := v_value2;
  dbms_output.put_line('TaskOwner:' || v_value2);
  elsif (v_value = 'PrimaryContact') then
  PrimaryContact := v_value2;
  dbms_output.put_line('PrimaryContact:' || v_value2);
  elsif (v_value = 'ReportedDate') then
  ReportedDate := v_value2;
  dbms_output.put_line('ReportedDate:' || v_value2);
  elsif (v_value = 'ServiceDate') then
  ServiceDate := v_value2;
  dbms_output.put_line('ServiceDate:' || v_value2);
  elsif (v_value = 'TOKEN_DOMAIN') then
  TOKEN_DOMAIN := v_value2;
  dbms_output.put_line('TOKEN_DOMAIN:' || v_value2);
  elsif (v_value = 'TOKEN_USERACCESSSUBJECT') then
  TOKEN_USERACCESSSUBJECT := v_value2;
  dbms_output.put_line('TOKEN_USERACCESSSUBJECT:' || v_value2);
  elsif (v_value = 'TaskPrefix') then
  TskPrefix := v_value2;
  dbms_output.put_line('TskPrefix:' || v_value2);
  elsif (v_value = 'TaskWorkflowCode') then
  WorkflowCode := v_value2;
  dbms_output.put_line('WorkflowCode:' || v_value2);
  end if;
  end loop;
  
  v_query := 'begin ' ||
    ':' || 'v_Return :=  f_dcm_createfncase(ExtCode => ' || ':' || 'ExtCode, ActivityCode => ' || ':' || 'ActivityCode, AffectedRows => ' || ':' || 'AffectedRows, CaseId => ' || ':' || 'CaseId, ContactInfo => ' || ':' || 'ContactInfo,
    CreatedBy => ' || ':' || 'CreatedBy, CreatedDate => ' || ':' || 'CreatedDate, CW_ActivityCode => ' || ':' || 'CW_ActivityCode, CW_WorkflowCode => ' || ':' || 'CW_WorkflowCode, Description => ' || ':' || 'Description,
    ErrorCode => ' || ':' || 'ErrorCode, ErrorMessage => ' || ':' || 'ErrorMessage, FirstTimeComm => ' || ':' || 'FirstTimeComm, InfoFrom => ' || ':' || 'InfoFrom, OccuranceDate => ' || ':' || 'OccuranceDate,
    Owner => ' || ':' || 'Owner, Prefix => ' || ':' || 'Prefix, Priority => ' || ':' || 'Priority, PriorityCase => ' || ':' || 'PriorityCase, ProcedureId => ' || ':' || 'ProcedureId, Reason => ' || ':' || 'Reason,
    RecordId => ' || ':' || 'RecordId, RecordIdExt => ' || ':' || 'RecordIdExt, ReportingReqs => ' || ':' || 'ReportingReqs, Summary => ' || ':' || 'Summary, TaskOwner => ' || ':' || 'TaskOwner,
    Company => ' || ':' || 'Company, Location => ' || ':' || 'Location, PrimaryContact => ' || ':' || 'PrimaryContact, ReportedDate => ' || ':' || 'ReportedDate, ServiceDate => ' || ':' || 'ServiceDate,
    InvolvedParty1 => ' || ':' || 'InvolvedParty1, InvolvedParty2 => ' || ':' || 'InvolvedParty2, OffSite => ' || ':' || 'OffSite,
    TOKEN_DOMAIN => ' || ':' || 'TOKEN_DOMAIN, TOKEN_USERACCESSSUBJECT => ' || ':' || 'TOKEN_USERACCESSSUBJECT, TskPrefix => ' || ':' || 'TskPrefix, WorkflowCode => ' || ':' || 'WorkflowCode); end;';

  -- Invoke case creation function to create case and related tasks, workitems etc.
  execute immediate v_query using OUT v_Return, ExtCode, ActivityCode, OUT affectedRows, OUT CaseId, ContactInfo, CreatedBy, CreatedDate,
                                      CW_ActivityCode, CW_WorkflowCode, Description, OUT ErrorCode, OUT ErrorMessage,
                                      FirstTimeComm, InfoFrom, OccuranceDate, Owner, Prefix, Priority, PriorityCase, ProcedureId,
                                      Reason, OUT RecordId, OUT RecordIdExt, ReportingReqs, Summary, TaskOwner,
                                      Company, Location, PrimaryContact, ReportedDate, ServiceDate,
                                      InvolvedParty1, InvolvedParty2, OffSite,
                                      TOKEN_DOMAIN, TOKEN_USERACCESSSUBJECT, TskPrefix, WorkflowCode;
  commit;
  :p_caseId := CaseId;
  :p_recordId := RecordId;
  :p_recordIdExt := RecordIdExt;
end;
