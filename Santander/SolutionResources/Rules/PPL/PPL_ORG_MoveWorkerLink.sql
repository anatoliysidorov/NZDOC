	BEGIN 
		DECLARE 
			v_OrgChart_Id	  INTEGER;
			v_CaseWorker_Id	  INTEGER;
			v_CaseWorkerTarget_Id	  INTEGER;
			v_test INTEGER;
			v_ErrorCode INTEGER;
		 BEGIN 
			BEGIN
			v_ErrorCode := 0; 
			:ErrorMessage := ''; 
			:affectedRows := 0; 
			:recordId := 0;

			v_OrgChart_Id := :OrgChart_Id; 
			v_CaseWorker_Id := :CaseWorker_Id; 
			v_CaseWorkerTarget_Id := :CaseWorkerTarget_Id; 			

		-- check that the CaseWorker and CaseWorkerTarget exist in the OrgChart
		BEGIN
		  SELECT COUNT(1)
		  INTO v_test
		  FROM tbl_PPL_OrgChartMap 
		  WHERE col_orgchartorgchartmap = v_orgchart_id  AND 
				(col_caseworkerchild = v_caseworker_id OR
				 col_caseworkerparent = v_caseworker_id
				); 
		  
		  EXCEPTION
		  WHEN NO_DATA_FOUND then
			 :ErrorCode := 101;
			 :ErrorMessage := 'The dropped case worker is not found';
			 goto Cleanup;
		END;
		
		BEGIN
		  SELECT COUNT(1)
		  INTO v_test
		  FROM tbl_PPL_OrgChartMap 
		  WHERE col_orgchartorgchartmap = v_orgchart_id  AND 
				(col_caseworkerchild = v_CaseWorkerTarget_Id OR
				 col_caseworkerparent = v_CaseWorkerTarget_Id
				); 
		  
		  EXCEPTION
		  WHEN NO_DATA_FOUND then
			 :ErrorCode := 101;
			 :ErrorMessage := 'The target case worker is not found';
			 goto Cleanup;
		END;
		
		-- update the new parent of the child record
		UPDATE tbl_PPL_OrgChartMap
		SET col_CaseWorkerParent = v_CaseWorkerTarget_Id
		WHERE 	col_orgchartorgchartmap = v_orgchart_id AND
				col_caseworkerchild = v_caseworker_id;
				
		:affectedRows := 1; 
		
		EXCEPTION
			WHEN OTHERS THEN
			v_ErrorCode := 100;
			:ErrorMessage := SUBSTR(SQLERRM, 1, 200);
		END;
		
		<<Cleanup>> :ErrorCode := v_ErrorCode;
		END;
	END;
