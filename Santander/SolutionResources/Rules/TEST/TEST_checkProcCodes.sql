DECLARE
    
    v_result    NUMBER;
    v_errorCode NUMBER;
    v_errorMessage NCLOB;
    
    v_statement      VARCHAR2(2000) ;
    v_table_name     VARCHAR2(255) ;
    v_column         VARCHAR2(255) ;
    v_processor_code VARCHAR2(255) ;
    v_status         VARCHAR2(255) ;
    v_type           VARCHAR2(255) ;
    
    cur SYS_REFCURSOR;
BEGIN
    
    v_errorCode := 0;
    v_errorMessage := '';
    
    
    :ErrorCode := v_errorCode;
    :ErrorMessage := v_errorMessage;
    
    
    FOR REC IN
    (
        SELECT DISTINCT(table_name) TableName,
            column_name ProcessorColumn
        FROM all_tab_columns
        WHERE UPPER(table_name) LIKE 'TBL_%'
            AND UPPER(column_name) LIKE '%PROCESSORCODE%'
            AND owner = UPPER(
                               (
                                   SELECT VALUE
                                   FROM CONFIG
                                   WHERE NAME = 'ENV_SCHEMA'
                              )
                              )
        ORDER BY
            1
    )
    LOOP
        v_table_name := rec.TableName;
        v_column := rec.ProcessorColumn;
        
        v_statement := 'SELECT distinct(t.'|| v_column|| '), uo.object_type, uo.status  FROM ' || v_table_name || ' t ' || ' left join vw_util_deployedrule dr on lower(dr.localcode) = lower(replace(replace(t.'||v_column ||', ''f_''),''root_''))' || ' left join USER_OBJECTS uo on replace(uo.object_name,''F_'',''ROOT_'') = upper(dr.code)' || ' WHERE t.'||v_column||' IS NOT NULL and dr.code IS NULL';
        --DBMS_OUTPUT.PUT_LINE(v_statement) ;
        OPEN cur FOR v_statement;
        LOOP
            FETCH cur
            INTO v_processor_code,
                v_type,
                v_status;
            
            EXIT WHEN cur%NOTFOUND;
            --DBMS_OUTPUT.PUT_LINE('Table: '||v_table_name||' has undeployed rule: '||v_processor_code) ;
            v_errorCode := 128;
            IF v_type = 'FUNCTION'
                AND
                v_status = 'INVALID' THEN
                v_errorMessage := v_errorMessage || '<li>Table: '||v_table_name||' has invalid function: '||v_processor_code||'</li>';
            ELSE
                v_errorMessage := v_errorMessage || '<li>Table: '||v_table_name||' has undeployed rule: '||v_processor_code||'</li>';
            END IF;
        END LOOP;
        CLOSE cur;
    END LOOP;
    
    :ErrorCode := v_errorCode;
    :ErrorMessage := v_errorMessage;
END;