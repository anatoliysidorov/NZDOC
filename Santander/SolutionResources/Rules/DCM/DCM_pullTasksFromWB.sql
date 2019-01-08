DECLARE 
    v_caseworkerid    INTEGER; 
    v_errorcode       NUMBER; 
    v_errormessage    NVARCHAR2(155); 
    v_numberofrecords NUMBER; 
    v_workbasketid    INTEGER; 
    v_result          NUMBER; 
BEGIN 
    v_workbasketid := :WorkbasketId; 
    v_caseworkerid := Nvl(:CaseworkerId, F_util_getcwfromacode( Sys_context('CLIENTCONTEXT', 'AccessSubject'))); 
    v_numberofrecords := :NumberOfRecords; 
    v_result := F_dcm_pullTasksFromWBfn(
		caseworkerid => v_caseworkerid, 
		errorcode => v_errorcode, 
		errormessage => v_errormessage , 
		numberofrecords => v_numberofrecords, 
		workbasketid => v_workbasketid
	); 
END; 