declare
  v_TaskId Integer;
  v_createdby nvarchar2(255);
  v_createddate date;
  v_modifiedby nvarchar2(255);
  v_modifieddate date;
  v_owner nvarchar2(255);
   v_counter number;
  v_lastcounter number;
  v_TaskTemplateId number;
begin
  v_TaskId := :TaskId;
  v_owner := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  v_createdby := v_owner;
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  v_TaskTemplateId :=NULL;

  begin
    begin
      select col_id2 into v_tasktemplateid from tbl_task where col_id=v_taskid;
      exception
      when no_data_found then
        v_tasktemplateid := null;
    end;

    select gen_tbl_taskevent.nextval into v_counter from dual;
  
    insert into tbl_taskevent(col_processorcode,col_taskeventtaskstateinit,col_taskeventmomenttaskevent,col_taskeventtypetaskevent,col_taskeventorder,
                              col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
    (select te.col_processorcode,tsi2.col_id,te.col_taskeventmomnttaskeventtp,te.col_taskeventtypetaskeventtp,te.col_taskeventorder,
            v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
    from tbl_taskeventtmpl te
   --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
    inner join tbl_map_taskstateinittmpl tsi on te.col_taskeventtptaskstinittp = tsi.col_id
    inner join tbl_dict_tasksystype tst on tsi.col_TaskStateInitTp_TaskType = tst.col_id
    --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
    inner join tbl_map_taskstateinittmpl tsi2 on tsi2.col_MAP_TaskStInitTplTaskTpl = v_TaskTemplateId and tsi.col_MAP_TskStInitTpl_TskSt = tsi2.col_MAP_TskStInitTpl_TskSt
    where tst.col_id = (select col_taskdict_tasksystype from tbl_task where col_id = v_TaskId));
    
    select gen_tbl_taskevent.currval into v_lastcounter from dual;
  
    for rec in (select col_id from tbl_taskevent where col_id between v_counter and v_lastcounter)
    loop
      update tbl_taskevent set col_code = sys_guid() where col_id = rec.col_id;
    end loop;
    
    exception
       when DUP_VAL_ON_INDEX then
         return -1;
       when OTHERS then
         return -1;
    end;
end;