select td.col_id as ID, ctsk.col_id as CTaskId, cmtsi.col_id as CTaskStateInitId,
       ctwi.col_activity as CTaskActivityCode, ctwi.col_tw_workitemdict_taskstate as CTaskStateId,
       cts.col_id as CStateId, cts.col_activity as CStateActivity,
       ptsk.col_id as PTaskId, ptsk.col_casetask as PCaseId, pmtsi.col_id as PTaskStateInitId,
       ptwi.col_activity as PTaskActivityCode, ptwi.col_tw_workitemdict_taskstate as PTaskStateId,
       pts.col_id as PStateId, pts.col_activity as PStateActivity,
       td.col_id as TaskDependencyId, td.col_type as TaskDependencyType,
       arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue RuleParamValue,
       prc.col_code as PResolutionCode
      from tbl_task ctsk
      inner join tbl_map_taskstateinitiation cmtsi on ctsk.col_id = cmtsi.col_map_taskstateinittask
      inner join tbl_tw_workitem ctwi on ctsk.col_tw_workitemtask = ctwi.col_id
      inner join tbl_dict_taskstate cts on cmtsi.col_map_tskstinit_tskst = cts.col_id
      inner join tbl_taskdependency td on cmtsi.col_id = td.col_tskdpndchldtskstateinit and td.col_type in ('FS','FSC','FSCLR')
      inner join tbl_map_taskstateinitiation pmtsi on td.col_tskdpndprnttskstateinit = pmtsi.col_id
      inner join tbl_task ptsk on pmtsi.col_map_taskstateinittask = ptsk.col_id
      inner join tbl_tw_workitem ptwi on ptsk.col_tw_workitemtask = ptwi.col_id
      inner join tbl_dict_taskstate pts on pmtsi.col_map_tskstinit_tskst = pts.col_id
      left join tbl_stp_resolutioncode prc on ptsk.col_taskstp_resolutioncode = prc.col_id
      left join tbl_autoruleparameter arp on td.col_id = arp.col_autoruleparamtaskdep
      where ptsk.col_casetask = :CaseId