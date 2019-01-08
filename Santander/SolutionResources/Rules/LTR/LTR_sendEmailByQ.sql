declare

    localhash    ecxtypes.params_hash;

    v_filesPaths NCLOB;
    v_filesNames NCLOB;
    v_smtpServer NVARCHAR2(255);
    v_from       NVARCHAR2(255);
    v_userName   NVARCHAR2(255);
    v_pass       NVARCHAR2(255);
    v_port       NVARCHAR2(255);
    v_to         NVARCHAR2(255);
    v_html       NCLOB;
    v_subject    NVARCHAR2(255);

    v_errorcode    NUMBER;
    v_errormessage NVARCHAR2(255);

    v_queuerecordid NVARCHAR2(255);
    v_result		NUMBER;

begin

    v_filesPaths := :filesPaths;
    v_filesNames := :filesNames;
    v_smtpServer := :smtpServer;
    v_from       := :frm;
    v_userName   := :userName;
    v_pass       := :pass;
    v_port       := :port;
    v_to         := :to;
    v_html       := :html;
    v_subject    := :subject;
    :SuccessResponse := EMPTY_CLOB();

    v_errorcode := 0;
    v_errormessage := '';

    if v_to is null then 
        v_errorcode    := 101;
        v_errormessage := 'Address is empty';
        goto cleanup;
    end if;

    if v_html is null then 
        v_errorcode    := 102;
        v_errormessage := 'Html body is empty';
        goto cleanup;
    end if;

     if v_html is null then 
        v_errorcode    := 103;
        v_errormessage := 'Subject is empty';
        goto cleanup;
    end if;

    localhash('TO')          := v_to;
    localhash('HTML')        := v_html;
    localhash('SUBJECT')     := v_subject;

    if v_filesPaths is not null then 
        localhash('FILESPATHS')  := v_filesPaths;
    end if;
    
    if v_filesNames is not null then 
        localhash('FILESNAMES')  := v_filesNames;
    end if;
    
    if v_smtpServer is not null then 
        localhash('SMTP_SERVER') := v_smtpServer;
    end if;
    
    if v_from is not null then 
        localhash('FROM')        := v_from;
    end if;
    
    if v_userName is not null then 
        localhash('USER_NAME')   := v_userName;
    end if;
    
    if v_pass is not null then 
        localhash('PASS')        := v_pass;
    end if;

    if v_port is not null then 
        localhash('PORT')        := v_port;
    end if;

    begin
        v_queuerecordid := QUEUE_addWithHash(v_code          => sys_guid(),
                                            v_domain          => '@TOKEN_DOMAIN@',
                                            v_createddate     => sysdate,
                                            v_createdby       => '@TOKEN_USERACCESSSUBJECT@',
                                            v_owner           => '@TOKEN_USERACCESSSUBJECT@',
                                            v_scheduleddate   => sysdate,
                                            v_objecttype      => 1,
                                            v_processedstatus => 1,
                                            v_processeddate   => sysdate,
                                            v_errorstatus     => 0,
                                            v_parameters      => localhash,
                                            v_priority        => 0,
                                            v_objectcode      => 'root_LTR_sendEmail',
                                            v_error           => '');


    exception
        when others then
            v_errorcode    := 104;
            v_errormessage := substr(sqlerrm, 1, 200);
            goto cleanup;
    end;

	v_result := LOC_i18n(
		MessageText => 'Message was successfully sent to {{MESS_TO}}',
		MessageResult => :SuccessResponse,
		MessageParams => NES_TABLE(
			Key_Value('MESS_TO', v_to)
		)
	);

    <<cleanup>>
        :errorcode    := v_errorcode;
        :errormessage := v_errormessage;
end;