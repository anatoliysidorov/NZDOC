DECLARE 	
    --INTERNAL  
    v_result           INTEGER; 

BEGIN 
    v_result := F_hist_createhistoryfn(
		additionalinfo => 'Genesys PureConnect integration is not available. Please speak to your administrator.', 
		issystem => 0, message => NULL, 
		messagecode => 'GenericEventOff', 
		targetid => :taskid, 
		targettype => 'TASK'
	); 
    
	:ValidationResult := 1; 
    :Message := 'Beta functionality disabled'; 

    RETURN -1; 
END; 