DECLARE
    --INPUT
    v_DocumentId INT;
	
    --INTERNAL
    v_path NVARCHAR2(1000);
BEGIN
    --BIND AND PRE-CHECK
    v_DocumentId := NVL(:DocumentId,0);
    
    --GET FULL PATH TREE
    SELECT   utl_raw.Cast_to_nvarchar2(LISTAGG(utl_raw.Cast_to_raw(col_name),utl_raw.Cast_to_raw(N' &#xbb; ')) WITHIN GROUP(ORDER BY ROWNUM))
	INTO v_path
	FROM    (SELECT  col_name
			 FROM     tbl_doc_document
					  START WITH col_id = v_DocumentId
					  CONNECT BY PRIOR col_parentid = col_id
			 ORDER BY LEVEL DESC);
			   
    RETURN v_path;
EXCEPTION
WHEN OTHERS THEN
    RETURN 'ERROR';
END;