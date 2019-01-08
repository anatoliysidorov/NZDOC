DECLARE
    v_TaskId Integer;
	v_data nclob :='[';
begin
    begin
      select se.col_slaeventtask into v_TaskId
        from tbl_slaevent se
        inner join tbl_slaaction sa on se.col_id = sa.col_slaactionslaevent
        where sa.col_id = :SlaActionId;
    exception
      when NO_DATA_FOUND then
        return 'Task not found';
    end;
    for rec in ( 
      select col_ParamCode, col_ParamValue
        from tbl_AutoRuleParameter
        where col_autoruleparamslaaction = :SlaActionId
		)
        loop
         if (upper(rec.col_ParamCode) != 'SlaActionId') then
            	v_data := v_data || '{"name": "' || rec.col_ParamCode || '", "value": "' || rec.col_ParamValue || '"},';
         end if;
        end loop;

        v_data := v_data || '{"name": "TaskId", "value": ' || v_TaskId || '},';
        v_data := v_data || '{"name": "SlaActionId", "value": ' || :SlaActionId || '} ] ';

    return v_data;
  end;