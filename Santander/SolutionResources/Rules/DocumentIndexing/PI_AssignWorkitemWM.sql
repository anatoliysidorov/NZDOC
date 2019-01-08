DECLARE
    v_workitemId NUMBER;
    v_workBasketId NUMBER;
    v_isId NUMBER;
    v_workitemIds NVARCHAR2(32767);
    v_res NUMBER;
BEGIN

    v_workitemId := :WorkitemId;
    :ErrorMessage := '';
    :ErrorCode := 0;
    :SuccessResponse := '';
   
    IF(v_workitemId IS NOT NULL) THEN
        v_workitemIds := to_char(v_workitemId);
    ELSE
        v_workitemIds := :WorkitemIds;
    END IF;

    IF(v_workitemIds IS NULL) THEN
        :ErrorMessage := 'Workitem is not specified';
        :ErrorCode := 101;
        RETURN;
    END IF;

    v_workBasketId := :WorkbasketId;

    UPDATE TBL_PI_WORKITEM t SET
        COL_PI_WORKITEMPPL_WORKBASKET = v_workBasketId,
        COL_PI_WORKITEMPREVWORKBASKET = (SELECT p.COL_PI_WORKITEMPPL_WORKBASKET FROM TBL_PI_WORKITEM p WHERE p.col_Id = t.col_Id)
    WHERE t.col_Id in (select to_number(column_value) from table(asf_split(v_workitemIds, ',')));

    :SuccessResponse := 'Workitem(s) successfully assigned';
END;