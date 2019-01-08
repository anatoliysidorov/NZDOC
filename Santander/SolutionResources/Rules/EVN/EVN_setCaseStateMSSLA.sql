DECLARE
    v_result         INTEGER; 
    v_validationresult INTEGER; 
    v_message          NCLOB; 
 
BEGIN

--INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('START', 'f_EVN_setCaseStateMSSLA', NULL);
--INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('---', TO_CHAR(SLAActionID), Input);


  v_result := F_EVN_SETCASESTATEMS(INPUT=>:Input, 
                                  MESSAGE=>v_message, 
                                  TASKID=>F_dcm_gettaskidbyslafn(:SLAActionID), 
                                  VALIDATIONRESULT=>v_validationresult);

  :ValidationResult := v_validationresult; 
  :Message := v_message; 

--INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('---', 'v_validationresult', TO_CHAR(v_validationresult));
--INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('---', 'v_message', v_message);
--INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('END', 'f_EVN_setCaseStateMSSLA', NULL);
END;