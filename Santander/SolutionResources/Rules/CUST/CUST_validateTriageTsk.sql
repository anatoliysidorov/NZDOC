 /*
Example of validating before creating an Ad-hoc Task
Rule Type: SQL Non Query
Deploy Type: Procedure/Function
 
Input Parameters:
 ** INPUT, text area (XML of all context information about the event)
 
Output Parameters:
 ** ValidationResult, integer (0 = throw error on screen, 1 = don't throw error on screen)
 ** ErrorCode, integer (greater than 0 if there is a validation issue)
 ** ErrorMessage, text area (error message to display to user)
 
*/
 
DECLARE
    --INPUT
    v_INPUT NCLOB;
    --INTERNAL
    v_SourceTaskId INT;
    v_TaskCode NVARCHAR2(255);
    v_CaseId INT;
    v_TaskId INT;
    v_TaskTypeId INT;
    v_cnt number;
    v_message nclob;
    v_validationresult number;
    v_errorcode number;
BEGIN
    --BIND
    v_INPUT := :INPUT;
     
     --PARSE INPUT
    SELECT extractvalue(xmltype(v_input),'CustomData/Attributes/TaskId')
    INTO   v_TaskId
    FROM   dual;
    
    v_message           := 'Task cannot be closed until ';
    v_validationresult  := 1;

    BEGIN
        SELECT instr(f_UTIL_extractXmlAsTextFn(INPUT=> to_clob(col_customdata), PATH=>'/CustomData/Attributes/Form[@name="TRIAGE__CLONE__CLONE"]/*/text()'), 'false')
        INTO v_cnt
        FROM  tbl_task
        WHERE col_id = V_TASKID;

        if (NVL(v_cnt,1) > 0) then
            v_message := SUBSTR(v_message, 0, length(v_message)-1);
            DBMS_LOB.append (v_message , ' field(s) on task form has not been checked. ');
            v_validationresult := 0;
            v_errorcode := 101;
        end if;

        if v_validationresult = 1 then 
                v_message := '';
                v_errorcode := -1;
        end if;
        
    EXCEPTION WHEN OTHERS THEN
        v_validationresult := SQLCODE;
        v_message := SUBSTR('ERROR ON VALIDATION: ' || dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, 1, 200);
        v_errorcode := SQLCODE;
    END;
    
    :ValidationResult := v_validationresult;
    :Errormessage := v_message;
    :ErrorCode := v_errorcode;

/*            
    insert into tbl_log(col_bigdata1, col_data1, col_data10, col_data11, col_data12) 
    values(V_INPUT, 'V_TASKID -> '||V_TASKID, 'v_cnt -> '|| NVL(v_cnt, 1), 'ValidationResult -> '||ValidationResult, 'Errormessage -> ' || Errormessage);
*/
    
END; 