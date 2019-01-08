declare
  v_result number;
  v_TaskStateInitId Integer;
  v_ResolutionCode number;
  v_stateClosed nvarchar2(255);
begin
  v_TaskStateInitId := :TaskStateInitId;
  v_result := 0;
  v_stateClosed := f_dcm_getTaskClosedState();
  for rec in
    (select ptsk.col_taskstp_resolutioncode as ResolutionCode
      from tbl_task ctsk
      inner join tbl_map_taskstateinitiation cmtsi on ctsk.col_id = cmtsi.col_map_taskstateinittask
      inner join tbl_taskdependency ctd on cmtsi.col_id = ctd.col_tskdpndchldtskstateinit and ctd.col_type = 'FSC'
      inner join tbl_map_taskstateinitiation pmtsi on ctd.col_tskdpndprnttskstateinit = pmtsi.col_id
      inner join tbl_task ptsk on pmtsi.col_map_taskstateinittask = ptsk.col_id
      inner join tbl_tw_workitem ptwi on ptsk.col_tw_workitemtask = ptwi.col_id
      where cmtsi.col_id = v_TaskStateInitId
      and ptwi.col_activity = v_stateClosed)
  loop
    for rec2 in (select col_paramcode, col_paramvalue from tbl_autoruleparameter where col_ruleparam_taskstateinit = v_TaskStateInitId)
    loop
      if (rec2.col_paramvalue >= 1) and (rec2.col_paramvalue = rec.ResolutionCode) then
        v_result := 1;
        :TaskResult := v_result;
        return v_result;
      else
        v_result := 0;
      end if;
    end loop;
  end loop;
  :TaskResult := v_result;
end;