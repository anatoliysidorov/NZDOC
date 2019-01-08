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
  select gen_tbl_caseeventcc.nextval into v_counter from dual;
  begin
    insert into tbl_caseeventcc(col_processorcode,col_caseeventcccasestinitcc,col_taskeventmomntcaseeventcc,col_taskeventtypecaseeventcc,col_caseeventorder,
                              col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
      (select ce.col_processorcode,csi2.col_id,ce.col_taskeventmomntcaseeventtp,ce.col_taskeventtypecaseeventtp,ce.col_caseeventorder,
              v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
         from tbl_caseeventtmpl ce
         --JOIN TO DESIGN TIME CASESTATEINITIATION RECORDS
         inner join tbl_map_casestateinittmpl csi on ce.col_caseeventtpcasestinittp = csi.col_id
         inner join tbl_casecc cs on csi.col_casestateinittp_casetype = cs.col_caseccdict_casesystype
         --JOIN TO RUNTIME CASESTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME CASESTATEINITIATION RECORDS
         inner join tbl_map_casestateinitcc csi2 on cs.col_id = csi2.col_map_casestateinitcccasecc and csi.col_map_csstinittp_csst = csi2.col_map_csstinitcc_csst
         where cs.col_id = v_CaseId);
    exception
      when DUP_VAL_ON_INDEX then
        return -1;
      when OTHERS then
        return -1;
  end;
  select gen_tbl_caseeventcc.currval into v_lastcounter from dual;
  for rec in (select col_id from tbl_caseeventcc where col_id between v_counter and v_lastcounter)
  loop
    update tbl_caseeventcc set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
end;