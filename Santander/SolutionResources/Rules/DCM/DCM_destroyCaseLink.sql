DECLARE

    V_LINKID  NUMBER;
    V_LINKIDS NVARCHAR2(255);
    --STANDARD      
    V_ERRORCODE        NUMBER := 0;
    V_ERRORMESSAGE     NVARCHAR2(255 CHAR) := '';
BEGIN

    V_LINKID  := :ID;
    V_LINKIDS := :IDS;

    FOR LINK_RECORD IN (SELECT 
                            COL_ID AS ID
                        FROM TBL_CASELINK 
                        WHERE (V_LINKID IS NULL OR COL_ID = V_LINKID)
                        AND   (
                                V_LINKIDS IS NULL 
                                OR COL_ID IN (SELECT * FROM TABLE(ASF_SPLIT(V_LINKIDS,',')))
                              )
                        )

    LOOP

        BEGIN

            DELETE FROM TBL_CASELINK WHERE COL_ID = LINK_RECORD.ID;

        EXCEPTION
            WHEN OTHERS THEN
                V_ERRORCODE    := 102;
                V_ERRORMESSAGE := SUBSTR(SQLERRM, 1, 200);
                GOTO CLEANUP;
        END;

    END LOOP;

    <<CLEANUP>>
        :ERRORCODE    := V_ERRORCODE;
        :ERRORMESSAGE := V_ERRORMESSAGE;
END;