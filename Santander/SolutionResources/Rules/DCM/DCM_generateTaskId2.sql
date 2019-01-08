declare
    v_taskid Integer;
    v_tasktitle nvarchar2(255);
    v_tasktypeid Integer;
    v_tasktypecode nvarchar2(255);
    v_tasktypename nvarchar2(255);
    v_tasktypeprocessorcode nvarchar2(255);
    v_stateconfigid Integer;
    v_ErrorCode number;
    v_ErrorMessage nvarchar2(255);
    v_affectedRows number;
    v_result number;
begin
    v_taskid := :TaskId;
    begin
        select tsk.col_taskdict_tasksystype
        into
               v_tasktypeid
        from   tbl_task tsk
        where  tsk.col_id = v_taskid;
    
    exception
    when NO_DATA_FOUND then
        v_tasktypeid := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Task type for task ' || to_char(v_taskid) || ' not found';
        return -1;
    end;
    begin
        select col_code,
               col_name,
               col_processorcode,
               col_stateconfigtasksystype
        into
               v_tasktypecode,
               v_tasktypename,
               v_tasktypeprocessorcode,
               v_stateconfigid
        from   tbl_dict_tasksystype
        where  col_id = v_tasktypeid;
    
    exception
    when NO_DATA_FOUND then
        v_ErrorCode := 102;
        v_ErrorMessage := 'Task type not found';
        return -1;
    end;
    --GENERATE TASK TITLE
    if v_tasktypeprocessorcode is not null then
        v_tasktitle := f_dcm_invokeTaskIdGenProc(ProcessorName => v_tasktypeprocessorcode,
                                                 TaskId => v_taskid);
        update tbl_task
        set    col_taskid = v_tasktitle
        where  col_id = v_taskid;
    
    else
        v_result := f_DCM_generateTaskId(affectedRows => v_affectedRows,
                                         ErrorCode => ErrorCode,
                                         ErrorMessage => ErrorMessage,
                                         prefix => 'TASK',
                                         recordid => v_taskid,
                                         taskid => v_tasktitle);
    end if;
    :TaskTitle := v_tasktitle;
end;