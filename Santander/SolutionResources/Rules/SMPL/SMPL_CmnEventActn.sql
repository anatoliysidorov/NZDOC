
--Sample of Action Rule for Common Event
--Rule Type - SQL Non Query
--Deploy as Function - No

--Input:
--  Input, IN nclob  (collection of passed parameters in XML format)
--Output: (none)

DECLARE
    --INPUT
    v_input NCLOB;
	
    --INTERNAL
    v_ignore INT;
    v_messageText NVARCHAR2(400);
    v_CommonEventID INT;
    v_CommonEventType NVARCHAR2(100);
    v_CommonEventExType NVARCHAR2(100);
    v_CommonEventMoment NVARCHAR2(100);
    v_EventType NVARCHAR2(100);
BEGIN
    --Input--
    v_input := :INPUT;
	
    --WRITE THE ENTIRE XML INTO A TABLE (4.4.4.1)
	v_ignore := f_UTIL_createSysLogFn(v_input);

    -- WRITE THE ENTIRE XML INTO A TABLE (4.4.5 - uncomment if needed)
    v_CommonEventID := TO_NUMBER(f_UTIL_extractXmlAsTextFn(INPUT=> v_input, PATH=>'/CustomData/Attributes/CommonEventId/text()')); 
    SELECT ce.col_code, tem.col_code, cet.col_code,tet.col_code
    INTO v_CommonEventExType, v_CommonEventMoment, v_CommonEventType, v_EventType
    FROM TBL_COMMONEVENT ce
    LEFT JOIN TBL_DICT_TASKEVENTMOMENT tem ON tem.col_id = ce.COL_COMMONEVENTEVENTMOMENT
    LEFT JOIN TBL_DICT_COMMONEVENTTYPE cet ON cet.col_id = ce.COL_COMEVENTCOMEVENTTYPE
    LEFT JOIN TBL_DICT_TASKEVENTTYPE tet ON tet.col_id = ce.COL_COMMONEVENTTASKEVENTTYPE
    WHERE ce.col_id = v_CommonEventID;    
	v_ignore := f_UTIL_createLogFn(MESSAGE=>'<b>Event for</b> ' || v_EventType || ' &rarr; ' ||v_CommonEventMoment || ' &rarr; ' || v_CommonEventType || ' &rarr; ' || v_CommonEventExType, ADDITIONALINFO =>'{[this.YELLOW_TABLE(''Input XML into this rule'', ''' || XMLTYPE(v_input).getClobVal() || ''', ''xml'')]}');

END;