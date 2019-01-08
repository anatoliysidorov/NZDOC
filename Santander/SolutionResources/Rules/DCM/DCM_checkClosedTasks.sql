declare
  v_count Integer;
  v_col_csid Integer;
  v_col_activity nvarchar2(255);
  v_col_csactivity nvarchar2(255);
begin
  v_col_csid := :csid;
  v_col_activity := 'root_TSK_Status_CLOSED';
  v_col_csactivity := 'root_CS_Status_FIXED';
  v_count := -1;
  :affectedRows := 0;
  begin
      select count(*) into v_count from tbl_task tsk
      inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
      where tsk.col_casetask = v_col_csid
      and tsk.col_leaf = 1 and tsk.col_required=1 and twi.col_activity <> v_col_activity;
      exception
        when NO_DATA_FOUND then
          return -1;
  end;
  if (v_count = 0) then
    begin
      update tbl_cw_workitem cwi
        set cwi.col_activity = v_col_csactivity
          where cwi.col_id =
            (select col_cw_workitemcase from tbl_case cs where cwi.col_id = cs.col_cw_workitemcase and cs.col_id = v_col_csid);
      update tbl_case set col_activity = v_col_csactivity where col_id = v_col_csid;
      :affectedRows := 1;
      exception
        when NO_DATA_FOUND then
          :affectedRows := 0;
        when DUP_VAL_ON_INDEX then
          :affectedRows := 0;
    end;
  end if;
    return :affectedRows;
end;