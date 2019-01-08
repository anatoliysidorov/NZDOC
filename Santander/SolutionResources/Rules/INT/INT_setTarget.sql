DECLARE
    /*--input*/
    v_targetid      INTEGER;
    v_integrationId INTEGER;
    v_targettype NVARCHAR2(255) ;
    v_integrationCode NVARCHAR2(255) ;
    v_externalIntegrationID NVARCHAR2(255) ;

BEGIN
    v_targetid := :TargetId;
    v_targettype := lower(:TargetType) ;
    v_integrationId := :IntegrationId;
    v_integrationCode := :IntegrationCode;
    v_externalIntegrationID := :ExternalIntegrationID;


    /*--GET INTEGRATION TYPE*/
    IF NVL(v_integrationId,0) = 0 AND TRIM(v_integrationCode) IS NOT NULL THEN
        v_integrationId := f_UTIL_getIdByCode(TableName => 'tbl_int_integtarget',
                                              code => v_integrationCode) ;
    END IF;


    /*--UPDATE IN PROPER PLACE*/
    IF v_targettype = 'task' THEN
        UPDATE tbl_TASK
        SET    COL_INT_INTEGTARGETTASK = v_integrationId,
			   COL_EXTSYSID = v_externalIntegrationID
        WHERE  COL_ID = v_targetid;
    
    END IF;
    
    :errorCode := 0;
    :errorMessage := '';
    :SuccessResponse := '';
END;