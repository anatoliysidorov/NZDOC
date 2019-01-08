DECLARE
  v_workitemId   NUMBER;
  v_actionCode   NVARCHAR2(255);
  v_actionName   NVARCHAR2(255);
  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);
  v_currentActivity NVARCHAR2(255);
  v_count NUMBER;
  v_isdeleted NUMBER;
  v_workbasketid NUMBER;
  v_result NUMBER;
BEGIN
    v_workitemId := :WorkitemId;
    v_actionCode := :ActionCode;    
    v_currentActivity := :CurrentActivity; 
    v_errorMessage := '';
    v_errorCode := 0;
    :ErrorCode := 0;
    :ErrorMessage := '';

    select 
        col_isdeleted, 
        col_pi_workitemppl_workbasket
        into v_isdeleted, v_workbasketid     
    from tbl_pi_workitem 
    where col_id = v_workitemId;

    BEGIN   
        select col_name into v_actionName
        from tbl_ac_permission
        where col_code = v_actionCode
        and col_permissionaccessobjtype = (select col_id
                                            from tbl_ac_accessobjecttype
                                            where col_code = 'WORKITEM');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_actionName := '';
    END;

    if (v_actionCode = 'PERMANENT_DELETE') then
        v_isDeleted := 1;
    end if;

    -- check access to action
    v_result := f_DCM_getPIWorkitemAccessFn(IsDeleted => v_isDeleted, PermissionCode => v_actionCode, WorkbasketId => v_workbasketId);
    if (v_result = 0) then
        v_errorCode    := 101;
        v_errorMessage := 'You do not have permission for Document Workitem to ''' || v_actionName || '''.';
        goto cleanup;  
    end if;

    -- check current activity
    select COUNT(*) into v_count
    from tbl_pi_workitem
    where col_id = v_workitemId 
            and col_currmsactivity = v_currentActivity;

    if(v_count = 0) then
        v_errorCode    := 101;
        v_errorMessage := 'Current WorkItem is into another activity.';
        goto cleanup;  
    end if; 

    <<cleanup>>
    :ErrorCode    := v_errorCode;
    :ErrorMessage := v_errorMessage;
END;