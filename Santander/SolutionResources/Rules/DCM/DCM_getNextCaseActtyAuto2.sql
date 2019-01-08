declare
  v_activity nvarchar2(255);
  v_nextactivity nvarchar2(255);
  v_CaseId Integer;
begin
  v_activity := :CaseActivity;
  v_CaseId := :CaseId;
  begin
    select csts.col_activity into v_nextactivity
    from tbl_dict_casetransition cst
    inner join tbl_dict_casestate csss on cst.col_sourcecasetranscasestate = csss.col_id
    inner join tbl_dict_casestate csts on cst.col_targetcasetranscasestate = csts.col_id
    where csss.col_activity = v_activity and nvl(cst.col_manualonly, 0) = 0
    and nvl(csss.col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
      (select col_casedict_casesystype from tbl_case where col_id = v_CaseId))
    and nvl(csts.col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
      (select col_casedict_casesystype from tbl_case where col_id = v_CaseId));
    exception
      when NO_DATA_FOUND then
        v_nextactivity := null;
      when TOO_MANY_ROWS then
        v_nextactivity := null;
  end;
  return v_nextactivity;
end;