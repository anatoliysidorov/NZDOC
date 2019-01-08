declare
  v_Source nvarchar2(255);
  v_Target nvarchar2(255);
  v_Transition nvarchar2(255);
  v_CaseId Integer;
begin
  v_Source := :Source;
  v_Target := :Target;
  v_CaseId := :CaseId;
  begin
    select col_transition into v_Transition
    from tbl_dict_casetransition cst
    inner join tbl_dict_casestate csss on cst.col_sourcecasetranscasestate = csss.col_id
    inner join tbl_dict_casestate csts on cst.col_targetcasetranscasestate = csts.col_id
    where csss.col_activity = v_Source and csts.col_activity = v_Target
    and nvl(csss.col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
      (select col_casedict_casesystype from tbl_case where col_id = v_CaseId))
    and nvl(csts.col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
      (select col_casedict_casesystype from tbl_case where col_id = v_CaseId));
      exception
        when NO_DATA_FOUND then
          v_Transition := 'NONE';
        when TOO_MANY_ROWS then
          v_Transition := 'NONE';
  end;
  return v_Transition;
end;