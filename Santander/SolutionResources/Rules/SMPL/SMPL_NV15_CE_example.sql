BEGIN
INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('invoked CommonEvent NV15_CE_example', 'Input', :Input); 
INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('invoked CommonEvent NV15_CE_example', 'CaseId='||TO_CHAR(:CaseId), NULL); 
:validationresult:=1;
:ErrorCode :=0;
:ErrorMessage := 'no errors';
END;