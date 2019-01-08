DECLARE 
    v_result NCLOB;
    v_PMode NUMBER;
BEGIN
	v_PMode := :PMode;
	IF(v_PMode = 1) THEN 
		FOR rec IN (SELECT rc.col_Id as Id
					FROM tbl_stp_resolutionCode rc
          INNER JOIN TBL_TASKSYSTYPERESOLUTIONCODE TaskResCode ON TaskResCode.col_tbl_stp_resolutionCode = rc.col_id
					  AND TaskResCode.col_tbl_dict_tasksystype = :SearchRecordId)
		LOOP 
			IF v_result IS NULL THEN 
			  v_result := TO_CHAR(rec.Id);
			ELSE 
			  v_result := v_result 
						  || '|||' 
						  || TO_CHAR(rec.Id); 
			END IF; 
		END LOOP;
	ELSE
		IF(v_PMode = 2) THEN
			FOR rec IN (SELECT rc.col_Id as Id
					FROM tbl_stp_resolutionCode rc
					INNER JOIN TBL_CASESYSTYPERESOLUTIONCODE CaseResCode ON CaseResCode.col_casetyperesolutioncode = rc.col_id
					  AND CaseResCode.col_tbl_dict_casesystype = :SearchRecordId)
			LOOP 
				IF v_result IS NULL THEN 
				  v_result := TO_CHAR(rec.Id);
				ELSE  
				  v_result := v_result 
							  || '|||' 
							  || TO_CHAR(rec.Id); 
				END IF; 
			END LOOP;
		END IF;
	END IF;
	

    RETURN v_result; 
END;