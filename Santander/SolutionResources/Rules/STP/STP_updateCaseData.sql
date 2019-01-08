DECLARE
  v_caseid          INTEGER;
  v_Summary         NVARCHAR2(255);
  v_action          NVARCHAR2(255);
  v_workbasketid    NUMBER;
  v_target_activity NVARCHAR2(255);
  v_targetID        NUMBER;
  v_target          NVARCHAR2(255);
  v_targetName      NVARCHAR2(255);
  v_resolutionid    INTEGER;
  v_CustomData      NCLOB;
  v_old_Summary      NVARCHAR2(255);
  v_old_workbasketid NUMBER;
  v_old_casestate_id NUMBER;
  v_result          NUMBER;
  v_isId            NUMBER;
  v_AccessObjectId  NUMBER;
  v_CaseTypeId      NUMBER;
  v_TransitionId    NUMBER;
  v_EventsIDs       NVARCHAR2(4000);
  v_SLAEvtId        NUMBER;
  --standard
  v_errorcode       NUMBER;
  v_errormessage    NVARCHAR2(255);
  v_ErrMessage      NVARCHAR2(255);--VARCHAR2(2000);
  v_tempErrCd       INTEGER;
  v_tempErrMsg      NCLOB;
  v_SuccessResponse NCLOB;
  v_SuccessResp 	  NCLOB;
BEGIN
  --COMMON ATTRIBUTES
  v_caseid          := NVL(:ID, 0);
  v_Summary         := :SUMMARY;
  v_action          := 'ASSIGN';
  v_workbasketid    := NVL(:WORKBASKET_ID, 0);
  v_resolutionid    := NVL(:RESOLUTIONID, 0);
  v_CustomData      := :CUSTOMDATA;
  v_target_activity := :TARGET_ACTIVITY;
  v_targetID 	    := NVL(:CASESTATE_ID, 0);--this is deprecated parameter
  v_TransitionId  := :TransitionId; 
  v_EventsIDs     := :EventsIDs;
  v_errorcode     := 0;
  v_errormessage  := '';
  v_ErrMessage    := '';
  v_SuccessResp   := '';
  v_SLAEvtId      := NULL;

  -- validation on Id is Exist 
  -- TaskId
  IF v_caseid > 0 THEN
    v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                           errormessage => v_errormessage,
                           id           => v_caseid,
                           tablename    => 'TBL_CASE');
    IF v_errorcode > 0 THEN
	  v_ErrMessage := v_errorMessage;
      GOTO cleanup;
    END IF;
  END IF;

  -- get CaseTypeId
  BEGIN
    SELECT COL_CASEDICT_CASESYSTYPE INTO v_CaseTypeId FROM tbl_case WHERE col_id = v_caseid;
  EXCEPTION
    WHEN no_data_found THEN
      v_errorCode    := 101;
      v_ErrMessage := 'CaseTypeId not found';
      GOTO cleanup;
  END;
  -- get AccessObjectId
  BEGIN
    SELECT Id INTO v_AccessObjectId FROM TABLE(f_DCM_getCaseTypeAOList()) WHERE CaseTypeId = v_CaseTypeId;
  EXCEPTION
    WHEN no_data_found THEN
      v_errorCode    := 102;
      v_ErrMessage := 'AccessObjectId not found';
      GOTO cleanup;
  END;

  -- check access for AccessObjectId
  IF (v_AccessObjectId IS NULL OR f_DCM_isCaseTypeModifyAlwMS(AccessObjectId => v_AccessObjectId) <> 1) THEN
      v_errorCode    := 103;
      v_ErrMessage := 'You are not have enougth rights to modify a Case of that type';
      GOTO cleanup;
  END IF;
  
	--get old values
	SELECT 
		cv.Summary,
		cv.Workbasket_Id,
		cv.CaseState_Id
	INTO
		v_old_Summary,
		v_old_workbasketid,
		v_old_casestate_id
	FROM vw_dcm_simplecaseac cv
	WHERE col_id = v_caseid;

	--update Summary
	IF (v_Summary IS NOT NULL AND v_Summary <> v_old_Summary) THEN
		UPDATE tbl_case SET 
			col_summary = v_Summary
		WHERE col_id = v_caseid;
		v_SuccessResp := 'Summary for Case ' || TO_CHAR(v_caseid) || ' was updated.';
	END IF;
 
	--set new owner
	IF (v_workbasketid > 0 AND (NVL(v_old_workbasketid, 0) < 1 OR v_workbasketid <> v_old_workbasketid)) THEN

		v_result := F_DCM_assignCaseFn(
									Action => v_action, 
									Case_Id => v_caseid, 
									CaseParty_Id => null,
									errorCode => v_errorCode, 
									errorMessage => v_errorMessage, 
									Note => null, 
									SuccessResponse => v_SuccessResponse, 
									WorkBasket_Id => v_workbasketid);
		IF v_result <> 0 THEN
			v_ErrMessage := v_errorMessage; 
		END IF;
        v_SuccessResp := f_UTIL_addToMessage(originalMsg => v_SuccessResp, newMsg => v_SuccessResponse);
	END IF;
	  
    --ROUTE THE CASE
	IF v_target_activity IS NOT NULL THEN
    v_result := f_DCM_caseMSRouteManualFn ( EVENTSIDS    =>NULL,--v_EventsIDs,
                                            TRANSITIONID =>v_TransitionId,
                                            ERRORCODE => v_tempErrCd,
                                            ERRORMESSAGE => v_tempErrMsg,
                                            TARGET => v_target_activity,
                                            RESOLUTIONID => null,
                                            CASEID => v_caseid,
                                            WORKBASKETID => null);

    IF NVL(v_tempErrCd, 0) > 0 THEN
        v_ErrMessage := f_UTIL_addToMessage( originalMsg => v_ErrMessage,newMsg => 'ERROR: There was an error routing the Case');
        v_ErrMessage := f_UTIL_addToMessage( originalMsg => v_ErrMessage,newMsg => v_tempErrMsg);
        GOTO cleanup;
    ELSE
        /* a code is working (commented by VV)
           now we use a "transition way" for a solve this issue    
        IF v_EventsIDs IS NOT NULL THEN
          FOR rec IN
          (
            SELECT REPLACE(column_value, 'SLA_') AS Id
            FROM TABLE(ASF_SPLITCLOB(v_EventsIDs,','))
            WHERE column_value LIKE '%SLA_%'
          )
          LOOP
            v_SLAEvtId  := NULL;
            BEGIN
              SELECT ssa.COL_STATESLAACTNSTATESLAEVNT INTO v_SLAEvtId
              FROM TBL_DICT_STATESLAACTION ssa
              WHERE COl_ID=TO_NUMBER(rec.Id);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN v_SLAEvtId:=0;
            END;

            IF v_SLAEvtId IS NOT NULL THEN
              INSERT INTO TBL_MSSLAQUEUE(COL_MSSLAQUEUECASE, COL_DATAFLAG,
                                         COL_SLAQUEUEDICT_STSLAEVENT, COL_SLAQUEUEDICT_STSLAACT)
              VALUES(v_caseid, 1, v_SLAEvtId, TO_NUMBER(rec.Id));
            END IF;  
          END LOOP;
        END IF; 
*/
        v_SuccessResp := f_UTIL_addToMessage(originalMsg => v_SuccessResp, newMsg => 'The case was routed successfully.');
    END IF;
  END IF;

/*
	--set new state
	IF (v_targetID > 0) THEN
		BEGIN
			SELECT col_activity, col_name INTO v_target, v_targetName FROM tbl_dict_casestate WHERE col_id = v_targetID;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_target := null;
				v_errorcode := 105;
				v_ErrMessage   := v_ErrMessage || CHR(13)||CHR(10) || 'Target Case state undefined'; 
		END;
		  
		IF (v_target IS NOT NULL AND (NVL(v_old_casestate_id, 0) < 1 OR v_targetID <> v_old_casestate_id)) THEN
			v_result := f_DCM_caseRouteValidate(ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, Target => v_Target, CaseId => v_CaseId);
			if (v_ErrorCode is not null) then
				:ErrorCode := v_ErrorCode;
				v_ErrMessage   := v_ErrMessage || CHR(13)||CHR(10) || v_ErrorMessage; 
				GOTO cleanup;
			end if;
			v_result := f_DCM_caseRouteManualFn(ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, Target => v_target, ResolutionId => v_ResolutionId, CaseId => v_CaseId, WorkbasketId => null);
			IF v_result <> 0 THEN
				v_ErrMessage := v_ErrMessage || CHR(13)||CHR(10) || v_errorMessage; 
			ELSE
				v_SuccessResp := v_SuccessResp || CHR(13)||CHR(10) || 'Case State was updated to ' || v_targetName;
			END IF;
		END IF;
	END IF;
*/
	IF v_SuccessResp IS NULL THEN
		v_SuccessResp := 'There is no changes.';
	END IF;
	
  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := SUBSTR(v_ErrMessage, 1 , 255);
  :SuccessResponse := v_SuccessResp;

END;