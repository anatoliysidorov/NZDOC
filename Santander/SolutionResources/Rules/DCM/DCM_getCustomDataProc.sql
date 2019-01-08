declare
  v_CaseTypeId Integer;
  v_ProcedureId Integer;
  v_ProcInCaseTypeCode nvarchar2(255);
  v_customdataprocessor nvarchar2(255);
  v_result number;
begin
  v_CaseTypeId := :CaseTypeId;
  v_ProcedureId := :ProcedureId;
  begin
    select pict.col_code into v_ProcInCaseTypeCode
    from tbl_dict_casesystype ct
    left join tbl_dict_procedureincasetype pict on ct.col_casetypeprocincasetype = pict.col_id
    where ct.col_id = v_CaseTypeId;
    exception
    when NO_DATA_FOUND then
      :CustomDataProcessor := null;
      return -1;
  end;
  if v_ProcInCaseTypeCode is null then
    v_ProcInCaseTypeCode := 'dedicated_single';
  end if;
  if lower(v_ProcInCaseTypeCode) = 'dedicated_single' then
    if nvl(v_CaseTypeId,0) = 0 then
      :CustomDataProcessor := null;
      return -1;
    end if;
    begin
      select col_customdataprocessor into v_customdataprocessor from tbl_dict_casesystype where col_id = v_CaseTypeId;
      exception
      when NO_DATA_FOUND then
        v_customdataprocessor := null;
    end;
  elsif lower(v_ProcInCaseTypeCode) = 'dedicated_multiple' then
    if nvl(v_ProcedureId,0) = 0 then
      :CustomDataProcessor := null;
      return -1;
    end if;
    begin
      select col_customdataprocessor into v_customdataprocessor from tbl_procedure where col_id = v_ProcedureId;
      exception
      when NO_DATA_FOUND then
      v_customdataprocessor := null;
    end;
  elsif lower(v_ProcInCaseTypeCode) = 'shared_single' then
    if nvl(v_CaseTypeId,0) = 0 then
      :CustomDataProcessor := null;
      return -1;
    end if;
    begin
      select v_customdataprocessor into v_customdataprocessor from tbl_dict_casesystype where col_id = v_CaseTypeId;
      exception
      when NO_DATA_FOUND then
        v_customdataprocessor := null;
    end;
  elsif lower(v_ProcInCaseTypeCode) = 'shared_multiple' then
    if nvl(v_CaseTypeId,0) = 0 or nvl(v_ProcedureId,0) = 0 then
      :CustomDataProcessor := null;
      return -1;
    end if;
    begin
      select col_id into v_result from tbl_map_casetypeprocedure where col_casetypeproccasetype = v_CaseTypeId and col_casetypeprocprocedure = v_ProcedureId;
      exception
      when NO_DATA_FOUND then
        :CustomDataProcessor := null;
        return -1;
      when TOO_MANY_ROWS then
        :CustomDataProcessor := null;
        return -1;
    end;
    begin
      select col_customdataprocessor into v_customdataprocessor from tbl_procedure where col_id = v_ProcedureId;
      exception
      when NO_DATA_FOUND then
        v_customdataprocessor := null;
    end;
  end if;
  :CustomDataProcessor := v_customdataprocessor;
end;