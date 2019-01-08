SELECT --BASIC DATA 
	c.col_id                                 AS ID, 
	c.col_id                                 AS COL_ID, 
	c.col_caseid                             AS CaseId, 
	c.col_extsysid                           AS ExtSysId, 
	c.col_int_integtargetcase                AS IntegTarget_Id, 
	c.col_summary                            AS SUMMARY, 
	ce.col_description                       AS Description, 
	c.col_createdby                          AS CreatedBy, 
	c.col_createddate                        AS CreatedDate, 
	c.col_modifiedby                         AS ModifiedBy, 
	c.col_modifieddate                       AS ModifiedDate, 
	c.col_dateassigned                       AS DateAssigned, 
	c.col_dateclosed                         AS DateClosed, 
	c.col_manualworkduration                 AS ManualWorkDuration, 
	c.col_manualdateresolved                 AS ManualDateResolved, 
	ce.col_resolutiondescription             AS ResolutionDescription, 
	c.col_draft                              AS Draft, 
	c.col_casefrom                           AS CaseFrom, 
	--CASE TYPE  
	cst.col_id                               AS CaseSysType_Id, 
	cst.col_name                             AS CaseSysType_Name, 
	cst.col_code                             AS CaseSysType_Code, 
	cst.col_iconcode                         AS CaseSysType_IconCode, 
	cst.col_colorcode                        AS CaseSysType_ColorCode, 
	cst.col_usedatamodel                     AS CaseSysType_UseDataModel, 
	cst.col_isdraftmodeavail                 AS CaseSysType_IsDraftModeAvail, 
	--WORKITEM  
	cw.col_id                                AS Workitem_Id, 
	cw.col_activity                          AS Workitem_Activity, 
	cw.col_workflow                          AS Workitem_Workflow, 
	--PRIORITY  
	prty.col_id                              AS Priority_Id, 
	prty.col_name                            AS Priority_Name, 
	prty.col_value                           AS Priority_Value, 
	--Case STATE CONFIG (Milestones) 
	sc.col_id                                AS StateConfig_id, 
	sc.col_name                              AS StateConfig_Name, 
	sc.col_code                              AS StateConfig_code, 
	sc.col_isdefault                         AS StateConfig_IsDefault, 
	--CASE STATE  
	dts.col_id                               AS CaseState_Id, 
	dts.col_name                             AS CaseState_name, 
	dts.col_isstart                          AS CaseState_ISSTART, 
	dts.col_isresolve                        AS CaseState_ISRESOLVE, 
	dts.col_isfinish                         AS CaseState_ISFINISH, 
	dts.col_isassign                         AS CaseState_ISASSIGN, 
	dts.col_isfix                            AS CaseState_ISFIX, 
	dts.col_isdefaultoncreate2               AS CaseState_ISINPROCESS, 
	dts.col_isdefaultoncreate                AS CaseState_ISDEFAULTONCREATE, 
	--OWNERSHIP  
	wb.id                                    AS Workbasket_id, 
	wb.calcname                              AS Workbasket_name, 
	wb.calcname                              AS Owner_CaseWorker_Name, 
	wb.workbaskettype_name                   AS Workbasket_type_name, 
	wb.workbaskettype_code                   AS Workbasket_type_code, 
	--RESOLUTION  
	c.col_stp_resolutioncodecase             AS ResolutionCode_Id, 
	rc.col_name                              AS ResolutionCode_Name, 
	rc.col_code                              AS ResolutionCode_Code, 
	rc.col_iconcode                          AS ResolutionCode_Icon, 
	rc.col_theme                             AS ResolutionCode_Theme, 
	(SELECT SUM(col_hoursspent) 
	 FROM   tbl_dcm_workactivity 
	 WHERE  col_workactivitycase = c.col_id) AS HoursSpent, 
	--MILESTONE 
	dict_state.col_id                        AS MS_StateId, 
	dict_state.col_name                      AS MS_StateName, 
	dict_state.col_commoncode                AS MS_CommonCode, 
	--Goal SLA 
	gsla.slaeventtypeid                      AS GoalSlaEventTypeId, 
	gsla.slaeventtypecode                    AS GoalSlaEventTypeCode, 
	gsla.slaeventtypename                    AS GoalSlaEventTypeName, 
	gsla.sladatetime                         AS GoalSlaDateTime, 
	--DeadLine (DLine) SLA 
	dsla.slaeventtypeid                      AS DLineSlaEventTypeId, 
	dsla.slaeventtypecode                    AS DLineSlaEventTypeCode, 
	dsla.slaeventtypename                    AS DLineSlaEventTypeName, 
	dsla.sladatetime                         AS DLineSlaDateTime 
	---- 
FROM   tbl_case c 
  INNER JOIN tbl_caseext ce on c.col_id = ce.col_caseextcase
  LEFT JOIN tbl_stp_priority prty ON c.col_stp_prioritycase = prty.col_id
  LEFT JOIN tbl_cw_workitem cw ON c.col_cw_workitemcase = cw.col_id
  LEFT JOIN tbl_dict_casestate dts ON cw.col_cw_workitemdict_casestate = dts.col_id
  LEFT JOIN tbl_dict_casesystype cst ON c.col_casedict_casesystype = cst.col_id
  LEFT JOIN vw_ppl_simpleworkbasket wb ON (wb.id = c.col_caseppl_workbasket)
  LEFT JOIN tbl_stp_resolutioncode rc ON c.col_stp_resolutioncodecase = rc.col_id
  LEFT JOIN TBL_DICT_STATECONFIG sc ON cst.col_stateconfigcasesystype = sc.col_id
  /*LEFT JOIN tbl_dict_stateconfig state_conf ON cst.col_msstateconfigcasesystype = state_conf.col_id*/
  LEFT JOIN tbl_dict_state dict_state ON c.col_casedict_state = dict_state.col_id

  --Goal SLA
  LEFT JOIN (
        SELECT
          s1.CaseId, sse1.COL_STATESLAEVENTDICT_STATE AS StateId, s1.SSEID AS SSEID, s1.DateValue_Latest,
          setp.col_id as SlaEventTypeId, setp.col_code as SlaEventTypeCode, setp.col_name as SlaEventTypeName,
          (cast(s1.DateValue_Latest +
            (case when sse1.COL_INTERVALDS is not null then to_dsinterval(sse1.COL_INTERVALDS) else to_dsinterval('0 0:0:0') end) * (sse1.COL_ATTEMPTCOUNT + 1) +
            (case when sse1.COL_INTERVALYM is not null then to_yminterval(sse1.COL_INTERVALYM) else to_yminterval('0-0') end) * (sse1.COL_ATTEMPTCOUNT + 1) as timestamp)) as SlaDateTime
        FROM
            (
              SELECT cs.col_id AS CaseId,
                     sse.col_id AS SSEID,
                     dte.COL_DATEEVENT_DATEEVENTTYPE AS DateEvtType,
                     MAX(dte.COL_DATEVALUE) AS DateValue_Latest

              FROM TBL_DICT_STATESLAEVENT sse
              INNER JOIN TBL_DICT_STATE st ON sse.COL_STATESLAEVENTDICT_STATE=st.COL_ID
              INNER JOIN TBL_CASE  cs ON cs.COL_CASEDICT_STATE=st.COL_ID
              INNER JOIN TBL_DATEEVENT dte ON dte.COL_DATEEVENTCASE=cs.COL_ID AND
                                              dte.COL_DATEEVENTDICT_STATE=sse.COL_STATESLAEVENTDICT_STATE
              LEFT JOIN TBL_DICT_DATEEVENTTYPE dtet ON dte.COL_DATEEVENT_DATEEVENTTYPE=dtet.COL_ID
              WHERE NVL(dtet.COL_ISCASEMAINFLAG, 0)=1
              GROUP BY sse.COL_ID, cs.COL_ID, dte.COL_DATEEVENT_DATEEVENTTYPE
            ) s1
            LEFT OUTER JOIN TBL_DICT_STATESLAEVENT sse1 ON sse1.COL_ID=s1.SSEID
            INNER JOIN tbl_dict_slaeventtype setp ON setp.col_code = 'GOAL' AND upper(sse1.COL_SERVICESUBTYPE) = setp.col_code
      ) gsla ON gsla.CaseId = c.col_id AND gsla.StateId = dict_state.col_id
  --DeadLine (DLine) SLA
  LEFT JOIN (
        SELECT
          s1.CaseId, sse1.COL_STATESLAEVENTDICT_STATE AS StateId, s1.SSEID AS SSEID, s1.DateValue_Latest,
          setp.col_id as SlaEventTypeId, setp.col_code as SlaEventTypeCode, setp.col_name as SlaEventTypeName,
          (cast(s1.DateValue_Latest +
            (case when sse1.COL_INTERVALDS is not null then to_dsinterval(sse1.COL_INTERVALDS) else to_dsinterval('0 0:0:0') end) * (sse1.COL_ATTEMPTCOUNT + 1) +
            (case when sse1.COL_INTERVALYM is not null then to_yminterval(sse1.COL_INTERVALYM) else to_yminterval('0-0') end) * (sse1.COL_ATTEMPTCOUNT + 1) as timestamp)) as SlaDateTime
        FROM
            (
              SELECT cs.col_id AS CaseId,
                     sse.col_id AS SSEID,
                     dte.COL_DATEEVENT_DATEEVENTTYPE AS DateEvtType,
                     MAX(dte.COL_DATEVALUE) AS DateValue_Latest

              FROM TBL_DICT_STATESLAEVENT sse
              INNER JOIN TBL_DICT_STATE st ON sse.COL_STATESLAEVENTDICT_STATE=st.COL_ID
              INNER JOIN TBL_CASE  cs ON cs.COL_CASEDICT_STATE=st.COL_ID
              INNER JOIN TBL_DATEEVENT dte ON dte.COL_DATEEVENTCASE=cs.COL_ID AND
                                              dte.COL_DATEEVENTDICT_STATE=sse.COL_STATESLAEVENTDICT_STATE
              LEFT JOIN TBL_DICT_DATEEVENTTYPE dtet ON dte.COL_DATEEVENT_DATEEVENTTYPE=dtet.COL_ID
              WHERE NVL(dtet.COL_ISCASEMAINFLAG, 0)=1
              GROUP BY sse.COL_ID, cs.COL_ID, dte.COL_DATEEVENT_DATEEVENTTYPE
            ) s1
            LEFT OUTER JOIN TBL_DICT_STATESLAEVENT sse1 ON sse1.COL_ID=s1.SSEID
            INNER JOIN tbl_dict_slaeventtype setp ON setp.col_code = 'DEADLINE' AND upper(sse1.COL_SERVICESUBTYPE) = setp.col_code
      ) dsla ON dsla.CaseId = c.col_id AND dsla.StateId = dict_state.col_id
