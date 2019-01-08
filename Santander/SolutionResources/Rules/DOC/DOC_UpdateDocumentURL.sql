declare
    v_id   nvarchar2(255);
    v_url  nvarchar2(255);
    v_name nvarchar2(255);
begin
    v_id   := :DocumentId;
    v_url  := :NewUrl;
    v_name := :NewName;

    update 
        tbl_doc_document
    set 
        col_url = v_url,
        col_name = v_name
    where 
        col_id = v_id;
end;