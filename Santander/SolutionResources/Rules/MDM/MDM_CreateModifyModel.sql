DECLARE

    V_ID              TBL_MDM_MODEL.COL_ID%TYPE;
    V_COL_CODE        TBL_MDM_MODEL.COL_CODE%TYPE;
    V_COL_NAME        TBL_MDM_MODEL.COL_NAME%TYPE;
    V_COL_DESCRIPTION TBL_MDM_MODEL.COL_DESCRIPTION%TYPE;
    V_COL_CONFIG      TBL_MDM_MODEL.COL_CONFIG%TYPE;
    V_COL_ISDELETED   TBL_MDM_MODEL.COL_ISDELETED%TYPE;
    V_COL_USEDFOR     TBL_MDM_MODEL.COL_USEDFOR%TYPE;
    --V_COL_CASETYPE_ID TBL_MDM_MODEL.COL_MDM_MODELDICT_CASETYPE%TYPE;
    V_COL_OBJECT_ID   TBL_MDM_MODEL.COL_MDM_MODELFOM_OBJECT%TYPE;
	  v_isUpdateConfig  INTEGER;

    V_RESULT          NUMBER;
    V_ERRORCODE       NUMBER := 0;
    V_ERRORMESSAGE    NVARCHAR2(255 CHAR) := '';

BEGIN

    V_ID              := :ID;
    V_COL_CODE        := :CODE;
    V_COL_NAME        := :NAME;
    V_COL_DESCRIPTION := :DESCRIPTION;
    V_COL_CONFIG      := :CONFIG;
    V_COL_ISDELETED   := :ISDELETED;
    V_COL_USEDFOR     := :USEDFOR;
--    V_COL_CASETYPE_ID := :CASETYPEID;
    V_COL_OBJECT_ID   := :OBJECTID;	

    :AFFECTEDROWS := 0;

  -- VALIDATION ON ID IS EXIST
    IF (NVL(V_ID, 0) > 0) THEN

        V_RESULT := F_UTIL_GETID(ERRORCODE => V_ERRORCODE,
                                ERRORMESSAGE => V_ERRORMESSAGE,
                                ID => V_ID,
                                TABLENAME => 'TBL_MDM_MODEL');
        
        IF (V_ERRORCODE > 0) THEN
            GOTO CLEANUP;
        END IF;

    END IF;
    BEGIN
  
        IF (V_ID IS NULL) THEN

/*            SELECT COUNT(*) INTO V_RESULT
            FROM TBL_MDM_MODEL dm 
            WHERE dm.COL_MDM_MODELDICT_CASETYPE = V_COL_CASETYPE_ID;

            IF(V_RESULT > 0) THEN
                V_ERRORMESSAGE := 'Current Case Type already have Data Model. It can have only one Data Model.';
                V_ERRORCODE := 101;
                GOTO CLEANUP;       
            END IF;
*/

            INSERT INTO TBL_MDM_MODEL (
                COL_CODE,
                COL_NAME,
                COL_DESCRIPTION,
                COL_CONFIG,
                COL_ISDELETED,
                COL_USEDFOR,
                --COL_MDM_MODELDICT_CASETYPE,
                COL_MDM_MODELFOM_OBJECT
                ) VALUES (
                V_COL_CODE,
                V_COL_NAME,
                V_COL_DESCRIPTION,
                V_COL_CONFIG,
                V_COL_ISDELETED,
                V_COL_USEDFOR,
                --V_COL_CASETYPE_ID,
                V_COL_OBJECT_ID
                ) RETURNING COL_ID INTO V_ID;
                
            :SUCCESSRESPONSE := 'Created {{MESS_NAME}} model';

        ELSE		
			
			UPDATE TBL_MDM_MODEL SET
				COL_NAME = V_COL_NAME,
				COL_DESCRIPTION = V_COL_DESCRIPTION,
				COL_ISDELETED = V_COL_ISDELETED
			WHERE COL_ID = V_ID;
			
			:SUCCESSRESPONSE := 'Updated {{MESS_NAME}} model';

    END IF;

    :AFFECTEDROWS := SQL%ROWCOUNT;
    :RECORDID := V_ID;

    V_RESULT := LOC_I18N(MESSAGETEXT  => :SUCCESSRESPONSE,
                        MESSAGERESULT => :SUCCESSRESPONSE,
                        MESSAGEPARAMS => NES_TABLE(KEY_VALUE('MESS_NAME', V_COL_NAME)));

    EXCEPTION

        WHEN DUP_VAL_ON_INDEX THEN

            :AFFECTEDROWS := 0;
            V_ERRORCODE := 101;
            V_RESULT := LOC_I18N(MESSAGETEXT  => 'There already exists a model with the code {{MESS_CODE}}',
                                MESSAGERESULT => V_ERRORMESSAGE,
                                MESSAGEPARAMS => NES_TABLE(KEY_VALUE('MESS_CODE', V_COL_CODE)));  
            :SUCCESSRESPONSE := '';

        WHEN OTHERS THEN

            :AFFECTEDROWS := 0;
            V_ERRORCODE := 102;
            V_ERRORMESSAGE := SUBSTR(SQLERRM, 1, 200);
            :SUCCESSRESPONSE := '';

    END;

<<CLEANUP>>
  :ERRORCODE := V_ERRORCODE;
  :ERRORMESSAGE := V_ERRORMESSAGE;

END;