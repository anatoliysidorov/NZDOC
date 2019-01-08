select tsk.col_id as ID, tsk.col_id as TaskId, tsi.col_id as TaskStateInitId, te.col_id as TaskEventId, te.col_processorcode as EventProcessor,
          arp.col_id as AutoRuleParamId, arp.col_paramcode as AutoRuleParamCode, arp.col_paramvalue as AutoRuleParamValue,
          twi.col_activity as TaskActivityCode, twi.col_tw_workitemdict_taskstate as TaskStateId,
          tem.col_code as TaskEventMoment,
          tet.col_code as TaskEventType
   from tbl_task tsk
   inner join tbl_map_taskstateinitiation tsi on tsk.col_id = tsi.col_map_taskstateinittask
   inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
   inner join tbl_dict_taskstate ts on tsi.col_map_tskstinit_tskst = ts.col_id and ts.col_activity = :TaskState
   inner join tbl_taskevent te on tsi.col_id = te.col_taskeventtaskstateinit
   inner join tbl_dict_taskeventmoment tem on te.col_taskeventmomenttaskevent = tem.col_id
   inner join tbl_dict_taskeventtype tet on te.col_taskeventtypetaskevent = tet.col_id
   inner join tbl_autoruleparameter arp on te.col_id = arp.col_taskeventautoruleparam
   where tsk.col_id = :TaskId
   and lower(tem.col_code) = :TaskEventMoment
   and lower(tet.col_code) = :TaskEventType
union all
select tsk.col_id as ID, tsk.col_id as TaskId, tsi.col_id as TaskStateInitId, null as TaskEventId, null as EventProcessor,
       null as AutoRuleParamId, N'TaskId' as AutoRuleParamCode, to_nchar(27726) as AutoRuleParamValue,
       twi.col_activity as TaskActivityCode, twi.col_tw_workitemdict_taskstate as TaskStateId,
       null as TaskEventMoment,
       null as TaskEventType
   from tbl_task tsk
   inner join tbl_map_taskstateinitiation tsi on tsk.col_id = tsi.col_map_taskstateinittask
   inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
   inner join tbl_dict_taskstate ts on tsi.col_map_tskstinit_tskst = ts.col_id and ts.col_activity = :TaskState
   where tsk.col_id = :TaskId