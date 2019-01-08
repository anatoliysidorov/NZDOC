declare
  v_CaseId                   Integer;
  v_Target                   nvarchar2(255);
  v_result                   number;
  v_ResolutionId             Integer;
  v_WorkbasketId             Integer;
  v_CustomData               nclob;
  v_routecustomdataprocessor nvarchar2(255);
  v_casetypeid               integer;
  v_ErrorCode                number;
  v_ErrorMessage             nclob;
  v_RoutingDescription       nclob;
begin
  v_CaseId := :CaseId;
  v_Target := :Target;
  v_ResolutionId := :ResolutionId;
  v_Workbasketid := :WorkbasketId;
  v_CustomData := :CUSTOMDATA;
  v_RoutingDescription := :RoutingDescription;
  v_result := f_DCM_caseRouteValidate(ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, Target => v_Target, CaseId => v_CaseId);
  if (v_ErrorCode is not null) then
    :ErrorCode := v_ErrorCode;
    :ErrorMessage := v_ErrorMessage;
    return;
  end if;
  v_result := f_DCM_caseRouteManualFn(ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, Target => v_target, ResolutionId => v_ResolutionId, CaseId => v_CaseId, WorkbasketId => v_WorkbasketId);
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  --CALL CUSTOM PROCESSOR IF ONE EXISTS
  begin
    select col_casedict_casesystype into v_casetypeid from tbl_case where col_id = v_CaseId;
    exception
    when NO_DATA_FOUND then
    v_casetypeid := null;
  end;
  begin 
    select col_routecustomdataprocessor
    into   v_routecustomdataprocessor
    from tbl_dict_casesystype
    where col_id = v_casetypeid;
    exception
    when NO_DATA_FOUND then
    v_routecustomdataprocessor := null;
  end;
  if v_CustomData is not null and v_routecustomdataprocessor is not null then
    v_result := f_dcm_invokeCaseCusDataProc(CaseId => v_CaseId, Input => v_CustomData, ProcessorName => v_routecustomdataprocessor);
  elsif v_CustomData is not null then
    --set custom data XML if no special processor passed
    update tbl_caseext
    set col_customdata = XMLTYPE(v_CustomData)
    where col_caseextcase = v_CaseId;
  end if;
  
  if v_RoutingDescription is not null then
    INSERT INTO TBL_NOTE
     (COL_NOTENAME,
      COL_NOTE,
      COL_CREATEDBY,
      COL_CREATEDDATE,
      COL_OWNER,
      COL_VERSION,
      COL_CASENOTE)
     VALUES
      ('Routing note',
      v_RoutingDescription,
      '@TOKEN_USERACCESSSUBJECT@',
      SYSDATE,
      '@TOKEN_USERACCESSSUBJECT@',
      1,
      v_CaseId);
  end if;
  
end;