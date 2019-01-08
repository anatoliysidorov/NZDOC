DECLARE
    v_ITEMS sys_refcursor;
    v_result INT;
BEGIN
    v_result := f_DCM_getObjectCountsFn(CaseId => :Case_ID,
                                        TaskId => :Task_ID,
                                        ExternalPartyId => :ExternalParty_Id,
                                        ITEMS => v_ITEMS) ;
    :ITEMS := v_ITEMS;
END;