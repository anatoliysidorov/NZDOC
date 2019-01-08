DECLARE
	--INPUT PARAMETERS
	v_INPUT             NCLOB; -- IN
	v_PROCESSORNAME     NVARCHAR2(255); --IN
	v_ERRORCODE         INT; -- OUT
	v_ERRORMESSAGE      NCLOB; -- OUT
	v_VALIDATIONRESULT  INT; -- OUT
  v_InData            CLOB;

	--INTERNAL VARIABLES
	v_SQLVARS     NVARCHAR2(1000);
	v_SQLSTR      NVARCHAR2(1000);	
	v_cur_hdl     INTEGER;
	v_paramName   NVARCHAR2(50);
	v_count       INT;
	v_ignore      INT;

	--TEMP OUTPUT VARIABLES
	v_temp_ErrorCode          INT;
	v_temp_ErrorMessage       NCLOB;
	v_temp_ValidationResult   INT;
	v_temp_Message            NCLOB;
	v_temp_NumberResult       INT;
	v_temp_TextResult         NCLOB;
  v_temp_OutData            CLOB;

BEGIN
	--BIND
	v_INPUT           := :INPUT;
	v_PROCESSORNAME   := UPPER(:PROCESSORNAME);
  v_InData          := :InData;

  v_temp_OutData    := NULL;
  
	--CHECK THAT THE PROCESSOR FUNCTION EXISTS
	SELECT COUNT(1)
	INTO v_count
	FROM user_objects
	WHERE object_type = 'FUNCTION'
		AND object_name = v_PROCESSORNAME;
		
	IF v_count = 0 THEN
		v_ErrorCode := 101;
		v_ErrorMessage := 'The function ' || v_PROCESSORNAME || ' is missing or not compiled.';
		GOTO cleanup;
	END IF;

	
	--GET THE FUNCTION VARIABLES
	SELECT listagg(argument_name,',:') within GROUP(ORDER BY position)
	INTO v_SQLVARS
	FROM user_arguments
        WHERE object_id =
            (
                SELECT object_id
                FROM user_objects
                WHERE object_type = 'FUNCTION'
                    AND object_name = v_PROCESSORNAME
            )
            AND NOT
            (
                argument_name IS NULL
                AND in_out = 'OUT'
                AND position = 0
            );
	v_SQLVARS := '(:' || v_SQLVARS || ');';
	
	--CREATE THE REST OF THE STATEMENT AND PARSE IT
	v_SQLSTR := 'BEGIN :' || 'DYN_RESULT := ' || v_PROCESSORNAME || v_SQLVARS || ' END;';
	v_cur_hdl := DBMS_SQL.OPEN_CURSOR;
	DBMS_SQL.PARSE(v_cur_hdl, v_SQLSTR, DBMS_SQL.NATIVE);
	
	--BIND THE DYNAMIC VARIABLES
	FOR rec IN
    (
        SELECT 
            argument_name,
            position,
            in_out,
			data_type
        FROM user_arguments
        WHERE object_id =
            (
                SELECT object_id
                FROM user_objects
                WHERE object_type = 'FUNCTION'
                    AND object_name = v_PROCESSORNAME
            )
        ORDER BY
            position
    )
    LOOP
        v_paramName := UPPER(rec.argument_name) ;
		
		IF rec.in_out = 'IN' THEN
			IF v_paramName = 'TASKID' THEN
				DBMS_SQL.BIND_VARIABLE (v_cur_hdl, ':' || v_paramName, f_form_getparambyname(v_Input,'TaskId'));
			ELSIF v_paramName = 'CASEID' THEN
				DBMS_SQL.BIND_VARIABLE (v_cur_hdl, ':' || v_paramName, f_form_getparambyname(v_Input,'CaseId'));
			ELSIF v_paramName = 'PROCEDUREID' THEN
				DBMS_SQL.BIND_VARIABLE (v_cur_hdl, ':' || v_paramName, f_form_getparambyname(v_Input,'ProcedureId'));
			ELSIF v_paramName = 'INPUT' THEN
				DBMS_SQL.BIND_VARIABLE (v_cur_hdl, ':' || v_paramName, v_Input);
			ELSIF v_paramName = 'INDATA' THEN
				DBMS_SQL.BIND_VARIABLE (v_cur_hdl, ':' || v_paramName, v_InData);        
			END IF;
		ELSE
			IF v_paramName IS NULL AND rec.data_type = 'NUMBER' THEN
				DBMS_SQL.BIND_VARIABLE (v_cur_hdl, ':' || 'DYN_RESULT', v_temp_NumberResult);
			ELSIF v_paramName IS NULL THEN
				DBMS_SQL.BIND_VARIABLE (v_cur_hdl, ':' || 'DYN_RESULT', v_temp_TextResult );
			ELSIF v_paramName = 'ERRORCODE' THEN
				DBMS_SQL.BIND_VARIABLE (v_cur_hdl, ':' || v_paramName, v_temp_ErrorCode);
			ELSIF v_paramName = 'ERRORMESSAGE' THEN
				DBMS_SQL.BIND_VARIABLE (v_cur_hdl, ':' || v_paramName, v_temp_ErrorMessage);
			ELSIF v_paramName = 'VALIDATIONRESULT' THEN
				DBMS_SQL.BIND_VARIABLE (v_cur_hdl, ':' || v_paramName, v_temp_ValidationResult);
			ELSIF v_paramName = 'MESSAGE' THEN
				DBMS_SQL.BIND_VARIABLE (v_cur_hdl, ':' || v_paramName, v_temp_Message);	
      ELSIF v_paramName = 'OUTDATA' THEN
        DBMS_SQL.BIND_VARIABLE (v_cur_hdl, ':' || v_paramName, v_temp_OutData);	                    
			END IF;
		
		END IF;
    END LOOP;
	
	--EXECUTE DYNAMIC SQL
	v_ignore := DBMS_SQL.EXECUTE(v_cur_hdl);
	
	 --GET OUTPUT PARAMETERS
    FOR rec IN
    (
        SELECT 
            argument_name,
            position,
            in_out,
			data_type
        FROM user_arguments
        WHERE object_id =
            (
                SELECT object_id
                FROM user_objects
                WHERE object_type = 'FUNCTION'
                    AND object_name = v_PROCESSORNAME
            ) AND in_out='OUT'
            
        ORDER BY position
    )
    LOOP
        v_paramName := UPPER(rec.argument_name) ;
        IF v_paramName IS NULL AND rec.data_type = 'NUMBER' THEN
            DBMS_SQL.VARIABLE_VALUE (v_cur_hdl, 'DYN_RESULT', v_temp_NumberResult);
        ELSIF v_paramName IS NULL THEN
            DBMS_SQL.VARIABLE_VALUE (v_cur_hdl, 'DYN_RESULT', v_temp_TextResult);
        ELSIF v_paramName = 'ERRORCODE' THEN
            DBMS_SQL.VARIABLE_VALUE (v_cur_hdl, v_paramName, v_temp_ErrorCode);
        ELSIF v_paramName = 'ERRORMESSAGE' THEN
            DBMS_SQL.VARIABLE_VALUE (v_cur_hdl, v_paramName, v_temp_ErrorMessage);
        ELSIF v_paramName = 'VALIDATIONRESULT' THEN
            DBMS_SQL.VARIABLE_VALUE (v_cur_hdl, v_paramName, v_temp_ValidationResult);                
        ELSIF v_paramName = 'MESSAGE' THEN
            DBMS_SQL.VARIABLE_VALUE (v_cur_hdl, v_paramName, v_temp_Message);
        ELSIF v_paramName = 'OUTDATA' THEN
            DBMS_SQL.VARIABLE_VALUE (v_cur_hdl, v_paramName, v_temp_OutData);	                    
        END IF;

    END LOOP;
	DBMS_SQL.CLOSE_CURSOR(v_cur_hdl);
	
	--EVALUATE THE RESULTS
	v_ERRORCODE := v_temp_ErrorCode;
	v_ERRORMESSAGE := v_temp_ErrorMessage;
	v_VALIDATIONRESULT := NVL(v_temp_ValidationResult, 1);
	
	IF (v_ERRORCODE > 0 OR v_VALIDATIONRESULT = 0) AND v_ERRORMESSAGE IS NULL THEN
		v_ERRORMESSAGE := NVL(v_temp_Message, 'There was an error executing ' || v_PROCESSORNAME);	
	END IF;
	IF v_VALIDATIONRESULT = 0 AND (v_ERRORCODE IS NULL OR v_ERRORCODE = 0 or v_ERRORCODE = 200) THEN
        v_ERRORCODE := 201;
    END IF;
	
	
	--RETURN SUCCESS
  :ErrorCode        := v_ERRORCODE;
  :ErrorMessage     := v_ERRORMESSAGE;
  :validationresult := v_validationresult;
  :OutData          := v_temp_OutData;
  RETURN 0;
	
  --ERROR HANDLING
  <<cleanup>> 
  :ErrorCode        := v_ErrorCode;
  :ErrorMessage     := v_ErrorMessage;
  :validationresult := v_validationresult;
  :OutData          := v_temp_OutData;
  RETURN -1;
	
	EXCEPTION
    WHEN OTHERS THEN
      :ErrorCode := 121;
      :ErrorMessage := 'There was an issue executing ' || v_PROCESSORNAME || '<br>' || SUBSTR(DBMS_UTILITY.format_error_backtrace, 1, 200);
      :validationresult := 0;
      :OutData          := v_temp_OutData;
      RETURN -1;
    END;
    