BEGIN
INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('invoked SMPL_CommonEvent2', '(CLOB) INPUT=', :INPUT); 
:validationresult:=1;
:ErrorCode :=0;
:ErrorMessage :='ALL OK';
END;