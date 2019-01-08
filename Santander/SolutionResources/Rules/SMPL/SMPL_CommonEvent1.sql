BEGIN
INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('invoked SMPL_CommonEvent1', 'TaskId='||TO_CHAR(:TaskId), NULL); 
:validationresult:=1;
END;