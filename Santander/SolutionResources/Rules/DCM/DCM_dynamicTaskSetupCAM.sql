declare
  v_CurrTSI Integer;
  v_PrevTSI Integer;
  v_ChildTSIId Integer;
  v_SessionId nvarchar2(255);
  v_StartedActivityCode nvarchar2(255);
  v_AssignedActivityCode nvarchar2(255);
  v_ClosedActivityCode nvarchar2(255);
  v_InProcessActivityCode nvarchar2(255);
  v_ResolvedActivityCode nvarchar2(255);
  v_TaskDependencyType nvarchar2(255);
  v_ProcessorCode nvarchar2(255);
  v_initMethodId Integer;
begin
  v_SessionId := :SessionId;
  v_TaskDependencyType := 'FS';
  v_StartedActivityCode := f_dcm_getTaskStartedState();
  v_AssignedActivityCode := f_dcm_getTaskAssignedState();
  v_ClosedActivityCode := f_dcm_getTaskClosedState();
  v_InProcessActivityCode := f_dcm_getTaskInProcessState();
  v_ResolvedActivityCode := f_dcm_getTaskResolvedState();
  begin
    select col_id into v_initMethodId from tbl_dict_initmethod where lower(col_code) = 'manual';
    exception
    when NO_DATA_FOUND then
      v_initMethodId := null;
  end;
  v_PrevTSI := null;
  update tbl_dynamictask set col_id2 = col_id where col_sessionid = v_SessionId;
  for rec1 in (select col_id, col_taskorder from tbl_dynamictask where col_sessionid = v_SessionId order by col_taskorder)
  loop
    for rec2 in (select col_id, col_activity from tbl_dict_taskstate where col_stateconfigtaskstate is null and col_activity in (v_StartedActivityCode, v_AssignedActivityCode, v_InProcessActivityCode, v_ResolvedActivityCode, v_ClosedActivityCode))
      loop
        insert into tbl_map_taskstateinitiation(col_taskstateinitdynamictask, col_map_tskstinit_tskst, col_map_tskstinit_initmtd, col_code) values(rec1.col_id, rec2.col_id, v_initMethodId, sys_guid());
        select gen_tbl_map_taskstateinitiat.currval into v_CurrTSI from dual;
        if (rec2.col_activity = v_ClosedActivityCode) then
          v_PrevTSI := v_CurrTSI;
        end if;
      end loop;
  end loop;
  --NO DEPENDENCY BETWEEN TASKS IS SET
  --SETUP TASK EVENTS
  v_ProcessorCode := 'f_DCM_actionResolveCAMWF';
  for rec in (select tsi.col_id as ResolvedTSIId
                  from tbl_map_taskstateinitiation tsi
                  inner join tbl_dict_taskstate ts on tsi.col_map_tskstinit_tskst = ts.col_id
                  where tsi.col_taskstateinitdynamictask in (select col_id from tbl_dynamictask
                  where col_sessionid = v_SessionId and col_dynamictaskparentid <> 0 and col_dynamictaskparentid is not null)
                  and ts.col_activity = v_ResolvedActivityCode)
  loop
    insert into tbl_taskevent(col_processorcode, col_taskeventtaskstateinit, col_taskeventmomenttaskevent, col_taskeventtypetaskevent, col_code)
      values(v_ProcessorCode, rec.ResolvedTSIId,
             (select col_id from tbl_dict_taskeventmoment where lower(col_code) = 'after'),
             (select col_id from tbl_dict_taskeventtype where lower(col_code) = 'action'),
             sys_guid());
  end loop;
end;