DECLARE

    V_FULLERRORMESSAGE NVARCHAR2(2000) := '';
    V_ERRORMESSAGE NVARCHAR2(255) := '';
    V_ERRORCODE NUMBER := 0;

    V_CASE_ID NUMBER;
    V_POTENTIAL_PARENT NUMBER;
    V_POTENTAL_CHILD NUMBER;

BEGIN
    V_CASE_ID          := :CASE_ID;
    V_POTENTIAL_PARENT := :POTENTIAL_PARENT;
    V_POTENTAL_CHILD   := :POTENTAL_CHILD;

    IF NVL(V_CASE_ID, 0) = 0 THEN
        V_ERRORMESSAGE := 'Case id can not pe empty for this operation';
        V_ERRORCODE := 101;
        GOTO CLEANUP;
    END IF;

    FOR CYCLED_RECORS IN ( 
                            SELECT 
                                PATH_STRING 
                            FROM(
                                    SELECT 
                                        CONNECT_BY_ISCYCLE AS ISCYCLE,
                                        LEVEL AS TREE_LEVEL,
                                        SYS_CONNECT_BY_PATH('(P) '|| cParent.col_caseid || ' -> (C) ' || cChild.col_caseid, '<br> ') AS PATH_STRING,
                                        'DOWN' AS SEARCH_DIRECTION
                                    FROM (
                                        SELECT
                                            COL_CASELINKPARENTCASE AS PARENT_CASE,
                                            COL_CASELINKCHILDCASE AS CHILD_CASE
                                        FROM TBL_CASELINK
                                        
                                        UNION ALL
                                        
                                        SELECT
                                            V_POTENTIAL_PARENT AS PARENT_CASE,
                                            V_POTENTAL_CHILD AS CHILD_CASE
                                        FROM DUAL
                                        
                                        ) subQ
												inner join tbl_case cParent on cParent.col_id = subQ.PARENT_CASE
												inner join tbl_case cChild on cChild.col_id = subQ.CHILD_CASE
                                    START WITH subQ.PARENT_CASE = V_CASE_ID
                                    CONNECT BY NOCYCLE PRIOR CHILD_CASE = subQ.PARENT_CASE
                                ) 
                            WHERE ISCYCLE = 1
                        )
    LOOP

        V_ERRORCODE :=111;
        V_ERRORMESSAGE := 'Detected cycle';

        IF(V_FULLERRORMESSAGE IS NULL OR V_FULLERRORMESSAGE = '') THEN
            V_FULLERRORMESSAGE := 'Cycle path(s) : '||CYCLED_RECORS.PATH_STRING;
        ELSE
            V_FULLERRORMESSAGE := V_FULLERRORMESSAGE||'<br>'||CYCLED_RECORS.PATH_STRING;
        END IF;
    
    END LOOP;

   <<CLEANUP>>
    /*DBMS_OUTPUT.PUT_LINE('ErrorCode : '||V_ERRORCODE);
    DBMS_OUTPUT.PUT_LINE('ErrorMessage : '||V_ERRORMESSAGE);
    DBMS_OUTPUT.PUT_LINE('FullErrorMessage : '||V_FULLERRORMESSAGE);*/
    
    :ERRORCODE := V_ERRORCODE;
    :ERRORMESSAGE := V_ERRORMESSAGE;
    :FULLERRORMESSAGE := V_FULLERRORMESSAGE;

END;