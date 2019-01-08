declare
  v_SessionId nvarchar2(255);
begin
  -- DELETE ALL DATA FOR DYNAMIC TASKS FOR PROVIDED SESSION ID AS FUNCTION PARAMETER
  v_SessionId := :SessionId;

  -- SELECT AUTO RULE PARAMETERS RELATED TO AUTOMATIC TASKS
  delete from (
  select * from tbl_autoruleparameter
    where col_autoruleparamdynamictask in
    (select col_id from tbl_dynamictask where col_sessionid = v_SessionId)
  );

  -- SELECT AUTO RULE PARAMETERS RELATED TO TASK STATE INITIATION
  delete from (
  select * from tbl_autoruleparameter
    where col_ruleparam_taskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_taskstateinitdynamictask in
    (select col_id from tbl_dynamictask where col_sessionid = v_SessionId))
  );

  -- SELECT AUTO RULE PARAMETERS RELATED TO TASK EVENTS
  delete from (
  select * from tbl_autoruleparameter
    where col_taskeventautoruleparam in
    (select col_id from tbl_taskevent where col_taskeventtaskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_taskstateinitdynamictask in
    (select col_id from tbl_dynamictask where col_sessionid = v_SessionId)))
  );

  -- SELECT TASK EVENTS
  delete from (
  select * from tbl_taskevent
    where col_taskeventtaskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_taskstateinitdynamictask in
    (select col_id from tbl_dynamictask where col_sessionid = v_SessionId))
  );

  -- SELECT TASK DEPENDENCIES
  delete from (
  select * from tbl_taskdependency
    where col_tskdpndchldtskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_taskstateinitdynamictask in
    (select col_id from tbl_dynamictask where col_sessionid = v_SessionId))
    and col_tskdpndprnttskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_taskstateinitdynamictask in
    (select col_id from tbl_dynamictask where col_sessionid = v_SessionId))
  );

  -- SELECT TASK STATE INITIATION
  delete from (
  select * from tbl_map_taskstateinitiation
    where col_taskstateinitdynamictask in
    (select col_id from tbl_dynamictask where col_sessionid = v_SessionId)
  );

  -- SELECT SLA ACTIONS
  delete from (
  select * from tbl_slaaction where col_slaactionslaevent in
    (select col_id from tbl_slaevent
    where col_slaeventdynamictask in
    (select col_id from tbl_dynamictask where col_sessionid = v_SessionId))
  );

  -- SELECT SLA EVENTS FOR TASKS IN CASE
  delete from (
  select * from tbl_slaevent
    where col_slaeventdynamictask in
    (select col_id from tbl_dynamictask where col_sessionid = v_SessionId)
  );

  -- SELECT WORKITEMS FOR DYNAMIC TASKS
  delete from (
  select * from tbl_tw_workitem
    where col_id in
    (select col_dynamictasktw_workitem from tbl_dynamictask where col_sessionid = v_SessionId)
  );

  -- SELECT MAPPING BETWEEN DOCUMENTS AND DYNAMIC TASKS
  /*
  delete from (
  select * from tbl_documentdynamictask where col_tbl_dynamictask in
    (select col_id from tbl_dynamictask where col_sessionid = v_SessionId)
  );
  */


  -- SELECT WORKITEMS
  delete from (
  select * from tbl_tw_workitem
    where col_id in
    (select col_dynamictasktw_workitem from tbl_dynamictask where col_sessionid = v_SessionId)
  );

  -- SELECT TASKS
  delete from (
  select * from tbl_dynamictask where col_sessionid = v_SessionId
  );

end;