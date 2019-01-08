declare

    v_documentid        number;
    v_versionids        nvarchar2(255);
    localhash           ecxtypes.params_hash;
    v_queuerecordids    nvarchar2(255);
    v_createdby         nvarchar2(255);
    v_domain            nvarchar2(255);
    v_errorcode         number;
    v_errormessage      nvarchar2(255);

begin

    v_documentid     := :documentid;
    v_versionids     := :versionids;
    v_createdby      := :token_useraccesssubject;
    v_domain         := :token_domain;
    v_queuerecordids := '';

    for doc_record in (select 
                            col_id as id,
                            col_url as url
                        from tbl_doc_documentversion 
                        where (v_documentid is null or col_docversiondocid= v_documentid)
                        and   (
                                v_versionids is null 
                                or col_id in (select * from table(ASF_SPLIT(v_versionids,',')))
                              )
                      )

    loop

        begin

            localhash('CMS_URL') := doc_record.url;

            v_queuerecordids := v_queuerecordids || ' ' || QUEUE_addWithHash(v_code => sys_guid(),
                                                                            v_domain          => v_domain,
                                                                            v_createddate     => sysdate,
                                                                            v_createdby       => v_createdby,
                                                                            v_owner           => v_createdby,
                                                                            v_scheduleddate   => sysdate,
                                                                            v_objecttype      => 1,
                                                                            v_processedstatus => 1,
                                                                            v_processeddate   => sysdate,
                                                                            v_errorstatus     => 0,
                                                                            v_parameters      => localhash,
                                                                            v_priority        => 0,
                                                                            v_objectcode      => 'root_DOC_deleteCMSFile',
                                                                            v_error           => '');

            delete from tbl_doc_documentversion where col_id= doc_record.id;

        exception
            when others then
                v_errorcode    := 102;
                v_errormessage := substr(sqlerrm, 1, 200);
                goto cleanup;
        end;

    end loop;

    <<cleanup>>
        :errorcode    := v_errorcode;
        :errormessage := v_errormessage;
end;