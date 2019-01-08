DECLARE
  --INPUT
  v_case_id NUMBER;
  v_task_id NUMBER;

  v_stateConfigId            NUMBER;
  v_casetypeid               NUMBER;
  v_customcountdataprocessor NVARCHAR2(255);
  v_sourceActivity           NVARCHAR2(255);
  v_result                   NUMBER;

  v_CanClose     INTEGER;
  v_CanRoute     INTEGER;
  v_CanReopen    INTEGER;
  v_IsFinishCase INTEGER;
  v_counters     SYS_REFCURSOR;

  v_dir   NVARCHAR2(255);
  v_sort  NVARCHAR2(255);
  v_query VARCHAR2(32767);

  v_errorCode           NUMBER;
  v_errorMessage        NVARCHAR2(4000);
  v_validationErrorCode NUMBER;
  v_validationMessage   NVARCHAR2(4000);

BEGIN
  --INPUT
  v_case_id := :CASE_ID;
  v_task_id := :TASK_ID;
  v_sort    := NVL(:sort, 'SORDER, NAME');
  v_dir     := NVL(:dir, 'ASC');

  --calculated
  v_stateConfigId  := NULL;
  v_sourceActivity := NULL;

  --GET DATA IF EITHER CASEID OR TASKID IS PRESENT
  IF v_case_id > 0 OR v_task_id > 0 THEN
    OPEN :CUR_DATA FOR
      SELECT c.col_id AS ID,
             c.col_caseid AS CaseId,
             c.col_extsysid AS ExtSysId,
             c.col_int_integtargetcase AS IntegTarget_Id,
             c.col_summary AS SUMMARY,
             (SELECT col_description FROM tbl_caseext WHERE col_caseextcase = c.col_id) AS Description,
             c.col_createdby AS CreatedBy,
             c.col_createddate AS CreatedDate,
             c.col_modifiedby AS ModifiedBy,
             c.col_modifieddate AS ModifiedDate,
             f_getNameFromAccessSubject(c.col_createdby) AS CreatedBy_Name,
             f_UTIL_getDrtnFrmNow(c.col_createddate) AS CreatedDuration,
             f_getNameFromAccessSubject(c.col_modifiedby) AS ModifiedBy_Name,
             f_UTIL_getDrtnFrmNow(c.col_modifieddate) AS ModifiedDuration,
             (SELECT col_resolutiondescription FROM tbl_caseext WHERE col_caseextcase = c.col_id) AS ResolutionDescription,
             c.col_draft AS Draft,
             c.col_casefrom AS CaseFrom,
             f_DCM_getCaseCustomData(c.col_id) AS CustomData,
             
             --CASE TYPE
             cst.col_id               AS CaseSysType_Id,
             cst.col_name             AS CaseSysType_Name,
             cst.col_code             AS CaseSysType_Code,
             cst.col_iconcode         AS CaseSysType_IconCode,
             cst.col_colorcode        AS CaseSysType_ColorCode,
             cst.col_usedatamodel     AS CaseSysType_UseDataModel,
             cst.col_isdraftmodeavail AS CaseSysType_IsDraftModeAvail,
             
             --PRIORITY
             prty.col_id    AS Priority_Id,
             prty.col_name  AS Priority_Name,
             prty.col_value AS Priority_Value,
             
             --CASE STATE
             dts.col_id                 AS CaseState_Id,
             dts.col_name               AS CaseState_name,
             dts.col_isstart            AS CaseState_ISSTART,
             dts.col_isresolve          AS CaseState_ISRESOLVE,
             dts.col_isfinish           AS CaseState_ISFINISH,
             dts.col_isassign           AS CaseState_ISASSIGN,
             dts.col_isfix              AS CaseState_ISFIX,
             dts.col_isdefaultoncreate2 AS CaseState_ISINPROCESS,
             dts.col_isdefaultoncreate  AS CaseState_ISDEFAULTONCREATE,
             
             --OWNERSHIP
             wb.id                  AS Workbasket_id,
             wb.calcname            AS Workbasket_name,
             wb.workbaskettype_name AS Workbasket_type_name,
             wb.workbaskettype_code AS Workbasket_type_code,
             wb.emailaddress        AS Workbasket_email,
             
             --RESOLUTION
             c.col_stp_resolutioncodecase AS ResolutionCode_Id,
             rc.col_name                  AS ResolutionCode_Name,
             rc.col_iconcode              AS ResolutionCode_Icon,
             rc.col_theme                 AS ResolutionCode_Theme,
             
             --MILESTONE
             dict_state.col_id AS MS_StateId,
             dict_state.col_name AS MS_StateName,
             dict_state.col_commoncode AS MS_CommonCode,
             (SELECT col_id FROM tbl_dict_slaeventtype WHERE col_code = 'GOAL') AS GoalSlaEventTypeId,
             (SELECT col_code FROM tbl_dict_slaeventtype WHERE col_code = 'GOAL') AS GoalSlaEventTypeCode,
             (SELECT col_name FROM tbl_dict_slaeventtype WHERE col_code = 'GOAL') AS GoalSlaEventTypeName,
             c.col_goalsladatetime AS GoalSlaDateTime,
             (SELECT col_id FROM tbl_dict_slaeventtype WHERE col_code = 'DEADLINE') AS DLineSlaEventTypeId,
             (SELECT col_code FROM tbl_dict_slaeventtype WHERE col_code = 'DEADLINE') AS DLineSlaEventTypeCode,
             (SELECT col_name FROM tbl_dict_slaeventtype WHERE col_code = 'DEADLINE') AS DLineSlaEventTypeName,
             c.col_dlinesladatetime AS DLineSlaDateTime,
             f_util_getdrtnfrmnow(c.col_goalsladatetime) AS GoalSlaDuration,
             f_util_getdrtnfrmnow(c.col_dlinesladatetime) AS DLineSlaDuration,
             
             --PAGE DETAIL DATA
             f_dcm_getpageid(entity_id => c.col_id, entity_type => 'case') AS DesignerPage_Id,
             
             --PERMISSIONS
             CASE
               WHEN EXISTS (SELECT col_casetypedetcachecasetype
                       FROM tbl_ac_casetypedetailcache
                      WHERE col_accesssubjectcode = sys_context('CLIENTCONTEXT', 'AccessSubject')
                        AND col_casetypedetcachecasetype = c.col_casedict_casesystype) THEN
                1
               ELSE
                0
             END AS PERM_CASETYPE_DETAIL,
             CASE
               WHEN EXISTS (SELECT col_casetypemodcachecasetype
                       FROM tbl_ac_casetypemodifycache
                      WHERE col_accesssubjectcode = sys_context('CLIENTCONTEXT', 'AccessSubject')
                        AND col_casetypemodcachecasetype = c.col_casedict_casesystype) THEN
                1
               ELSE
                0
             END AS PERM_CASETYPE_MODIFY
        FROM tbl_case c
        LEFT JOIN tbl_stp_priority prty
          ON c.col_stp_prioritycase = prty.col_id
        LEFT JOIN tbl_cw_workitem cw
          ON c.col_cw_workitemcase = cw.col_id
        LEFT JOIN tbl_dict_casestate dts
          ON cw.col_cw_workitemdict_casestate = dts.col_id
        LEFT JOIN tbl_dict_casesystype cst
          ON c.col_casedict_casesystype = cst.col_id
        LEFT JOIN vw_ppl_simpleworkbasket wb
          ON (wb.id = c.col_caseppl_workbasket)
        LEFT JOIN tbl_stp_resolutioncode rc
          ON c.col_stp_resolutioncodecase = rc.col_id
        LEFT JOIN tbl_dict_stateconfig sc
          ON cst.col_stateconfigcasesystype = sc.col_id
        LEFT JOIN tbl_dict_state dict_state
          ON c.col_casedict_state = dict_state.col_id
        WHERE 1 = 1
             <%=IfNotNull(":Case_Id", " AND c.col_id = :Case_Id")%>
             <%=IfNotNull(":Task_Id", " AND c.col_id = (SELECT COL_CASETASK FROM TBL_TASK WHERE COL_ID = :Task_Id)")%>
             ;
  END IF;

  IF v_case_id > 0 THEN
    -- GET ROUTING DATA
    v_result := f_DCM_validateCaseLinks(TRANSITIONID => NULL,
                                        CASE_ID      => v_case_id,
                                        ERRORCODE    => v_validationErrorCode,
                                        ERRORMESSAGE => v_validationMessage,
                                        TARGET       => NULL,
                                        CANCLOSE     => v_CanClose,
                                        CANROUTE     => v_CanRoute);
  
    -- get IsFinishCase flag
    BEGIN
      SELECT CASESTATE_ISFINISH INTO v_IsFinishCase FROM vw_dcm_simplecase WHERE id = v_case_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_IsFinishCase := 0;
    END;
  
    --Check access to Close Case
    IF v_CanClose = 1 THEN
      BEGIN
        SELECT f_dcm_iscasetypeclosealwms(AccessObjectId => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = v_case_id)))
          INTO v_CanClose
          FROM dual;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_CanClose := 1;
      END;
    END IF;
  
    --Check access to Route Case
    IF v_CanRoute = 1 THEN
      BEGIN
        SELECT f_dcm_iscasetyperoutealwms(AccessObjectId => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = v_case_id)))
          INTO v_CanRoute
          FROM dual;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_CanRoute := 1;
      END;
    END IF;
  
    --Check access to Reopen Case
    IF v_CanRoute = 1 THEN
      BEGIN
        SELECT f_dcm_iscasetypeaccess(accessobjectid => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = v_case_id)),
                                      permissioncode => 'REOPEN')
          INTO v_CanReopen
          FROM dual;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_CanReopen := 1;
      END;
    END IF;
  
    --define a source activity
    BEGIN
      SELECT cs.col_milestoneactivity,
             s.COL_STATESTATECONFIG
        INTO v_sourceActivity,
             v_stateConfigId
        FROM TBL_CASE cs
        LEFT OUTER JOIN TBL_DICT_STATE s
          ON s.col_ID = cs.COL_CASEDICT_STATE
       WHERE cs.COL_ID = v_case_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_ErrorCode    := 101;
        v_ErrorMessage := 'Cant define a Source Activity for Case#' || TO_CHAR(v_case_id);
        GOTO cleanup;
      WHEN OTHERS THEN
        v_ErrorCode    := 101;
        v_ErrorMessage := 'Cant define a Source Activity for Case#' || TO_CHAR(v_case_id);
        GOTO cleanup;
    END;
  
    --get next states for the case
    v_query := '  select cst.col_id           as ID,';
    v_query := v_query || '         cst.col_name         as NAME,';
    v_query := v_query || '         cst.col_code         as CODE,';
    v_query := v_query || '         cst.col_iconcode     as ICONCODE,';
    v_query := v_query || '         cst.col_colorcode    as COLORCODE,';
    v_query := v_query || '         cst.col_sorder       as SORDER,';
    v_query := v_query || '         csts1.col_id         as TARGET_MSSTATEID,';
    v_query := v_query || '         csts1.col_name       as TARGET_MSSTATENAME,';
    v_query := v_query || '         csts1.col_activity   as TARGET_ACTIVITY,';
    v_query := v_query || '         csts.col_activity    as TARGET_ACTIVITYSYS,';
    v_query := v_query || '         csts.col_isstart     as TARGET_ISSTART,';
    v_query := v_query || '         csts.col_isresolve   as TARGET_ISRESOLVE,';
    v_query := v_query || '         csts.col_isfinish    as TARGET_ISFINISH,';
    v_query := v_query || '         csts.col_isassign    as TARGET_CANASSIGN,';
    v_query := v_query || '         csts1.col_name||'': ''||cst.col_name AS CALCNAME';
    v_query := v_query || '  from   TBL_DICT_TRANSITION cst';
    v_query := v_query || '  inner join TBL_DICT_STATE csss1 on cst.COL_SOURCETRANSITIONSTATE = csss1.col_id';
    v_query := v_query || '  inner join TBL_DICT_CASESTATE csss on csss1.COL_STATECASESTATE = csss.col_id';
    v_query := v_query || '  inner join TBL_DICT_STATE csts1 on cst.COL_TARGETTRANSITIONSTATE = csts1.col_id';
    v_query := v_query || '  inner join TBL_DICT_CASESTATE csts on csts1.COL_STATECASESTATE = csts.col_id';
    v_query := v_query || '  WHERE ' || v_CanRoute || ' = 1';
    v_query := v_query || '        AND ( ' || to_char(NVL(v_CanClose, 0)) || ' = 1 OR  NVL(csts.col_isfinish,0) = 0 )';
    v_query := v_query || '        AND ( ' || to_char(NVL(v_IsFinishCase, 0)) || ' = 0 OR (' || to_char(NVL(v_CanReopen, 0)) || ' = 1 AND ' || to_char(NVL(v_IsFinishCase, 0)) || ' = 1 ))';
    v_query := v_query || '        AND nvl(cst.COL_NOTSHOWINUI, 0) = 0';
    v_query := v_query || '        AND csss1.COL_STATESTATECONFIG = ' || v_stateConfigId;
    v_query := v_query || '        AND csts1.COL_STATESTATECONFIG = ' || v_stateConfigId;
    v_query := v_query || '        AND UPPER(csss1.col_activity)=UPPER(''' || v_sourceActivity || ''')';
    v_query := v_query || ' ORDER BY ' || v_sort || ' ' || v_dir;
  
    BEGIN
      OPEN :CUR_AVAILTRANSITIONS FOR v_query;
    EXCEPTION
      WHEN OTHERS THEN
        v_ErrorCode    := SQLCODE;
        v_ErrorMessage := SUBSTR('Error on query' || ': ' || SQLERRM, 1, 200);
        GOTO cleanup;
    END;
  
    --get resolution codes for the case
    OPEN :CUR_RESCODES FOR
      SELECT rc.col_id          AS ID,
             rc.col_code        AS CODE,
             rc.col_description AS DESCRIPTION,
             rc.col_name        AS NAME,
             rc.col_iconcode    AS ICONCODE,
             rc.col_theme       AS THEME
        FROM tbl_case t
       INNER JOIN tbl_casesystyperesolutioncode m
          ON m.col_tbl_dict_casesystype = t.col_casedict_casesystype
       INNER JOIN tbl_stp_resolutioncode rc
          ON rc.col_id = m.col_casetyperesolutioncode
       WHERE t.col_id = v_case_id
       ORDER BY UPPER(rc.col_name);
  
    -- GET COUNTERS DATA
    v_query      := '';
    v_casetypeid := f_DCM_getCaseTypeForCase(v_case_id);
    BEGIN
      SELECT NVL(col_customcountdataprocessor, 'f_dcm_getobjectcountsfn') INTO v_customcountdataprocessor FROM tbl_dict_casesystype WHERE col_id = v_casetypeid;
    EXCEPTION
      WHEN no_data_found THEN
        v_customcountdataprocessor := 'f_dcm_getobjectcountsfn';
    END;
    v_query := 'begin ' || ':' || 'v_result := ' || v_customcountdataprocessor;
    v_query := v_query || '(CaseId => ' || ':' || 'v_case_id, TaskId => NULL, ExternalPartyId => NULL, ITEMS => ' || ':' || 'v_counters); end;';
  
    EXECUTE IMMEDIATE v_query
      USING OUT v_result, v_case_id, OUT v_counters;
  
    :CUR_COUNTERS := v_counters;
  
  END IF;

  <<cleanup>>
  :ERRORCODE           := v_ErrorCode;
  :ERRORMESSAGE        := v_ErrorMessage;
  :VALIDATIONMESSAGE   := v_validationMessage;
  :VALIDATIONERRORCODE := v_validationErrorCode;
END;