DECLARE
	--input
	v_DataKey NVARCHAR2(255); 
	v_accesssubject NVARCHAR2(50); 
	
	--calculated
	v_temp INTEGER;
	v_result NVARCHAR2(255); 
BEGIN 
	--input
	v_DataKey := lower(:DataKey);
	v_accesssubject := UPPER(NVL(:targetAccSub, sys_context('CLIENTCONTEXT', 'AccessSubject')));
	
	--calculate values
	IF v_DataKey = 'username' THEN
		SELECT login 
		INTO v_result
		FROM vw_users
		WHERE ACCESSSUBJECTCODE = v_accesssubject;		
		
	ELSIF v_DataKey = 'name' OR v_DataKey = 'userfullname' THEN
		SELECT name 
		INTO v_result
		FROM vw_users
		WHERE ACCESSSUBJECTCODE = v_accesssubject;	
		
	ELSIF v_DataKey = 'phone' THEN
		SELECT phone 
		INTO v_result
		FROM vw_users
		WHERE ACCESSSUBJECTCODE = v_accesssubject;		
		
	ELSIF v_DataKey = 'email' THEN
		SELECT email 
		INTO v_result
		FROM vw_users
		WHERE ACCESSSUBJECTCODE = v_accesssubject;				
	ELSE
		v_result := '==MISSING DATA KEY==';	
	END IF;
	
	:ResultText := v_result;
	
EXCEPTION  
	WHEN OTHERS THEN 
		:ResultText := 'SYSTEM ERROR'  || v_accesssubject; 
END;