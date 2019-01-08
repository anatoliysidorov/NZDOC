DECLARE 
    --INPUT-- 
    v_participantcode  NVARCHAR2(255); 
    v_inserttotask     INTEGER; 
	
    --INTERNAL  
    v_caseparty        INTEGER; 
    v_result           INTEGER; 
    v_position         NVARCHAR2(30); 
	
    --OUTPUT  
    v_message          NCLOB; 
    v_validationresult NUMBER; 
	
    --temp variables for returns  
    v_temperrmsg       NCLOB; 
    v_temperrcd        INTEGER; 
BEGIN 
    --INPUT-- 
    v_participantcode := Trim(F_form_getparambyname(:input, 'ParticipantCode')); 
    v_inserttotask := Nvl(F_form_getparambyname(:input, 'InsertToTask'), 0); 

	--OUTPUT-- 
    v_validationresult := 1; 
    v_message := '';
	
    --CALCULATED-- 
    v_caseparty := 0; 

    IF v_participantcode IS NOT NULL THEN 
      v_caseparty := F_ppl_getcasepartybycode(caseid => F_dcm_getcaseidbytaskid(:taskid), participantcode => v_participantcode); 
    END IF; 

	IF v_inserttotask = 1 THEN
		v_position := 'append';
	ELSE
		v_position := 'insert_after';
	END IF;


    --TRY TO INJECT A TASK 
    v_result := F_dcm_createadhoctaskccfn(
		sourceid => :taskid, 
		position => v_position, 
		tasksystypecode => F_form_getparambyname(:input, 'TaskTypeCode'), 
		name => F_form_getparambyname(:input, 'Name'), 
		description => F_form_getparambyname(:input, 'Description'), 
		casepartyid => v_caseparty, tasksystypeid => NULL, 
		caseid => NULL, 
		input => NULL, workbasketid => NULL, 
		errorcode => v_temperrcd, 
		errormessage => v_temperrmsg
	); 

    --DETERMINE IF ASSIGNMENT WAS SUCCESSFUL 
    IF v_result > 0 
       AND Nvl(v_temperrcd, 0) = 0 THEN 
      :validationresult := 1;
      :message := 'Success'; 
    ELSE 
      GOTO cleanup; 
    END IF; 

    RETURN 0; 

    --ERROR BLOCK 
    << cleanup >> 
    v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'WARNING: something went wrong'); 
    v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'ERROR CODE: ' || v_temperrcd); 
    v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'ERROR MESSAGE: ' || v_temperrmsg); 

    v_result := F_hist_createhistoryfn(
		additionalinfo => v_message, 
		issystem => 0, 
		message => NULL, 
		messagecode => 'GenericEventFailure', 
		targetid => taskid, 
		targettype => 'TASK'
	); 

    :validationresult := 0; 
    :message := v_temperrmsg;
    RETURN -1; 
END; 