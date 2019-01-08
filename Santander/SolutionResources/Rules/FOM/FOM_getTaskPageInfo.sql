DECLARE 
    v_id INTEGER;
    v_name NVARCHAR2(255);
    v_pageCode NVARCHAR2(255);
    v_pageParams NCLOB;
    v_customData NCLOB; 
    v_taskId NVARCHAR2(255);
    v_TARGET_RAWTYPE   NVARCHAR2(255);
    v_TARGET_ELEMENTID NVARCHAR2(255);
    
BEGIN
    
    v_id := :ID;
    
    BEGIN
        SELECT 
            NAME, TASKID INTO 
            v_name, v_taskId
        FROM vw_dcm_simpletask 
        WHERE id = v_id;  
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
    END;
    
    BEGIN
        SELECT ap.TARGET_RAWTYPE, ap.TARGET_ELEMENTID
        INTO v_TARGET_RAWTYPE, v_TARGET_ELEMENTID
        FROM vw_dcm_assocpage ap
        INNER JOIN tbl_dict_tasksystype cst ON ap.tasksystype = cst.col_id
        INNER JOIN tbl_task cs ON cst.col_id = cs.col_taskdict_tasksystype
        WHERE cs.col_id = v_id
              AND lower(ap.PAGETYPE_CODE) = lower('FULL_PAGE_TASK_DETAIL');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
    END;
    
    IF v_TARGET_RAWTYPE IS NULL OR v_TARGET_ELEMENTID IS NULL THEN
        BEGIN
            SELECT col_id
                    INTO v_TARGET_ELEMENTID
            FROM tbl_FOM_PAGE
            WHERE lower(col_usedfor) = 'task'
                 AND col_systemdefault = 1 
                 AND ROWNUM = 1;
            v_TARGET_RAWTYPE := 'PAGE';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
    END IF;
    
    IF v_TARGET_RAWTYPE IS NOT NULL AND v_TARGET_ELEMENTID IS NOT NULL THEN
        IF upper(v_TARGET_RAWTYPE) = 'PAGE' THEN
          v_pageCode := 'root_UTIL_CaseManagement';
          v_pageParams := '<PageParams>' ||
                            '<Task_Id>' || v_id || '</Task_Id>' ||
                            '<app>TaskDetailRuntime</app>' ||
                            '<group>FOM</group>' ||
                            '<usePageConfig>1</usePageConfig>' ||
                        '</PageParams>';
        ELSE
          v_pageCode := v_TARGET_ELEMENTID;
          v_pageParams := '<PageParams>' ||
                            '<Task_Id>' || v_id || '</Task_Id>' ||
                        '</PageParams>';
        END IF;
    END IF;  
    v_customData := f_DCM_getTaskCustomData(v_id);
    
    -- Output
    :TaskID := v_taskId;
    :Name := v_name;
    :PageCode := v_pageCode;
    :PageParams := v_pageParams;
    :CustomData := v_customData;    
END;