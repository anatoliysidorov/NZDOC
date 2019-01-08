DECLARE
    v_MilestoneCode nvarchar2(255);
    v_caseId number;
BEGIN
    v_CaseID := :CASE_ID;
     
    -- select milestone code
    select
     ms.col_commonCode into v_MilestoneCode
    from tbl_case cs
      inner join tbl_dict_state ms on ms.col_id = cs.col_casedict_state
    where cs.col_id = v_caseId ;
 
     IF v_MilestoneCode = 'RESOLVED' THEN
        RETURN 0; --ELEMENT SHOULD BE HIDDEN
    ELSE
        RETURN 1; --ELEMENT SHOULD BE VISIBLE
    END IF;
END;