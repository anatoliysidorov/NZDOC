DECLARE 

    LOCALHASH ECXTYPES.PARAMS_HASH;
  
    V_ERRORCODE      NUMBER;
    V_ERRORMESSAGE   NVARCHAR2(255);
    V_REQ_PARAMS_MESSAGE NVARCHAR2(255);

    V_DOMAIN       NVARCHAR2(255);
    V_CREATEDBY    NVARCHAR2(255);

    V_QUEUERECORD  NVARCHAR2(255);

BEGIN
    
    V_ERRORCODE    := 0;
    V_ERRORMESSAGE := '';
    V_REQ_PARAMS_MESSAGE := 'is required parameter for this operation';

    V_DOMAIN    := '@TOKEN_DOMAIN@';
    V_CREATEDBY := '@TOKEN_USERACCESSSUBJECT@';

    /*
    Actions for example

    run-auto-deploy
    deploy-1-progress
    execute-sql
    deploy-2-progress
    confirm
    deploy-3-progress
    */
    LOCALHASH('ACTION') := LOWER(NVL(:ACTION, 'run-auto-deploy'));
    LOCALHASH('SID')    := NVL(:SID,'');

    --LOCALHASH('TOKEN')                          = '@TOKEN_USERACCESSSUBJECT@';
    LOCALHASH('ENVIRONMENTCODE')                := '@TOKEN_DOMAIN@';

    --LOCALHASH('TENANT_CONFIGURATION_SERVICE_REST') = TENANTCONFIGURATIONSERVICEREST;
    LOCALHASH('VERSIONCODE')                    := :VERSIONCODE;
    LOCALHASH('SLEEP')                          := :SLEEP;

    /*IF TENANTCONFIGURATIONSERVICEREST IS NULL THEN

        V_ERRORCODE      = 1;
        V_ERRORMESSAGE   = 'TENANTCONFIGURATIONSERVICEREST '||V_REQ_PARAMS_MESSAGE;
        GOTO CLEANUP;
    */
    IF :VERSIONCODE IS NULL THEN

        V_ERRORCODE      := 2;
        V_ERRORMESSAGE   := 'VERSIONCODE '||V_REQ_PARAMS_MESSAGE;
        GOTO CLEANUP;

    ELSIF :SLEEP IS NULL THEN

        V_ERRORCODE      := 3;
        V_ERRORMESSAGE   := 'SLEEP '||V_REQ_PARAMS_MESSAGE;
        GOTO CLEANUP;

    END IF;

    V_QUEUERECORD := QUEUE_CREATEEVENT2(V_CODE          => SYS_GUID(),
                                        V_DOMAIN          => V_DOMAIN,
                                        V_CREATEDDATE     => SYSDATE,
                                        V_CREATEDBY       => V_CREATEDBY,
                                        V_OWNER           => V_CREATEDBY,
                                        V_SCHEDULEDDATE   => SYSDATE,
                                        V_OBJECTTYPE      => 1,
                                        V_PROCESSEDSTATUS => 1,
                                        V_PROCESSEDDATE   => SYSDATE,
                                        V_ERRORSTATUS     => 0,
                                        V_PARAMETERS      => LOCALHASH,
                                        V_PRIORITY        => 0,
                                        V_OBJECTCODE      => 'root_MDM_RunAutoDeployCs',
                                        V_ERROR           => '');

    <<CLEANUP>>
        :ERRORCODE    := V_ERRORCODE;
        :ERRORMESSAGE := V_ERRORMESSAGE;

END;