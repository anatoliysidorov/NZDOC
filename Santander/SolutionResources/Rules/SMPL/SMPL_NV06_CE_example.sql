BEGIN
INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('invoked CommonEvent NV06_CE_example', 'CaseId='||TO_CHAR(:CaseId), NULL); 
INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('invoked CommonEvent NV06_CE_example', 'TaskId='||TO_CHAR(:TaskId), NULL); 
INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('invoked CommonEvent NV06_CE_example', 'ProcedureId='||TO_CHAR(:ProcedureId), NULL); 
:validationresult:=1;
:ErrorCode :=0;
:ErrorMessage:='no errors';
END;