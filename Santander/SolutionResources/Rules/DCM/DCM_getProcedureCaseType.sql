declare
  v_result number;
  v_CaseSysTypeId Integer;
  v_ProcInCaseTypeCode nvarchar2(255);
  v_ProcedureId Integer;
  v_ProcedureCode nvarchar2(255);
begin
  v_CaseSysTypeId := :CaseSysTypeId;
  v_ProcedureId := :ProcedureId;
  v_ProcInCaseTypeCode := null;
  begin
    select pict.col_code into v_ProcInCaseTypeCode from tbl_dict_casesystype ct
    left join tbl_dict_procedureincasetype pict on ct.col_casetypeprocincasetype = pict.col_id
    where ct.col_id = v_CaseSysTypeId;
    exception
    when NO_DATA_FOUND then
      v_ProcInCaseTypeCode := 'dedicated_single';
  end;
  if v_ProcInCaseTypeCode is null then
    v_ProcInCaseTypeCode := 'dedicated_single';
  end if;
  if lower(v_ProcInCaseTypeCode) = 'dedicated_single' then
    begin
      select col_id into v_ProcedureId from tbl_procedure
        where col_proceduredict_casesystype = v_CaseSysTypeId;
      exception
        when NO_DATA_FOUND then
          v_ProcedureId := null;
        when TOO_MANY_ROWS then
          v_ProcedureId := null;
    end;
  elsif lower(v_ProcInCaseTypeCode) = 'dedicated_multiple' then
    if v_ProcedureId is not null then
      begin
        select col_id into v_ProcedureId
          from tbl_procedure
          where col_proceduredict_casesystype = v_CaseSysTypeId and col_id = v_ProcedureId;
        exception
          when NO_DATA_FOUND then
            v_ProcedureId := null;
          when TOO_MANY_ROWS then
            v_ProcedureId := null;
      end;
    else
      begin
        select s1.ProcedureId into v_ProcedureId
        from
        (select col_id as ProcedureId, row_number() over (order by col_name) as RowNumber
          from tbl_procedure
          where col_proceduredict_casesystype = v_CaseSysTypeId) s1
        where s1.RowNumber = 1;
        exception
          when NO_DATA_FOUND then
            v_ProcedureId := null;
          when TOO_MANY_ROWS then
            v_ProcedureId := null;
      end;
    end if;
  elsif lower(v_ProcInCaseTypeCode) = 'shared_single' then
    begin
      select col_casesystypeprocedure into v_ProcedureId from tbl_dict_casesystype
        where col_id = v_CaseSysTypeId;
      exception
        when NO_DATA_FOUND then
          v_ProcedureId := null;
        when TOO_MANY_ROWS then
          v_ProcedureId := null;
    end;
  elsif lower(v_ProcInCaseTypeCode) = 'shared_multiple' then
    v_result := v_ProcedureId;
  else
    begin
      select col_id into v_ProcedureId from tbl_procedure
        where col_proceduredict_casesystype = v_CaseSysTypeId;
      exception
        when NO_DATA_FOUND then
          v_ProcedureId := null;
        when TOO_MANY_ROWS then
          v_ProcedureId := null;
    end;
  end if;
  begin
    select col_code into v_ProcedureCode from tbl_procedure where col_id = v_ProcedureId;
    exception
    when NO_DATA_FOUND then
      v_ProcedureCode := null;
  end;
    
  return v_ProcedureId;

end;