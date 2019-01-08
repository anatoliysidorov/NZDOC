declare
  v_docid Integer;
  v_CaseId Integer;
  v_CaseTypeId Integer;
  v_FolderId Integer;
  v_name nvarchar2(255);
  v_ErrorMessage nvarchar2(255);
  v_ErrorCode number;
  v_count Integer;
  v_first Integer;
  v_next Integer;
begin
  v_CaseId := :CaseId;
  v_CaseTypeId := :CaseTypeId;
  v_FolderId := :FolderId;
  v_name := :Name;
  if v_CaseId is null and v_CaseTypeId is null then
    :ErrorMessage := 'Either CaseId or CaseTypeId is required';
    :ErrorCode := 101;
    return -1;
  end if;
  if v_CaseId is not null and v_CaseTypeId is not null then
    :ErrorMessage := 'Either CaseId or CaseTypeId is required';
    :ErrorCode := 102;
    return -1;
  end if;
  if v_name is null and v_FolderId is not null then
    if v_name is null and v_CaseId is not null then
      v_name := 'Case Folder ' || to_char(v_caseId);
    elsif v_name is null and v_CaseTypeId is not null then
      v_name := 'Casetype Folder ' || to_char(v_CaseTypeId);
    end if;
    v_name := v_name || ' Folder SubFolder ' || to_char(v_FolderId);
  end if;
  if v_name is null and v_CaseId is not null then
    v_name := 'Case Folder ' || to_char(v_CaseId);
  elsif v_name is null and v_CaseTypeId is not null then
    v_name := 'Casetype Folder ' || to_char(v_CaseTypeId);
  end if;
  /*
  begin
    select count(*) into v_count from tbl_docfolder
    where nvl(COL_DOCFOLDERCASE,0) = nvl(v_CaseId,0)
    and nvl(COL_DOCFOLDERCASESYSTYPE,0) = nvl(v_CaseTypeId,0)
    and lower(trim(substr(col_name,1,instr(col_name,'(')-1))) = lower(v_name);
    exception
    when NO_DATA_FOUND then
      v_count := 0;
  end;
  */
  /*
  if v_count = 0 then
    begin
      select count(*) into v_first from tbl_docfolder
      where nvl(COL_DOCFOLDERCASE,0) = nvl(v_CaseId,0)
      and nvl(COL_DOCFOLDERCASESYSTYPE,0) = nvl(v_CaseTypeId,0)
      and lower(trim(case when instr(col_name,'(') > 0 then substr(col_name,1,instr(col_name,'(')-1) else col_name end)) =
      lower(trim(case when instr(v_name,'(') > 0 then substr(v_name,1,instr(v_name,'(')-1) else v_name end));
      exception
      when NO_DATA_FOUND then
        v_first := 0;
    end;
  end if;
  */
  v_next := null;
  /*
  if v_count > 0 then
    select max(to_number(substr(col_name,instr(col_name,'(')+1,instr(col_name,')')-instr(col_name,'(')-1)))+1 into v_next
      from tbl_docfolder
      where nvl(COL_DOCFOLDERCASE,0) = nvl(v_CaseId,0)
      and nvl(COL_DOCFOLDERCASESYSTYPE,0) = nvl(v_CaseTypeId,0)
      and lower(trim(substr(col_name,1,instr(col_name,'(')-1))) = lower(v_name);
  elsif v_first = 1 then
    v_next := 1;
  end if;
  */
  if v_next is not null then
    v_name := v_name || '(' || to_char(v_next) || ')';
  end if;
  :GeneratedName := v_name;
end;