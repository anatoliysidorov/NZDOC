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

  begin
    select col_taskccdict_tasksystype into v_tasksystypeid from tbl_taskcc where col_id = v_TaskId;
    exception
      when NO_DATA_FOUND then
        v_tasksystypeid := null;
  end;

  begin
    select count(*) into v_count from tbl_map_taskstateinitcc where col_taskstateinitcc_tasktype = v_tasksystypeid;
    exception
      when NO_DATA_FOUND then
        v_count := 0;
  end;

  if v_count > 0 THEN
  FOR rec IN (SELECT col_map_tskstinitcc_initmtd,col_map_tskstinitcc_tskst,col_processorcode,
                     col_assignprocessorcode,col_createdby,col_createddate,col_modifiedby,col_modifieddate
               FROM tbl_map_taskstateinitcc
               WHERE col_taskstateinitcc_tasktype = v_tasksystypeid
  )
  LOOP
    INSERT INTO tbl_map_taskstateinitcc
      (col_map_taskstateinitcctaskcc,col_map_tskstinitcc_initmtd,col_map_tskstinitcc_tskst,col_processorcode,
       col_assignprocessorcode,col_createdby,col_createddate,col_modifiedby, 
       col_modifieddate, col_code)
    VALUES (v_TaskId, rec.col_map_tskstinitcc_initmtd, rec.col_map_tskstinitcc_tskst, rec.col_processorcode,
            rec.col_assignprocessorcode, rec.col_createdby, rec.col_createddate, rec.col_modifiedby,
            rec.col_modifieddate, sys_guid());
  END LOOP;
  /*
    select gen_tbl_map_taskstateinitcc.nextval into v_counter from dual;

    insert into tbl_map_taskstateinitcc
      (col_map_taskstateinitcctaskcc,col_map_tskstinitcc_initmtd,col_map_tskstinitcc_tskst,col_processorcode,
       col_assignprocessorcode,col_createdby,col_createddate,col_modifiedby,col_modifieddate)
    (select v_TaskId,col_map_tskstinitcc_initmtd,col_map_tskstinitcc_tskst,col_processorcode,
     col_assignprocessorcode,col_createdby,col_createddate,col_modifiedby,col_modifieddate
     from tbl_map_taskstateinitcc
     where col_taskstateinitcc_tasktype = v_tasksystypeid);

    select gen_tbl_map_taskstateinitcc.currval into v_lastcounter from dual;

    for rec in (select col_id from tbl_map_taskstateinitcc where col_id between v_counter and v_lastcounter)
    loop
      update tbl_map_taskstateinitcc set col_code = sys_guid() where col_id = rec.col_id;
    end loop;
    */
  else
    for cur in (select col_id,
                       col_code,
                       col_name,
                       col_activity
                  from tbl_dict_taskstate
                  where nvl(col_stateconfigtaskstate,0) = (select nvl(col_stateconfigtasksystype,0) 
                                                           from tbl_dict_tasksystype 
                                                           where col_id = 
                                                           (select col_taskccdict_tasksystype 
                                                           from tbl_taskcc 
                                                           where col_id = v_TaskId)))
    loop
      insert into tbl_map_taskstateinitcc
                  (col_map_taskstateinitcctaskcc,
                   col_map_tskstinitcc_initmtd,
                   col_map_tskstinitcc_tskst,
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