DECLARE 
    v_errorcode   NUMBER;
	v_createddate   DATE; 
	v_createdby     NVARCHAR2(255); 
	
	v_SourceOrgChart_Id NUMBER;
	v_TargetOrgChart_Id NUMBER;
	
	v_cnt 		NUMBER;
	v_team_id 	NUMBER;
BEGIN 

	v_errorcode := 0;
	v_createddate := SYSDATE; 
	v_createdby := '@TOKEN_USERACCESSSUBJECT@'; 

    v_SourceOrgChart_Id := :SourceOrgChart_Id;
    v_TargetOrgChart_Id := :TargetOrgChart_Id;
	
	-- check if source chart present
	SELECT Count(col_id) 
	INTO   v_cnt 
	FROM   tbl_ppl_orgchart 
	WHERE  col_id = v_SourceOrgChart_Id; 

	IF ( v_cnt = 0 ) THEN 
	  v_errorcode := 1; 
	  GOTO cleanup; 
	END IF;
	
	-- check if target chart present
	SELECT Count(col_id) 
	INTO   v_cnt 
	FROM   tbl_ppl_orgchart 
	WHERE  col_id = v_TargetOrgChart_Id; 
	
	IF ( v_cnt = 0 ) THEN 
	  v_errorcode := 2; 
	  GOTO cleanup; 
	END IF;
	
	-- check if all members of the SourceOrgChart are members of the Team
	SELECT COL_TEAMORGCHART INTO v_team_id
	FROM TBL_PPL_ORGCHART
	WHERE col_Id = v_SourceOrgChart_Id;
	
	IF (v_team_id > 0) THEN
		SELECT COUNT(wt.col_tbl_ppl_team) INTO v_cnt
		FROM TBL_CASEWORKERTEAM wt
		LEFT JOIN tbl_ppl_orgchartmap ocm ON ocm.col_CaseWorkerChild = wt.col_tm_ppl_caseworker AND ocm.col_orgchartorgchartmap = v_SourceOrgChart_Id
		WHERE wt.COL_TBL_PPL_TEAM != v_team_id
		GROUP BY wt.col_tbl_ppl_team;
		
		IF (v_cnt > 0) THEN
			v_errorcode := 3; 
			GOTO cleanup; 					
		END IF;
	END IF;
			

	BEGIN
	
		DELETE FROM TBL_PPL_ORGCHARTMAP
		WHERE COL_ORGCHARTORGCHARTMAP = v_TargetOrgChart_Id;
		
		INSERT INTO TBL_PPL_ORGCHARTMAP(COL_CREATEDBY, COL_CREATEDDATE, COL_OWNER,
			COL_CASEWORKERCHILD, COL_CASEWORKERPARENT, COL_ORGCHARTORGCHARTMAP, COL_POSITION)
		SELECT v_createdby, v_createddate, v_createdby,
			COL_CASEWORKERCHILD, COL_CASEWORKERPARENT, v_TargetOrgChart_Id, COL_POSITION
		FROM TBL_PPL_ORGCHARTMAP
		WHERE COL_ORGCHARTORGCHARTMAP = v_SourceOrgChart_Id;
		
	
    EXCEPTION 
        WHEN OTHERS THEN 
			v_errorcode := 4;
    END; 

	<<cleanup>> 
        :ErrorCode := v_errorcode; 
    RETURN; 
END;