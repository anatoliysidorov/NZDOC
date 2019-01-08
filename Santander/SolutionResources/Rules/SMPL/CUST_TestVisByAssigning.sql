DECLARE
    v_StateCode nvarchar2(255);
    v_TaskID number;
BEGIN
    v_TaskID := :TASK_ID;
     
    -- select state code
    select
     dts.col_code into v_StateCode
    from tbl_task tsk
      LEFT JOIN tbl_dict_taskstate dts ON tsk.col_taskdict_taskstate = dts.col_id
    where tsk.col_id = v_TaskID;
 
     IF v_StateCode = 'DEFAULT_TASK_AUTO_ASSIGNMENT' THEN
        RETURN 0; --ELEMENT SHOULD BE HIDDEN
    ELSE
        RETURN 1; --ELEMENT SHOULD BE VISIBLE
    END IF;
END;