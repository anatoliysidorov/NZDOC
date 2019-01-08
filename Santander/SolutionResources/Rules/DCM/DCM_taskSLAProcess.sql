--DCM-5496
DECLARE
    v_result   NUMBER;
BEGIN 
    v_result := f_DCM_regSlaActionGlobal();    
    v_result := f_util_createsyslogfn(message => 'FOR TASKS: SLA Event Triggered');
END;