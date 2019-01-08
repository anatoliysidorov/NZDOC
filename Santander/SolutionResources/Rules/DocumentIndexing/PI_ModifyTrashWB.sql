DECLARE
    v_workitemId NUMBER;
    v_workBasketId NUMBER;
    v_res NUMBER;
    v_workitemIds NVARCHAR2(32767);

    v_message NCLOB;
    v_errorCode number;
    v_errorMessage NVARCHAR2(255);
    v_wiTitle NVARCHAR2(255);
    v_actionCode NVARCHAR2(255);
    v_actionType NVARCHAR2(255);
BEGIN

    v_workitemId := :WorkitemId;
    v_actionType := :ActionType;
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
        (case when v_actionType = 'ADD' then 'TRASH'
              when v_actionType = 'DELETE' then 'UNTRASH'
              when v_actionType = 'PERMANENT_DELETE' then 'PERMANENT_DELETE'
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

        IF(v_actionType = 'ADD') THEN
            UPDATE TBL_PI_WORKITEM SET
            COL_ISDELETED = 1
            WHERE col_Id = rec.id;
        ELSIF(v_actionType = 'DELETE') THEN
            UPDATE TBL_PI_WORKITEM SET
            COL_ISDELETED = 0
            WHERE col_Id =  rec.id;
        ELSIF(v_actionType = 'PERMANENT_DELETE') THEN
            v_res := f_PI_PermanentDeleteFn(
                                                WorkitemId => rec.id, 
                                                ErrorMessage => :ErrorMessage, 
                                                ErrorCode => :ErrorCode,
                                                TokenDomain => f_UTIL_getDomainFn(),
                                                TokenAccessSubject => '@TOKEN_USERACCESSSUBJECT@'
                                            );
        END IF;
    END LOOP;

    if(v_message is not null) then
        :ErrorCode := 101;
        :ErrorMessage := 'There was an error executing this action';
        :ExecutionLog := v_message;
    else 
        IF(v_actionType = 'ADD') THEN
            :SuccessResponse := 'Workitem(s) successfully moved to trash';
        ELSIF(v_actionType = 'DELETE') THEN
            :SuccessResponse := 'Workitem(s) successfully removed from trash';
        ELSIF(v_actionType = 'PERMANENT_DELETE') THEN
            :SuccessResponse := 'Workitem(s) successfully removed';
        END IF;
    end if;
END;
