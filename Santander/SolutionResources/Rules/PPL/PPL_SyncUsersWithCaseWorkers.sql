DECLARE 
    var_userid2                 INT; 
    var_list_users              VARCHAR2(3000) := :list_users; 
    v_caseworker_id             NUMBER; 
    v_personalworkbaskettype_id INT; 
    v_asid                      INTEGER; 
    v_errorCode                 NUMBER;
    v_errorMessage              NVARCHAR2(255);
    v_result                    NUMBER;
    --LIST OF CASEWORKERS TO ADD OR ENABLED 
    CURSOR c1 IS 
      SELECT au.userid        AS USERID, 
             cw.col_userid    AS CWUSERID, 
             cw.col_isdeleted AS ISDELETED, 
             au.name          AS NAME 
      FROM   vw_users au 
             inner join (SELECT To_number(column_value) userid 
                         FROM   TABLE(Asf_split(var_list_users, '|||'))) ul 
                     ON ( au.userid = ul.userid ) 
             left join tbl_ppl_caseworker cw 
                    ON ( cw.col_userid = au.userid ) 
      WHERE  cw.col_userid IS NULL 
              OR Nvl(cw.col_isdeleted, 0) = 1; 
			  
    --LIST OF CASEWORKERS TO DISABLE 
    CURSOR c2 IS 
      SELECT col_userid AS userid 
      FROM   tbl_ppl_caseworker cw 
      WHERE  ( Nvl(cw.col_isdeleted, 0) = 0 ) 
             AND col_userid NOT IN (SELECT To_number(column_value) userid 
                                    FROM   TABLE(Asf_split(var_list_users, '|||' 
                                           ))); 
BEGIN 
	v_errorCode := 0;
    v_errorMessage := '';
    
    :ErrorCode := v_errorCode;
    :ErrorMessage := v_errorMessage;
    
    --CREATE NEW CASEWORKERS OR ENABLED EXISTING ONES 
    FOR newuser IN c1 LOOP 
        v_caseworker_id := F_ppl_createmodifycwfn(userid => newuser.userid, 
                           externalid => NULL, ErrorCode => v_errorCode, ErrorMessage => v_errorMessage); 
        if (v_caseworker_id is null or v_caseworker_id = 0) THEN
        	:ErrorCode := v_errorCode;
            :ErrorMessage := v_errorMessage;
        ELSE
            UPDATE tbl_ppl_caseworker 
            SET    col_isdeleted = 0 
            WHERE  col_id = v_caseworker_id; 
        END IF;     
    END LOOP; 

    --DISABLE CASE WORKERS 
    OPEN c2; 

    LOOP 
        FETCH c2 INTO var_userid2; 

        EXIT WHEN c2%NOTFOUND; 

        UPDATE tbl_ppl_caseworker 
        SET    col_isdeleted = 1 
        WHERE  col_userid = var_userid2; 
    END LOOP; 

    CLOSE c2;

    v_result := f_DCM_createCTAccessCache();
    
END; 