DECLARE 

    V_CASEID NUMBER;
    V_CASETITLE NVARCHAR2(255); 
    V_CASETYPECODE NVARCHAR2(255); 

BEGIN 

   V_CASEID := :CASEID;
   V_CASETITLE := '';

    BEGIN 
    
        SELECT    CT.COL_CODE 
        INTO      V_CASETYPECODE 
        FROM      TBL_CASE C 
        LEFT JOIN TBL_DICT_CASESYSTYPE CT ON CT.COL_ID = C.COL_CASEDICT_CASESYSTYPE 
        WHERE     C.COL_ID = V_CASEID; 

        V_CASETITLE :='CUST-' 
                      || TO_CHAR(SYSDATE, 'YYYY/MM') 
                      || '/' 
                      || TO_CHAR(V_CASEID); 
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN 
          V_CASETITLE := 'SYSTEM ERROR'; 
    END; 

    --DBMS_OUTPUT.PUT_LINE(V_CASETITLE);
    :CASETITLE := V_CASETITLE;

END; 