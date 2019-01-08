  DECLARE
    v_WorkItemId    NUMBER;
    v_InstanceId    NVARCHAR2(255);
    v_WorkflowCode  NVARCHAR2(255);
    v_ActivityCode  NVARCHAR2(255);

    v_TaskId        INTEGER;
    v_result        NVARCHAR2(255);
    v_taskStateId   NUMBER;
      
  BEGIN      
    v_WorkflowCode := :WorkflowCode;
    v_ActivityCode := :ActivityCode;

    v_TaskId        := :TaskId;
    v_InstanceId    := SYS_GUID();
    v_taskStateId   := NULL;
      
    begin
        select     ts.col_activity
        into       v_result
        from       tbl_taskcc         tsk
        inner join tbl_tasktemplate   tt on tsk.col_id2 = tt.col_id
        left join  tbl_dict_taskstate ts on tt.col_tasktmpldict_taskstate = ts.col_id
        where      tsk.col_id = v_TaskId;
    
    exception
    when NO_DATA_FOUND then
        v_result := null;
    end;
        
    if v_result is not null then
        v_ActivityCode := v_result;
    end if;
    
    --define a task activity
    BEGIN
      SELECT COL_ID INTO v_taskStateId      
      FROM    TBL_DICT_TASKSTATE
      WHERE   COL_ACTIVITY = v_ActivityCode
              and nvl(col_stateconfigtaskstate,0) =
              case
                      when(select col_taskccdict_tasksystype
                              from    tbl_taskcc
                              where   col_id = TaskId) is null then
                              case
                                      when(select col_id
                                              from    tbl_dict_stateconfig
                                              where   col_isdefault = 1 and lower(col_type) = 'task') is not null then(select col_id
                                              from    tbl_dict_stateconfig
                                              where   col_isdefault = 1 and lower(col_type) = 'task') else 0
                              end else(select nvl(col_stateconfigtasksystype,0)
                                       from    tbl_dict_tasksystype
                                       where   col_id =(select col_taskccdict_tasksystype
                                               from    tbl_taskcc
                                               where   col_id = TaskId))
              end;    
    EXCEPTION WHEN NO_DATA_FOUND THEN  v_taskStateId :=NULL;       
    END;
            
    INSERT INTO TBL_TW_WORKITEMCC(COL_WORKFLOW, COL_ACTIVITY,
                                  COL_TW_WORKITEMCCDICT_TASKST, COL_INSTANCEID,
                        --COL_OWNER,
                        --COL_CREATEDBY,
                        --COL_CREATEDDATE,
                        COL_INSTANCETYPE)
      VALUES(v_WorkflowCode, v_ActivityCode, v_taskStateId, v_InstanceId,
                --v_Owner,
                --TOKEN_USERACCESSSUBJECT,
                --sysdate,
                1) RETURNING col_id INTO      v_WorkItemId;
        
      ErrorCode := 0;
      ErrorMessage := '';
      
      UPDATE TBL_TASKCC
      SET    COL_TW_WORKITEMCCTASKCC = v_WorkItemId,
                COL_TASKCCDICT_TASKSTATE = v_taskStateId
      WHERE  COL_ID = TaskId;
    
    EXCEPTION
    WHEN OTHERS THEN
        ErrorCode := 100;
        ErrorMessage := SUBSTR(SQLERRM,1,200);    
END;