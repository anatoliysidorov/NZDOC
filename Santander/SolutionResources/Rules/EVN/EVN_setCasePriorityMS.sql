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
  --Input--   
  v_caseid := :CaseId;

  --CALCULATED-- 
  v_priority_code := TRIM(Lower(F_form_getparambyname(:INPUT, 'PRIORITY_CODE')));
  v_priority_id   := F_util_getidbycode(code => v_priority_code, tablename => 'tbl_stp_priority');

  IF v_priority_id IS NULL THEN
    v_message := 'EVN_setCasePriorityMS: Priority Id cannot be NULL or empty';
    GOTO cleanup;
  END IF;

  IF v_caseid IS NULL THEN
    v_message := 'EVN_setCasePriorityMS: Case Id cannot be NULL or empty';
    GOTO cleanup;
  END IF;

  IF v_priority_code IS NULL THEN
    v_message := 'EVN_setCasePriorityMS: Priority Code cannot be NULL or empty';
    GOTO cleanup;
  END IF;

  --OUTPUT-- 
  v_validationresult := 1;
  v_message          := '==EVN_setCasePriorityMS==';

  --ADD BASIC INFORMATION 
  v_message := F_util_addtomessage(originalmsg => v_message, newmsg => 'INFO: param Priority Code - ' || Nvl(v_priority_code, ' ==none=='));

  --TRY TO ASSIGN USING PARTICIPANT CODE OR RULE   
  v_result := f_DCM_setCasePriorityFn(CASE_ID => v_caseid, PRIORITY_ID => v_priority_id, ERRORCODE => v_temperrcd, ERRORMESSAGE => v_temperrmsg, SUCCESSRESPONSE => v_tempsccss);

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
  :Message          := v_message;

  RETURN - 1;
END;
