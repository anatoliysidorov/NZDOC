DECLARE
    --INPUT
    v_CaseId NUMBER;
    v_TransitionId NUMBER;
    v_Target NVARCHAR2(255);
    v_ResolutionId NUMBER;
    v_WorkbasketId NUMBER;
    v_CustomData NCLOB;
    v_RoutingDescription NCLOB;
    
    --INTERNAL
    v_routecustomdataprocessor NVARCHAR2(255);
    v_casetypeid NUMBER;
    v_CustomDataXML XMLTYPE;
    
    v_result INTEGER;
    v_tempErrCd INTEGER;
    v_tempErrMsg NCLOB;
    v_tempSccss NCLOB;
    v_message NCLOB;

BEGIN
    --INPUT
    v_CaseId := :CaseId; 
    v_Target := :Target;
    v_ResolutionId := :ResolutionId;
    v_Workbasketid := :WorkbasketId;
    v_CustomData := :CUSTOMDATA;
    v_RoutingDescription := :RoutingDescription;
    v_TransitionId := :TransitionId;
    
    --DO BASIC ERROR HANDLING
    IF v_CaseId <= 0 THEN
        v_tempErrMsg := 'ERROR: Case ID is missing';
        v_tempErrCd := 110;
        GOTO cleanup;
    END IF;
    
    IF v_Target IS NULL THEN
        v_tempErrMsg := 'ERROR: Target Activity Code is missing';
        v_tempErrCd := 110;
        GOTO cleanup;
    END IF;
	
    --CHECK IF CUSTOM DATA IS PASSED IN AND WHETHER IT'S VALID XML
    IF v_CustomData IS NOT NULL THEN
        v_message := f_UTIL_addToMessage( originalMsg => v_message,
                                          newMsg => 'INFO: Attempting to parse Custom Data');
        BEGIN
            v_CustomDataXML := XMLType(v_CustomData);
        EXCEPTION
        WHEN OTHERS THEN
            v_message := f_UTIL_addToMessage( originalMsg => v_message, newMsg => 'SQLCODE: ' || TO_CHAR(SQLCODE));
            v_message := f_UTIL_addToMessage( originalMsg => v_message, newMsg => 'SQL ERROR STACK:');
            v_message := f_UTIL_addToMessage( originalMsg => v_message, newMsg => DBMS_UTILITY.FORMAT_ERROR_STACK);
            v_tempErrMsg := 'ERROR: Failed to parse Custom Data';
            v_tempErrCd := 102;
            GOTO cleanup;
        END;
        v_message := f_UTIL_addToMessage( originalMsg => v_message, newMsg => 'INFO: Parsed custom data');
    ELSE
        v_message := f_UTIL_addToMessage( originalMsg => v_message, newMsg => 'INFO: No custom data passed in');
    END IF;

    --ROUTE THE CASE
    v_message := f_UTIL_addToMessage( originalMsg => v_message, newMsg => 'INFO: Attempting to route Case to target milestone');
    v_result := f_DCM_caseMSRouteManualFn ( TRANSITIONID =>v_TransitionId,
                                            ERRORCODE => v_tempErrCd ,
                                            ERRORMESSAGE => v_tempErrMsg ,
                                            TARGET => v_target ,
                                            RESOLUTIONID => v_ResolutionId ,
                                            CASEID => v_CaseId ,
                                            WORKBASKETID => v_WorkbasketId );
    
    IF NVL(v_tempErrCd, 0) > 0 THEN
        v_message := f_UTIL_addToMessage( originalMsg => v_message,newMsg => 'ERROR: There was an error routing the Case');
        GOTO cleanup;
    ELSE
        v_message := f_UTIL_addToMessage( originalMsg => v_message,newMsg => 'INFO: Succesfully routed Case');
        v_tempSccss := 'Succesfully routed';
    END IF;
    
    
    --DETERMINE IF A CUSTOM PROCESSOR IS PRESENT
    v_message := f_UTIL_addToMessage( originalMsg => v_message,newMsg => 'INFO: Attempting to find a custom processor for data');
    BEGIN
        SELECT col_routecustomdataprocessor
        INTO   v_routecustomdataprocessor
        FROM   tbl_dict_casesystype
        WHERE  col_id IN
               (
                      SELECT col_casedict_casesystype
                      FROM   tbl_case
                      WHERE  COL_ID=v_CaseId
               );
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_message := f_UTIL_addToMessage( originalMsg => v_message, newMsg => 'WARNING: Missing Case Type for Case');
        v_routecustomdataprocessor := NULL;
    END;
    
    --EITHER INVOKE CUSTOM PROCESSOR OR WRITE THE CUSTOM DATA TO THE CASE EXTENSION
    IF v_CustomData IS NOT NULL and v_routecustomdataprocessor IS NOT NULL THEN
        v_message := f_UTIL_addToMessage( originalMsg => v_message, newMsg => 'INFO: Attempting to route use custom processor ' || v_routecustomdataprocessor);
		BEGIN
            v_result := f_dcm_invokeCaseCusDataProc ( CaseId => v_CaseId ,
                                                      Input => v_CustomData ,
                                                      ProcessorName => v_routecustomdataprocessor );
        EXCEPTION
        WHEN OTHERS THEN
            v_message := f_UTIL_addToMessage( originalMsg => v_message, newMsg => 'SQLCODE: ' || TO_CHAR(SQLCODE));
            v_message := f_UTIL_addToMessage( originalMsg => v_message, newMsg => 'SQLERRM: ');
            v_message := f_UTIL_addToMessage( originalMsg => v_message, newMsg => SQLERRM);
            v_tempErrMsg := 'ERROR: There was an error executing the custom processor. Notify your administrator.';
            v_tempErrCd := 103;
            GOTO cleanup;        
        END;
    ELSIF v_CustomData IS NOT NULL THEN
        --set custom data XML IF no special processor passed
        UPDATE tbl_caseext
        SET    col_customdata  = XMLTYPE(v_CustomData)
        WHERE  col_caseextcase = v_CaseId;
		v_tempErrMsg := 'INFO: Updated Case with new custom data'; 
        v_result := f_HIST_createHistoryFn(AdditionalInfo => v_message,
                                           IsSystem => 0,
                                           MESSAGE => NULL,
                                           MessageCode => 'CaseModified',
                                           TargetID => v_CaseId,
                                           TargetType => 'CASE');		
    END IF;
    
    --ADD NOTE TO CASE IF NEEDED
    IF v_RoutingDescription IS NOT NULL THEN
        INSERT INTO TBL_NOTE
               (COL_NOTENAME ,
               COL_NOTE ,
               COL_VERSION ,
               COL_CASENOTE
               )
               VALUES
               ('Routing note' ,
               v_RoutingDescription ,
               1 ,
               v_CaseId
               );
			   v_tempErrMsg := 'INFO: Added Note to Case';  
    
    END IF;
    
     /*--SUCCESS BLOCK*/
    :ERRORCODE := 0;
    :ERRORMESSAGE := '';
    :SUCCESSRESPONSE := v_tempSccss;
    :EXECUTIONLOG := v_message;
    RETURN;
    
     /*--ERROR BLOCK*/
    <<cleanup>> 
	v_message := f_UTIL_addToMessage(originalMsg => v_message,newMsg => 'ERROR CODE: ' || v_tempErrCd);
    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR MSG: ' || v_tempErrMsg);
    
	IF v_CaseId > 0 THEN
        v_result := f_HIST_createHistoryFn(AdditionalInfo => v_message,
                                           IsSystem => 0,
                                           MESSAGE => NULL,
                                           MessageCode => 'GenericEventFailure',
                                           TargetID => v_CaseId,
                                           TargetType => 'CASE');
    END IF;
    
    :ERRORCODE := v_tempErrCd;
    :ERRORMESSAGE := v_tempErrMsg;
    :EXECUTIONLOG := v_message;
    :SUCCESSRESPONSE := '';
	
	--ROLLBACK DATA AFTER FAILURE
	ROLLBACK;
EXCEPTION
WHEN OTHERS THEN
    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'SQL ERROR: ');
    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => dbms_utility.format_error_backtrace);
    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => dbms_Utility.format_error_stack);
    
    :ERRORCODE := 199;
    :ERRORMESSAGE := 'There was an error routing';
    :EXECUTIONLOG := v_message;
    :SUCCESSRESPONSE := '';
	
	--ROLLBACK DATA AFTER FAILURE
	ROLLBACK;
END;