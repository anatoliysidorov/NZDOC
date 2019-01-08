DECLARE
    --INPUT
    v_ParentTaskID INT;
    v_CaseID INT; --optional, used if ParentTaskID is null
    v_WorkBasketID INT; --owner
    v_Name NVARCHAR2(255);
    v_Description NCLOB;
    v_CustomData NCLOB;
	
	v_TargetType NVARCHAR2(50); --TASKTYPE or PROCEDURE
	v_TargetID INT; --COL_ID or TASKTYPE OR PROCEDURE
	v_TargetCode NVARCHAR2(255); --COL_CODE used if v_TargetID IS EMPTY
	
    --INTERNAL
    v_temperrmsg NCLOB;
    v_temperrcd INTEGER;
    v_tempresponce NCLOB;
	v_result INT;

	v_createdID INT;

BEGIN
	--BIND
	v_TargetType := UPPER(TRIM(:TargetType));
	v_TargetID := NVL(:TargetID, 0);
	v_TargetCode := TRIM(:TargetCode);
	v_CaseID := :CaseID;
    v_WorkBasketID := :WorkBasketID;
    v_TaskName := :TaskName;
    v_Description := :Description;
    v_CustomData := CustomData;
	
	--ERROR HANDLING
	IF (v_TargetID = 0 AND v_TargetCode IS NULL)OR v_TargetType IS NULL THEN
		v_temperrcd := 101;
        v_temperrmsg := 'Both the Target Type and the Target ID have to be non-empty';
		GOTO cleanup; 
	END IF;
	
	--ADDA TASK OR A PROCEDURE
	IF v_TargetType = 'TASKTYPE' THEN
		v_createdID := f_DCM_injectAdhocTaskFn(
			--input
			CaseID => v_CaseID,
			CustomData => v_CustomData,
			Description => v_Description,
			ParentTaskID => v_ParentTaskID,
			TaskName => v_Name,
			TaskTypeID => v_TargetID,
			TaskTypeCode => v_TargetCode,
			WorkbasketId => v_WorkBasketID,
			--output
			TaskID => v_createdID,
			ErrorCode => v_temperrcd,
			ErrorMessage => v_temperrmsg			
		);
	ELSIF v_TargetType = 'PROCEDURE' THEN
		NULL;
	ELSE
		v_temperrcd := 101;
        v_temperrmsg := 'The Target Type needs to be either TASKTYPE or PROCEDURE';
		GOTO cleanup; 
	END IF;	
	
	IF v_temperrcd > 0 THEN
		GOTO cleanup; 
	END IF;

	--RETURN DATA
	:ErrorCode := 0;
	:ErrorMessage := NULL;
	
    <<cleanup>> 
	:ErrorCode := v_temperrcd;
    :ErrorMessage := v_temperrmsg;
	
EXCEPTION WHEN OTHERS THEN
	:ErrorCode := 201;
    :ErrorMessage := DBMS_UTILITY.FORMAT_ERROR_STACK;
end;