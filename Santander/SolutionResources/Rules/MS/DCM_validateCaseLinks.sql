  DECLARE 

    V_RESULT         VARCHAR2(255);
    
    V_CASE_ID        INTEGER;
    V_STATE_CONF_ID   INTEGER;
    V_CASE_ACTIVITY  VARCHAR2(255);

    V_TARGET         VARCHAR2(255); 
    
    V_FIND_INTO      VARCHAR2(255);
    V_SCENARIO       VARCHAR2(255);
    V_LINK_TYPE_CODE VARCHAR2(255);
    V_IS_TRY_TO_CLOSE INTEGER;
    v_TransitionId    NUMBER;
    
    V_ERRORCODE      INTEGER;
    V_ERRORMESSAGE   VARCHAR2(4000);
    V_RELATEDCASEIDS VARCHAR2(4000);
    V_MESSAGEBUFFER  VARCHAR2(4000);
    
    V_CANROUTE INTEGER  := 1;
    V_CANCLOSE INTEGER  := 1;

BEGIN

    V_CASE_ID  := :CASE_ID;
    V_TARGET   := UPPER(:TARGET);
    v_TransitionId  := :TransitionId;

    V_IS_TRY_TO_CLOSE := NULL;
    V_LINK_TYPE_CODE  := NULL;
    V_SCENARIO        := NULL;
    V_FIND_INTO       := NULL;
    V_ERRORMESSAGE    := NULL;
    V_ERRORCODE       := NULL;
    V_MESSAGEBUFFER   :='';
    
    -- validation  
    IF (V_CASE_ID IS NULL) THEN
      V_ERRORCODE :=101;
      V_ERRORMESSAGE :='Case Id must be not null or empty';
      GOTO CLEANUP;
    END IF;

    IF f_DCM_CSisCaseInCache(V_CASE_ID)=1 THEN
      BEGIN
          SELECT  s.COL_STATESTATECONFIG, CSE.COL_MILESTONEACTIVITY INTO V_STATE_CONF_ID, V_CASE_ACTIVITY
          FROM TBL_CSCASE CSE
          LEFT OUTER JOIN TBL_DICT_STATE s ON s.col_ID =cse.COL_CASEDICT_STATE        
          WHERE CSE.COL_ID = V_CASE_ID;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN    
              V_ERRORCODE      := 101;
              V_ERRORMESSAGE   := 'Data from Case or State Config is missing';
              GOTO CLEANUP;
          WHEN TOO_MANY_ROWS THEN    
              V_ERRORCODE      := 101;
              V_ERRORMESSAGE   := 'Data from Case or State Config is missing';
              GOTO CLEANUP;
      END;
    END IF;

    IF f_DCM_CSisCaseInCache(V_CASE_ID)=0 THEN
      BEGIN
          SELECT  s.COL_STATESTATECONFIG, CSE.COL_MILESTONEACTIVITY INTO V_STATE_CONF_ID, V_CASE_ACTIVITY
          FROM TBL_CASE CSE
          LEFT OUTER JOIN TBL_DICT_STATE s ON s.col_ID =cse.COL_CASEDICT_STATE        
          WHERE CSE.COL_ID = V_CASE_ID;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN    
              V_ERRORCODE      := 101;
              V_ERRORMESSAGE   := 'Data from Case or State Config is missing';
              GOTO CLEANUP;
          WHEN TOO_MANY_ROWS THEN    
              V_ERRORCODE      := 101;
              V_ERRORMESSAGE   := 'Data from Case or State Config is missing';
              GOTO CLEANUP;
      END;
    END IF;

    IF (V_TARGET IS NOT NULL) THEN

        BEGIN
            SELECT 
                --target_cust_state.col_activity AS TargetCustomActivity, 
                --target_system_State.col_activity as TargetSystemActivity, 
                NVL(TARGET_SYSTEM_STATE.COL_ISFINISH,0) INTO V_IS_TRY_TO_CLOSE --as IsFinish
            FROM TBL_DICT_TRANSITION TRANSITION 
            LEFT OUTER JOIN TBL_DICT_STATE SOURCE_CUST_STATE ON TRANSITION.COL_SOURCETRANSITIONSTATE=SOURCE_CUST_STATE.COL_ID -- custom
            LEFT OUTER JOIN TBL_DICT_STATE TARGET_CUST_STATE ON TRANSITION.COL_TARGETTRANSITIONSTATE=TARGET_CUST_STATE.COL_ID  
            INNER JOIN TBL_DICT_CASESTATE SOURCE_SYSTEM_STATE ON SOURCE_CUST_STATE.COL_STATECASESTATE=SOURCE_SYSTEM_STATE.COL_ID --system
            INNER JOIN TBL_DICT_CASESTATE TARGET_SYSTEM_STATE ON TARGET_CUST_STATE.COL_STATECASESTATE=TARGET_SYSTEM_STATE.COL_ID
            WHERE SOURCE_CUST_STATE.COL_STATESTATECONFIG = V_STATE_CONF_ID AND
                TARGET_CUST_STATE.COL_STATESTATECONFIG = V_STATE_CONF_ID
                AND UPPER(SOURCE_CUST_STATE.COL_ACTIVITY)=UPPER(V_CASE_ACTIVITY)
                AND UPPER(TARGET_CUST_STATE.COL_ACTIVITY)=UPPER(V_TARGET) 
            ORDER BY TRANSITION.COL_ID ASC;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN    
                V_ERRORCODE      := 101;
            WHEN TOO_MANY_ROWS THEN    
                V_ERRORCODE      := 102;
        END;
        
        
        IF V_ERRORCODE IS NOT NULL THEN
          BEGIN
              SELECT 
                  --target_cust_state.col_activity AS TargetCustomActivity, 
                  --target_system_State.col_activity as TargetSystemActivity, 
                  NVL(TARGET_SYSTEM_STATE.COL_ISFINISH,0) INTO V_IS_TRY_TO_CLOSE --as IsFinish
              FROM TBL_DICT_TRANSITION TRANSITION 
              LEFT OUTER JOIN TBL_DICT_STATE SOURCE_CUST_STATE ON TRANSITION.COL_SOURCETRANSITIONSTATE=SOURCE_CUST_STATE.COL_ID -- custom
              LEFT OUTER JOIN TBL_DICT_STATE TARGET_CUST_STATE ON TRANSITION.COL_TARGETTRANSITIONSTATE=TARGET_CUST_STATE.COL_ID  
              INNER JOIN TBL_DICT_CASESTATE SOURCE_SYSTEM_STATE ON SOURCE_CUST_STATE.COL_STATECASESTATE=SOURCE_SYSTEM_STATE.COL_ID --system
              INNER JOIN TBL_DICT_CASESTATE TARGET_SYSTEM_STATE ON TARGET_CUST_STATE.COL_STATECASESTATE=TARGET_SYSTEM_STATE.COL_ID
              WHERE TRANSITION.COL_ID=NVL(v_TransitionId,0);

          EXCEPTION
              WHEN NO_DATA_FOUND THEN    
                  V_ERRORCODE      := 101;
                  V_ERRORMESSAGE   := 'The transition is missing with that ACTIVITY CODE'; -- message fixed by Max
                  GOTO CLEANUP;
              WHEN TOO_MANY_ROWS THEN    
                  V_ERRORCODE      := 102;
                  V_ERRORMESSAGE   := 'Too many transitions with that ACTIVITY CODE'; -- message fixed by Max
                  GOTO CLEANUP;
          END;        
        END IF;
        
    END IF;
    
    IF (V_IS_TRY_TO_CLOSE = 1) OR (V_TARGET IS NULL) THEN
        V_SCENARIO := 'CLOSING';
    ELSE
        V_SCENARIO := 'ROUTING';
    END IF;    
                                
    IF UPPER(V_SCENARIO) = 'CLOSING' THEN

        V_RESULT := F_DCM_FINDCASELINKS(CASE_ID          => V_CASE_ID,
                                        ERRORCODE        => V_ERRORCODE,
                                        ERRORMESSAGE     => V_ERRORMESSAGE,
                                        FIND_INTO        => 'CHILD',
                                        LINK_TYPE_CODE   => 'BLOCKED_BY',
                                        RELATED_CASE_IDS => V_RELATEDCASEIDS,
                                        FIND_ONLY_NOT_CLOSED => 1);

  		IF V_RELATEDCASEIDS != 'NOT_FOUND' THEN
            V_MESSAGEBUFFER := V_MESSAGEBUFFER||'Case : '||V_CASE_ID||' cannot be closed until blocking case(s) : '||V_RELATEDCASEIDS||'<br>';
            V_CANCLOSE := 0;
        END IF;
    
  		V_RESULT := F_DCM_FINDCASELINKS(CASE_ID      => V_CASE_ID,
                                        ERRORCODE        => V_ERRORCODE,
                                        ERRORMESSAGE     => V_ERRORMESSAGE,
                                        FIND_INTO        => 'PARENT',
                                        LINK_TYPE_CODE   => 'BLOCKS',
                                        RELATED_CASE_IDS => V_RELATEDCASEIDS,
                                        FIND_ONLY_NOT_CLOSED => 1);
    
    	IF V_RELATEDCASEIDS != 'NOT_FOUND' THEN
            V_MESSAGEBUFFER := V_MESSAGEBUFFER||'Blocking case(s) : '||V_RELATEDCASEIDS||' must be closed before blocked case : '||V_CASE_ID ||'<br>';
            V_CANCLOSE := 0;
        END IF;      

    END IF;

    V_RESULT := F_DCM_FINDCASELINKS(CASE_ID          => V_CASE_ID,
                                    ERRORCODE        => V_ERRORCODE,
                                    ERRORMESSAGE     => V_ERRORMESSAGE,
                                    FIND_INTO        => 'CHILD',
                                    LINK_TYPE_CODE   => 'DISABLED_BY',
                                    RELATED_CASE_IDS => V_RELATEDCASEIDS,
                                    FIND_ONLY_NOT_CLOSED => 1);
   

    IF V_RELATEDCASEIDS != 'NOT_FOUND' THEN
        V_MESSAGEBUFFER := V_MESSAGEBUFFER||'Case with id : '||V_CASE_ID||' cannot be routed until disabling case(s) : '||V_RELATEDCASEIDS||'<br>';
        V_CANROUTE := 0;
    END IF;

    V_RESULT := F_DCM_FINDCASELINKS(CASE_ID          => V_CASE_ID,
                                    ERRORCODE        => V_ERRORCODE,
                                    ERRORMESSAGE     => V_ERRORMESSAGE,
                                    FIND_INTO        => 'PARENT',
                                    LINK_TYPE_CODE   => 'DISABLES',
                                    RELATED_CASE_IDS => V_RELATEDCASEIDS,
                                    FIND_ONLY_NOT_CLOSED => 1);
 	
    IF V_RELATEDCASEIDS != 'NOT_FOUND' THEN  
        V_MESSAGEBUFFER := V_MESSAGEBUFFER||'Parent case(s) : '||V_RELATEDCASEIDS||' disallows routing of the child case : '||V_CASE_ID ||'<br>';
        V_CANROUTE := 0;
    END IF;

  <<CLEANUP>>
  
    IF V_MESSAGEBUFFER != '' OR V_MESSAGEBUFFER IS NOT NULL THEN
        --ERROR BLOCK
        V_ERRORCODE    := 123;
        V_ERRORMESSAGE := V_MESSAGEBUFFER;

    END IF;

    IF ((NVL(V_ERRORCODE,0) <> 123) AND (NVL(V_ERRORCODE,0) <> 0)) THEN
        V_CANCLOSE := 0;
        V_CANROUTE :=0;
    END IF;
    
    :ERRORCODE     := V_ERRORCODE;
    :ERRORMESSAGE  := V_ERRORMESSAGE;
    :CANCLOSE      := V_CANCLOSE;
    :CANROUTE      := V_CANROUTE;  

    /*DBMS_OUTPUT.PUT_LINE(V_ERRORCODE);
    DBMS_OUTPUT.PUT_LINE(V_ERRORMESSAGE);
    DBMS_OUTPUT.PUT_LINE(V_CANCLOSE);
    DBMS_OUTPUT.PUT_LINE(V_CANROUTE);*/

END;