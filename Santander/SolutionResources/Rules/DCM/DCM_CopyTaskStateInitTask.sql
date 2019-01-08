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
  v_count Integer;
  v_tasksystypeid Integer;
  v_counter number;
  v_lastcounter number;
  v_TaskTemplateId number;
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
  v_TaskTemplateId:=NULL;

  begin
    select col_id into v_initmethodid from tbl_dict_initmethod where lower(col_code) = v_initmethod;
    exception
      when NO_DATA_FOUND then
        v_initmethodid := null;
  end;

  begin
    select col_taskdict_tasksystype into v_tasksystypeid from tbl_task where col_id = v_TaskId;
    exception
      when NO_DATA_FOUND then
        v_tasksystypeid := null;
  end;

  BEGIN
    SELECT COL_ID2 INTO v_TaskTemplateId FROM TBL_TASK WHERE COL_ID=v_TaskId;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_TaskTemplateId := null;  
  END;

  begin
    --select count(*) into v_count from tbl_map_taskstateinitiation where col_taskstateinit_tasksystype = v_tasksystypeid;
    select count(*) into v_count from tbl_map_taskstateinittmpl where col_taskstateinittp_tasktype = v_tasksystypeid;
    exception
      when NO_DATA_FOUND then
        v_count := 0;
  end;

  if v_count > 0 then
    select gen_tbl_map_taskstateinitiat.nextval into v_counter from dual;
    insert into tbl_map_taskstateinitiation
      (col_map_taskstateinittask,col_map_tskstinit_initmtd,col_map_tskstinit_tskst,col_processorcode,col_assignprocessorcode,
       col_createdby,col_createddate,col_modifiedby,col_modifieddate)
    (select v_TaskId, col_map_tskstinittpl_initmtd,col_map_tskstinittpl_tskst,col_processorcode,col_assignprocessorcode,col_createdby,col_createddate,col_modifiedby,col_modifieddate
      from tbl_map_taskstateinittmpl
      where col_taskstateinittp_tasktype = v_tasksystypeid);
    select gen_tbl_map_taskstateinitiat.currval into v_lastcounter from dual;
    for rec in (select col_id from tbl_map_taskstateinitiation where col_id between v_counter and v_lastcounter)
    loop
      update tbl_map_taskstateinitiation set col_code = sys_guid() where col_id = rec.col_id;
    end loop;
  else
    for cur in (select col_id,
                       col_code,
                       col_name,
                       col_activity
                  from tbl_dict_taskstate
                  where nvl(col_stateconfigtaskstate,0) = (select nvl(col_stateconfigtasksystype,0) from tbl_dict_tasksystype where col_id = (select col_taskdict_tasksystype from tbl_task where col_id = v_TaskId)))
    loop
      insert into tbl_map_taskstateinitiation
                  (col_map_taskstateinittask,
                   col_map_tskstinit_initmtd,
                   col_map_tskstinit_tskst,
                   col_code,
                   col_createdby,
                   col_createddate,
                   col_modifiedby,
                   col_modifieddate)
      values      (v_TaskId,
                   v_initmethodid,
                   cur.col_id,
                   sys_guid(),
                   v_createdby,
                   v_createddate,
                   v_createdby,
                   v_createddate);
    end loop;
  end if;

  /*
  begin
   insert into tbl_map_taskstateinitiation(col_map_taskstateinittask,col_processorcode,col_map_tskstinit_initmtd,col_map_tskstinit_tskst,
                                          col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
     (select v_TaskId, v_processorcode, v_initmethodid, col_id,
     col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner from tbl_dict_taskstate where lower(col_code) in (v_TaskStateNew, v_TaskStateStarted, v_TaskStateAssigned, v_TaskStateInProcess, v_TaskStateResolved, v_TaskStateClosed));
   exception
     when DUP_VAL_ON_INDEX then
       return -1;
     when OTHERS then
       return -1;
  end;
  */
end;