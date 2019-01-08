DECLARE
	--input
	v_StateSLAActionId INTEGER;
	v_StateSLAEventId INTEGER;
	v_DataKey NVARCHAR2(255); 
	
	--calculated
	v_temp INTEGER;
	v_result NVARCHAR2(255); 
BEGIN 
	--input
	v_StateSLAActionId := :StateSLAActionId;
	v_StateSLAEventId := :StateSLAEventId;
	
	IF NVL(v_StateSLAEventId, 0) = 0 AND v_StateSLAActionId > 0 THEN
		SELECT COL_STATESLAACTNSTATESLAEVNT
		INTO v_StateSLAEventId
		FROM TBL_DICT_STATESLAACTION
		WHERE COL_ID = v_StateSLAActionId;		
	END IF;
	v_DataKey := lower(:DataKey);
	
	--calculate values
	IF v_DataKey = 'slatype' THEN
		v_temp := f_DCM_genMsSlaTypeMsgPh(StateSLAEventId=> v_StateSLAEventId, PlaceholderResult => v_result);
		
	ELSIF v_DataKey = 'sladuration' THEN
		v_temp := f_DCM_genMsSlaDurationMsgPh(StateSLAEventId=> v_StateSLAEventId, PlaceholderResult => v_result);
		
	ELSE
		v_result := '==MISSING DATA KEY==';	
	END IF;
	
	:ResultText := v_result; 
	
EXCEPTION  
	WHEN OTHERS THEN 
		:ResultText := 'SYSTEM ERROR'; 
END;