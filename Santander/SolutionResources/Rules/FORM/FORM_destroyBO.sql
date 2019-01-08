DECLARE
  v_Id               NUMBER;
  v_ErrorCode     NUMBER;
  v_ErrorMessage  NVARCHAR2(255);
  v_customAttr	  NUMBER;
   
BEGIN
  v_ErrorCode := 0;
  v_ErrorMessage := '';
  :affectedRows := 0;
  v_Id := :Id;

    IF v_Id IS NULL THEN
    v_ErrorMessage := 'Id can not be empty';
    v_ErrorCode := 101;
    GOTO cleanup;
    END IF;


	SELECT COUNT(COL_ID) INTO v_customAttr	  
	FROM TBL_CUSTOMATTRIBUTE 
	WHERE COL_CUSTOMATTRBUSOBJECT = v_Id;

	IF(v_customAttr > 0)
		THEN
		v_ErrorMessage := 'There exists a Custom Attribute that attached to this Business Object';		
		v_ErrorCode := 102;
		GOTO cleanup;
	ELSE 
    	DELETE TBL_DICT_BUSINESSOBJECT tdb
    	WHERE col_id = v_Id;
	END IF;
 
    --get affected rows
    :affectedRows := SQL%ROWCOUNT; 
     
    <<cleanup>>
    :ErrorMessage := v_ErrorMessage;
    :ErrorCode := v_ErrorCode;
    
END;