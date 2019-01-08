DECLARE
    --INPUT
    v_TASKTYPECODE NVARCHAR2(255); --from tbl_DICT_TaskSysType
    v_PROCESSORCODE NVARCHAR2(255); --function name, such as 'f_CUST_Somefn''
    v_EVENTTYPECODE NVARCHAR2(255); --'VALIDATION' or 'ACTION'
	
    --INTERNAL
    v_tasktypeid INTEGER;
    v_eventMomentCode NVARCHAR2(255);
	v_recordid INTEGER;
    V_GENCODE  NVARCHAR2(255);
BEGIN
    --INPUT
    v_PROCESSORCODE := LOWER(TRIM(:PROCESSORCODE));
    v_TASKTYPECODE := LOWER(TRIM(:TASKTYPCODE));
    v_EVENTTYPECODE := LOWER(TRIM(:EVENTTYPECODE));
	
    --BASIC CHECK
    IF v_PROCESSORCODE IS NULL OR v_TASKTYPECODE IS NULL OR v_EVENTTYPECODE IS NULL THEN
        :ERRORCODE := 101;
        :ERRORMESSAGE := 'PROCESSORCODE and TASKTYPCODE and EVENTTYPECODE can not be empty';
		:SUCCESSRESPONSE := NULL;
        RETURN;
    END IF;
	
    --CALCULATE
    IF v_EVENTTYPECODE = 'validation' THEN
        v_eventMomentCode := 'before';
    ELSIF v_EVENTTYPECODE = 'action' THEN
        v_eventMomentCode := 'after';
    END IF;
    v_genCode := f_UTIL_calcUniqueCode(TableName => 'TBL_COMMONEVENTTMPL',
                                       BaseCode => v_TASKTYPECODE || '_' || v_EVENTTYPECODE);
									   
    --CREATE COMMON EVENT
    INSERT INTO TBL_COMMONEVENTTMPL(COL_CODE,
                  COL_EVENTORDER,
                  COL_NAME,
                  COL_PROCESSORCODE,
                  COL_COMEVENTTMPLCOMEVENTTYPE,
                  COL_COMEVTTMPLEVTMMNT,
                  COL_COMEVTTMPLTASKEVTT,
                  COL_COMMONEVENTTMPLTASKTYPE)
           VALUES(v_genCode,
                  0,
                  v_genCode,
                  v_PROCESSORCODE,
                  f_UTIL_getIdByCode(TableName => 'TBL_DICT_COMMONEVENTTYPE',Code => 'CREATE_ADHOC_TASK'),
                  f_UTIL_getIdByCode(TableName => 'tbl_dict_taskeventmoment',Code => v_eventMomentCode),
                  f_UTIL_getIdByCode(TableName => 'tbl_dict_taskeventtype',Code => v_EVENTTYPECODE),
                  f_UTIL_getIdByCode(TableName => 'tbl_dict_tasksystype',Code => v_TASKTYPECODE)
	  )RETURNING COL_ID INTO v_recordid ;
	  
	--RETURN STATUS
	:ERRORCODE := 0;
	:ERRORMESSAGE := NULL;
	:SUCCESSRESPONSE := 'Created common event with ID ' || TO_CHAR(v_recordid);
END;