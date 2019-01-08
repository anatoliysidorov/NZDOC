DECLARE
  v_WorkItemId    NUMBER;
  v_InstanceId    NVARCHAR2(255);
  v_WorkflowCode  NVARCHAR2(255);
  v_ActivityCode  NVARCHAR2(255);
  v_TaskId        INTEGER;
  v_result        NVARCHAR2(255);
  v_result2       INTEGER;
  v_taskStateId   NUMBER;
  v_CSisInCache   INTEGER;  

BEGIN
  v_WorkflowCode  := :WorkflowCode;
  v_ActivityCode  := :ActivityCode;
  v_TaskId        := :TaskId;

  v_InstanceId    := SYS_GUID();
  v_taskStateId   := NULL;

  v_CSisInCache := f_DCM_CSisTaskInCache(v_TaskId);--new cache

  --case not in new cache 
  IF v_CSisInCache=0 THEN	
    begin
      select     ts.col_activity
      into       v_result
      from       tbl_task           tsk
      inner join tbl_tasktemplate   tt on tsk.col_id2 = tt.col_id
      left join  tbl_dict_taskstate ts on tt.col_tasktmpldict_taskstate = ts.col_id
      where      tsk.col_id = v_TaskId;
    
    exception
    when NO_DATA_FOUND then
        v_result := null;
    end;
  END IF;

  --case in new cache 
  IF v_CSisInCache=1 THEN	
    BEGIN
      SELECT ts.COL_ACTIVITY INTO v_result
      FROM TBL_CSTASK tsk
      INNER JOIN TBL_TASKTEMPLATE  tt on tsk.COL_ID2 = tt.COL_ID
      LEFT JOIN  TBL_DICT_TASKSTATE ts on tt.COL_TASKTMPLDICT_TASKSTATE = ts.COL_ID
      WHERE tsk.COL_ID = v_TaskId;    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN v_result := null;
    END;
  END IF;

  IF v_result IS NOT NULL THEN v_ActivityCode := v_result; END IF;

  --GET NEW ID
  SELECT gen_tbl_TW_Workitem.NEXTVAL INTO  v_WorkItemId FROM   DUAL;

  --define a task activity
  --case not in new cache 
  IF v_CSisInCache=0 THEN	
    BEGIN
      SELECT col_id INTO v_taskStateId
      FROM  TBL_DICT_TASKSTATE
      WHERE   col_activity = v_ActivityCode
              and nvl(col_stateconfigtaskstate,0) =
              case
                when(select col_taskdict_tasksystype
                        from    tbl_task
                        where   col_id = v_TaskId) is null then
                        case
                          when(select col_id
                                  from    tbl_dict_stateconfig
                                  where   col_isdefault = 1 and lower(col_type) = 'task') is not null THEN 
                                  (select col_id
                                  from    tbl_dict_stateconfig
                                  where   col_isdefault = 1 and lower(col_type) = 'task') else 0
                        end else(select nvl(col_stateconfigtasksystype,0)
                                 from    tbl_dict_tasksystype
                                 where   col_id =(select col_taskdict_tasksystype
                                         from    tbl_task
                                         where   col_id = v_TaskId))
              end;
    EXCEPTION WHEN NO_DATA_FOUND THEN  v_taskStateId :=NULL;
    END;

    INSERT INTO TBL_TW_WORKITEM(COl_ID, COL_WORKFLOW, COL_ACTIVITY, COL_TW_WORKITEMDICT_TASKSTATE,
                                COL_INSTANCEID, COL_INSTANCETYPE)
    VALUES(v_WorkItemId, v_WorkflowCode, v_ActivityCode, v_taskStateId, v_InstanceId, 1);

    UPDATE TBL_TASK
    SET   COL_TW_WORKITEMTASK = v_WorkItemId,
          COL_TASKDICT_TASKSTATE=v_taskStateId
    WHERE  COL_ID = v_TaskId;
  END IF;

  --case  in new cache 
  IF v_CSisInCache=1 THEN	
    BEGIN
      SELECT col_id INTO v_taskStateId
      FROM  TBL_DICT_TASKSTATE
      WHERE   col_activity = v_ActivityCode
              and nvl(col_stateconfigtaskstate,0) =
              case
                when(select col_taskdict_tasksystype
                        from    tbl_cstask
                        where   col_id = v_TaskId) is null then
                        case
                          when(select col_id
                                  from    tbl_dict_stateconfig
                                  where   col_isdefault = 1 and lower(col_type) = 'task') is not null THEN 
                                  (select col_id
                                  from    tbl_dict_stateconfig
                                  where   col_isdefault = 1 and lower(col_type) = 'task') else 0
                        end else(select nvl(col_stateconfigtasksystype,0)
                                 from    tbl_dict_tasksystype
                                 where   col_id =(select col_taskdict_tasksystype
                                         from    tbl_cstask
                                         where   col_id = v_TaskId))
              end;
    EXCEPTION WHEN NO_DATA_FOUND THEN  v_taskStateId :=NULL;
    END;

    INSERT INTO TBL_CSTW_WORKITEM(COL_ID, COL_WORKFLOW, COL_ACTIVITY, COL_TW_WORKITEMDICT_TASKSTATE,
                                  COL_INSTANCEID, COL_INSTANCETYPE)
    VALUES(v_WorkItemId, v_WorkflowCode, v_ActivityCode, v_taskStateId, v_InstanceId, 1);
  
    UPDATE TBL_CSTASK
    SET COL_TW_WORKITEMTASK = v_WorkItemId,
        COL_TASKDICT_TASKSTATE=v_taskStateId
    WHERE  COL_ID = v_TaskId;
  END IF;
    
  v_result2 := f_DCM_addTaskDateEventList(TaskId => v_TaskId, state => v_ActivityCode);

  :ErrorCode := 0;
  :ErrorMessage := '';
  
EXCEPTION
WHEN OTHERS THEN
    ErrorCode := 100;
    ErrorMessage := SUBSTR(SQLERRM,1,200);  

END;