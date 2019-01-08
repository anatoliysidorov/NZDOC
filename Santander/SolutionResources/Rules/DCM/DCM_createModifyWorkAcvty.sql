DECLARE 
  --custom 
  v_id        NUMBER;
  v_id1       NUMBER;
  v_isdeleted NUMBER; 
  v_peopleinvolved NCLOB; 
  v_resolution NCLOB; 
  v_summary NCLOB; 
  v_hoursspent     NUMBER; 
  v_case             NUMBER; 
  v_task             NUMBER; 
  v_workactivitytype NUMBER; 
  v_customdata        nclob;
  v_result INTEGER;
  v_WAName NVARCHAR2(255); 
  --standard 
  v_errorcode NUMBER; 
  v_errormessage NVARCHAR2(255); 
BEGIN 
  --custom 
  :affectedRows := 0; 
  v_errorcode := 0; 
  v_errormessage := ''; 
  --standard 
  v_id := :ID; 
  v_id1 := :ID; --this is for history
  v_isdeleted := Nvl(:IsDeleted, 0);
  v_customdata := NVL(:CustomData,'<CustomData><Attributes><Form></Form></Attributes></CustomData>');
  v_peopleinvolved := :PeopleInvolved; 
  v_resolution := :Resolution; 
  v_summary := :Summary; 
  v_hoursspent := :hoursSpent; 
  v_case := :Case_Id; 
  v_task := :Task_Id; 
  v_workactivitytype := :WORKACTIVITYTYPE_ID;

  v_WAName :=NULL;
  
  BEGIN 
  
    BEGIN
      SELECT COL_NAME INTO v_WAName
      FROM TBL_DICT_WORKACTIVITYTYPE
      WHERE COl_ID=v_workactivitytype;
    EXCEPTION
    WHEN OTHERS THEN  v_WAName :=NULL;   
    END;
    
    --add new record if needed
    IF v_id IS NULL THEN 
      INSERT INTO tbl_dcm_workactivity 
                  ( 
                    col_workactivitycase, 
                    col_workactivitytask 
                  ) 
                  VALUES 
                  ( 
                    v_case, 
                    v_task 
                  ) 
      returning   col_id 
      INTO        v_id; 
      
      v_result := F_hist_createhistoryfn(additionalinfo => NULL,
                                   issystem       => 0,
                                   MESSAGE        => 'Work activity "'||NVL(v_WAName, '')||'" created.',
                                   messagecode    => NULL,
                                   targetid       => v_case,
                                   targettype     => 'CASE');
     
    END IF; 
	
	--update record with necessary info
    UPDATE tbl_dcm_workactivity 
    SET    col_hoursspent = v_hoursspent, 
           col_peopleinvovled = v_peopleinvolved, 
           col_resolution = v_resolution, 
           col_summary = v_summary, 
           col_workactivitycase = v_case, 
           col_isdeleted = v_isdeleted, 
           col_workactivitytype = v_workactivitytype,
           col_customdata = XMLTYPE(v_customdata)
    WHERE  col_id = v_id; 
    
    IF NVL(v_id1,0)<>0 THEN
      v_result := F_hist_createhistoryfn(additionalinfo => NULL,
                                   issystem       => 0,
                                   MESSAGE        => 'Work activity "'||NVL(v_WAName, '')||'" modified.',
                                   messagecode    => NULL,
                                   targetid       => v_case,
                                   targettype     => 'CASE');    
    END IF;
     
    :affectedRows := 1; 
    :recordId := v_id; 
EXCEPTION 
WHEN OTHERS THEN 
  :affectedRows := 0; 
  v_errorcode := 102; 
  v_errormessage := Substr(SQLERRM, 1, 200); 
END; 
:errorCode := v_errorcode; 
:errorMessage := v_errormessage; 
END;