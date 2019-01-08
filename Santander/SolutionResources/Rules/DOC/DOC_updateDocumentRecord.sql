declare
v_docid nvarchar2(255);
v_url nvarchar2(255);
v_filename nvarchar2(255);
begin
v_docid := :attachid;
v_url := :attachurl;
v_filename := :filename;

update tbl_document
set col_url = v_url,
	col_name = v_filename
where col_id = v_docid;
end;