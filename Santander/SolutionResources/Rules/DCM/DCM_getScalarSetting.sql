DECLARE 
    v_result NVARCHAR2(255); 
BEGIN 
    SELECT Nvl(col_value, :defaultResult) 
    INTO   v_result 
    FROM   tbl_config 
    WHERE  col_name = :p_name; 

    RETURN v_result; 
END; 