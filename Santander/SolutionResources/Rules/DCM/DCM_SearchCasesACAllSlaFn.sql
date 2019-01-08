declare
  v_CREATED_END date;
  v_CREATED_START date;
  v_CalcEmail nvarchar2(255);
  v_CalcExtSysId nvarchar2(255);
  v_CalcName nvarchar2(255);
  v_CaseId nvarchar2(255);
  v_CaseSysTypeIds nvarchar2(255);
  v_CaseSysType_Code nvarchar2(255);
  v_Case_Id Integer;
  v_CaseworkerIds nvarchar2(255);
  v_DESCRIPTION nvarchar2(255);
  v_DIR nvarchar2(255);
  v_ExternalPartyIds nvarchar2(255);
  v_LIMIT number;
  v_PriorityIds nvarchar2(255);
  v_ResolutionCodeIds nvarchar2(255);
  v_SORT nvarchar2(255);
  v_START number;
  v_Task_Id Integer;
  v_TeamIds nvarchar2(255);
  v_WorkbasketIds nvarchar2(255);
  v_summary nvarchar2(255);
  v_workbasket_name nvarchar2(255);
  v_query varchar2(32767);
  v_query2 varchar2(32767);
  v_whereqry varchar2(32767);
  v_sortqry varchar2(32767);
  v_countquery varchar2(32767);
  v_CaseStateIds varchar2(32767);
begin

  v_CREATED_END := :CREATED_END;
  v_CREATED_START := :CREATED_START;
  v_CalcEmail := :CalcEmail;
  v_CalcExtSysId := :CalcExtSysId;
  v_CalcName := :CalcName;
  v_CaseId := :CaseId;
  v_CaseSysTypeIds := :CaseSysTypeIds;
  v_CaseSysType_Code := :CaseSysType_Code;
  v_Case_Id := :Case_Id;
  v_CaseworkerIds := :CaseworkerIds;
  v_DESCRIPTION := :DESCRIPTION;
  v_DIR := :DIR;
  if v_DIR is null then
    v_DIR := 'ASC';
  end if;
  v_ExternalPartyIds := :ExternalPartyIds;
  v_LIMIT := :LIMIT;
  v_PriorityIds := :PriorityIds;
  v_ResolutionCodeIds := :ResolutionCodeIds;
  v_SORT := :SORT;
  if v_SORT is null then
    v_SORT := 'Id';
  end if;
  v_START := :FIRST;
  if v_START is null then
    v_START := 0;
  end if;
  if nvl(v_LIMIT,0) = 0 then
    v_LIMIT := 1;
  end if;
  v_Task_Id := :Task_Id;
  v_TeamIds := :TeamIds;
  v_WorkbasketIds := :WorkbasketIds;
  v_summary := :summary;
  v_workbasket_name := :workbasket_name;
  v_CaseStateIds := :CaseStateIds;
  --Start building of SQL statement
  --v_query := 'select ID from (select /*+ FIRST_ROWS(' || to_char(v_LIMIT) || ') */ ID, rn from (select ID, rownum rn from (select ';
  v_query := 'select ID from (select ID, rn from (select ID, rownum rn from (select ';
  if lower(v_SORT) <> 'id' then
    v_query := v_query || 'cv.' || v_SORT || ', cv.ID';
  else
    v_query := v_query || 'cv.ID';
  end if;
  v_query := v_query || ' from vw_dcm_simplecasectaccachelst cv ';
  v_whereqry := null;
  if v_Task_Id is not null then
    v_whereqry := ' WHERE cv.id = (select col_casetask from tbl_task where col_id  = ' || to_char(v_Task_Id) || ')';
  end if;
  if v_Case_Id is not null and v_whereqry is null then
    v_whereqry := ' WHERE cv.id = ' || to_char(v_Case_Id);
  elsif v_Case_Id is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cv.id = ' || to_char(v_Case_Id);
  end if;
  if v_CaseStateIds is not null and v_whereqry is null then
    v_whereqry :=  ' where (cv.CaseState_Id in (select to_number(column_value) from table(asf_split(' || '''' || v_CaseStateIds || '''' || ', '',''))))';
  elsif v_CaseStateIds is not null and v_whereqry is not null then
    v_whereqry :=  v_whereqry || ' and (cv.CaseState_Id in (select to_number(column_value) from table(asf_split(' || '''' || v_CaseStateIds || '''' || ', '',''))))';
  end if;  
  if v_CaseId is not null and v_whereqry is null then
    v_whereqry := ' WHERE lower(cv.caseid) LIKE lower(''%' || v_CaseId || '%'')';
  elsif v_CaseId is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND lower(cv.caseid) LIKE lower(''%' || v_CaseId || '%'')';
  end if;
  if v_summary is not null and v_whereqry is null then
    v_whereqry := ' WHERE LOWER(cv.summary) LIKE lower(''%' || v_summary || '%'')';
  elsif v_summary is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND LOWER(cv.summary) LIKE lower(''%' || v_summary || '%'')';
  end if;
  if v_workbasket_name is not null and v_whereqry is null then
    v_whereqry := ' WHERE LOWER(cv.workbasket_name) LIKE lower(''%' || v_workbasket_name || '%'')';
  elsif v_workbasket_name is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND LOWER(cv.workbasket_name) LIKE lower(''%' || v_workbasket_name || '%'')';
  end if;
  if v_DESCRIPTION is not null and v_whereqry is null then
    v_whereqry := ' WHERE LOWER(cv.DESCRIPTION) LIKE lower(''%' || v_DESCRIPTION || '%'')';
  elsif v_DESCRIPTION is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND LOWER(cv.DESCRIPTION) LIKE lower(''%' || v_DESCRIPTION || '%'')';
  end if;
  if v_CREATED_START is not null and v_whereqry is null then
    v_whereqry := ' WHERE trunc(cv.CREATEDDATE) >= trunc(to_date(''' || to_char(v_CREATED_START) || '''))';
  elsif v_CREATED_START is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND trunc(cv.CREATEDDATE) >= trunc(to_date(''' || to_char(v_CREATED_START) || '''))';
  end if;
  if v_CREATED_END is not null and v_whereqry is null then
    v_whereqry := ' WHERE trunc(cv.CREATEDDATE) <= trunc(to_date(''' || to_char(v_CREATED_END) || '''))';
  elsif v_CREATED_END is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND trunc(cv.CREATEDDATE) <= trunc(to_date(''' || to_char(v_CREATED_END) || '''))';
  end if;
  if v_CaseSysType_Code is not null and v_whereqry is null then
    v_whereqry := ' WHERE lower(cv.casesystype_code) in (SELECT lower(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(' || '''' || v_CaseSysType_Code || '''' || ', '','')))';
  elsif v_CaseSysType_Code is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND lower(cv.casesystype_code) in (SELECT lower(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(' || '''' || v_CaseSysType_Code || '''' || ', '','')))';
  end if;
  if v_WorkbasketIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE cv.Workbasket_Id in (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_WorkbasketIds || '''' || ','','')))';
  elsif v_WorkbasketIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cv.Workbasket_Id in (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_WorkbasketIds || '''' || ','','')))';
  end if;
  if v_PriorityIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE cv.PRIORITY_ID in (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_PriorityIds || '''' || ','','')))';
  elsif v_PriorityIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cv.PRIORITY_ID in (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_PriorityIds || '''' || ','','')))';
  end if;
  if v_ResolutionCodeIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE cv.RESOLUTIONCODE_ID in (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_ResolutionCodeIds || '''' || ','','')))';
  elsif v_ResolutionCodeIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cv.RESOLUTIONCODE_ID in (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_ResolutionCodeIds || '''' || ','','')))';
  end if;
  if v_CaseSysTypeIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE cv.CaseSysType_Id in (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_CaseSysTypeIds || '''' || ','','')))';
  elsif v_CaseSysTypeIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cv.CaseSysType_Id in (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_CaseSysTypeIds || '''' || ','','')))';
  end if;
  if v_CaseworkerIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE exists(select s1.cpid, s1.cpcaseid
                 from ((select cp.id as cpid, cp.case_id as cpcaseid, cp.caseworker_id as cpcaseworkerid from vw_ppl_caseparty cp) s1
                       inner join
                       (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_CaseworkerIds || '''' || ','',''))) s2 on s1.cpcaseworkerid = s2.c2)
                 where s1.cpcaseid = cv.id)';
  elsif v_CaseworkerIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND exists(select s1.cpid, s1.cpcaseid
                 from ((select cp.id as cpid, cp.case_id as cpcaseid, cp.caseworker_id as cpcaseworkerid from vw_ppl_caseparty cp) s1
                       inner join
                       (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_CaseworkerIds || '''' || ','',''))) s2 on s1.cpcaseworkerid = s2.c2)
                 where s1.cpcaseid = cv.id)';
  end if;
  if v_TeamIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE exists(select s1.cpid, s1.cpcaseid
                 from ((select cp.id as cpid, cp.case_id as cpcaseid, cp.team_id as cpteamid from vw_ppl_caseparty cp) s1
                       inner join
                       (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_TeamIds || '''' || ','',''))) s2 on s1.cpteamid = s2.c2)
                 where s1.cpcaseid = cv.id)';
  elsif v_TeamIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND exists(select s1.cpid, s1.cpcaseid
                 from ((select cp.id as cpid, cp.case_id as cpcaseid, cp.team_id as cpteamid from vw_ppl_caseparty cp) s1
                       inner join
                       (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_TeamIds || '''' || ','',''))) s2 on s1.cpteamid = s2.c2)
                 where s1.cpcaseid = cv.id)';
  end if;
  if v_ExternalPartyIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE exists(select s1.cpid, s1.cpcaseid
                 from ((select cp.id as cpid, cp.case_id as cpcaseid, cp.externalparty_id as cpexternalpartyid from vw_ppl_caseparty cp) s1
                       inner join
                       (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_ExternalPartyIds || '''' || ','',''))) s2 on s1.cpexternalpartyid = s2.c2)
                 where s1.cpcaseid = cv.id)';
  elsif v_ExternalPartyIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND exists(select s1.cpid, s1.cpcaseid
                 from ((select cp.id as cpid, cp.case_id as cpcaseid, cp.externalparty_id as cpexternalpartyid from vw_ppl_caseparty cp) s1
                       inner join
                       (select to_number(column_value) as c2 from table(asf_splitclob(' || '''' || v_ExternalPartyIds || '''' || ','',''))) s2 on s1.cpexternalpartyid = s2.c2)
                 where s1.cpcaseid = cv.id)';
  end if;
  if v_CalcExtSysId is not null and v_whereqry is null then
    v_whereqry := ' WHERE exists(select lower(cp.CALC_EXTSYSID) as cpExtSysId from vw_ppl_caseparty cp where cp.case_id = cv.id and lower(cp.CALC_EXTSYSID) = lower(''' || v_CalcExtSysId || '''))';
  elsif v_CalcExtSysId is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND exists(select lower(cp.CALC_EXTSYSID) as cpExtSysId from vw_ppl_caseparty cp where cp.case_id = cv.id and lower(cp.CALC_EXTSYSID) = lower(''' || v_CalcExtSysId || '''))';
  end if;
  if v_CalcEmail is not null and v_whereqry is null then
    v_whereqry := ' WHERE exists(select lower(cp.calc_email) as cpCalcEmail from vw_ppl_caseparty cp where cp.case_id = cv.id and lower(cp.calc_email) like ''%'' || lower(''' || v_CalcEmail || ''') || ''%'')';
  elsif v_CalcEmail is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND exists(select lower(cp.calc_email) as cpCalcEmail from vw_ppl_caseparty cp where cp.case_id = cv.id and lower(cp.calc_email) like ''%'' || lower(''' || v_CalcEmail || ''') || ''%'')';
  end if;
  if v_CalcName is not null and v_whereqry is null then
    v_whereqry := ' WHERE exists(select lower(cp.CALC_NAME) as cpCalcName from vw_ppl_caseparty cp where cp.case_id = cv.id and lower(cp.CALC_NAME) like ''%'' || lower(''' || v_CalcName || ''') || ''%'')';
  elsif v_CalcName is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND exists(select lower(cp.CALC_NAME) as cpCalcName from vw_ppl_caseparty cp where cp.case_id = cv.id and lower(cp.CALC_NAME) like ''%'' || lower(''' || v_CalcName || ''') || ''%'')';
  end if;
  v_query := v_query || v_whereqry;
  v_query := v_query || ' order by cv.' || v_SORT || ' ' || v_DIR;
  v_query := '(' || v_query || ') v where rownum < ' || to_char(v_START + v_LIMIT + 1);
  v_query := v_query || ') where rn >= ' || to_char(v_START + 1) || '))';
  v_query2 := v_query;
  v_query := 'select cv.CaseFrom, cv.CaseId, cv.CaseState_Id, cv.CaseState_IsAssign, cv.CaseState_IsFinish, cv.CaseState_IsFix, cv.CaseState_IsResolve, cv.CaseState_IsStart, cv.CaseState_Name,
                          cv.CaseState_ISINPROCESS, cv.CaseState_ISDEFAULTONCREATE, cv.CaseSysType_Code, cv.CaseSysType_ColorCode, cv.CaseSysType_IconCode, cv.CaseSysType_Id, cv.CaseSysType_Name,
                          cv.CaseSysType_UseDataModel, cv.CaseSysType_IsDraftModeAvail, /*cv.Milestone_Id , cv.Milestone_Name, cv.Milestone_Code,*/cv.MS_StateName,
                          cv.GoalSlaEventTypeId, cv.GoalSlaEventTypeCode, cv.GoalSlaEventTypeName, cv.GoalSlaDateTime, cv.GoalSlaDuration,
                          cv.DLineSlaEventTypeId, cv.DLineSlaEventTypeCode, cv.DLineSlaEventTypeName, cv.DLineSlaDateTime, cv.DLineSlaDuration,
                          cv.Col_Id, cv.CreatedBy, cv.CreatedDate, cv.DateAssigned, cv.DateClosed, cv.Description, cv.Draft, cv.ExtSysId, cv.HoursSpent,
                          cv.ID, cv.IntegTarget_Id, cv.ManualDateResolved, cv.ManualWorkDuration, cv.Owner_Caseworker_Name, cv.Priority_Id, cv.Priority_Name, cv.Priority_Value,
                          cv.ResolutionCode_Code, cv.ResolutionCode_Icon, cv.ResolutionCode_Id, cv.ResolutionCode_Name, cv.ResolutionCode_Theme, cv.ResolutionDescription,
                          cv.Summary, cv.Workbasket_Id, cv.Workbasket_Name, cv.Workbasket_Type_Code, cv.Workbasket_Type_Name, cv.Workitem_Activity, cv.Workitem_Id, cv.Workitem_Workflow,
                          csla.nextslaseconds as nextslaseconds, csla.prevslaseconds as prevslaseconds,
  case when exists(select col_casetypedetcachecasetype from tbl_ac_casetypedetailcache where col_accesssubjectcode = sys_context(''CLIENTCONTEXT'', ''AccessSubject'')
                      and col_casetypedetcachecasetype = cv.CaseSysType_Id) then 1 else 0 end as PERM_CASETYPE_DETAIL,
                          (select assignorname from table(f_DCM_getCaseOwnerProxy2(CaseId => cv.Id))) as AssignorName,
                          (select assigneename from table(f_DCM_getCaseOwnerProxy2(CaseId => cv.Id))) as AssigneeName,
                          cv.CreatedBy_Name, cv.CreatedDuration, cv.ModifiedBy_Name, cv.ModifiedDuration,';
  if v_Case_Id is null then
    v_query := v_query || ' NULL as customdata,';
  elsif v_Case_Id is not null then
    v_query := v_query || ' F_dcm_getcasecustomdata(cv.id) as customdata,';
  end if;
  if v_Task_Id is null then
    v_query := v_query || ' NULL as TASK_ID,';
  elsif v_Case_Id is not null then
    v_query := v_query || to_char(v_Task_Id) || ' as TASK_ID,';
  end if;
  if v_Case_Id is null then
    v_query := v_query || ' NULL as DesignerPage_Id';
  elsif v_Case_Id is not null then
    v_query := v_query || ' f_dcm_getpageid(entity_id => cv.id, entity_type => ''case'')  as DesignerPage_Id';
  end if;
  if v_Case_Id is null then
    v_query := v_query || ' FROM vw_dcm_simplecasectaccachelst cv';
  elsif v_Case_Id is not null then
    v_query := v_query || ' FROM vw_dcm_simplecasectaccache cv';
  end if;
  --v_query := v_query || ' where cv.col_id in ' || v_query2;
  v_query := v_query || ' inner join ' || v_query2 || ' cv2 on cv.col_id = cv2.ID ';
  v_query := v_query || ' left join vw_dcm_caseslabytasks csla on nextcaseid = cv.col_id ';
  v_query := v_query || ' order by cv.' || v_SORT || ' ' || v_DIR;
  --v_countquery := 'SELECT COUNT(*) FROM (SELECT * FROM vw_dcm_simplecasectaccache cv ' || v_whereqry || ')';
  v_countquery := 'SELECT COUNT(*) FROM vw_dcm_simplecasectaccachelst cv ' || v_whereqry;
  BEGIN
    EXECUTE IMMEDIATE v_countquery
      INTO :TotalCount;
  EXCEPTION
    WHEN OTHERS THEN
        :ErrorCode := SQLCODE;
        :ErrorMessage := SUBSTR('Error in count query' || ': ' || SQLERRM, 1, 200);
  END;
  BEGIN
    OPEN :ITEMS FOR v_query;
  EXCEPTION
    WHEN OTHERS THEN :ErrorCode := SQLCODE;
        :ErrorMessage := SUBSTR('Error on search query' || ': ' || SQLERRM, 1, 200);
  END;
  --insert into tbl_log(col_bigdata1) values(v_query);
end;