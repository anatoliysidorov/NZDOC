declare
  v_res number;
begin
  v_res := f_doc_destrdocversfn(errorcode             => :errorcode,
                              errormessage            => :errormessage,
                              documentid              => :documentId,
                              versionids              => :ids,
                              token_domain            => '@TOKEN_DOMAIN@',
                              token_useraccesssubject => '@TOKEN_USERACCESSSUBJECT@');
end;