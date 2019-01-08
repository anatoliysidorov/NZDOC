declare
  v_caseid Integer;
  v_casetitle nvarchar2(255);
  v_casetypeid Integer;
  v_casetypecode nvarchar2(255);
  v_casetypename nvarchar2(255);
  v_casetypeprocessorcode nvarchar2(255);
  v_stateconfigid Integer;
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
  v_affectedRows number;
  v_result number;
begin
  v_caseid := :CaseId;
  begin
    select cs.col_caseccdict_casesystype into v_casetypeid
    from tbl_casecc cs
    inner join tbl_cw_workitemcc cwi on cs.col_cw_workitemcccasecc = cwi.col_id
    where cs.col_id = v_caseid;
    exception
      when NO_DATA_FOUND then
        v_casetypeid := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Case type for case ' || to_char(v_caseid) || ' not found';
        return -1;
  end;
  begin
    select col_code, col_name, col_processorcode, col_stateconfigcasesystype
      into v_casetypecode, v_casetypename, v_casetypeprocessorcode, v_stateconfigid
      from tbl_dict_casesystype
      where col_id = v_casetypeid;
    exception
      when NO_DATA_FOUND then
        v_ErrorCode := 102;
        v_ErrorMessage := 'Case type not found';
        return -1;
  end;
  --GENERATE CASE TITLE
  if v_casetypeprocessorcode is not null then
    v_casetitle := f_dcm_invokeCaseIdGenProc(CaseId => v_caseid, ProcessorName => v_casetypeprocessorcode);
    update tbl_casecc set col_caseid = v_casetitle where col_id = v_caseid;
  else
   v_result := f_DCM_generateCaseCCId2(affectedRows => v_affectedRows, caseid => v_casetitle, ErrorCode => ErrorCode, ErrorMessage => ErrorMessage, prefix => 'CASE', recordid => v_caseid);
  end if;
  :CaseTitle := v_casetitle;
end;