DECLARE
	--INPUT
    v_caseid INT;
    v_Summary NVARCHAR2(255);
    v_workbasketid INT;    
    v_resolutionid INT;
	v_TransitionId INT;
	
	--INTERNAL
	v_assignAction NVARCHAR2(255);
	v_target_activity NVARCHAR2(255);
	v_ignore INT;
    v_AccessObjectId INT;
    v_CaseTypeId INT;
	v_old_workbasketid INT;
	v_old_summary NVARCHAR2(255);
	
    --STANDARD
    V_ERRORCODE INT;
    v_ERRORMESSAGE NCLOB;
    V_SUCCESSRESPONSE NCLOB;
    v_tempErrCd INT;
    v_tempErrMsg NCLOB;
    v_tempSuccResp NCLOB;
BEGIN
    --INPUT PARAMETERS
    v_caseid := NVL(:ID,0);
    v_Summary := :SUMMARY;
    v_workbasketid := NVL(:WORKBASKET_ID, 0);
    v_target_activity := :TARGET_ACTIVITY;
    v_TransitionId := :TransitionId;
	
    --STANDARD
    v_CaseTypeId := f_DCM_getCaseTypeForCase(v_caseid);
    V_ERRORCODE := 0;
    v_ERRORMESSAGE := '';
    V_SUCCESSRESPONSE := '';
	
	--GET CURRENT CASE WORK BASKET
	BEGIN
		SELECT NVL(COL_CASEPPL_WORKBASKET, 0), COL_SUMMARY
		INTO v_old_workbasketid, v_old_summary
		FROM   tbl_case
		WHERE  col_id = v_caseid;
	EXCEPTION
    WHEN no_data_found THEN
        V_ERRORCODE := 101;
        v_ERRORMESSAGE := 'Case does not exist';
        GOTO cleanup;
    END;
	
    -- CHECK SECURITY
    BEGIN
        SELECT Id
        INTO v_AccessObjectId
        FROM   TABLE(f_DCM_getCaseTypeAOList())
        WHERE  CaseTypeId = v_CaseTypeId;
    
    EXCEPTION
    WHEN no_data_found THEN
        V_ERRORCODE := 102;
        v_ERRORMESSAGE := 'Access Object ID not found';
        GOTO cleanup;
    END;
	
	
    IF(v_AccessObjectId IS NULL OR f_DCM_isCaseTypeModifyAlwMS(AccessObjectId => v_AccessObjectId) <> 1) THEN
        V_ERRORCODE := 103;
        v_ERRORMESSAGE := 'You do not permission to modify a Case of that type';
        GOTO cleanup;
    END IF;   
    
    --UPDATE CASE SUMMARY IF NEEDED
    IF(v_Summary <> v_old_Summary) THEN
        UPDATE tbl_case
        SET    col_summary = v_Summary
        WHERE  col_id = v_caseid;
        
        V_SUCCESSRESPONSE := f_UTIL_addToMessage(originalMsg => V_SUCCESSRESPONSE, newMsg => 'Summary was updated');
    END IF;
	
	--ASSIGN AND/OR ROUTE CASE IF NEEDED
	IF(v_target_activity IS NOT NULL OR v_TransitionId > 0) THEN
		v_ignore := f_DCM_caseMSRouteManualFn(TRANSITIONID => v_TransitionId,
                                              ERRORCODE => v_tempErrCd,
                                              ERRORMESSAGE => v_tempErrMsg,
                                              TARGET => v_target_activity,
                                              RESOLUTIONID => NULL,
                                              CASEID => v_caseid,
                                              WORKBASKETID => v_workbasketid);
        IF NVL(v_tempErrCd,0) > 0 THEN
			v_ERRORCODE := v_tempErrCd;
            v_ERRORMESSAGE := f_UTIL_addToMessage(originalMsg => v_ERRORMESSAGE,newMsg => 'ERROR: There was an error routing the Case');
            v_ERRORMESSAGE := f_UTIL_addToMessage(originalMsg => v_ERRORMESSAGE,newMsg => v_tempErrMsg);
            GOTO cleanup;
        ELSE
			V_SUCCESSRESPONSE := f_UTIL_addToMessage(originalMsg => V_SUCCESSRESPONSE, newMsg => 'Case was routed');
			IF(v_old_workbasketid <> v_workbasketid AND v_workbasketid > 0) THEN 
				V_SUCCESSRESPONSE := f_UTIL_addToMessage(originalMsg => V_SUCCESSRESPONSE, newMsg => 'Case was assigned');
			ELSIF NVL(v_workbasketid, 0) = 0 THEN
				V_SUCCESSRESPONSE := f_UTIL_addToMessage(originalMsg => V_SUCCESSRESPONSE, newMsg => 'Case was unassigned');
			END IF;			
            
        END IF;
	ELSIF v_old_workbasketid <> v_workbasketid THEN
		IF(v_workbasketid > 0) THEN
			v_assignAction := 'ASSIGN';
		ELSE
			v_assignAction := 'UNASSIGN';
		END IF;
		
		v_ignore := F_DCM_assignCaseFn(Action => v_assignAction,
                                       Case_Id => v_caseid,
                                       CaseParty_Id => NULL,
                                       errorCode => v_tempErrCd,
                                       errorMessage => v_tempErrMsg,
                                       Note => NULL,
                                       SuccessResponse => v_tempSuccResp,
                                       WorkBasket_Id => v_workbasketid);
        IF( v_ignore <> 0 OR v_tempErrCd > 0) THEN
            v_ERRORMESSAGE := v_tempErrMsg;
        END IF;
        V_SUCCESSRESPONSE := f_UTIL_addToMessage(originalMsg => V_SUCCESSRESPONSE, newMsg => v_tempSuccResp);

	END IF;
	
    <<cleanup>> 
	:errorCode := V_ERRORCODE;
    :errorMessage := v_ERRORMESSAGE;
    :SuccessResponse := V_SUCCESSRESPONSE;
END;