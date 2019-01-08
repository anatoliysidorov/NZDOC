DECLARE 
    v_errorcode   NUMBER;
	v_createddate   DATE; 
	v_createdby     NVARCHAR2(255); 
	
	v_OrgChart_Id NUMBER;
	
	v_cnt 		NUMBER;
BEGIN 
v_errorcode:= 0;
    v_OrgChart_Id := :OrgChart_Id;

	

	BEGIN
	
		DELETE FROM TBL_PPL_ORGCHARTMAP
		WHERE COL_ORGCHARTORGCHARTMAP = v_OrgChart_Id;

		
	
    EXCEPTION 
        WHEN OTHERS THEN 
			v_errorcode := 4;
    END; 

	<<cleanup>> 
        :ErrorCode := v_errorcode; 
    RETURN; 
END;