DECLARE
  v_taskid     INTEGER;
  v_name NVARCHAR2(255);
  v_action       NVARCHAR2(255);
  v_workbasketid NUMBER;
  v_targetID     NUMBER;
  v_target       nvarchar2(255);
  v_targetName   nvarchar2(255);
  v_resolutionid INTEGER;
  v_CustomData   nclob;
  v_old_name NVARCHAR2(255);
  v_old_workbasketid NUMBER;
  v_old_taskstate_id NUMBER;
  v_result       NUMBER;
  v_isId         NUMBER;
  v_AccessObjectId NUMBER;
  v_TaskTypeId     NUMBER;
  --standard
  v_errorcode       NUMBER;
  v_errormessage    NCLOB;
  v_ErrMessage      NCLOB;--VARCHAR2(2000);
  v_SuccessResponse NCLOB;
  v_SuccessResp		NCLOB;
BEGIN
  --COMMON ATTRIBUTES
  v_taskid       := NVL(:ID, 0);
  v_name         := :TASKNAME;
  v_action       := 'ASSIGN';
  v_workbasketid := NVL(:WORKBASKET_ID, 0);
  v_resolutionid := NVL(:ResolutionId, 0);
  v_CustomData   := :CUSTOMDATA;
  v_targetID 	 := NVL(:TASKSTATE_ID, 0);
  v_errorcode    := 0;
  v_errormessage := '';
  v_ErrMessage   := '';
  v_SuccessResp  := '';

-- validation on Id is Exist 
  -- TaskId
  IF v_taskid > 0 THEN
    v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                           errormessage => v_errormessage,
                           id           => v_taskid,
                           tablename    => 'TBL_TASK');
    IF v_errorcode > 0 THEN
	  v_ErrMessage := v_errorMessage;
      GOTO cleanup;
    END IF;
  END IF;

  -- get TaskTypeId
  BEGIN
    SELECT COL_TASKDICT_TASKSYSTYPE INTO v_TaskTypeId FROM tbl_task WHERE col_id = v_taskid;
  EXCEPTION
    WHEN no_data_found THEN
      v_errorCode    := 101;
      v_errorMessage := 'CaseTypeId not found';
      GOTO cleanup;
  END;
  -- get AccessObjectId
  BEGIN
    SELECT Id INTO v_AccessObjectId FROM TABLE(f_DCM_getTaskTypeAOList()) WHERE TaskTypeId = v_TaskTypeId;
  EXCEPTION
    WHEN no_data_found THEN
      v_errorCode    := 102;
      v_ErrMessage := 'AccessObjectId not found';
      GOTO cleanup;
  END;

  -- check access for AccessObjectId
  IF (v_AccessObjectId IS NULL OR f_DCM_isTaskTypeModifyAlwMS(AccessObjectId => v_AccessObjectId) <> 1) THEN
      v_errorCode    := 103;
      v_ErrMessage := 'You are not have enougth rights to modify a Task of that type';
      GOTO cleanup;
  END IF;
  
  --get old values
  SELECT 
	tv.taskName,
	tv.Workbasket_Id,
	tv.TASKSTATE_ID
  INTO
	v_old_name,
	v_old_workbasketid,
	v_old_taskstate_id
  FROM vw_dcm_simpletask tv
  WHERE id = v_taskid;

  IF (v_name IS NOT NULL AND v_name <> v_old_name) THEN
	  UPDATE tbl_task SET 
		col_name = v_name
	  WHERE col_id = v_taskid;
	  v_SuccessResp := 'Name for Task ' || TO_CHAR(v_taskid) || ' was updated.';
  END IF;
 
	  --set new owner
	  IF (v_workbasketid > 0 AND (NVL(v_old_workbasketid, 0) < 1 OR v_workbasketid <> v_old_workbasketid)) THEN

		  v_result       := F_DCM_assignTaskFn(Action          => v_action,
											   CaseParty_Id    => null,
											   errorCode       => v_errorCode,
											   errorMessage    => v_errorMessage,
											   Note            => null,
											   SuccessResponse => v_SuccessResponse,
											   Task_Id         => v_taskid,
											   WorkBasket_Id   => v_workbasketid);
		  IF v_result <= 0 THEN
			v_ErrMessage := v_errorMessage; 	
		  END IF;
		  v_SuccessResp := v_SuccessResp || CHR(13)||CHR(10) || v_SuccessResponse;
	  END IF;
	  
	  --set new state
	  IF (v_targetID > 0) THEN
		  BEGIN
			  SELECT col_activity, col_name INTO v_target, v_targetName FROM tbl_dict_taskstate WHERE col_id = v_targetID;
		  EXCEPTION
		  WHEN NO_DATA_FOUND THEN
			v_target := null;
			v_errorcode := 105;
			v_ErrMessage   := v_ErrMessage || CHR(13)||CHR(10) || 'Task state undefined'; 
		  END;
		  
		  IF (v_target IS NOT NULL AND (NVL(v_old_taskstate_id, 0) < 1 OR v_targetID <> v_old_taskstate_id)) THEN
			  v_result := f_DCM_taskTransitionManualFn(CUSTOMDATA => v_CustomData, ErrorCode => v_errorcode, ErrorMessage => v_errormessage, ResolutionId => v_resolutionid,
												 Target => v_target, TaskId => v_taskid, WorkbasketId => null);
			  IF v_result <> 0 THEN
				v_ErrMessage := v_ErrMessage || CHR(13)||CHR(10) || v_errorMessage; 
			  ELSE
				v_SuccessResp := v_SuccessResp || CHR(13)||CHR(10) || 'Task State was updated to ' || v_targetName;
			  END IF;
		  END IF;
	  END IF;
 
	  IF v_SuccessResp IS NULL THEN
		v_SuccessResp := 'There is no changes.';
	  END IF;
 <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := SUBSTR(v_ErrMessage, 1 , 255);
  :SuccessResponse := v_SuccessResp;

END;