declare

  v_CaseId Integer;

begin
  -- DELETE ALL DATA FOR CASE IDENTIFIED BY CASE ID AS FUNCTION PARAMETER
  v_CaseId := :CaseId;

  -- CASE WORKITEM
  delete from (
  select * from tbl_cw_workitem
    where col_id = (select col_cw_workitemcase from tbl_case where col_id = v_CaseId)
  );



  -- SELECT CASE EVENT QUEUE ELEMENTS RELATED TO CASE
  delete from (
  select * from tbl_caseeventqueue
    where col_caseeventqueuecase = v_CaseId
  );

  -- SELECT CASE EVENT QUEUE ELEMENTS RELATED TO CASE STATE INIT
  delete from (
  select * from tbl_caseeventqueue
    where col_caseeventqueuecaseevent in
    (select col_id from tbl_caseevent
    where col_caseeventcasestateinit in
    (select col_id from tbl_map_casestateinitiation where col_map_casestateinitcase = v_CaseId))
  );

  -- SELECT CASE QUEUE ELEMENTS
  delete from (
  select * from tbl_casequeue where col_casecasequeue = v_CaseId
  );



  -- SELECT TASK EVENT QUEUE ELEMENTS RELATED TO TASKS IN CASE
  delete from (
  select * from tbl_taskeventqueue
    where col_taskeventqueuetask in
    (select col_id from tbl_task where col_casetask = v_CaseId)
  );

  -- SELECT TASK EVENT QUEUE ELEMENTS RELATED TO TASK STATE INIT
  delete from (
  select * from tbl_taskeventqueue
    where col_taskeventqueuetaskevent in
    (select col_id from tbl_taskevent
    where col_taskeventtaskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask in
    (select col_id from tbl_task where col_casetask = v_CaseId)))
  );


  -- SELECT AUTO RULE PARAMETERS RELATED TO AUTOMATIC TASKS
  delete from (
  select * from tbl_autoruleparameter
    where col_autoruleparametertask in
    (select col_id from tbl_task where col_casetask = v_CaseId)
  );

  -- SELECT AUTO RULE PARAMETERS RELATED TO TASK STATE INITIATION
  delete from (
  select * from tbl_autoruleparameter
    where col_ruleparam_taskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask in
    (select col_id from tbl_task where col_casetask = v_CaseId))
  );

  -- SELECT AUTO RULE PARAMETERS RELATED TO TASK EVENTS
  delete from (
  select * from tbl_autoruleparameter
    where col_taskeventautoruleparam in
    (select col_id from tbl_taskevent where col_taskeventtaskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask in
    (select col_id from tbl_task where col_casetask = v_CaseId)))
  );

  -- SELECT AUTO RULE PARAMETERS RELATED TO CASE EVENTS
  delete from (
  select * from tbl_autoruleparameter
    where col_caseeventautoruleparam in
    (select col_id from tbl_caseevent where col_caseeventcasestateinit in
    (select col_id from tbl_map_casestateinitiation where col_map_casestateinitcase = v_CaseId))
  );

  -- SELECT TASK EVENTS
  delete from (
  select * from tbl_taskevent
    where col_taskeventtaskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask in
    (select col_id from tbl_task where col_casetask = v_CaseId))
  );

  -- SELECT CASE EVENTS
  delete from (
  select * from tbl_caseevent
    where col_caseeventcasestateinit in
    (select col_id from tbl_map_casestateinitiation where col_map_casestateinitcase = v_CaseId)
  );

  -- SELECT CASE STATE INITIATIONS
  delete from (
  select * from tbl_map_casestateinitiation
    where col_map_casestateinitcase = v_CaseId
  );

  -- SELECT TASK DEPENDENCIES
  delete from (
  select * from tbl_taskdependency
    where col_tskdpndchldtskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask in
    (select col_id from tbl_task where col_casetask = v_CaseId))
    and col_tskdpndprnttskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask in
    (select col_id from tbl_task where col_casetask = v_CaseId))
  );

  -- SELECT TASK STATE INITIATION
  delete from (
  select * from tbl_map_taskstateinitiation
    where col_map_taskstateinittask in
    (select col_id from tbl_task where col_casetask = v_CaseId)
  );

  -- SELECT CASE PARTIES
  delete from (
  select * from tbl_caseparty where col_casepartycase = v_CaseId
  );

  -- SELECT SLA EVENTS FOR CASE
  delete from (
  select * from tbl_slaevent
  where col_slaeventcase = v_CaseId
  );

  -- SELECT SLA ACTIONS
  delete from (
  select * from tbl_slaaction where col_slaactionslaevent in
    (select col_id from tbl_slaevent
    where col_slaeventtask in
    (select col_id from tbl_task where col_casetask = v_CaseId))
  );

  -- SELECT SLA EVENTS FOR TASKS IN CASE
  delete from (
  select * from tbl_slaevent
    where col_slaeventtask in
    (select col_id from tbl_task where col_casetask = v_CaseId)
  );

  -- SELECT CASE HISTORY
  delete from (
  select * from tbl_history where col_historycase = v_CaseId
  );

  -- SELECT CASE TASKS HISTORY
  delete from (
  select * from tbl_history
    where col_historytask in
  (select col_id from tbl_task where col_casetask = v_CaseId)
  );

  -- SELECT MAPPING BETWEEN DOCUMENTS AND DYNAMIC TASKS
  /*
  delete from (
  select * from tbl_documentdynamictask where col_tbl_dynamictask in
    (select col_id from tbl_dynamictask where col_casedynamictask = v_CaseId)
  );
  */

  -- SELECT DATE EVENTS FOR CASE
  delete from (
  select * from tbl_dateevent where col_dateeventcase = v_CaseId
  );

  -- SELECT DATE EVENTS FOT TASKS
  delete from (
  select * from tbl_dateevent where col_dateeventtask in
    (select col_id from tbl_task where col_casetask = v_CaseId)
  );

  -- SELECT WORKITEMS
  delete from (
  select * from tbl_tw_workitem
    where col_id in
    (select col_tw_workitemtask from tbl_task where col_casetask = v_CaseId)
  );

  -- SELECT TASKEXT
  delete from (
  select * from tbl_taskext where col_taskexttask in
  (select col_id from tbl_task where col_casetask = v_CaseId));

  -- SELECT TASKS
  delete from (
  select * from tbl_task where col_casetask = v_CaseId
  );

  -- SELECT CASE SERVICE EXT
  delete from (
  select * from tbl_caseserviceext where col_casecaseserviceext = v_CaseId
  );

  -- SELECT CASE
  delete from (
  select * from tbl_case where col_id = v_CaseId
  );

end;