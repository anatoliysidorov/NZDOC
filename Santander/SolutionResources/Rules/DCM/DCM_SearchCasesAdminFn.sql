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
  v_MilestoneIds varchar2(32767);
  v_availcasetype varchar2(32767);
  v_GoalSlaEventTypeId Integer;
  v_GoalSlaEventTypeCode nvarchar2(255);
  v_GoalSlaEventTypeName nvarchar2(255);
  v_DLineSlaEventTypeId Integer;
  v_DLineSlaEventTypeCode nvarchar2(255);
  v_DLineSlaEventTypeName nvarchar2(255);
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
  v_MilestoneIds := REPLACE(:MilestoneIds, '''', '');

  v_CaseId := REPLACE(v_CaseId, '''', '''''');
  v_summary := REPLACE(v_summary, '''', '''''');
  v_DESCRIPTION := REPLACE(v_DESCRIPTION, '''', '''''');
  v_CalcName := REPLACE(v_CalcName, '''', '''''');
  v_workbasket_name := REPLACE(v_workbasket_name, '''', '''''');
  v_CalcEmail := REPLACE(v_CalcEmail, '''', '''''');
  v_CalcExtSysId := REPLACE(v_CalcExtSysId, '''', '''''');
  v_CalcName := REPLACE(v_CalcName, '''', '''''');

  if lower(trim(v_SORT)) = 'goalsladuration' then
    v_SORT := 'GOALSLADATETIME';
  end if;
  if lower(trim(v_SORT)) = 'dlinesladuration' then
    v_SORT := 'DLINESLADATETIME';
  end if;
  if lower(trim(v_SORT)) = 'createdduration' then
    v_SORT := 'CREATEDDATE';
  end if;

  --DBMS_SESSION.SET_CONTEXT ('CLIENTCONTEXT', 'AccessSubject', '6D627AB101B02947E0530405000A0739');

  /*DCM-5601 - MGill*/
  /*v_availcasetype := null;
  for rec in (select col_casetypeviewcachecasetype from tbl_ac_casetypeviewcache where col_accesssubjectcode = sys_context('CLIENTCONTEXT', 'AccessSubject'))
  loop
    if v_availcasetype is null then
      v_availcasetype := rec.col_casetypeviewcachecasetype;
    else
      v_availcasetype := v_availcasetype || ',' || rec.col_casetypeviewcachecasetype;
    end if;
  end loop;
  if v_availcasetype is null then
    TotalCount := 0;
    Items := null;
    return 0;
  end if;*/

  begin
    select col_id, col_code, col_name into v_GoalSlaEventTypeId, v_GoalSlaEventTypeCode, v_GoalSlaEventTypeName from tbl_dict_slaeventtype where col_code = 'GOAL';
    exception
    when NO_DATA_FOUND then
    v_GoalSlaEventTypeId := 0;
    v_GoalSlaEventTypeCode := 'null';
    v_GoalSlaEventTypeName := 'null';
  end;

  begin
    select col_id, col_code, col_name into v_DLineSlaEventTypeId, v_DLineSlaEventTypeCode, v_DLineSlaEventTypeName from tbl_dict_slaeventtype where col_code = 'DEADLINE';
    exception
    when NO_DATA_FOUND then
    v_DLineSlaEventTypeId := 0;
    v_DLineSlaEventTypeCode := 'null';
    v_DLineSlaEventTypeName := 'null';
  end;

  --Start building of SQL statement
  --v_query := 'select ID from (select /*+ FIRST_ROWS(' || to_char(v_LIMIT) || ') */ ID, rn from (select ID, rownum rn from (select ';
  --v_query := 'select ID from (select ID, rn from (select ID, rownum rn from (select ';
  v_query := 'select ID, rn from (select ID, rn from (select ID, rownum rn from (select ';
  if lower(v_SORT) <> 'id' then
    v_query := v_query || 'cv.' || v_SORT || ', cv.ID';
  else
    v_query := v_query || 'cv.ID';
  end if;
  if lower(trim(v_sort)) = 'goalsladuration' or lower(trim(v_sort)) = 'goalsladatetime' then
    v_query := v_query || ' from (select cv.col_id as ID, cv.col_goalsladatetime  as GOALSLADATETIME from tbl_case cv ';
  elsif lower(trim(v_sort)) = 'dlinesladuration' or lower(trim(v_sort)) = 'dlinesladatetime' then
    v_query := v_query || ' from (select cv.col_id as ID, cv.col_dlinesladatetime  as DLINESLADATETIME from tbl_case cv ';
  elsif lower(trim(v_sort)) = 'createdby_name' then
    v_query := v_query || ' from (select cv.col_id as ID, p.FIRSTNAME || '' '' || p.LASTNAME AS CreatedBy_Name
                          FROM tbl_case cv
               left join ' || '@TOKEN_SYSTEMDOMAINUSER@' || '.asf_accesssubject acc on acc.code = cv.col_createdby
               left join ' || '@TOKEN_SYSTEMDOMAINUSER@' || '.asf_user u on acc.accesssubjectid = u.accesssubjectid
               left join ' || '@TOKEN_SYSTEMDOMAINUSER@' || '.user_profile p on u.userid = p.userid ';
  elsif lower(trim(v_sort)) = 'modifiedby_name' then
    v_query := v_query || ' from (select cv.col_id as ID, p.FIRSTNAME || '' '' || p.LASTNAME AS ModifiedBy_Name
                          FROM tbl_case cv
               left join ' || '@TOKEN_SYSTEMDOMAINUSER@' || '.asf_accesssubject acc on acc.code = cv.col_modifiedby
               left join ' || '@TOKEN_SYSTEMDOMAINUSER@' || '.asf_user u on acc.accesssubjectid = u.accesssubjectid
               left join ' || '@TOKEN_SYSTEMDOMAINUSER@' || '.user_profile p on u.userid = p.userid ';
  elsif lower(trim(v_sort)) = 'id' then
    v_query := v_query || ' from (select cv.col_id as ID
                                  FROM tbl_case cv ';
  elsif lower(trim(v_sort)) = 'caseid' then
    v_query := v_query || ' from (select cv.col_id as ID, cv.col_CaseId as CaseId
                                  FROM tbl_case cv ';
  elsif lower(trim(v_sort)) = 'summary' then
    v_query := v_query || ' from (select cv.col_id as ID, cv.col_Summary as Summary
                                  FROM tbl_case cv ';
  elsif lower(trim(v_sort)) = 'createdduration' or lower(trim(v_sort)) = 'createddate' then
    v_query := v_query || ' from (select cv.col_id as ID, cv.col_CreatedDate as CreatedDate, f_UTIL_getDrtnFrmNow (cv.col_createddate) as CreatedDuration
                                  FROM tbl_case cv ';
  elsif lower(trim(v_sort)) = 'modifiedduration' or lower(trim(v_sort)) = 'modifieddate' then
    v_query := v_query || ' from (select cv.col_id as ID, cv.col_ModifiedDate as ModifiedDate, f_UTIL_getDrtnFrmNow (cv.col_modifieddate) as ModifiedDuration
                                  FROM tbl_case cv ';
  elsif lower(trim(v_sort)) = 'casesystype_name' then
    v_query := v_query || ' from (select cv.col_id as ID, cst.col_name as CaseSysType_Name
                                  FROM tbl_case cv LEFT JOIN tbl_dict_casesystype cst ON cv.col_casedict_casesystype = cst.col_id ';
  elsif lower(trim(v_sort)) = 'workbasket_name' then
    v_query := v_query || ' from (select cv.col_id as ID, wb.calcname as Workbasket_Name
                                  FROM tbl_case cv LEFT JOIN vw_ppl_simpleworkbasket wb ON cv.col_caseppl_workbasket = wb.id ';
  elsif lower(trim(v_sort)) = 'priority_value' then
    v_query := v_query || ' from (select cv.col_id as ID, prty.col_Value as Priority_Value
                                  FROM tbl_case cv LEFT JOIN tbl_stp_priority prty ON cv.col_stp_prioritycase = prty.col_id ';
  elsif lower(trim(v_sort)) = 'ms_statename' then
    v_query := v_query || ' from (select cv.col_id as ID, dict_state.col_name AS MS_StateName
                                  FROM tbl_case cv LEFT JOIN tbl_dict_state dict_state ON cv.col_casedict_state = dict_state.col_id ';
  elsif lower(trim(v_sort)) = 'resolutioncode_name' then
    v_query := v_query || ' from (select cv.col_id as ID, rc.col_Name AS ResolutionCode_Name
                                  FROM tbl_case cv LEFT JOIN tbl_stp_resolutioncode rc ON cv.col_stp_resolutioncodecase = rc.col_id';
  else
    v_query := v_query || ' from (vw_dcm_casectaccachelstsimple cv ';
  end if;
  if v_CaseworkerIds is not null or v_TeamIds is not null then
    v_query := v_query || ' inner join tbl_caseparty cp on cv.col_id = cp.col_casepartycase ';
  end if;
  v_whereqry := null;
  if v_Task_Id is not null then
    v_whereqry := ' WHERE cv.col_id = (select col_casetask from tbl_task where col_id  = ' || to_char(v_Task_Id) || ')';
  end if;
  if v_Case_Id is not null and v_whereqry is null then
    v_whereqry := ' WHERE cv.col_id = ' || to_char(v_Case_Id);
  elsif v_Case_Id is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cv.col_id = ' || to_char(v_Case_Id);
  end if;
  if v_CaseStateIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE cv.col_casedict_casestate in (' || v_CaseStateIds || ')';
  elsif v_CaseStateIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cv.col_casedict_casestate in (' || v_CaseStateIds || ')';
  end if;
  if v_MilestoneIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE cv.col_casedict_state in (' || v_MilestoneIds || ')';
  elsif v_MilestoneIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cv.col_casedict_state in (' || v_MilestoneIds || ')';
  end if;
  if v_CaseId is not null and v_whereqry is null then
    v_whereqry := ' WHERE lower(cv.col_caseid) LIKE lower(''%' || v_CaseId || '%'')';
  elsif v_CaseId is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND lower(cv.col_caseid) LIKE lower(''%' || v_CaseId || '%'')';
  end if;
  if v_summary is not null and v_whereqry is null then
    v_whereqry := ' WHERE LOWER(cv.col_summary) LIKE lower(''%' || v_summary || '%'')';
  elsif v_summary is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND LOWER(cv.col_summary) LIKE lower(''%' || v_summary || '%'')';
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
    v_whereqry := ' WHERE trunc(cv.col_CREATEDDATE) >= trunc(to_date(''' || to_char(v_CREATED_START) || '''))';
  elsif v_CREATED_START is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND trunc(cv.col_CREATEDDATE) >= trunc(to_date(''' || to_char(v_CREATED_START) || '''))';
  end if;
  if v_CREATED_END is not null and v_whereqry is null then
    v_whereqry := ' WHERE trunc(cv.col_CREATEDDATE) <= trunc(to_date(''' || to_char(v_CREATED_END) || '''))';
  elsif v_CREATED_END is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND trunc(cv.col_CREATEDDATE) <= trunc(to_date(''' || to_char(v_CREATED_END) || '''))';
  end if;
  if v_CaseSysType_Code is not null and v_whereqry is null then
    v_whereqry := ' WHERE cv.casesystype_code in (select trim(regexp_substr(' || '''' || v_CaseSysType_Code || ''',''[^,]+'',' || '1,level)) c2 from dual connect by level <= length(' || '''' || v_CaseSysType_Code || ''')' || ' - length(replace(' ||  '''' || v_CaseSysType_Code || ''','','',''''))+1) ';
  elsif v_CaseSysType_Code is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cv.casesystype_code in (select trim(regexp_substr(' || '''' || v_CaseSysType_Code || ''',''[^,]+'',' || '1,level)) c2 from dual connect by level <= length(' || '''' || v_CaseSysType_Code || ''')' || ' - length(replace(' ||  '''' || v_CaseSysType_Code || ''','','',''''))+1) ';
  end if;
  if v_WorkbasketIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE cv.col_caseppl_workbasket in (' || v_WorkbasketIds || ')';
  elsif v_WorkbasketIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cv.col_caseppl_workbasket in (' || v_WorkbasketIds || ')';
  end if;
  if v_PriorityIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE cv.col_stp_prioritycase in (' || v_PriorityIds || ')';
  elsif v_PriorityIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cv.col_stp_prioritycase in (' || v_PriorityIds || ')';
  end if;
  if v_ResolutionCodeIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE cv.col_stp_resolutioncodecase in (' || v_ResolutionCodeIds || ')';
  elsif v_ResolutionCodeIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cv.col_stp_resolutioncodecase in (' || v_ResolutionCodeIds || ')';
  end if;
  if v_CaseSysTypeIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE cv.col_casedict_casesystype in (' || v_CaseSysTypeIds || ')';
  elsif v_CaseSysTypeIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cv.col_casedict_casesystype in (' || v_CaseSysTypeIds || ')';
  end if;
  if v_CaseworkerIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE cp.col_casepartyppl_caseworker in (' || v_CaseworkerIds || ')';
  elsif v_CaseworkerIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cp.col_casepartyppl_caseworker in (' || v_CaseworkerIds || ')';
  end if;
  if v_TeamIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE cp.col_casepartyppl_team in (' || v_TeamIds || ')';
  elsif v_TeamIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cp.col_casepartyppl_team in (' || v_TeamIds || ')';
  end if;
  if v_ExternalPartyIds is not null and v_whereqry is null then
    v_whereqry := ' WHERE cp.col_casepartyexternalparty in (' || v_ExternalPartyIds || ')';
  elsif v_ExternalPartyIds is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ' AND cp.col_casepartyexternalparty in (' || v_ExternalPartyIds || ')';
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
  /*DCM-5601 - MGill*/
  /*if v_whereqry is null then
    v_whereqry := ' WHERE cv.col_casedict_casesystype in (' || v_availcasetype || ')';
  else
    v_whereqry := v_whereqry || ' AND cv.col_casedict_casesystype in (' || v_availcasetype || ')';
  end if;*/
  v_query := v_query || v_whereqry || ') cv';
  v_countquery := 'SELECT COUNT(*) FROM (' || v_query || '))) cv )';
  v_query := v_query || ' order by cv.' || v_SORT || ' ' || v_DIR;
  v_query := '(' || v_query || ') v where rownum < ' || to_char(v_START + v_LIMIT + 1);
  v_query := v_query || ') where rn >= ' || to_char(v_START + 1) || '))';
  v_query2 := v_query;
  v_query := 'select cs.col_casefrom as CaseFrom, cs.col_caseid as CaseId, cs.col_casedict_casestate as CaseState_Id, dts.col_isassign as CaseState_IsAssign, dts.col_isfinish as CaseState_IsFinish,
  dts.col_isfix as CaseState_IsFix, dts.col_isresolve as CaseState_IsResolve, dts.col_isstart as CaseState_IsStart, dts.col_name as CaseState_Name, dts.col_isdefaultoncreate2 as CaseState_IsInProcess,
  dts.col_isdefaultoncreate as CaseState_IsDefaultOnCreate, cst.col_code as CaseSysType_Code, cst.col_colorcode as CaseSysType_ColorCode, cst.col_iconcode as CaseSysType_IconCode,
  cs.col_casedict_casesystype as CaseSysType_Id, cst.col_name as CaseSysType_Name, cst.col_usedatamodel as CaseSysType_UseDataModel, cst.col_isdraftmodeavail as CaseSysType_IsDraftModeAvail,
  dict_state.col_name as MS_StateName, ' ||
  v_GoalSlaEventTypeId || ' as GoalSlaEventTypeId, ''' || v_GoalSlaEventTypeCode || ''' as GoalSlaEventTypeCode, ''' || v_GoalSlaEventTypeName || ''' as GoslSlaEventTypeName, ' ||
  'cs.col_goalsladatetime as GoalSlaDateTime, F_util_getdrtnfrmnow(cs.col_goalsladatetime) as GoalSlaDuration, ' ||
  v_DLineSlaEventTypeId || ' as DLineSlaEventTypeId, ''' || v_DLineSlaEventTypeCode || ''' as DLineSlaEventTypeCode, ''' || v_DLineSlaEventTypeName || ''' as DLineSlaEventTypeName, ' ||
  'cs.col_dlinesladatetime as DLineSlaDateTime, F_util_getdrtnfrmnow(cs.col_dlinesladatetime) as DLineSlaDuration,
  cs.col_id as Col_Id, cs.col_createdby as CreatedBy, cs.col_createddate as CreatedDate,
 /* (select col_description from tbl_caseext where col_caseextcase = cs.col_id)*/ null as Description,
  cs.col_draft as Draft, cs.col_extsysid as ExtSysId, cs.col_id as ID, cs.col_int_integtargetcase as IntegTarget_Id,
  cs.col_manualdateresolved as ManualDateResolved, cs.col_manualworkduration as ManualWorkDuration,
  wb.calcname as Owner_Caseworker_Name,
  cs.col_stp_prioritycase as Priority_Id, prty.col_name as Priority_Name, prty.col_value as Priority_Value,
  rc.col_code as ResolutionCode_Code, rc.col_iconcode as ResolutionCode_Icon, cs.col_stp_resolutioncodecase as ResolutionCode_Id, rc.col_name as ResolutionCode_Name,
  rc.col_theme as ResolutionCode_Theme, rc.col_description as ResolutionDescription,
  cs.col_summary as Summary,
  cs.col_caseppl_workbasket as Workbasket_Id, wb.calcname as Workbasket_Name, wb.workbaskettype_code as Workbasket_Type_Code, wb.workbaskettype_name as Workbasket_Type_Name,
  cs.col_activity as Workitem_Activity, cs.col_cw_workitemcase as Workitem_Id, null as Workitem_Workflow,
  case when exists(select col_casetypedetcachecasetype from tbl_ac_casetypedetailcache where col_accesssubjectcode = sys_context(''CLIENTCONTEXT'', ''AccessSubject'')
                   and col_casetypedetcachecasetype = cs.col_casedict_casesystype) then 1 else 0 end as PERM_CASETYPE_DETAIL,
  case when exists(select col_casetypemodcachecasetype from tbl_ac_casetypemodifycache where col_accesssubjectcode = sys_context(''CLIENTCONTEXT'', ''AccessSubject'')
                   and col_casetypemodcachecasetype = cs.col_casedict_casesystype) then 1 else 0 end as PERM_CASETYPE_MODIFY,
  f_getNameFromAccessSubject(cs.col_createdby) as CreatedBy_Name, f_UTIL_getDrtnFrmNow(cs.col_createddate) as CreatedDuration,
  f_getNameFromAccessSubject(cs.col_modifiedby) as ModifiedBy_Name, f_UTIL_getDrtnFrmNow (cs.col_modifieddate) as ModifiedDuration,';
  if v_Case_Id is null then
    v_query := v_query || ' NULL as customdata,';
  elsif v_Case_Id is not null then
    v_query := v_query || ' dbms_xmlgen.CONVERT(F_dcm_getcasecustomdata(cs.col_id)) as customdata,';
  end if;
  if v_Task_Id is null then
    v_query := v_query || ' NULL as TASK_ID,';
  elsif v_Case_Id is not null then
    v_query := v_query || to_char(v_Task_Id) || ' as TASK_ID,';
  end if;
  if v_Case_Id is null then
    v_query := v_query || ' NULL as DesignerPage_Id';
  elsif v_Case_Id is not null then
    v_query := v_query || ' f_dcm_getpageid(entity_id => cs.col_id, entity_type => ''case'')  as DesignerPage_Id';
  end if;
  /*
  if v_Case_Id is null then
    v_query := v_query || ' FROM vw_dcm_simplecaselist cv';
  elsif v_Case_Id is not null then
    v_query := v_query || ' FROM vw_dcm_simplecasectaccache cv';
  end if;
  v_query := v_query || ' where cv.col_id in ' || v_query2;
  */
  -----------------------------------------------------------------------------------------------------------
  v_query := v_query || ' from (' || v_query2 || ') c';
  if v_Case_Id is null then
    /*
    v_query := v_query || ' inner join vw_dcm_simplecaselist cv on c.id = cv.id ';
    */
    ---------------------------------------------------------------------------------------------------------
    --Switch from view to set of tables----------------------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------
    v_query := v_query || ' inner join tbl_case cs on c.id = cs.col_id ' ||
          ' left join tbl_dict_casestate dts on cs.col_casedict_casestate = dts.col_id ' ||
          ' left join tbl_dict_casesystype cst on cs.col_casedict_casesystype = cst.col_id ' ||
          ' left join vw_ppl_workbasketsimple wb on cs.col_caseppl_workbasket = wb.id ' ||
          ' left join tbl_stp_priority prty on cs.col_stp_prioritycase = prty.col_id ' ||
          ' left join tbl_stp_resolutioncode rc on cs.col_stp_resolutioncodecase = rc.col_id ' ||
          ' left join tbl_dict_state dict_state ON cs.col_casedict_state = dict_state.col_id ';
    --------------------------------------------------------------------------------------------------------
  else
    /*
    v_query := v_query || ' inner join vw_dcm_simplecasectaccache cv on c.id = cv.id ';
    */
    ---------------------------------------------------------------------------------------------------------
    v_query := v_query || ' inner join tbl_case cs on c.id = cs.col_id ' ||
          ' left join tbl_dict_casestate dts on cs.col_casedict_casestate = dts.col_id ' ||
          ' left join tbl_dict_casesystype cst on cs.col_casedict_casesystype = cst.col_id ' ||
          ' left join vw_ppl_workbasketsimple wb on cs.col_caseppl_workbasket = wb.id ' ||
          ' left join tbl_stp_priority prty on cs.col_stp_prioritycase = prty.col_id ' ||
          ' left join tbl_stp_resolutioncode rc on cs.col_stp_resolutioncodecase = rc.col_id ' ||
          ' left join tbl_dict_state dict_state ON cs.col_casedict_state = dict_state.col_id ';
    ---------------------------------------------------------------------------------------------------------
  end if;
  ------------------------------------------------------------------------------------------------------------
  v_query := v_query || ' order by c.rn';
  --insert into tbl_log(col_bigdata1) values(v_query);
  --return -1;
  if v_Case_Id is not null then
    :TotalCount := 1;
  else
    BEGIN
      EXECUTE IMMEDIATE v_countquery
        INTO :TotalCount;
    EXCEPTION
      WHEN OTHERS THEN
          :ErrorCode := SQLCODE;
          :ErrorMessage := SUBSTR('Error in count query' || ': ' || SQLERRM, 1, 200);
    END;
  end if;
  BEGIN
    OPEN :ITEMS FOR v_query;
  EXCEPTION
    WHEN OTHERS THEN :ErrorCode := SQLCODE;
        :ErrorMessage := SUBSTR('Error on search query' || ': ' || SQLERRM, 1, 200);
  END;
  --insert into tbl_log(col_bigdata1) values(v_countquery);
  --insert into tbl_log(col_bigdata1) values(v_query);
end;
