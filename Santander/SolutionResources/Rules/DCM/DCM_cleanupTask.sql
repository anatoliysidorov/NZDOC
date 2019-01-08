declare
  v_TaskId Integer;
begin
  -- DELETE ALL DATA FOR CASE IDENTIFIED BY CASE ID AS FUNCTION PARAMETER
  v_TaskId := :TaskId;


  -- SELECT TASK EVENT QUEUE ELEMENTS RELATED TO TASKS IN CASE
  delete from (
  select * from tbl_taskeventqueue
    where col_taskeventqueuetask = v_TaskId
  );

  -- SELECT TASK EVENT QUEUE ELEMENTS RELATED TO TASK STATE INIT
  delete from (
  select * from tbl_taskeventqueue
    where col_taskeventqueuetaskevent in
    (select col_id from tbl_taskevent
    where col_taskeventtaskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask = v_TaskId))
  );

  -- SELECT AUTO RULE PARAMETERS RELATED TO AUTOMATIC TASKS
  delete from (
  select * from tbl_autoruleparameter
    where col_autoruleparametertask = v_TaskId
  );

  -- SELECT AUTO RULE PARAMETERS RELATED TO TASK STATE INITIATION
  delete from (
  select * from tbl_autoruleparameter
    where col_ruleparam_taskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask = v_TaskId)
  );

  -- SELECT AUTO RULE PARAMETERS RELATED TO TASK EVENTS
  delete from (
  select * from tbl_autoruleparameter
    where col_taskeventautoruleparam in
    (select col_id from tbl_taskevent where col_taskeventtaskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask = v_TaskId))
  );

  -- SELECT AUTO RULE PARAMETERS RELATED TO CASE EVENTS
  delete from (
  select * from tbl_autoruleparameter
    where col_caseeventautoruleparam in
    (select col_id from tbl_caseevent where col_caseeventcasestateinit = v_TaskId)
  );

  -- SELECT TASK EVENTS
  delete from (
  select * from tbl_taskevent
    where col_taskeventtaskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask = v_TaskId)
  );

  -- SELECT TASK DEPENDENCIES
  delete from (
  select * from tbl_taskdependency
    where col_tskdpndchldtskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask = v_TaskId)
    and col_tskdpndprnttskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask = v_TaskId)
  );

  -- SELECT TASK STATE INITIATION
  delete from (
  select * from tbl_map_taskstateinitiation
    where col_map_taskstateinittask = v_TaskId
  );

  -- SELECT SLA ACTIONS
  delete from (
  select * from tbl_slaaction where col_slaactionslaevent in
    (select col_id from tbl_slaevent
    where col_slaeventtask = v_TaskId)
  );

  -- SELECT SLA EVENTS FOR TASKS IN CASE
  delete from (
  select * from tbl_slaevent
    where col_slaeventtask = v_TaskId
  );

  -- SELECT CASE TASKS HISTORY
  delete from (
  select * from tbl_history
    where col_historytask = v_TaskId
  );

  -- SELECT MAPPING BETWEEN DOCUMENTS AND DYNAMIC TASKS
  /*
  delete from (
  select * from tbl_documentdynamictask where col_tbl_dynamictask = v_TaskId
  );
  */

  -- SELECT WORKITEMS
  delete from (
  select * from tbl_tw_workitem
    where col_id in
    (select col_tw_workitemtask from tbl_task where col_id = v_TaskId)
  );

  -- SELECT TASKS
  delete from (
  select * from tbl_task where col_id = v_TaskId
  );

  -- SELECT DATE EVENTS FOT TASKS
  delete from (
  select * from tbl_dateevent where col_dateeventtask = v_TaskId
  );

end;