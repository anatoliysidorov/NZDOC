declare
    v_col_createddate   date;
    v_col_createdby     nvarchar2(255);
    v_col_owner         nvarchar2(255);
 
    v_col_CaseId nvarchar2(255);
    v_col_PriorityCase number;
    v_col_ProcedureId number;
    v_col_DateAssigned date;
    v_col_Summary nvarchar2(255);
    v_ResolveBy date;
    v_CaseSysTypeId Integer;
    v_ProcedureId Integer;
    v_Description nclob;
    v_OwnerWorkBasketId Integer;
    v_draft number;

begin
  :affectedRows := 0;
  :recordId := 0;

  v_col_createdby := :TOKEN_USERACCESSSUBJECT;
  v_col_createddate := sysdate;
  v_col_owner := :Owner;
  v_col_CaseId := null;
  v_col_PriorityCase := :PriorityCase;
  v_col_Summary := :Summary;
  v_ResolveBy := :ResolveBy;
  v_CaseSysTypeId := :CaseSysTypeId;
  v_col_ProcedureId := :ProcedureId;
  v_Description := :Description;
  v_OwnerWorkBasketId:= :OwnerWorkBasketId;
  v_draft := :Draft;
  if(v_col_owner is not null) then
    v_col_DateAssigned := v_col_createddate;
  else
    v_col_DateAssigned := null;
  end if;

  begin
    insert into tbl_Case
    (
      col_CaseId,
      col_CreatedBy,
      col_CreatedDate,
      col_DateAssigned,
      col_Owner,
      col_STP_PriorityCase,
      col_ProcedureCase,
      col_CaseDICT_CaseSysType,
      col_Summary,
      col_ResolveBy,
      COL_CASEPPL_WORKBASKET,
      col_draft
    )
    values
    ( 
      v_col_CaseId,
      v_col_CreatedBy,
      v_col_CreatedDate,
      v_col_DateAssigned,
      v_col_Owner,
      v_col_PriorityCase,
      v_col_ProcedureId,
      v_CaseSysTypeId,
      v_col_Summary,
      v_ResolveBy,
      v_OwnerWorkBasketId,
      v_draft
    );
    select gen_tbl_Case.currval into :recordId from dual;
    insert into tbl_caseext(col_caseextcase, col_description) values(:recordId, v_Description);
    :affectedRows := 1;
    exception 
      when NO_DATA_FOUND then
       :affectedRows := 0;   
      when DUP_VAL_ON_INDEX then
        :affectedRows := 0;   
  end;

  return :recordId;

end;