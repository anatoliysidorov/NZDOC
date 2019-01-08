DECLARE
    v_result NUMBER;
BEGIN
    INSERT INTO queue_event(code,
                        domainid,
                        createdby,
                        scheduleddate,
                        objecttype,
                        processedstatus,
                        priority,
                        objectcode,
                        PARAMETERS)
              VALUES(Sys_guid(),
                        '@TOKEN_DOMAIN@',
                        sys_context('CLIENTCONTEXT', 'AccessSubject'),
                        SYSDATE,
                        1,
                        1,
                        100,
                        :RuleCode,
                        :PARAMETERS)
    RETURNING QUEUEID
    INTO
              v_result;
    
    RETURN v_result;
END;