declare
  v_activity nvarchar2(255);
  v_nextactivity nvarchar2(255);
begin
  v_activity := :TaskActivity;
  begin
    select tskts.col_activity into v_nextactivity
      from tbl_dict_tasktransition tskt
      inner join tbl_dict_taskstate tskss on tskt.col_sourcetasktranstaskstate = tskss.col_id
      inner join tbl_dict_taskstate tskts on tskt.col_targettasktranstaskstate = tskts.col_id
      where tskss.col_activity = v_activity;
    exception
      when NO_DATA_FOUND then
        v_nextactivity := 'NONE';
      when TOO_MANY_ROWS then
        v_nextactivity := 'NONE';
  end;
  return v_nextactivity;
end;