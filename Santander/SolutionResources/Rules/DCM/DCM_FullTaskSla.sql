SELECT    
--TASK DATA
tsk.col_id AS ID,
tsk.col_taskid AS TITLE,
tsk.col_name AS NAME,
tsk.col_description AS DESCRIPTION,
tsk.col_parentid AS PARENTID,
tsk.col_createdby AS CreatedBy,
tsk.col_createddate AS CreatedDate,
tsk.col_modifiedby AS ModifiedBy,
tsk.col_modifieddate AS ModifiedDate,
tsk.COL_RESOLUTIONDESCRIPTION as RESOLUTIONDESCRIPTION,

--TASK TYPE
tst.col_iconCode AS CALC_ICON,
tst.col_id AS TASKSYSTYPE_ID,
tst.col_name as TASKSYSTYPE_NAME,
tst.col_code as TASKSYSTYPE_CODE,

--TASK EXECUTION TYPE
em.col_name as EXECUTIONMETHOD_NAME,
em.col_code as EXECUTIONMETHOD_CODE,

--TASK RESOLUTION CODE
rc.col_id as RESOLUTIONCODE_ID,
rc.col_name as RESOLUTIONCODE_NAME,
rc.col_code as RESOLUTIONCODE_CODE,
rc.col_iconcode as RESOLUTIONCODE_ICON,
rc.COL_THEME as RESOLUTIONCODE_THEME,


--TASK STATE
dts.col_id AS TASKSTATE_ID,
dts.col_name AS TASKSTATE_NAME,
dts.col_code AS TASKSTATE_CODE,
dts.col_isdefaultoncreate AS TASKSTATE_ISDEFAULTONCREATE,
dts.col_isstart AS TASKSTATE_ISSTART,
dts.col_isfinish AS TASKSTATE_ISFINISH,

--WORKBASKET
tsk.col_taskppl_workbasket AS WORKBASKET_ID,
pwb.col_name as WORKBASKET_NAME, 
wbt.col_code as WORKBASKET_TYPE_CODE,

--SLA
cast(gse.col_slaeventdate as timestamp) as GoalSlaDateTime,
cast(dse.col_slaeventdate as timestamp) as DLineSlaDateTime,

--CASE DATA
tsk.col_casetask AS CASE_ID,
cse.col_caseid AS CASE_TITLE,
cse.col_summary AS CASE_SUMMARY,
cse.COL_CASEPPL_WORKBASKET as CASE_WORKBASKETID,
cse.col_draft as CASE_DRAFT,

--CASE PRIORITY
cp.col_id as PRIORITY_ID,
cp.col_name as PRIORITY_NAME,
cp.col_value as PRIORITY_VALUE,

--CASE TYPE
cct.col_id as CASESYSTYPE_ID,
cct.col_code as CASESYSTYPE_CODE,
cct.col_name as CASESYSTYPE_NAME,
cct.col_colorcode as CASESYSTYPE_COLORCODE,
cct.col_iconcode as CASESYSTYPE_ICONCODE,

--CASE STATE
cs.col_id as CASESTATE_ID,
cs.col_name as CASESTATE_NAME,
cs.col_code as CASESTATE_CODE,
cs.col_ISSTART as CASESTATE_ISSTART,
cs.col_ISFINISH as CASESTATE_ISFINISH,
cs.col_ISDEFAULTONCREATE as CASESTATE_ISDEFAULTONCREATE,

--CASE MILESTONE
cms.col_id as CASE_MS_ID,
cms.col_name as CASE_MS_NAME,
cms.col_code as CASE_MS_CODE,
cms.col_commoncode as CASE_MS_COMMONCODE,
cms.COL_ICONCODE as CASE_MS_ICONCODE

FROM      tbl_task tsk
LEFT JOIN tbl_dict_taskstate dts   ON tsk.col_taskdict_taskstate = dts.col_id
LEFT JOIN tbl_dict_tasksystype tst ON tsk.col_taskdict_tasksystype = tst.col_id
LEFT JOIN tbl_dict_executionmethod em	ON em.col_id = tsk.COL_TASKDICT_EXECUTIONMETHOD
LEFT JOIN tbl_stp_resolutioncode rc	ON rc.col_id = tsk.COL_TASKSTP_RESOLUTIONCODE
--Case related
LEFT JOIN tbl_case cse ON cse.col_id = tsk.col_casetask
LEFT JOIN tbl_dict_casestate cs ON cs.col_id = cse.COL_CASEDICT_CASESTATE
LEFT JOIN tbl_stp_priority cp ON cp.col_id = cse.COL_STP_PRIORITYCASE
LEFT JOIN tbl_dict_casesystype cct ON cct.col_id = cse.COL_CASEDICT_CASESYSTYPE
LEFT JOIN tbl_dict_state cms ON cms.col_id = cse.COL_CASEDICT_STATE
--Goal SLA
LEFT JOIN tbl_dict_slaeventtype gsetp ON lower(gsetp.col_code) = 'goal'
LEFT JOIN tbl_slaevent gse            ON gse.col_slaeventtask = tsk.col_id AND gse.col_slaeventdict_slaeventtype = gsetp.col_id
--DeadLine (DLine) SLA
LEFT JOIN tbl_dict_slaeventtype dsetp ON lower(dsetp.col_code) = 'deadline'
LEFT JOIN tbl_slaevent dse            ON dse.col_slaeventtask = tsk.col_id AND dse.col_slaeventdict_slaeventtype = dsetp.col_id
-- Workbakset
LEFT JOIN tbl_ppl_workbasket pwb on pwb.col_id = tsk.col_taskppl_workbasket  
LEFT JOIN tbl_dict_workbaskettype wbt on wbt.col_id = pwb.col_workbasketworkbaskettype