/*
Rule Name: PPL_getAllInvovledInCase
Type: SQL Non Query - not deployed as function
Inputs
 - CaseId, INTEGER
 - TaskId, INTEGER (one or the other is required)
Outputs
 - CaseOwnerCalcName, Text (name of user, team, skill, ...)
 - CaseOwnerCalcType, Text (Case Worker, Team, Skill, ...)
 - CaseOwnerWB, INTEGER (the ID of the Work Basket to which this Case is assigned)
 - CUR_CaseParty, Cursor (the list of all people involved in the Case but not necessary owners)
 - CUR_OtherInvolved, Cursor (searhc through Case history to see if there are other involved people)
*/

DECLARE
    --input
    v_CaseId INT;
    --internal
    v_CaseOwnerWB INT;
    v_CaseOwnerCalcType NVARCHAR2(50);
    v_CaseOwnerCalcName NVARCHAR2(255);
    v_CaseOwnerACCode NVARCHAR2(50);
    --standard
    v_errorCode INT;
    v_errorMessage NCLOB;
BEGIN
    --input
    v_CaseId := NVL(:CaseId, f_DCM_getCaseIdByTaskId(:TaskId));
	
    --get case owner
    BEGIN
        SELECT     wb.ID ,
                   wb.CALCTYPECODE ,
                   wb.CALCNAME ,
                   wb.ACCESSSUBJECTCODE
        INTO       v_CaseOwnerWB ,
                   v_CaseOwnerCalcType ,
                   v_CaseOwnerCalcName ,
                   v_CaseOwnerACCode
        FROM       tbl_case cse
        INNER JOIN vw_PPL_SimpleWorkBasket wb ON cse.COL_CASEPPL_WORKBASKET = wb.id
        WHERE      cse.col_id = v_caseid ;
    
    EXCEPTION
    WHEN no_data_found THEN
        NULL;
    END;
    :CaseOwnerWB := v_CaseOwnerWB;
    :CaseOwnerCalcType := v_CaseOwnerCalcType;
    :CaseOwnerCalcName :=v_CaseOwnerCalcName;
    :CaseOwnerACCode := v_CaseOwnerACCode;
	
    --get case party
    OPEN :CUR_CASEPARTY FOR
    SELECT    cp.CALC_NAME AS NAME ,
              cp.PartyType_Name AS PARTYTYPE ,
              cp.name AS PURPOSENAME ,
              cwu.ACCODE AS ACCODE
    FROM      vw_PPL_CaseParty cp
    LEFT JOIN VW_PPL_CASEWORKERSUSERS cwu ON cwu.id = cp.CASEWORKER_ID
    WHERE     CASE_ID = v_CaseId ;
    
    --gather other potentially involved users
    OPEN :CUR_OTHERINVOLVED FOR
    SELECT DISTINCT (COL_CREATEDBY)
    FROM   tbl_HISTORY
    WHERE  COL_HISTORYCASE = v_CaseId
    
    UNION
    
    SELECT DISTINCT (COL_CREATEDBY)
    FROM   tbl_NOTE
    WHERE  COL_CASENOTE = v_CaseId ;

END;