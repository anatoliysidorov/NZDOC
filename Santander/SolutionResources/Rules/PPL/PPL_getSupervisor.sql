DECLARE 
    v_cw_id         NUMBER; 
    v_supervisor_id NUMBER; 
BEGIN 
    v_cw_id := :CW; 

    BEGIN 
        SELECT col_caseworkerparent 
        INTO   v_supervisor_id 
        FROM   tbl_ppl_orgchartmap ocm
		LEFT JOIN tbl_ppl_orgchart oc ON (ocm.COL_ORGCHARTORGCHARTMAP = oc.col_id)
        WHERE  ocm.col_caseworkerchild = :CW AND oc.col_isprimary = 1; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_supervisor_id := NULL; 
    END; 

    :SupervisorCW := v_supervisor_id; 
END; 