declare
  v_TaskId Integer; 
  v_createdby nvarchar2(255);
  v_createddate date;
  v_modifiedby nvarchar2(255);
  v_modifieddate date;
  v_owner nvarchar2(255);
  v_processorcode nvarchar2(255);
  v_initmethod nvarchar2(255);
  v_initmethodid Integer;
  v_TaskStateNew nvarchar2(255);
  v_TaskStateStarted nvarchar2(255);
  v_TaskStateAssigned nvarchar2(255);
  v_TaskStateInProcess nvarchar2(255);
  v_TaskStateResolved nvarchar2(255);
  v_TaskStateClosed nvarchar2(255);
  v_counter number;
  v_lastcounter number;
begin
  v_TaskId := :TaskId;
  v_owner := :owner;
  v_createdby := v_owner;
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  v_processorcode := null;
  v_initmethod := 'manual';
  v_TaskStateNew := 'new';
  v_TaskStateStarted := 'started';
  v_TaskStateAssigned := 'assigned';
  v_TaskStateInProcess := 'in_process';
  v_TaskStateResolved := 'resolved';
  v_TaskStateClosed := 'closed';
  begin
    select col_id into v_initmethodid from tbl_dict_initmethod where lower(col_code) = v_initmethod;
    exception
      when NO_DATA_FOUND then
        v_initmethodid := null;
  end;
  select gen_tbl_map_taskstateinitiat.nextval into v_counter from dual;
  begin
   insert into tbl_map_taskstateinitiation(col_map_taskstateinittask,col_processorcode,col_assignprocessorcode,col_map_tskstinit_initmtd,col_map_tskstinit_tskst,
                                          col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
   (select tsk.col_id, col_processorcode, col_assignprocessorcode, col_map_tskstinittpl_initmtd, col_map_tskstinittpl_tskst, v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
    from tbl_map_taskstateinittmpl tsi
     inner join tbl_task tsk on tsi.col_MAP_TaskStInitTplTaskTpl = tsk.col_id2
   where tsk.col_id = v_TaskId);
   exception
     when DUP_VAL_ON_INDEX then
       return -1;
     when OTHERS then
       return -1;
  end;
  select gen_tbl_map_taskstateinitiat.currval into v_lastcounter from dual;
  for rec in (select col_id from tbl_map_taskstateinitiation where col_id between v_counter and v_lastcounter)
  loop
    update tbl_map_taskstateinitiation set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
end;