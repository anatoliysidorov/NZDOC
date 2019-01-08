DECLARE 

    V_RESULT VARCHAR2(255);
    
    V_CASE_ID        INTEGER;
    V_TARGET         VARCHAR2(255);
    
    V_FIND_INTO      VARCHAR2(255);
    V_SCENARIO       VARCHAR2(255);
    V_LINK_TYPE_CODE VARCHAR2(255);
    V_IS_TRY_TO_CLOSE INTEGER;
    
    V_ERRORCODE      INTEGER;
    V_ERRORMESSAGE   VARCHAR2(255);
    V_RELATEDCASEIDS VARCHAR2(255);
    V_MESSAGEBUFFER  VARCHAR2(255);

BEGIN

    V_CASE_ID      := :CASE_ID;
    V_TARGET       := UPPER(:TARGET);
    V_ERRORCODE    := 0;
    V_ERRORMESSAGE :='';
    V_MESSAGEBUFFER:= '';
    
    SELECT NVL(COL_ISFINISH,0) INTO V_IS_TRY_TO_CLOSE FROM TBL_DICT_CASESTATE WHERE UPPER(COL_ACTIVITY) = V_TARGET;

    IF V_IS_TRY_TO_CLOSE = 1 THEN
        V_SCENARIO := 'CLOSING';
    else
        V_SCENARIO := 'ROUTING';
    end if;    
    
                              
    IF UPPER(V_SCENARIO) = 'CLOSING' THEN

        V_RESULT := F_FINDCASELINKS(CASE_ID          => V_CASE_ID,
                                    ERRORCODE        => V_ERRORCODE,
                                    ERRORMESSAGE     => V_ERRORMESSAGE,
                                    FIND_INTO        => 'CHILD',
                                    LINK_TYPE_CODE   => 'BLOCKED_BY',
                                    RELATED_CASE_IDS => V_RELATEDCASEIDS,
                                    FIND_ONLY_NOT_CLOSED => 1);
        
        IF NVL(V_ERRORCODE,0) != 0 THEN
            goto done;
        end if;

		IF V_RELATEDCASEIDS != 'NOT_FOUND' THEN

			V_MESSAGEBUFFER := V_MESSAGEBUFFER||'Case with id : '||V_CASE_ID||' can''t be closed. Blocked by '||V_RELATEDCASEIDS||' case(s)'||'\r\n';
			V_ERRORCODE := 113;

		END IF;
    
		V_RESULT := F_FINDCASELINKS(CASE_ID      => V_CASE_ID,
								ERRORCODE        => V_ERRORCODE,
								ERRORMESSAGE     => V_ERRORMESSAGE,
								FIND_INTO        => 'PARENT',
								LINK_TYPE_CODE   => 'BLOCKS',
								RELATED_CASE_IDS => V_RELATEDCASEIDS,
								FIND_ONLY_NOT_CLOSED => 1);

        IF NVL(V_ERRORCODE,0) != 0 THEN
            goto done;
        end if;

		IF V_RELATEDCASEIDS != 'NOT_FOUND' THEN

			V_MESSAGEBUFFER := V_MESSAGEBUFFER||'Case with id : '||V_CASE_ID||' can''t be closed. Blocks by '||V_RELATEDCASEIDS||' case(s)'||'\r\n';

		END IF;

    END IF;

        
        V_RESULT := F_FINDCASELINKS(CASE_ID           => V_CASE_ID,
                                    ERRORCODE        => V_ERRORCODE,
                                    ERRORMESSAGE     => V_ERRORMESSAGE,
                                    FIND_INTO        => 'CHILD',
                                    LINK_TYPE_CODE   => 'DISABLED_BY',
                                    RELATED_CASE_IDS => V_RELATEDCASEIDS,
                                    FIND_ONLY_NOT_CLOSED => 1);
        
        IF NVL(V_ERRORCODE,0) != 0 THEN
            goto done;
        end if;

        IF V_RELATEDCASEIDS != 'NOT_FOUND' THEN

			V_MESSAGEBUFFER := V_MESSAGEBUFFER||'Case with id : '||V_CASE_ID||' can''t be routed. Disabled by '||V_RELATEDCASEIDS||' case(s)'||'\r\n';

        END IF;
    
        V_RESULT := F_FINDCASELINKS(CASE_ID           => V_CASE_ID,
                                    ERRORCODE        => V_ERRORCODE,
                                    ERRORMESSAGE     => V_ERRORMESSAGE,
                                    FIND_INTO        => 'PARENT',
                                    LINK_TYPE_CODE   => 'DISABLES',
                                    RELATED_CASE_IDS => V_RELATEDCASEIDS,
                                    FIND_ONLY_NOT_CLOSED => 1);

        IF NVL(V_ERRORCODE,0) != 0 THEN
            goto done;
        end if;
        
        IF V_RELATEDCASEIDS != 'NOT_FOUND' THEN

			V_MESSAGEBUFFER := V_MESSAGEBUFFER||'Case with id : '||V_CASE_ID||' can''t be routed. Disabled by '||V_RELATEDCASEIDS||' case(s)'||'\r\n';

        END IF;
  
    IF NVL(V_ERRORCODE,0) != 0 THEN
        goto done;
    end if;


	<<done>>
        if NVL(V_ERRORCODE,0) != 0 THEN
            :ERRORCODE := V_ERRORCODE;
            :ERRORMESSAGE := V_ERRORMESSAGE;    
        else
            :ERRORCODE := 123;
            :ERRORMESSAGE := V_MESSAGEBUFFER;   
        end if;
    
        /*DBMS_OUTPUT.PUT_LINE(V_MESSAGEBUFFER);
        DBMS_OUTPUT.PUT_LINE(V_ERRORMESSAGE);
        DBMS_OUTPUT.PUT_LINE(V_ERRORCODE);*/
END;