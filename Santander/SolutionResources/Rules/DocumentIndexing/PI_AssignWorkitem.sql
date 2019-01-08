DECLARE
    v_assignType NVARCHAR2(50);
    v_workitemId NUMBER;
    v_workBasketId NUMBER;
    v_isId NUMBER;
    v_workitemIds NVARCHAR2(32767);
    v_res NUMBER;
    v_message NCLOB;
    v_errorCode number;
    v_errorMessage NVARCHAR2(255);
    v_wiTitle NVARCHAR2(255);
    v_actionCode NVARCHAR2(255);
BEGIN

    v_assignType := :AssignType;
    v_workitemId := :WorkitemId;
    v_errorCode := 0;
    v_errorMessage := '';
    v_message := '';
    :ErrorMessage := '';
    :ErrorCode := 0;
    :ExecutionLog := '';
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

    select 
        (case when v_assignType = 'ASSIGN' then 'RE_ASSIGN'
              when v_assignType = 'ASSIGN_TO_ME' then 'ASSIGN_TO_ME'
              when v_assignType = 'ASSIGN_BACK' then 'ASSIGN_BACK'
              else ''
        end) into v_actionCode
    from dual;

    FOR rec in (select to_number(column_value) as id from table(asf_split(v_workitemIds, ',')))
    LOOP  
         v_res := f_PI_allowAction(
            WorkitemId => rec.id, 
            ActionCode => v_actionCode, 
            CurrentActivity => 'root_CS_STATUS_DOCINDEXINGSTATES_WAITING_FOR_REVIEW',
            ErrorCode => v_errorCode,
            ErrorMessage => v_errorMessage
        );

        if(v_errorCode > 0) THEN
            begin
                select col_title into v_wiTitle from tbl_pi_workitem where col_id = rec.id;          
                exception
                  when no_data_found then
                    v_wiTitle := '';                
            end;
            v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => v_wiTitle || ': ' || v_errorMessage);
            continue;
        end if;        


        IF(v_assignType = 'ASSIGN') THEN
            v_workBasketId := :WorkbasketId;
        ELSIF(v_assignType = 'ASSIGN_TO_ME') THEN
            BEGIN
                SELECT wb.col_Id INTO v_workBasketId
                FROM VW_USERS vu
                INNER JOIN TBL_PPL_CASEWORKER cw ON cw.COL_USERID = vu.USERID
                INNER JOIN vw_ppl_simpleworkbasket wb ON wb.Caseworker_Id = cw.COL_ID
                WHERE vu.ACCESSSUBJECTCODE = sys_context('CLIENTCONTEXT', 'AccessSubject')
                AND UPPER(wb.workbaskettype_code) = 'PERSONAL';
            EXCEPTION 
                WHEN NO_DATA_FOUND THEN
                NULL;
            END;        
        ELSIF(v_assignType = 'ASSIGN_BACK') THEN
            BEGIN
                SELECT COL_PI_WORKITEMPREVWORKBASKET INTO v_workBasketId
                FROM TBL_PI_WORKITEM 
                WHERE col_Id = rec.id;         
            EXCEPTION 
                WHEN NO_DATA_FOUND THEN
                NULL;
            END;   
        END IF;

        IF(v_workBasketId IS NOT NULL) THEN
            UPDATE TBL_PI_WORKITEM SET
                COL_PI_WORKITEMPPL_WORKBASKET = v_workBasketId,
                COL_PI_WORKITEMPREVWORKBASKET = (SELECT COL_PI_WORKITEMPPL_WORKBASKET FROM TBL_PI_WORKITEM WHERE col_Id = rec.id)
            WHERE col_Id = rec.id;
        END IF;
    END LOOP;

    if(v_message is not null) then
        :ErrorCode := 101;
        :ErrorMessage := 'There was an error executing this action';
        :ExecutionLog := v_message;
    else    
        :SuccessResponse := 'Workitem(s) successfully assigned';
    end if;
END;