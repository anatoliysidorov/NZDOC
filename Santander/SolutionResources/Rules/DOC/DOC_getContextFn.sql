DECLARE
	--INPUT
	v_DocumentId INT;
	
	--INTERNAL
	v_TargetType NVARCHAR2(30);
	v_TargetID INT;
	
BEGIN
	--BIND
	v_DocumentId := :DocumentId;
	v_TargetID := NULL;
	v_TargetType := NULL;

	--ATTEMPT TO FIND DOCUMENT IN CASE or TASK
	IF v_TargetID IS NULL THEN
		BEGIN
		  SELECT COL_DOCCASECASE 
		  INTO v_TargetID
		  FROM TBL_DOC_DOCCASE
		  WHERE COL_DOCCASEDOCUMENT = DocumentId;	  
		  v_TargetType := 'CASE';	  
		EXCEPTION
		  WHEN NO_DATA_FOUND THEN
			NULL;
		END;
	END IF;
	
	IF v_TargetID IS NULL THEN
		BEGIN
		  SELECT COL_DOCTASKTASK
		  INTO v_TargetID
		  FROM TBL_DOC_DOCTASK
		  WHERE COL_DOCTASKDOCUMENT = DocumentId;	  
		  v_TargetType := 'TASK';	  
		EXCEPTION
		  WHEN NO_DATA_FOUND THEN
			NULL;
		END;
	END IF;
	
	IF v_TargetID IS NULL THEN
		--TODO
		v_TargetID := NULL;
		v_TargetType := 'UNKNOWN';	
	END IF;

	:TargetType := v_TargetType;
	:TargetID := v_TargetID;
END;