declare
  v_activity nvarchar2(255);
  v_nextactivity nvarchar2(255);
  v_transition nvarchar2(255);
  v_CaseId Integer;
begin
  v_activity := :CaseActivity;
  v_transition := :Transition;
  v_CaseId := :CaseId;
  if v_transition is not null then
    begin
      select csts.col_activity into v_nextactivity
      from tbl_dict_transition cst
      inner join tbl_dict_state csss on cst.col_sourcetransitionstate = csss.col_id
      inner join tbl_dict_state csts on cst.col_targettransitionstate = csts.col_id
      where csss.col_activity = v_activity and cst.col_transition = v_transition
      and nvl(csss.col_statestateconfig,0) = (select col_id from tbl_dict_stateconfig where nvl(col_stateconfigversion,0) = (select nvl(col_dictvercasesystype,0) from tbl_dict_casesystype where col_id =
        (select col_casedict_casesystype from tbl_case where col_id = v_CaseId)))
      and nvl(csts.col_statestateconfig,0) = (select col_id from tbl_dict_stateconfig where nvl(col_stateconfigversion,0) = (select nvl(col_dictvercasesystype,0) from tbl_dict_casesystype where col_id =
        (select col_casedict_casesystype from tbl_case where col_id = v_CaseId)));
      exception
        when NO_DATA_FOUND then
          v_nextactivity := null;
        when TOO_MANY_ROWS then
          v_nextactivity := null;
    end;
  else
    begin
      select csts.col_activity into v_nextactivity
      from tbl_dict_transition cst
      inner join tbl_dict_state csss on cst.col_sourcetransitionstate = csss.col_id
      inner join tbl_dict_state csts on cst.col_targettransitionstate = csts.col_id
      where csss.col_activity = v_activity and cst.col_isnextdefault = 1
      and nvl(csss.col_statestateconfig,0) = (select col_id from tbl_dict_stateconfig where nvl(col_stateconfigversion,0) = (select nvl(col_dictvercasesystype,0) from tbl_dict_casesystype where col_id =
        (select col_casedict_casesystype from tbl_case where col_id = v_CaseId)))
      and nvl(csts.col_statestateconfig,0) = (select col_id from tbl_dict_stateconfig where nvl(col_stateconfigversion,0) = (select nvl(col_dictvercasesystype,0) from tbl_dict_casesystype where col_id =
        (select col_casedict_casesystype from tbl_case where col_id = v_CaseId)));
      exception
        when NO_DATA_FOUND then
          v_nextactivity := null;
        when TOO_MANY_ROWS then
          v_nextactivity := null;
    end;
  end if;
  return v_nextactivity;
end;