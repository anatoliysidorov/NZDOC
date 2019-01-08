DECLARE
  --INPUT  
  v_priority_code NVARCHAR2(255);

  --INTERNAL  
  v_wb          INTEGER;
  v_result      INTEGER;
  v_priority_id INTEGER;
  v_caseid      INTEGER;

  --OUTPUT  
  v_message          NCLOB;
  v_validationresult NUMBER;

  --temp variables for returns  
  v_temperrmsg NCLOB;
  v_temperrcd  INTEGER;
  v_tempsccss  NCLOB;
BEGIN
  --CALCULATED--   
  v_caseid        := F_dcm_getcaseidbytaskid(:TaskId);
  v_priority_code := TRIM(Lower(F_form_getparambyname(:INPUT, 'priority')));
  v_priority_id   := F_util_getidbycode(code => v_priority_code, tablename => 'tbl_stp_priority');

  --OUTPUT-- 
  v_validationresult := 1;
  v_message          := '==EVN_setCasePriority==';

  --ADD BASIC INFORMATION 
  v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'INFO: param Priority Code - ' || Nvl(v_priority_code, ' ==none=='));

  --TRY TO ASSIGN USING PARTICIPANT CODE OR RULE   
  v_result := F_dcm_setcasepriorityfn(case_id => v_caseid, priority_id => v_priority_id, errorcode => v_temperrcd, errormessage => v_temperrmsg, successresponse => v_tempsccss);

  --DETERMINE IF ASSIGNMENT WAS SUCCESSFUL 
  IF v_result > 0 AND Nvl(v_temperrcd, 0) = 0 THEN
    :ValidationResult := 1;
    :Message          := 'Success';
  ELSE
    GOTO cleanup;
  END IF;

  RETURN 0;

  --ERROR BLOCK 
  <<cleanup>>
  v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'ERROR CODE: ' || v_temperrcd);
  v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'ERROR MESSAGE: ' || v_temperrmsg);
  v_result  := F_hist_createhistoryfn(additionalinfo => v_message, issystem => 0, message => NULL, messagecode => 'GenericEventFailure', targetid => v_caseid, targettype => 'CASE');

  :ValidationResult := 0;
  :Message          := v_temperrmsg;

  RETURN - 1;
END;
