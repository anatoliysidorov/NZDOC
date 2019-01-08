declare
  v_activity nvarchar2(255);
  v_prevactivity nvarchar2(255);
  v_transition nvarchar2(255);
  v_CaseId Integer;
begin
  v_activity := :CaseActivity;
  v_transition := :Transition;
  v_CaseId := :CaseId;
  if v_transition is not null then
    begin
      select csss.col_activity into v_prevactivity
      from tbl_dict_casetransition cst
      inner join tbl_dict_casestate csss on cst.col_sourcecasetranscasestate = csss.col_id
      inner join tbl_dict_casestate csts on cst.col_targetcasetranscasestate = csts.col_id
      where csts.col_activity = v_activity and cst.col_transition = v_transition
      and nvl(csss.col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
        (select col_caseccdict_casesystype from tbl_casecc where col_id = v_CaseId))
      and nvl(csts.col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
        (select col_caseccdict_casesystype from tbl_casecc where col_id = v_CaseId));
      exception
        when NO_DATA_FOUND then
          v_prevactivity := null;
        when TOO_MANY_ROWS then
          v_prevactivity := null;
    end;
  else
    begin
      select csss.col_activity into v_prevactivity
      from tbl_dict_casetransition cst
      inner join tbl_dict_casestate csss on cst.col_sourcecasetranscasestate = csss.col_id
      inner join tbl_dict_casestate csts on cst.col_targetcasetranscasestate = csts.col_id
      where csts.col_activity = v_activity and cst.col_isprevdefault = 1
      and nvl(csss.col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
        (select col_caseccdict_casesystype from tbl_casecc where col_id = v_CaseId))
      and nvl(csts.col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
        (select col_caseccdict_casesystype from tbl_casecc where col_id = v_CaseId));
      exception
        when NO_DATA_FOUND then
          v_prevactivity := null;
        when TOO_MANY_ROWS then
          v_prevactivity := null;
    end;
  end if;
  return v_prevactivity;

end;