begin
  declare
    v_Recordid Integer;
    v_Prefix nvarchar2(255);
    v_TaskId nvarchar2(255);
    v_CaseId nvarchar2(255);

    begin
    v_RecordId := :recordid;
    v_Prefix := :prefix;
    v_TaskId := v_prefix || to_char(v_Recordid);
    :taskid := '';
    
      begin
        select col_CaseId into v_CaseId from tbl_case cs
        inner join tbl_dynamictask tsk on cs.col_id = tsk.col_casedynamictask
        where tsk.col_id = v_Recordid;
        exception
          when NO_DATA_FOUND then
            return 0;
      end;
      v_TaskId := v_CaseId || '|' || v_TaskId;
      :taskid := v_TaskId;
      begin
        update tbl_dynamictask set col_TaskId = v_TaskId where col_id = v_Recordid;
      :affectedRows := 1;
      EXCEPTION 
      WHEN NO_DATA_FOUND THEN
       :affectedRows := 0;   
      WHEN DUP_VAL_ON_INDEX  THEN
       :affectedRows := 0;   
      END;
    end;    
end;