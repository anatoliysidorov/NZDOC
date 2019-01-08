DECLARE 
    v_id           NUMBER; 
    v_case         NUMBER; 
    v_errorcode    NUMBER; 
    v_errormessage NVARCHAR2(255); 
    v_result INTEGER;
    v_WAName NVARCHAR2(255); 
    
BEGIN 
    v_errorcode := 0; 
    v_errormessage := ''; 
    :affectedRows := 0; 
    v_id := :ID; 
    v_WAName :=NULL;
    v_case   :=NULL;
    
    BEGIN
      SELECT COL_NAME INTO v_WAName
      FROM TBL_DICT_WORKACTIVITYTYPE
      WHERE COl_ID = (SELECT col_workactivitytype 
                      FROM TBL_DCM_WORKACTIVITY 
                      WHERE  col_id = v_id);
    EXCEPTION
    WHEN OTHERS THEN  v_WAName :=NULL;   
    END;    

    BEGIN
      SELECT COL_WORKACTIVITYCASE INTO v_case
      FROM TBL_DCM_WORKACTIVITY     
      WHERE  col_id = v_id;
    EXCEPTION
    WHEN OTHERS THEN  v_case   :=NULL; 
    END;
    
    DELETE tbl_dcm_workactivity 
    WHERE  col_id = v_id; 
    
    v_result := F_hist_createhistoryfn(additionalinfo => NULL,
                                 issystem       => 0,
                                 MESSAGE        => 'Work activity "'||NVL(v_WAName, '')||'" deleted.',
                                 messagecode    => NULL,
                                 targetid       => v_case,
                                 targettype     => 'CASE');    

    --get affected rows 
    :affectedRows := SQL%rowcount; 

    <<cleanup>> 
    :ErrorMessage := v_errormessage; 
    :ErrorCode := v_errorcode; 
END; 