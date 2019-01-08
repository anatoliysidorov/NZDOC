declare
  v_CurrTSI Integer;
  v_PrevTSI Integer;
  v_SessionId nvarchar2(255);
  v_StartedActivityCode nvarchar2(255);
  v_AssignedActivityCode nvarchar2(255);
  v_ClosedActivityCode nvarchar2(255);
  v_TaskDependencyType nvarchar2(255);
begin
  v_SessionId := :SessionId;
  v_TaskDependencyType := 'FS';
  v_StartedActivityCode := f_dcm_getTaskStartedState();
  v_AssignedActivityCode := f_dcm_getTaskAssignedState();
  v_ClosedActivityCode := f_dcm_getTaskClosedState();
  v_PrevTSI := null;
  update tbl_dynamictask set col_id2 = col_id where col_sessionid = v_SessionId;
  for rec1 in (select col_id, col_taskorder from tbl_dynamictask where col_sessionid = v_SessionId order by col_taskorder)
  loop
    for rec2 in (select col_id, col_activity from tbl_dict_taskstate where col_stateconfigtaskstate is null and col_activity in (v_StartedActivityCode, v_AssignedActivityCode, v_ClosedActivityCode))
      loop
        insert into tbl_map_taskstateinitiation(col_taskstateinitdynamictask, col_map_tskstinit_tskst, col_code) values(rec1.col_id, rec2.col_id, sys_guid());
        select gen_tbl_map_taskstateinitiat.currval into v_CurrTSI from dual;
        if (rec2.col_activity = v_StartedActivityCode and v_PrevTSI is not null) then
          insert into tbl_taskdependency(col_tskdpndchldtskstateinit, col_tskdpndprnttskstateinit, col_type, col_code) values(v_CurrTSI, v_PrevTSI, v_TaskDependencyType, sys_guid());
        end if;
        if (rec2.col_activity = v_ClosedActivityCode) then
          v_PrevTSI := v_CurrTSI;
        end if;
      end loop;
  end loop;
end;