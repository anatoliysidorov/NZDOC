DECLARE
--input
  v_case_id       NUMBER;
  v_stateConfigId NUMBER;
  v_sourceActivity NVARCHAR2(255);
  v_result  NVARCHAR2(255);

  v_CanClose INTEGER;
  v_CanRoute INTEGER;
  v_CanReopen INTEGER;
  v_IsFinishCase INTEGER;

  v_dir nvarchar2(255);
  v_sort nvarchar2(255);
  v_query varchar2(32767);

  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(4000);
  v_validationErrorCode NUMBER;
  v_validationMessage NVARCHAR2(4000);
BEGIN
  --input
  v_case_id := :case_Id;
  v_sort := NVL(:sort,'SORDER, NAME');
  v_dir := NVL(:dir,'ASC');

  --calculated
  v_stateConfigId :=NULL;
  v_sourceActivity :=NULL;

  v_result := f_DCM_validateCaseLinks(TRANSITIONID => NULL,
                                      CASE_ID       => v_case_id, 
                                      ERRORCODE     => v_validationErrorCode,
                                      ERRORMESSAGE  => v_validationMessage,
                                      TARGET        => NULL,
                                      CANCLOSE      => v_CanClose,
                                      CANROUTE      => v_CanRoute);

  -- get IsFinishCase flag
  begin
  select CASESTATE_ISFINISH INTO v_IsFinishCase from vw_dcm_simplecase where id = v_case_id;
    exception
    when NO_DATA_FOUND then
          v_IsFinishCase := 0;
  end;
  
  --Check access to Close Case
  if v_CanClose = 1 then
    begin
      select f_dcm_iscasetypeclosealwms(AccessObjectId => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) where CaseTypeId = (select col_casedict_casesystype from tbl_case where col_id = v_case_id))) into v_CanClose from dual;
      exception
      when NO_DATA_FOUND then
      v_CanClose := 1;
    end;
  end if;

  --Check access to Route Case
  if v_CanRoute = 1 then
    begin
      select f_dcm_iscasetyperoutealwms(AccessObjectId => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) where CaseTypeId = (select col_casedict_casesystype from tbl_case where col_id = v_case_id))) into v_CanRoute from dual;
      exception
      when NO_DATA_FOUND then
      v_CanRoute := 1;
    end;
  end if;

  --Check access to Reopen Case
  if v_CanRoute = 1 then
    begin
      select f_dcm_iscasetypeaccess(accessobjectid => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = (select col_casedict_casesystype from tbl_case where col_id = v_case_id)), permissioncode => 'REOPEN') into v_CanReopen from dual;
      exception
      when NO_DATA_FOUND then
      v_CanReopen := 1;
    end;
  end if;
  
  --define a source activity
  BEGIN
    SELECT cs.col_milestoneactivity, s.COL_STATESTATECONFIG INTO v_sourceActivity, v_stateConfigId
    FROM TBL_CASE cs 
    LEFT OUTER JOIN TBL_DICT_STATE s ON s.col_ID =cs.COL_CASEDICT_STATE
    WHERE cs.COL_ID=v_case_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN 
      v_ErrorCode := 101;
      v_ErrorMessage := 'Cant define a Source Activity for Case#'||TO_CHAR(v_case_id);    
      goto CLEANUP;
    WHEN OTHERS THEN 
      v_ErrorCode := 101;
      v_ErrorMessage := 'Cant define a Source Activity for Case#'||TO_CHAR(v_case_id);    
      goto CLEANUP;    
  END;  
  
  --system
  --:ErrorCode := NULL;
  --:ErrorMessage := NULL;

  --get next states for the case
v_query := '  select cst.col_id           as ID,';
v_query := v_query || '         cst.col_name         as NAME,';
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
v_query := v_query || '  WHERE '|| v_CanRoute ||' = 1';
v_query := v_query || '        AND ( '|| to_char(NVL(v_CanClose,0)) || ' = 1 OR  NVL(csts.col_isfinish,0) = 0 )';
v_query := v_query || '        AND ( '||  to_char(NVL(v_IsFinishCase,0)) || ' = 0 OR ('|| to_char(NVL(v_CanReopen,0)) || ' = 1 AND '||  to_char(NVL(v_IsFinishCase,0)) || ' = 1 ))';
v_query := v_query || '        AND csss1.COL_STATESTATECONFIG = '|| v_stateConfigId;
v_query := v_query || '        AND csts1.COL_STATESTATECONFIG = '|| v_stateConfigId;
v_query := v_query || '        AND UPPER(csss1.col_activity)=UPPER('''|| v_sourceActivity ||''')';
v_query := v_query || ' ORDER BY ' || v_sort || ' ' || v_dir;

  BEGIN
    OPEN :CUR_AVAILTRANSITIONS FOR v_query;
  EXCEPTION
    WHEN OTHERS THEN
      v_ErrorCode := SQLCODE;
      v_ErrorMessage := SUBSTR('Error on query' || ': ' || SQLERRM, 1, 200);
      goto CLEANUP;
  END;

  --get resolution codes for the case
  OPEN :CUR_RESCODES FOR
    SELECT 
      rc.col_id as ID,
      rc.col_code as CODE,
      rc.col_description as DESCRIPTION,
      rc.col_name as NAME,
      rc.col_iconcode as ICONCODE,
      rc.col_theme as THEME
    FROM tbl_case t
    INNER JOIN tbl_casesystyperesolutioncode m ON m.col_tbl_dict_casesystype = t.col_casedict_casesystype
    INNER JOIN tbl_stp_resolutioncode rc ON rc.col_id = m.col_casetyperesolutioncode
    WHERE t.col_id = v_case_id
    ORDER BY UPPER(rc.col_name);

    <<CLEANUP>>
    :ERRORCODE := v_ErrorCode;
    :ERRORMESSAGE := v_ErrorMessage;
    :CANROUTE := v_CanRoute;
    :CANCLOSE := v_CanClose;
    :CANREOPEN := v_CanReopen;
    :VALIDATIONMESSAGE := v_validationMessage;
    :VALIDATIONERRORCODE := v_validationErrorCode;
END;