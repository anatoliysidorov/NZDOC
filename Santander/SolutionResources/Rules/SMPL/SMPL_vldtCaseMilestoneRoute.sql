/*
Sample of Validation Rule for determining whether the Case Milestone routing validation is allowed.

Rule Type - SQL Non Query
Deploy as Function - Yes
Input:
  - CaseId, Integer (Case.Id)
  - TargetMilestone, Integer (DICT_State.Id)
  - TargetOwner, Integer (PPL_Workbasket.Id)
  - TargetResCode, Integer (STP_ResolutionCode.Id)
  - TransitionTaken, Integer (STP_Transition.Id)

Output  
  - ValidationResult, Integer (0 = don't allow, 1 = allow)
  - ValidatonMessage, Text Area
*/

DECLARE
  v_caseId            NUMBER;
  v_targetMilestoneId NUMBER;
  v_targetOwnerId     NUMBER;
  v_targetResCodeId   NUMBER;
  v_transitionTakenId NUMBER;
  v_validationResult  NUMBER;
  v_validatonMessage  NCLOB;
  v_day               NUMBER;
BEGIN

  v_caseId            := :CaseId;
  /*
  v_targetMilestoneId := TargetMilestone;
  v_targetOwnerId     := TargetOwner;
  v_targetResCodeId   := TargetResCode;
  v_transitionTakenId := TransitionTaken;
*/

  v_validationResult := 0;
  v_validatonMessage := '';

  BEGIN
  
    -- sample of validation
    SELECT TO_CHAR(TRUNC (SYSDATE, 'IW'), 'D') INTO v_day FROM DUAL;
    IF v_day = 1 THEN
      --  if today's day is Monday
      v_validationResult := 1;
      v_validatonMessage := 'You can route a Case on Monday';
    ELSE
      --  if today's day is any other day
      v_validationResult := 0;
      v_validatonMessage := 'You can ONLY route a Case on Mondays';
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      v_validationResult := SQLCODE;
      v_validatonMessage := SUBSTR('Error on validation: ' || SQLERRM, 1, 200);
  END;

  :ValidationResult := v_validationResult;
  :Message          := v_validatonMessage;

  RETURN 0;
END;