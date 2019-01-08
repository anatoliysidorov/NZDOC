DECLARE
	--input
	v_SLAActionId INTEGER;
	v_SLAEventId INTEGER;
	v_DataKey NVARCHAR2(255); 
	
	--calculated
	v_temp INTEGER;
	v_result NVARCHAR2(255); 
BEGIN 
	--input
	v_SLAActionId := :SLAActionId;
	v_SLAEventId := :SLAEventId;
	
	IF NVL(v_SLAEventId, 0) = 0 AND v_SLAActionId > 0 THEN
		SELECT COL_SLAACTIONSLAEVENT
		INTO v_SLAEventId
		FROM TBL_SLAACTION
		WHERE COL_ID = v_SLAActionId;		
	END IF;
	v_DataKey := lower(:DataKey);
	
	--calculate values
	IF v_DataKey = 'slatype' THEN
		v_temp := f_DCM_genSlaTypeMsgPh(SLAEventId=> v_SLAEventId, PlaceholderResult => v_result);
		
	ELSIF v_DataKey = 'sladuration' THEN
		v_temp := f_DCM_genSlaDurationMsgPh(SLAEventId=> v_SLAEventId, PlaceholderResult => v_result);
		
	ELSIF v_DataKey = 'sladateevent' THEN
		v_temp := f_ DCM_genSlaDateEventMsgPh(SLAEventId=> v_SLAEventId, PlaceholderResult => v_result);
		
	ELSE
		v_result := '==MISSING DATA KEY==';	
	END IF;
	
	:ResultText := v_result; 
	
EXCEPTION  
	WHEN OTHERS THEN 
		:ResultText := 'SYSTEM ERROR'; 
END;