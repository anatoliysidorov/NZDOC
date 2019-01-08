declare
  v_CaseId Integer; 
  v_createdby nvarchar2(255);
  v_createddate date;
  v_modifiedby nvarchar2(255);
  v_modifieddate date;
  v_owner nvarchar2(255);
  v_counter number;
  v_lastcounter number;
begin
  v_CaseId := :CaseId;
  v_owner := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  v_createdby := v_owner;
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  select gen_tbl_map_casestateinitiat.nextval into v_counter from dual;
  begin
    insert into tbl_map_casestateinitiation(col_map_casestateinitcase, col_map_csstinit_csst, col_processorcode, col_assignprocessorcode, col_casestateinit_initmethod,
                                            col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
      (select v_CaseId, col_map_csstinit_csst, col_processorcode, col_assignprocessorcode, col_casestateinit_initmethod, v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
         from tbl_map_casestateinitiation
         where col_casestateinit_casesystype = (select col_casedict_casesystype from tbl_case where col_id = v_CaseId));
   exception
     when DUP_VAL_ON_INDEX then
       return -1;
     when OTHERS then
       return -1;
  end;
  select gen_tbl_map_casestateinitiat.currval into v_lastcounter from dual;
  for rec in (select col_id from tbl_map_casestateinitiation where col_id between v_counter and v_lastcounter)
  loop
    update tbl_map_casestateinitiation set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
end;