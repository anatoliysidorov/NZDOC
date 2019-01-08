--RULE SELECTS TASKS THAT CAN BE INITIALIZED ACCORDING TO TASK DEPENDENCY SETTINGS
--THOSE TASKS ARE RETURNED AS OUTPUT PARAMETER OF SYS_REFCURSOR DATA TYPE
--ONLY 'FS' DEPENDENCY TYPE IS PROCESSED BY THIS RULE (FINISH-TO-START, MEANING CHILD TASK CAN BE INITIALIZED AFTER PARENT TASKS ARE CLOSED)
--RULE ACCEPTS PARENT TASK ID AS INPUT PARAMETER AND FINDS ALL CHILD TASKS THAT ARE DEPENDENT FROM PARENT TASK BY 'FS' DEPENDENCY TYPE
--IN ORDER TO BE INCLUDED TO RESULTING LIST OF TASKS FOLLOWING CONDITIONS MUST BE SATISFIED
--1.CHILD TASKS MUST BE FOUND IN THE LIST OF DEPENDENT TASKS FROM INPUT PARAMETER TASK IF PARENT TASK IS CLOSED (COL_DATECLOSED IS NOT NULL)
--2.CHILD TASK MUST NOT BE FOUND IN THE LIST OF DEPENDENT TASKS FROM INPUT PARAMETER TASK IF PARENT TASK IS NOT CLOSED (COL_DATECLOSED IS NULL)
--3.CHILD TASK MUST NOT BE DEPENDENT ON ANY OTHER PARENT TASK (NOT THE TASK SENT AS RULE PARAMETER) THAT IS NOT CLOSED
--4.CHILD TASK MUST NOT BE ENABLED (COL_ENABLED = 0)
--5.CHILD TASK MUST NOT BE ASSIGNED (COL_DATEASSIGNED IS NULL)
declare
  v_TaskId Integer;
  v_result SYS_REFCURSOR;
begin
  v_TaskId := :TaskId;
  open v_result for select col_id from tbl_task tsk1
  where col_id in
          (select td.col_tskdpndchldtskstateinit from tbl_taskdependency td
            inner join tbl_map_taskstateinitiation tsi on td.col_tskdpndchldtskstateinit = tsi.col_id
            inner join tbl_map_taskstateinitiation tsi2 on td.col_tskdpndprnttskstateinit = tsi2.col_id
            inner join tbl_task tsk on tsi.col_map_taskstateinittask = tsk.col_id
            inner join tbl_task tsk2 on tsi2.col_map_taskstateinittask = tsk2.col_id
            where tsk2.col_id = v_TaskId
            and td.col_type = 'FS'
            and tsk2.col_dateclosed is not null)
    and col_id not in
          (select td.col_tskdpndchldtskstateinit from tbl_taskdependency td
            inner join tbl_map_taskstateinitiation tsi on td.col_tskdpndchldtskstateinit = tsi.col_id
            inner join tbl_map_taskstateinitiation tsi2 on td.col_tskdpndprnttskstateinit = tsi2.col_id
            inner join tbl_task tsk on tsi.col_map_taskstateinittask = tsk.col_id
            inner join tbl_task tsk2 on tsi2.col_map_taskstateinittask = tsk2.col_id
            where tsk2.col_id = v_TaskId
            and td.col_type = 'FS'
            and tsk2.col_dateclosed is null)
    and (select count(*) from tbl_taskdependency td
                           inner join tbl_map_taskstateinitiation tsi on td.col_tskdpndchldtskstateinit = tsi.col_id
                           inner join tbl_task tsk on tsi.col_map_taskstateinittask = tsk.col_id
                           where tsi.col_map_taskstateinittask = tsk1.col_id
                           and td.col_tskdpndprnttskstateinit in (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittask <> v_TaskId)
                           and td.col_type = 'FS' and tsk.col_dateclosed is null) = 0
    and col_enabled = 0 and col_dateassigned is null;
  :result := v_result;
end;