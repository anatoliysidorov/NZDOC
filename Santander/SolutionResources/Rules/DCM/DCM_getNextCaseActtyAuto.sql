declare
  v_activity nvarchar2(255);
  v_nextactivity nvarchar2(255);
begin
  v_activity := :CaseActivity;
  begin
    select csts.col_activity into v_nextactivity
    from tbl_dict_casetransition cst
    inner join tbl_dict_casestate csss on cst.col_sourcecasetranscasestate = csss.col_id
    inner join tbl_dict_casestate csts on cst.col_targetcasetranscasestate = csts.col_id
    where csss.col_activity = v_activity and nvl(cst.col_manualonly, 0) = 0;
    exception
      when NO_DATA_FOUND then
        v_nextactivity := null;
      when TOO_MANY_ROWS then
        v_nextactivity := null;
  end;
  return v_nextactivity;
end;