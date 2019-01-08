DECLARE
    v_state   NVARCHAR2(255);
BEGIN
    BEGIN
        SELECT col_activity
        INTO v_state
        FROM tbl_dict_casestate
        WHERE col_isfinish = 1;

    EXCEPTION
        WHEN no_data_found THEN
            v_state := 'root_CS_Status_CLOSED';
        WHEN too_many_rows THEN
            v_state := 'root_CS_Status_CLOSED';
    END;

    RETURN v_state;
END;