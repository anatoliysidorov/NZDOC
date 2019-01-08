DECLARE 
    v_result NUMBER; 
BEGIN 
    BEGIN 
        SELECT allowed 
        INTO   v_result 
        FROM   

			TABLE(
				F_dcm_getcaseworkeraccessfn2( 
					p_accessobjectid => :AccessObjectId, 
					p_caseid => NULL, 
					p_caseworkerid => (SELECT id FROM vw_ppl_caseworkersusers WHERE  accode = Sys_context('CLIENTCONTEXT', 'AccessSubject') ), 
					p_permissionid => (SELECT col_id FROM tbl_ac_permission WHERE  col_code = 'VIEW' 
                                            AND col_permissionaccessobjtype = (SELECT col_id FROM tbl_ac_accessobjecttype WHERE col_code = 'CASE_STATE')
					), 
                    p_taskid => NULL)
			) where caseworkertype = 'CASEWORKER';
    EXCEPTION 
        WHEN no_data_found THEN 
          v_result := NULL; 
    END; 

    RETURN v_result; 
END; 