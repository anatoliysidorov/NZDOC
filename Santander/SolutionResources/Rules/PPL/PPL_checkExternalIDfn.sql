DECLARE
    v_externalid       NVARCHAR2(255);
    v_caseworker_id    NUMBER;
BEGIN
	v_externalid := :ExternalId;
	:CaseWorkerExist := 1;

    IF v_externalid is not NULL Then
        SELECT col_id
        INTO   v_caseworker_id
        FROM   tbl_ppl_caseworker
        WHERE  COL_EXTSYSID = v_externalid;

        IF v_caseworker_id IS NOT NULL THEN
            :CaseWorkerExist := 1;
        END IF;
    END IF;


EXCEPTION
	WHEN no_data_found THEN :CaseWorkerExist := 0;
END;