DECLARE
v_docid nvarchar2(255);
v_url nvarchar2(255);
BEGIN
 v_docid := :DocumentId;
 v_url := '';
 :URL := v_url;
 BEGIN
 	SELECT col_url 
    INTO v_url
    FROM tbl_document where col_id = v_docid;
 EXCEPTION WHEN NO_DATA_FOUND THEN
 v_url := '';
 END;
:URL := v_url; 
END;