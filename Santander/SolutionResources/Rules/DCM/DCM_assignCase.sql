DECLARE 
    v_action          NVARCHAR2(255); 
    v_caseid          NUMBER; 
    v_workbasketid    NUMBER; 
    v_casepartyid     NUMBER; 
    v_workbasketname  NVARCHAR2(255); 
    v_note            NVARCHAR2(2000); 
    v_result          NUMBER; 
	
    --standard   
    v_errorcode       NUMBER; 
    v_errormessage    NCLOB; 
    v_successresponse NCLOB; 
BEGIN 
    v_action := :Action; 
    v_caseid := :Case_Id; 
    v_workbasketid := :WorkBasket_Id; 
    v_casepartyid := :CaseParty_Id; 
    v_note := :Note; 

    --standard   
    v_errorcode := 0; 
    v_errormessage := ''; 
    v_result := F_dcm_assigncasefn(
					action => v_action, 
					case_id => v_caseid, 
					caseparty_id => v_casepartyid, 
					errorcode => v_errorcode, 
					errormessage => v_errormessage, 
					note => v_note, 
					successresponse => v_successresponse, 
					workbasket_id => v_workbasketid
				); 

    IF v_errorcode > 0 THEN 
      :errorCode := v_errorcode; 
      :errorMessage := v_errormessage; 
    END IF; 

    :SuccessResponse := v_successresponse; 
EXCEPTION 
    WHEN OTHERS THEN 
      :errorCode := 101; 
      :errorMessage := SQLERRM; 
      :SuccessResponse := ''; 
END; 