declare
v_counter Integer;
v_valueStr nclob;
v_prevPos Integer;
v_nextPos Integer;
v_Result number;
v_line nclob;
ErrorCode number;
ErrorMessage nvarchar2(255);
v_maxOrder Integer;
v_minOrder Integer;
CaseId nvarchar2(255);
RecordId Integer;
RecordIdExt Integer;
v_strFields nclob;
TOKEN_DOMAIN nvarchar2(255);
TOKEN_USERACCESSSUBJECT nvarchar2(255);
TOKEN_SYSTEMDOMAINUSER nvarchar2(255);
ActivityCode nvarchar2(255);
WorkflowCode nvarchar2(255);
CaseActivityCode nvarchar2(255);
CaseWorkflowCode nvarchar2(255);
Prefix nvarchar2(255);
TaskOwner nvarchar2(255);
TaskPrefix nvarchar2(255);
CreatedBy nvarchar2(255);
CreatedDate date;
ExtCode nvarchar2(255);
begin
v_valueStr := :valueStr;
v_maxOrder := :maxOrder;
v_minOrder := :minOrder;
v_strFields := :strFields;
TOKEN_DOMAIN := :p_TOKEN_DOMAIN;
TOKEN_USERACCESSSUBJECT := :p_TOKEN_USERACCESSSUBJECT;
TOKEN_SYSTEMDOMAINUSER := :p_TOKEN_SYSTEMDOMAINUSER;
ActivityCode := :p_ActivityCode;
WorkflowCode := :p_WorkflowCode;
CaseActivityCode := :p_CaseActivityCode;
CaseWorkflowCode := :p_CaseWorkflowCode;
Prefix := :p_Prefix;
TaskOwner := :p_TaskOwner;
TaskPrefix := :p_TaskPrefix;
CaseId := :pi_CaseId;
CreatedBy := :p_CreatedBy;
CreatedDate := :p_CreatedDate;
ExtCode := :p_ExtCode;
v_counter := 0;
DBMS_OUTPUT.ENABLE (buffer_size => NULL);
loop
if (v_counter = 0) then
v_prevPos := 0;
select instr(v_valueStr, CHR(10), 1, v_counter+1) into v_nextPos from dual;
select substr(v_valueStr, v_prevPos + 1, v_nextPos - v_prevPos - 1) into v_line from dual;
if (trim(both ' ' from v_line) is null) then
  exit;
end if;
dbms_output.put_line('v_line: ' || v_line);
-- skip first line of imported file
/*
v_Result := f_dcm_importvalueline(p_ExtCode => ExtCode,
                                  p_ActivityCode => ActivityCode, p_CaseActivityCode => CaseActivityCode, p_CaseWorkflowCode => CaseWorkflowCode, p_Prefix => Prefix, p_TaskOwner => TaskOwner,
                                  p_TaskPrefix => TaskPrefix, p_WorkflowCode => WorkflowCode, pi_CaseId => CaseId,
                                  p_CreatedBy => CreatedBy, p_CreatedDate => CreatedDate,
                                  ErrorCode => ErrorCode, ErrorMessage => ErrorMessage, maxOrder => v_maxOrder, minOrder => v_minOrder, p_caseId => CaseId, p_recordId => RecordId,
                                  p_recordIdExt => RecordIdExt, strFields => v_strFields, p_TOKEN_DOMAIN => TOKEN_DOMAIN, p_TOKEN_USERACCESSSUBJECT => TOKEN_USERACCESSSUBJECT,
                                  p_TOKEN_SYSTEMDOMAINUSER => TOKEN_SYSTEMDOMAINUSER, valueStr => v_line);
*/
v_counter := v_counter + 1;
end if;
select instr(v_valueStr, CHR(10), 1, v_counter) into v_prevPos from dual;
if (v_prevPos = 0) then
  exit;
end if;
select instr(v_valueStr, CHR(10), 1, v_counter+1) into v_nextPos from dual;
if (v_prevPos > 0 AND v_nextPos = 0) then
  v_nextPos := length(v_valueStr) + 1;
end if;
select substr(v_valueStr, v_prevPos + 1, v_nextPos - v_prevPos - 1) into v_line from dual;
if (trim(both ' ' from v_line) is null) then
  exit;
end if;
dbms_output.put_line('v_line: ' || v_line);
v_Result := f_dcm_importvalueline(p_ExtCode => ExtCode,
                                  p_ActivityCode => ActivityCode, p_CaseActivityCode => CaseActivityCode, p_CaseWorkflowCode => CaseWorkflowCode, p_Prefix => Prefix, p_TaskOwner => TaskOwner,
                                  p_TaskPrefix => TaskPrefix, p_WorkflowCode => WorkflowCode, pi_CaseId => CaseId,
                                  p_CreatedBy => CreatedBy, p_CreatedDate => CreatedDate,
                                  ErrorCode => ErrorCode, ErrorMessage => ErrorMessage, maxOrder => v_maxOrder, minOrder => v_minOrder, p_caseId => CaseId, p_recordId => RecordId,
                                  p_recordIdExt => RecordIdExt, strFields => v_strFields, p_TOKEN_DOMAIN => TOKEN_DOMAIN, p_TOKEN_USERACCESSSUBJECT => TOKEN_USERACCESSSUBJECT,
                                  p_TOKEN_SYSTEMDOMAINUSER => TOKEN_SYSTEMDOMAINUSER, valueStr => v_line);
v_counter := v_counter + 1;
end loop;
end;
