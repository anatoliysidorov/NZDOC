DECLARE 
    v_result NCLOB;
    v_PMode NUMBER;
BEGIN
	v_PMode := :PMode;
	IF (v_PMode = 1) THEN 
		--FOR rec IN (SELECT dt.col_id as id
			--FROM tbl_STP_DocumentType dt
			--INNER JOIN tbl_CaseSysTypeDocumentType csdt ON csdt.col_tbl_STP_DocumentType = dt.col_id
			  --AND csdt.col_tbl_DICT_CaseSysType = SearchRecordId)
		--LOOP 
			--IF v_result IS NULL THEN 
			  --v_result := TO_CHAR(rec.id);
			--ELSE 
			  --v_result := v_result 
						  --|| '|||' 
						  --|| TO_CHAR(rec.id); 
			--END IF; 
		--END LOOP;
	v_result := '';
	END IF;
	

    RETURN v_result; 
END;