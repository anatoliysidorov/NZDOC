DECLARE
    v_errorCode NUMBER;
    v_errorMessage NVARCHAR2(1255);
    v_workbasketId NUMBER;
BEGIN
    v_errorCode    := 0;
    v_errorMessage := 'No Error';
    v_workbasketId := 0;

    :ErrorCode     := v_errorCode;
    :ErrorMessage  := v_errorMessage;

    BEGIN
        SELECT COL_ID INTO v_workbasketId FROM TBL_PPL_WORKBASKET WHERE COL_CODE = 'DOCUMENT_INDEXING_EMAIL';

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_errorCode    := 131;
            v_errorMessage := 'No data was found';
            GOTO cleanup;
    END;

    :workbasketId := v_workbasketId;

    <<cleanup>>
    :ErrorCode    := v_errorCode;
    :ErrorMessage := v_errorMessage;

END;