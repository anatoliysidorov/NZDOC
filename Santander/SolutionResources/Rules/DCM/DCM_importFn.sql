declare

  v_inputStr nclob;
  v_valueStr nclob;
  v_strFields nclob;
  v_strOrders nclob;
  v_result Integer;

  ErrorCode NUMBER;
  ErrorMessage NVARCHAR2(200);
  v_Return NUMBER;
  
  v_minOrder Integer;
  v_maxOrder Integer;
  
  v_ExtCode nvarchar2(255);
  v_ActivityCode nvarchar2(255);
  v_WorkflowCode nvarchar2(255);
  v_CaseActivityCode nvarchar2(255);
  v_CaseWorkflowCode nvarchar2(255);
  v_Prefix nvarchar2(255);
  v_TaskOwner nvarchar2(255);
  v_TaskPrefix nvarchar2(255);
  v_CaseId nvarchar2(255);
  v_CreatedBy nvarchar2(255);
  v_CreatedDate date;

begin
v_inputStr := :inputStr;
v_valueStr := :valueStr;
v_ExtCode := :ExtCode;
v_ActivityCode := :ActivityCode;
v_WorkflowCode := :WorkflowCode;
v_CaseActivityCode := :CaseActivityCode;
v_CaseWorkflowCode := :CaseWorkflowCode;
v_Prefix := :Prefix;
v_TaskOwner := :TaskOwner;
v_TaskPrefix := :TaskPrefix;
v_CaseId := :CaseId;
v_CreatedBy := :TOKEN_USERACCESSSUBJECT;
v_CreatedDate := sysdate;


/*

v_inputStr := '1:' || 'TaskActivityCode|2:' || 'CaseId|3:' || 'ContactInfo|4:' || 'CreatedBy|5:' || 'CreatedDate|6:' || 'CaseActivityCode|7:' || 'CaseWorkflowCode|8:' || 'Description|9:' ||
'FirstTimeComm|10:' || 'InfoFrom|11:' || 'OccuranceDate|12:' || 'CaseOwner|13:' || 'CasePrefix|14:' || 'Priority|15:' || 'PriorityCase|16:' || 'ProcedureId|17:' || 'Reason|18:' || 'ReportingReqs|19:' ||
'Summary|20:' || 'TaskOwner|21:' || 'TOKEN_DOMAIN|22:' || 'TOKEN_USERACCESSSUBJECT|23:' || 'TaskPrefix|24:' || 'TaskWorkflowCode';

v_valueStr := 'root_TSK_Status_NEW,,Test1,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test1,1,Test1,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test1,Test1,Test1,D1161964B806CA8AE040A8C06C1014E8,DCM_Foundation_v1_Production.max,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
root_TSK_Status_NEW,,Test2,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test2,1,Test2,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test2,Test2,Test2,D1161964B806CA8AE040A8C06C1014E8,DCM_Foundation_v1_Production.max,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
root_TSK_Status_NEW,,Test3,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test3,1,Test3,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test3,Test3,Test3,D1161964B806CA8AE040A8C06C1014E8,DCM_Foundation_v1_Production.max,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
root_TSK_Status_NEW,,Test4,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test4,1,Test4,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test4,Test4,Test4,D1161964B806CA8AE040A8C06C1014E8,DCM_Foundation_v1_Production.max,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
root_TSK_Status_NEW,,Test5,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test5,1,Test5,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test5,Test5,Test5,D1161964B806CA8AE040A8C06C1014E8,DCM_Foundation_v1_Production.max,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status';


-- TaskActivityCode removed

v_inputStr := '2:' || 'CaseId|3:' || 'ContactInfo|4:' || 'CreatedBy|5:' || 'CreatedDate|6:' || 'CaseActivityCode|7:' || 'CaseWorkflowCode|8:' || 'Description|9:' ||
'FirstTimeComm|10:' || 'InfoFrom|11:' || 'OccuranceDate|12:' || 'CaseOwner|13:' || 'CasePrefix|14:' || 'Priority|15:' || 'PriorityCase|16:' || 'ProcedureId|17:' || 'Reason|18:' || 'ReportingReqs|19:' ||
'Summary|20:' || 'TaskOwner|21:' || 'TOKEN_DOMAIN|22:' || 'TOKEN_USERACCESSSUBJECT|23:' || 'TaskPrefix|24:' || 'TaskWorkflowCode';

v_valueStr := ',Test1,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test1,1,Test1,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test1,Test1,Test1,D1161964B806CA8AE040A8C06C1014E8,DCM_Foundation_v1_Production.max,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test2,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test2,1,Test2,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test2,Test2,Test2,D1161964B806CA8AE040A8C06C1014E8,DCM_Foundation_v1_Production.max,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test3,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test3,1,Test3,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test3,Test3,Test3,D1161964B806CA8AE040A8C06C1014E8,DCM_Foundation_v1_Production.max,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test4,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test4,1,Test4,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test4,Test4,Test4,D1161964B806CA8AE040A8C06C1014E8,DCM_Foundation_v1_Production.max,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test5,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test5,1,Test5,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test5,Test5,Test5,D1161964B806CA8AE040A8C06C1014E8,DCM_Foundation_v1_Production.max,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status';


-- TOKEN_DOMAIN and TOKEN_USERACCESSSUBJECT removed

v_inputStr := '2:' || 'CaseId|3:' || 'ContactInfo|4:' || 'CreatedBy|5:' || 'CreatedDate|6:' || 'CaseActivityCode|7:' || 'CaseWorkflowCode|8:' || 'Description|9:' ||
'FirstTimeComm|10:' || 'InfoFrom|11:' || 'OccuranceDate|12:' || 'CaseOwner|13:' || 'CasePrefix|14:' || 'Priority|15:' || 'PriorityCase|16:' || 'ProcedureId|17:' || 'Reason|18:' || 'ReportingReqs|19:' ||
'Summary|20:' || 'TaskOwner|23:' || 'TaskPrefix|24:' || 'TaskWorkflowCode';

v_valueStr := ',Test1,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test1,1,Test1,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test1,Test1,Test1,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test2,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test2,1,Test2,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test2,Test2,Test2,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test3,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test3,1,Test3,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test3,Test3,Test3,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test4,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test4,1,Test4,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test4,Test4,Test4,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test5,D1161964B806CA8AE040A8C06C1014E8,09 AUG 2013,root_CS_Status_NEW,root_CS_Status,Test5,1,Test5,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test5,Test5,Test5,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status';



-- CreatedBy and CreatedDate removed

v_inputStr := '2:' || 'CaseId|3:' || 'ContactInfo|4:' || 'CaseActivityCode|7:' || 'CaseWorkflowCode|8:' || 'Description|9:' ||
'FirstTimeComm|10:' || 'InfoFrom|11:' || 'OccuranceDate|12:' || 'CaseOwner|13:' || 'CasePrefix|14:' || 'Priority|15:' || 'PriorityCase|16:' || 'ProcedureId|17:' || 'Reason|18:' || 'ReportingReqs|19:' ||
'Summary|20:' || 'TaskOwner|23:' || 'TaskPrefix|24:' || 'TaskWorkflowCode';

v_valueStr := ',Test1,root_CS_Status_NEW,root_CS_Status,Test1,1,Test1,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test1,Test1,Test1,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test2,root_CS_Status_NEW,root_CS_Status,Test2,1,Test2,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test2,Test2,Test2,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test3,root_CS_Status_NEW,root_CS_Status,Test3,1,Test3,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test3,Test3,Test3,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test4,root_CS_Status_NEW,root_CS_Status,Test4,1,Test4,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test4,Test4,Test4,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test5,root_CS_Status_NEW,root_CS_Status,Test5,1,Test5,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test5,Test5,Test5,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status';




-- CaseActivityCode and CaseWorkflowCode removed

v_inputStr := '2:' || 'CaseId|3:' || 'ContactInfo|8:' || 'Description|9:' ||
'FirstTimeComm|10:' || 'InfoFrom|11:' || 'OccuranceDate|12:' || 'CaseOwner|13:' || 'CasePrefix|14:' || 'Priority|15:' || 'PriorityCase|16:' || 'ProcedureId|17:' || 'Reason|18:' || 'ReportingReqs|19:' ||
'Summary|20:' || 'TaskOwner|23:' || 'TaskPrefix|24:' || 'TaskWorkflowCode';

v_valueStr := ',Test1,Test1,1,Test1,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test1,Test1,Test1,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test2,Test2,1,Test2,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test2,Test2,Test2,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test3,Test3,1,Test3,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test3,Test3,Test3,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test4,Test4,1,Test4,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test4,Test4,Test4,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test5,Test5,1,Test5,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,INV-,Normal,1,1000,Test5,Test5,Test5,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status';



-- CasePrefix removed

v_inputStr := '2:' || 'CaseId|3:' || 'ContactInfo|8:' || 'Description|9:' ||
'FirstTimeComm|10:' || 'InfoFrom|11:' || 'OccuranceDate|12:' || 'CaseOwner|14:' || 'Priority|15:' || 'PriorityCase|16:' || 'ProcedureId|17:' || 'Reason|18:' || 'ReportingReqs|19:' ||
'Summary|20:' || 'TaskOwner|23:' || 'TaskPrefix|24:' || 'TaskWorkflowCode';

v_valueStr := ',Test1,Test1,1,Test1,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test1,Test1,Test1,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test2,Test2,1,Test2,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test2,Test2,Test2,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test3,Test3,1,Test3,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test3,Test3,Test3,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test4,Test4,1,Test4,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test4,Test4,Test4,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status
,Test5,Test5,1,Test5,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test5,Test5,Test5,D1161964B806CA8AE040A8C06C1014E8,TASK-,root_TSK_Status';



-- TaskOwner removed

v_inputStr := '2:' || 'CaseId|3:' || 'ContactInfo|8:' || 'Description|9:' ||
'FirstTimeComm|10:' || 'InfoFrom|11:' || 'OccuranceDate|12:' || 'CaseOwner|14:' || 'Priority|15:' || 'PriorityCase|16:' || 'ProcedureId|17:' || 'Reason|18:' || 'ReportingReqs|19:' ||
'Summary|23:' || 'TaskPrefix|24:' || 'TaskWorkflowCode';

v_valueStr := ',Test1,Test1,1,Test1,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test1,Test1,Test1,TASK-,root_TSK_Status
,Test2,Test2,1,Test2,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test2,Test2,Test2,TASK-,root_TSK_Status
,Test3,Test3,1,Test3,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test3,Test3,Test3,TASK-,root_TSK_Status
,Test4,Test4,1,Test4,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test4,Test4,Test4,TASK-,root_TSK_Status
,Test5,Test5,1,Test5,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test5,Test5,Test5,TASK-,root_TSK_Status';



-- TaskPrefix removed

v_inputStr := '2:' || 'CaseId|3:' || 'ContactInfo|8:' || 'Description|9:' ||
'FirstTimeComm|10:' || 'InfoFrom|11:' || 'OccuranceDate|12:' || 'CaseOwner|14:' || 'Priority|15:' || 'PriorityCase|16:' || 'ProcedureId|17:' || 'Reason|18:' || 'ReportingReqs|19:' ||
'Summary|24:' || 'TaskWorkflowCode';

v_valueStr := ',Test1,Test1,1,Test1,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test1,Test1,Test1,root_TSK_Status
,Test2,Test2,1,Test2,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test2,Test2,Test2,root_TSK_Status
,Test3,Test3,1,Test3,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test3,Test3,Test3,root_TSK_Status
,Test4,Test4,1,Test4,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test4,Test4,Test4,root_TSK_Status
,Test5,Test5,1,Test5,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test5,Test5,Test5,root_TSK_Status';



-- TaskWorkflowCode removed

v_inputStr := '2:' || 'CaseId|3:' || 'ContactInfo|8:' || 'Description|9:' ||
'FirstTimeComm|10:' || 'InfoFrom|11:' || 'OccuranceDate|12:' || 'CaseOwner|14:' || 'Priority|15:' || 'PriorityCase|16:' || 'ProcedureId|17:' || 'Reason|18:' || 'ReportingReqs|19:' ||
'Summary';

v_valueStr := ',Test1,Test1,1,Test1,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test1,Test1,Test1
,Test2,Test2,1,Test2,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test2,Test2,Test2
,Test3,Test3,1,Test3,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test3,Test3,Test3
,Test4,Test4,1,Test4,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test4,Test4,Test4
,Test5,Test5,1,Test5,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test5,Test5,Test5';



-- Orders arranged

v_inputStr := '1:' || 'CaseId|2:' || 'ContactInfo|3:' || 'Description|4:' ||
'FirstTimeComm|5:' || 'InfoFrom|6:' || 'OccuranceDate|7:' || 'CaseOwner|8:' || 'Priority|9:' || 'PriorityCase|10:' || 'ProcedureId|11:' || 'Reason|12:' || 'ReportingReqs|13:' ||
'Summary';

v_valueStr := ',Test1,Test1,1,Test1,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test1,Test1,Test1
,Test2,Test2,1,Test2,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test2,Test2,Test2
,Test3,Test3,1,Test3,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test3,Test3,Test3
,Test4,Test4,1,Test4,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test4,Test4,Test4
,Test5,Test5,1,Test5,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test5,Test5,Test5';


-- CaseId removed

v_inputStr := '1:' || 'ContactInfo|2:' || 'Description|3:' ||
'FirstTimeComm|4:' || 'InfoFrom|5:' || 'OccuranceDate|6:' || 'CaseOwner|7:' || 'Priority|8:' || 'PriorityCase|9:' || 'ProcedureId|10:' || 'Reason|11:' || 'ReportingReqs|12:' ||
'Summary';

v_valueStr := 'Test1,Test1,1,Test1,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test1,Test1,Test1
Test2,Test2,1,Test2,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test2,Test2,Test2
Test3,Test3,1,Test3,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test3,Test3,Test3
Test4,Test4,1,Test4,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test4,Test4,Test4
Test5,Test5,1,Test5,8 AUG 2013,D1161964B806CA8AE040A8C06C1014E8,Normal,1,1000,Test5,Test5,Test5';



-- CaseOwnerLogin instead of CaseOwner


v_inputStr := '1:' || 'ContactInfo|2:' || 'Description|3:' ||
'FirstTimeComm|4:' || 'InfoFrom|5:' || 'OccuranceDate|6:' || 'CaseOwnerLogin|7:' || 'Priority|8:' || 'PriorityCase|9:' || 'ProcedureId|10:' || 'Reason|11:' || 'ReportingReqs|12:' ||
'Summary';

v_valueStr := 'Test1,Test1,1,Test1,8 AUG 2013,admin@config.max,Normal,1,1000,Test1,Test1,Test1
Test2,Test2,1,Test2,8 AUG 2013,admin@config.max,Normal,1,1000,Test2,Test2,Test2
Test3,Test3,1,Test3,8 AUG 2013,admin@config.max,Normal,1,1000,Test3,Test3,Test3
Test4,Test4,1,Test4,8 AUG 2013,admin@config.max,Normal,1,1000,Test4,Test4,Test4
Test5,Test5,1,Test5,8 AUG 2013,admin@config.max,Normal,1,1000,Test5,Test5,Test5';




-- Priority changed to PriorityValue, PriorityCase removed


v_inputStr := '1:' || 'ContactInfo|2:' || 'Description|3:' ||
'FirstTimeComm|4:' || 'InfoFrom|5:' || 'OccuranceDate|6:' || 'CaseOwnerLogin|7:' || 'PriorityValue|8:' || 'ProcedureId|9:' || 'Reason|10:' || 'ReportingReqs|11:' ||
'Summary';

v_valueStr := 'Test1,Test1,1,Test1,8 AUG 2013,admin@config.max,50,1000,Test1,Test1,Test1
Test2,Test2,1,Test2,8 AUG 2013,admin@config.max,50,1000,Test2,Test2,Test2
Test3,Test3,1,Test3,8 AUG 2013,admin@config.max,50,1000,Test3,Test3,Test3
Test4,Test4,1,Test4,8 AUG 2013,admin@config.max,50,1000,Test4,Test4,Test4
Test5,Test5,1,Test5,8 AUG 2013,admin@config.max,50,1000,Test5,Test5,Test5';



-- ProcedureId changed to ProcedureName


v_inputStr := '1:' || 'ContactInfo|2:' || 'Description|3:' ||
'FirstTimeComm|4:' || 'InfoFrom|5:' || 'OccuranceDate|6:' || 'CaseOwnerLogin|7:' || 'PriorityValue|8:' || 'ProcedureName|9:' || 'Reason|10:' || 'ReportingReqs|11:' ||
'Summary';

v_valueStr := 'Test1,Test1,1,Test1,8 AUG 2013,admin@config.max,50,High-Value Auto Insurance Claim,Test1,Test1,Test1
Test2,Test2,1,Test2,8 AUG 2013,admin@config.max,50,High-Value Auto Insurance Claim,Test2,Test2,Test2
Test3,Test3,1,Test3,8 AUG 2013,admin@config.max,50,High-Value Auto Insurance Claim,Test3,Test3,Test3
Test4,Test4,1,Test4,8 AUG 2013,admin@config.max,50,High-Value Auto Insurance Claim,Test4,Test4,Test4
Test5,Test5,1,Test5,8 AUG 2013,admin@config.max,50,High-Value Auto Insurance Claim,Test5,Test5,Test5';

*/


v_inputStr := '1:' || 'ProcedureName|2:' || 'PriorityValue|3:' ||
'CaseOwnerLogin|4:' || 'Summary|5:' || 'OccuranceDate|6:' || 'FirstTimeComm|7:' || 'ContactInfo|8:' || 'InfoFrom|9:' || 'Reason|10:' || 'ReportingReqs|11:' || 'Description';

v_valueStr := 'Procedure (Name),Priority (Value),Owner (Username),Summary,Origin Request,First Time Request,Requestor''s Contact Info,Whom Investigation,Reason for Investigation,Reporting Reqs,Description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into John Smith,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,100,admin@config.max,Sample short investigation into Bob Smith,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Kathy Jones,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,0,admin@config.max,Sample short investigation into Jamal Abu Rubieh,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample investigation into Evita Homeyer,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Willy Kroeger,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,100,admin@config.max,Sample investigation into Ruthann Mccandless,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Khadijah Delmont,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,0,admin@config.max,Sample short investigation into Estrella Meagher,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Maxima Zwart,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,0,admin@config.max,Sample short investigation into Margherita Payton,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Tracey Groseclose,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,100,admin@config.max,Sample short investigation into Ramon Seldon,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Olin Gorski,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Del Crume,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Nettie Brokaw,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Bertha Shipe,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,0,admin@config.max,Sample short investigation into Nakia Cruz,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Rafael Wiener,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Leota Wohlers,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Dakota Trudeau,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Page Bartels,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Kathline Sjogren,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,100,admin@config.max,Sample short investigation into Alisa Ferrel,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Sindy Haefner,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Dorene Fredricks,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Walter Ward,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Maribeth Hartson,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,100,admin@config.max,Sample short investigation into Sena Police,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Krishna Lalonde,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Yung Matranga,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description
Sample Investigative Short Case,50,admin@config.max,Sample short investigation into Rachele Corning,22-Aug-2013,1,"Nicole J. Rosales 3078 Retreat Avenue Rochester- ME 03867","John Smith 3078 Retreat Avenue Rochester- ME 03867",Found evidence of potential fraud,Report to SEC,Sample description';


v_result := f_dcm_parseindexingschema(ErrorCode => ErrorCode, ErrorMessage => ErrorMessage, fields => v_strFields, orders => v_strOrders, inputStr => v_inputStr);

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------- Parse Orders string and find minimum and maximum values in orders -------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  v_result := f_dcm_processfieldorders(maxOrder => v_maxOrder, minOrder => v_minOrder, strOrders => v_strOrders);
  
  
-- Initialize variables using extracted values from input string, then use them as paramaters for function call

-- Extract lines from text file end create case for each line
v_result := f_dcm_importfile(p_ExtCode => v_ExtCode,
                             p_ActivityCode => v_ActivityCode, p_CaseActivityCode => v_CaseActivityCode, p_CaseWorkflowCode => v_CaseWorkflowCode, p_Prefix => v_Prefix,
                             p_TaskOwner => v_TaskOwner, p_TaskPrefix => v_TaskPrefix, p_WorkflowCode => v_WorkflowCode, pi_CaseId => v_CaseId,
                             p_CreatedBy => v_CreatedBy, p_CreatedDate => v_CreatedDate, ErrorCode => ErrorCode, ErrorMessage => ErrorMessage,
                             maxOrder => v_maxOrder, minOrder => v_minOrder, strFields => v_strFields, p_TOKEN_DOMAIN => :TOKEN_DOMAIN,
                             p_TOKEN_USERACCESSSUBJECT => :TOKEN_USERACCESSSUBJECT, p_TOKEN_SYSTEMDOMAINUSER => :TOKEN_SYSTEMDOMAINUSER, valueStr => v_valueStr);

end;
