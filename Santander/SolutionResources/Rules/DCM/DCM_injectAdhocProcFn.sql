declare
    --INPUT
    v_TaskTypeID INT;
	v_TaskTypeCode NVARCHAR2(255);
    v_ParentTaskID INT;
    v_CaseID INT; --optional, used if ParentTaskID is null
    v_WorkBasketID INT; --owner
    v_TaskName NVARCHAR2(255);
    v_Description NCLOB;
    v_CustomData NCLOB;
	
    --INTERNAL
    v_temperrmsg NCLOB;
    v_temperrcd INTEGER;
    v_tempresponce NCLOB;
	v_result INT;
	
    v_validationresult INT;
    v_TaskTypName NVARCHAR2(255);
    v_TaskTypeIconCode NVARCHAR2(40);
    v_ExecutionMethodID INTEGER;
    v_DateEventProcCode NVARCHAR2(40);
    v_AfterCreateDataProcCode NVARCHAR2(40);
    v_NumberingProcDode NVARCHAR2(40);
	v_stateconfigid INTEGER;
    v_ParentTaskDepth INT;
    v_highestTaskOrder INT;
    v_TaskID INT;
    v_TaskExtID INT;
	v_contextXML NCLOB;
    
	v_startActivityCode  NVARCHAR2(40);
    
begin
    --BIND
    v_TaskTypeID := NVL(:TaskTypeID,0);
	v_TaskTypeCode := LOWER(TRIM(:TaskTypeCode));
    v_ParentTaskID := NVL(:ParentTaskID,0);
    v_CaseID := NVL(:CaseID,0);
    v_WorkBasketID := :WorkBasketID;
    v_TaskName := TRIM(:TaskName);
    v_Description := TRIM(:Description);
    v_CustomData := f_UTIL_formatCustomDataFn(CustomData);
	
    --INIT
    v_temperrcd := 0;
	
    --BASIC ERROR HANDLING
    IF(v_ParentTaskID = 0 AND v_CaseID = 0) THEN
        v_temperrcd := 101;
        v_temperrmsg := 'Either the Parent Task ID is empty, the Case ID is empty or the Case does not have a root Task';
        GOTO cleanup;
    ELSIF(v_TaskTypeID = 0 AND v_TaskTypeCode IS NULL) THEN
        v_temperrcd := 101;
        v_temperrmsg := 'Task Type can not be empty';
        GOTO cleanup;
    END IF;
    
    --MAKE SURE BOTH CASE ID AND PARENT TASK ARE PROVIDED
    IF v_ParentTaskID = 0 THEN
        v_ParentTaskID := f_DCM_getCaseRootFn(v_CaseID);
    END IF;
    
    --GET INFO ABOUT THE TASK TYPE
    BEGIN
        SELECT COL_NAME,
               COL_ICONCODE,
               COL_STATECONFIGTASKSYSTYPE,
               COL_TASKSYSTYPEEXECMETHOD,
               TRIM(COL_DATEEVENTCUSTDATAPROC),
               TRIM(COL_CUSTOMDATAPROCESSOR),
               TRIM(COL_PROCESSORCODE
			   )
        INTO   v_TaskTypName,
               v_TaskTypeIconCode,
			   v_stateconfigid,
               v_ExecutionMethodID,
               v_DateEventProcCode,
               v_AfterCreateDataProcCode,
               v_NumberingProcDode			   
        FROM   TBL_DICT_TASKSYSTYPE
        WHERE  COL_ID = v_TaskTypeID OR lower(COL_CODE) = v_TaskTypeCode;
    
    EXCEPTION
    WHEN OTHERS THEN
        v_temperrcd := 102;
        v_temperrmsg := 'There was a problem retrieving the Task Type';
        GOTO cleanup;
    END;
	
    --GET INFO ABOUT THE PARENT TASK
    BEGIN
        SELECT COL_DEPTH,
               COL_CASETASK
        INTO   v_ParentTaskDepth,
               v_CaseID
        FROM   TBL_TASK
        WHERE  COL_ID = v_ParentTaskID;
        
        SELECT MAX(col_taskorder)
        INTO   v_highestTaskOrder
        FROM   TBL_TASK
        WHERE  COL_ID = v_ParentTaskID;
    
    EXCEPTION
    WHEN OTHERS THEN
        v_temperrcd := 102;
        v_temperrmsg := 'There was a problem retrieving the parent Task';
        GOTO cleanup;
    END;
	
	--CREATE CONTEXT XML TO SEND INTO COMMON EVENTS
	v_contextXML := '';
	v_contextXML := f_UTIL_addXmlNode(OriginalXML => v_contextXML, Tag => 'ParentTaskID', NodeValue => TO_CHAR(v_ParentTaskDepth));	
	v_contextXML := f_UTIL_addXmlNode(OriginalXML => v_contextXML, Tag => 'OwnerWorkbasketID', NodeValue => TO_CHAR(v_WorkBasketID));	
	v_contextXML := f_UTIL_addXmlNode(OriginalXML => v_contextXML, Tag => 'TaskName', NodeValue => v_TaskName);	
	
    --EXECUTE COMMON EVENT TO VALIDATE BEFORE TASK CREATE
    v_validationresult := 1;
    v_result := f_DCM_processCommonEvent(Attributes =>v_contextXML,
                                         code => NULL,
                                         caseid => NULL,
                                         casetypeid => NULL,
                                         commoneventtype => 'INSERT_ADHOC_TASK',
                                         errorcode => v_temperrcd,
                                         errormessage => v_temperrmsg,
                                         eventmoment => 'BEFORE',
                                         eventtype => 'VALIDATION',
                                         historymessage => v_tempresponce,
                                         procedureid => NULL,
                                         taskid => NULL,
                                         tasktypeid => v_TaskTypeID,
                                         validationresult => v_validationresult);
    IF v_validationresult <> 1 OR v_temperrcd > 0 THEN
        GOTO cleanup;
    END IF;
	
	--EXECUTE EVENT FOR BEFORE TASK CREATE
	v_validationresult := 1;
    v_result := f_DCM_processCommonEvent(Attributes =>v_contextXML,
                                         code => NULL,
                                         caseid => NULL,
                                         casetypeid => NULL,
                                         commoneventtype => 'INSERT_ADHOC_TASK',
                                         errorcode => v_temperrcd,
                                         errormessage => v_temperrmsg,
                                         eventmoment => 'BEFORE',
                                         eventtype => 'ACTION',
                                         historymessage => v_tempresponce,
                                         procedureid => NULL,
                                         taskid => NULL,
                                         tasktypeid => v_TaskTypeID,
                                         validationresult => v_validationresult);
    IF v_validationresult <> 1 OR v_temperrcd > 0 THEN
        GOTO cleanup;
    END IF;
	
    --CREATE NEW TASK
    insert into tbl_task(col_parentid,
                        col_description,
                        col_name,
                        col_depth,
                        col_leaf,
                        col_taskorder,
                        col_casetask,
                        col_taskdict_tasksystype,
                        col_taskdict_executionmethod,
                        col_isadhoc,
						col_customdata)
              values(v_ParentTaskID,
                        v_description,
                        NVL(v_TaskName,v_TaskTypName),
                        NVL(v_ParentTaskDepth, 0) + 1,
                        1,
                        NVL(v_highestTaskOrder, 0) + 1,
                        v_CaseId,
                        v_TaskTypeID,
                        v_ExecutionMethodID, 
                        1,
						XMLType(v_CustomData))
    RETURNING COL_ID
    INTO      V_TASKID;
    
    --GENERATE TASK TITLE (COL_TASKID) AND SET OTHER SYSTEM THINGS
    UPDATE TBL_TASK
    SET    COL_TASKID = 'TASK-' ||TO_CHAR(V_TASKID),
			COL_ID2  = COL_ID
    WHERE  COL_ID = V_TASKID;
    
    --CREATE TASK EXTENSION TO HOLD CUSTOM DATA IF NO CUSTOM PROCESSOR IS SET
    IF v_AfterCreateDataProcCode IS NOT NULL THEN
        v_TaskExtId := f_dcm_invokeCustomDataProc(Input => v_CustomData,
                                                  ProcessorName => v_AfterCreateDataProcCode,
                                                  TaskId => v_TaskId);
    END IF;
    
	--CREATE WORK ITEM 
	v_startActivityCode := f_DCM_getTaskNewState2(v_stateconfigid);
	v_result := f_TSKW_createWorkitem2(ActivityCode => v_startActivityCode,
								   ErrorCode => v_temperrcd,
								   ErrorMessage => v_temperrmsg,
								   TaskId => v_TaskId,
                                   WorkflowCode => NULL);

	--COPY STATE INITS, EVENTS AND OTHER THING
	v_Result := f_DCM_addTaskDateEventList(TaskId => v_TaskId, state => v_startActivityCode);
    v_result := f_DCM_CopyTaskStateInitTask(owner => NULL, TaskId => v_TaskId);
    v_result := f_DCM_CopyTaskEventAdhocTsk(TaskId => v_TaskId);
    v_result := f_DCM_CopyRuleParameterTask(TaskId => v_TaskId);
	
	--EXECUTE EVENT FOR AFTER CASE CREATE
	v_validationresult := 1;
    v_result := f_DCM_processCommonEvent(Attributes =>v_contextXML,
                                         code => NULL,
                                         caseid => NULL,
                                         casetypeid => NULL,
                                         commoneventtype => 'INSERT_ADHOC_TASK',
                                         errorcode => v_temperrcd,
                                         errormessage => v_temperrmsg,
                                         eventmoment => 'AFTER',
                                         eventtype => 'ACTION',
                                         historymessage => v_tempresponce,
                                         procedureid => NULL,
                                         taskid => v_TaskId,
                                         tasktypeid => v_TaskTypeID,
                                         validationresult => v_validationresult);
    IF v_validationresult <> 1 OR v_temperrcd > 0 THEN
        GOTO cleanup;
    END IF;
	
	--CREATE HISTORY FOR TASK CREATE
	v_result := F_hist_createhistoryfn(
		additionalinfo => NULL, 
		issystem => 0, 
		message => NULL, 
		messagecode => 'TaskInjected', 
		targetid => v_TaskId, 
		targettype => 'TASK'
	); 
	
	
	--ASSIGN TASK IF NEEDED
	IF v_WorkBasketID > 0 THEN
		v_result := F_DCM_assignTaskFn(Action          => 'ASSIGN',
                                       CaseParty_Id    => NULL,
                                       errorCode       => v_temperrcd,
                                       errorMessage    => v_temperrmsg,
                                       Note            => NULL,
                                       SuccessResponse => v_tempresponce,
                                       Task_Id         => v_taskid,
                                       WorkBasket_Id   => v_workbasketid);
									   
		IF v_temperrcd > 0 THEN
			GOTO cleanup;
		END IF;
	END IF;
	
	--INVALIDATE CASE TO EXECUTE EVENTS IF NEEDED
	v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
    v_result := f_dcm_casequeueproc5();
	
	--RETURN DATA
	:ErrorCode := 0;
	:ErrorMessage := NULL;
	:TaskID := v_TaskID;
	
	Return v_TaskID;

    <<cleanup>> 
	:ErrorCode := v_temperrcd;
    :ErrorMessage := v_temperrmsg;
    RETURN 0;
	
EXCEPTION WHEN OTHERS THEN
	:ErrorCode := 201;
    :ErrorMessage := DBMS_UTILITY.FORMAT_ERROR_STACK;
    RETURN 0;
end;