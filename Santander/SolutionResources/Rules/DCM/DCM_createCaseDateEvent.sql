declare
    v_date date;
    v_performedby nvarchar2(255);
    v_CaseworkerId Integer;
    v_CaseId Integer;
    v_name nvarchar2(255);
    v_EventTypeId Integer;
    v_EventTypeCode nvarchar2(255);
    v_DateEventId Integer;
    v_MultipleAllowed number;
    v_CanOverwrite number;
begin
    v_CaseId := :CaseId;
    v_name := :Name;
    v_date := sysdate;
    v_performedby := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
    begin
        select id
        into
               v_CaseworkerId
        from   vw_ppl_caseworkersusers
        where  accode = v_performedby;
    
    exception
    when NO_DATA_FOUND then
        v_CaseworkerId := null;
    end;
    begin
        select col_id,
               col_code,
               col_multipleallowed,
               col_canoverwrite
        into
               v_EventTypeId,
               v_EventTypeCode,
               v_MultipleAllowed,
               v_CanOverwrite
        from   tbl_dict_dateeventtype
        where  upper(col_code) = upper(v_name);
    
    exception
    when NO_DATA_FOUND then
        v_EventTypeId := null;
        v_EventTypeCode := null;
        v_MultipleAllowed := null;
        v_CanOverwrite := null;
    end;
    if(v_MultipleAllowed is null) or(v_MultipleAllowed = 0) then
        begin
            select col_id
            into
                   v_DateEventId
            from   tbl_dateevent
            where  col_dateeventcase = v_CaseId
                   and upper(col_datename) = upper(v_name);
        
        exception
        when NO_DATA_FOUND then
            v_DateEventId := null;
        when TOO_MANY_ROWS then
            delete
            from   tbl_dateevent
            where  col_dateeventcase = v_CaseId
                   and upper(col_datename) = upper(v_name);
            
            v_DateEventId := null;
        end;
    else
        v_DateEventId := null;
    end if;
    if v_DateEventId is null then
        insert into tbl_dateevent(col_dateeventcase,
                      col_datename,
                      col_datevalue,
                      col_performedby,
                      col_dateeventppl_caseworker,
                      col_dateevent_dateeventtype)
               values(v_CaseId,
                      upper(v_name),
                      v_date,
                      v_performedby,
                      v_CaseworkerId,
                      v_EventTypeId);
    
    elsif(v_DateEventId is not null) and(v_MultipleAllowed is not null) and(v_MultipleAllowed = 1) then
        insert into tbl_dateevent(col_dateeventcase,
                      col_datename,
                      col_datevalue,
                      col_performedby,
                      col_dateeventppl_caseworker,
                      col_dateevent_dateeventtype)
               values(v_CaseId,
                      upper(v_name),
                      v_date,
                      v_performedby,
                      v_CaseworkerId,
                      v_EventTypeId);
    
    elsif(v_DateEventId is not null) and((v_MultipleAllowed is null) or(v_MultipleAllowed = 0)) and(v_CanOverwrite is not null) and(v_CanOverwrite = 1) then
        update tbl_dateevent
        set    col_datevalue = v_date,
               col_performedby = v_performedby,
               col_dateeventppl_caseworker = v_CaseworkerId
        where  col_dateeventcase = v_CaseId
               and upper(col_datename) = upper(v_name);
    
    end if;
end;