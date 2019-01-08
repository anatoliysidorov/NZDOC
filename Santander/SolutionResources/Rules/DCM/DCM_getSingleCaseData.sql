DECLARE
	--INPUT
	v_case_id INTEGER;
	v_task_id INTEGER;
	
BEGIN
	--INPUT
	v_case_id := :CASE_ID;
	v_task_id := :TASK_ID;

	--GET DATA IF EITHER CASEID OR TASKID IS PRESENT
	IF v_case_id > 0 OR v_task_id > 0 THEN
		OPEN :ITEMS FOR
			SELECT 
				  c.col_id AS ID,
				  c.col_id AS COL_ID,
				  c.col_caseid AS CaseId,
				  c.col_extsysid AS ExtSysId,
				  c.col_int_integtargetcase AS IntegTarget_Id,
				  c.col_summary AS SUMMARY,
				  (SELECT col_description
				  FROM    tbl_caseext
				  WHERE   col_caseextcase = c.col_id) AS Description,
				  c.col_createdby AS CreatedBy,
				  c.col_createddate AS CreatedDate,
				  c.col_modifiedby AS ModifiedBy,
				  c.col_modifieddate AS ModifiedDate,
				  (SELECT col_resolutiondescription
				  FROM    tbl_caseext
				  WHERE   col_caseextcase = c.col_id) AS ResolutionDescription,
				  c.col_draft AS Draft,
				  c.col_casefrom AS CaseFrom,
				  f_DCM_getCaseCustomData(c.col_id) as CustomData,
				  
				  --CASE TYPE
				  cst.col_id AS CaseSysType_Id,
				  cst.col_name AS CaseSysType_Name,
				  cst.col_code AS CaseSysType_Code,
				  cst.col_iconcode AS CaseSysType_IconCode,
				  cst.col_colorcode AS CaseSysType_ColorCode,
				  cst.col_usedatamodel AS CaseSysType_UseDataModel,
				  cst.col_isdraftmodeavail AS CaseSysType_IsDraftModeAvail,
				  
				  --PRIORITY
				  prty.col_id AS Priority_Id,
				  prty.col_name AS Priority_Name,
				  prty.col_value AS Priority_Value,
				  
				  --CASE STATE
				  dts.col_id AS CaseState_Id,
				  dts.col_name AS CaseState_name,
				  dts.col_isstart AS CaseState_ISSTART,
				  dts.col_isresolve AS CaseState_ISRESOLVE,
				  dts.col_isfinish AS CaseState_ISFINISH,
				  dts.col_isassign AS CaseState_ISASSIGN,
				  dts.col_isfix AS CaseState_ISFIX,
				  dts.col_isdefaultoncreate2 AS CaseState_ISINPROCESS,
				  dts.col_isdefaultoncreate AS CaseState_ISDEFAULTONCREATE,
				  
				  --OWNERSHIP
				  wb.id AS Workbasket_id,
				  wb.calcname AS Workbasket_name,
				  wb.workbaskettype_name AS Workbasket_type_name,
				  wb.workbaskettype_code AS Workbasket_type_code,
				  
				  --RESOLUTION
				  c.col_stp_resolutioncodecase AS ResolutionCode_Id,
				  rc.col_name AS ResolutionCode_Name,
				  rc.col_iconcode AS ResolutionCode_Icon,
				  rc.col_theme AS ResolutionCode_Theme,
				  
				  --MILESTONE
				  dict_state.col_id AS MS_StateId,
				  dict_state.col_name AS MS_StateName,
				  dict_state.col_commoncode AS MS_CommonCode,
				  (SELECT col_id
				  FROM    tbl_dict_slaeventtype
				  WHERE   col_code = 'GOAL') AS GoalSlaEventTypeId,
				  (SELECT col_code
				  FROM    tbl_dict_slaeventtype
				  WHERE   col_code = 'GOAL') AS GoalSlaEventTypeCode,
				  (SELECT col_name
				  FROM    tbl_dict_slaeventtype
				  WHERE   col_code = 'GOAL') AS GoalSlaEventTypeName,
				  c.col_goalsladatetime AS GoalSlaDateTime,
				  (SELECT col_id
				  FROM    tbl_dict_slaeventtype
				  WHERE   col_code = 'DEADLINE') AS DLineSlaEventTypeId,
				  (SELECT col_code
				  FROM    tbl_dict_slaeventtype
				  WHERE   col_code = 'DEADLINE') AS DLineSlaEventTypeCode,
				  (SELECT col_name
				  FROM    tbl_dict_slaeventtype
				  WHERE   col_code = 'DEADLINE') AS DLineSlaEventTypeName,
				  c.col_dlinesladatetime AS DLineSlaDateTime
		FROM      tbl_case c
		left join tbl_stp_priority prty      ON c.col_stp_prioritycase = prty.col_id
		left join tbl_cw_workitem cw         ON c.col_cw_workitemcase = cw.col_id
		left join tbl_dict_casestate dts     ON cw.col_cw_workitemdict_casestate = dts.col_id
		left join tbl_dict_casesystype cst   ON c.col_casedict_casesystype = cst.col_id
		left join vw_ppl_simpleworkbasket wb ON(wb.id = c.col_caseppl_workbasket)
		left join tbl_stp_resolutioncode rc  ON c.col_stp_resolutioncodecase = rc.col_id
		left join tbl_dict_stateconfig sc    ON cst.col_stateconfigcasesystype = sc.col_id
		left join tbl_dict_state dict_state  ON c.col_casedict_state = dict_state.col_id
		WHERE 1 = 1    
		<%=IfNotNull(":Case_Id", " AND c.col_id = :Case_Id")%>
		<%=IfNotNull(":Task_Id", " AND c.col_id = (SELECT COL_CASETASK FROM TBL_TASK WHERE COL_ID = :Task_Id)")%>
		;
	END IF;
END;