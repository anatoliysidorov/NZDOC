BEGIN
    INSERT INTO TBL_LOG(col_data1,
                  col_data2,
                  col_bigdata1)
           values('invoked CUST_2VV',
                  '(CLOB) INPUT=',
                  INPUT);
    
    :validationresult := 0;
    :ErrorCode :=-1;
    :ErrorMessage := 'OOops. wrong )))';
END;