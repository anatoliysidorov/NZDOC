declare
  v_CaseId Integer;
  v_result Integer;
begin
  v_CaseId := :CaseId;
  begin
    select col_stateconfigcasesystype into v_result
    from tbl_dict_casesystype st
    inner join tbl_case cs on st.col_id = cs.col_casedict_casesystype
    where cs.col_id = v_CaseId;
    exception
    when NO_DATA_FOUND then
      v_result := null;
    when TOO_MANY_ROWS then
      v_result := null;
  end;
  return v_result;
end;