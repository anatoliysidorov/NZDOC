DECLARE 
    --custom 
    v_queueid      NUMBER; 
    v_objectcode   NVARCHAR2(255); 
    v_parameters   NCLOB; 
    --standard 
    v_errorcode    NUMBER; 
    v_errormessage NVARCHAR2(255); 
    v_result       NUMBER; 
BEGIN 
    --custom 
    v_queueid := :QueueId; 
    v_objectcode := :ObjectCode; 
    v_parameters := :Parameters; 
	
    --standard 
    :affectedRows := 0; 
    v_errorcode := 0; 
    v_errormessage := ''; 
    :SuccessResponse := Empty_clob(); 
    :errorMessage := Empty_clob(); 

    BEGIN 
        --add new record or update existing one 
        IF v_queueid IS NULL THEN 
          INSERT INTO queue_event 
                      (code, 
                       domainid, 
                       createdby, 
                       createddate, 
                       owner, 
                       scheduleddate, 
                       objecttype, 
                       processedstatus, 
                       priority, 
                       objectcode, 
                       parameters) 
          VALUES      ( Sys_guid(), 
                       f_UTIL_getDomainFn(), 
                       Sys_context ('CLIENTCONTEXT', 'AccessSubject'), 
                       --'@TOKEN_USERACCESSSUBEJECT@',  
                       SYSDATE, 
                       Sys_context ('CLIENTCONTEXT', 'AccessSubject'), 
                       --'@TOKEN_USERACCESSSUBEJECT@', 
                       SYSDATE, 
                       1, 
                       1, 
                       100, 
                       v_objectcode, 
                       v_parameters ) 
          returning queueid INTO :recordId; 
          :affectedRows := SQL%rowcount; 

          v_result := Loc_i18n( 
					messagetext => 'Created {{MESS_NAME}} Queue Event', 
					messageresult => :SuccessResponse, 
					messageparams => 
					Nes_table(Key_value( 'MESS_NAME', v_objectcode))); 
        ELSE 
          UPDATE queue_event 
          SET    parameters = v_parameters,
				objectcode = v_objectcode
          WHERE  queueid = v_queueid; 

          :affectedRows := SQL%rowcount; 
          :RecordId := v_queueid; 
          v_result := Loc_i18n( 
					messagetext => 'Updated {{MESS_NAME}} Queue Event', 
					messageresult => :SuccessResponse, 
					messageparams => 
					Nes_table(Key_value( 'MESS_NAME', v_objectcode))); 
        END IF; 
    EXCEPTION 
        WHEN dup_val_on_index THEN 
          :affectedRows := 0; 
          v_errorcode := 101; 
          v_result := Loc_i18n( 
					messagetext => 'There already exists an Queue Event with ID {{MESS_NAME}}', 
					messageresult => v_errormessage, messageparams => 
					Nes_table(Key_value( 'MESS_NAME', v_objectcode))); 
          :SuccessResponse := ''; 
        WHEN OTHERS THEN 
          :affectedRows := 0; 
          v_errorcode := 102; 
          v_errormessage := Substr(SQLERRM, 1, 200); 
          :SuccessResponse := ''; 
    END; 

    <<cleanup>> 
    :errorCode := v_errorcode; 
    :errorMessage := v_errormessage; 
END; 