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
  select gen_tbl_autoruleparamcc.nextval into v_counter from dual;
  begin
    insert into tbl_autoruleparamcc(col_caseeventccautoruleparcc, col_paramcode, col_paramvalue,
                                      col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
      (select ce2.col_id, arp.col_paramcode, arp.col_paramvalue,
              v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
         from tbl_autoruleparamtmpl arp
           inner join tbl_caseeventtmpl ce on arp.col_caseeventtpautorulepartp = ce.col_id
           inner join tbl_map_casestateinittmpl csi on ce.col_caseeventtpcasestinittp = csi.col_id
           inner join tbl_dict_casesystype cst on csi.col_casestateinittp_casetype = cst.col_id
           inner join tbl_casecc cs on cst.col_id = cs.col_caseccdict_casesystype
           inner join tbl_map_casestateinitcc csi2 on cs.col_id = csi2.col_map_casestateinitcccasecc
           inner join tbl_caseeventcc ce2 on csi2.col_id = ce2.col_caseeventcccasestinitcc
         where cs.col_id = v_CaseId);
    exception
     when DUP_VAL_ON_INDEX then
       return -1;
     when OTHERS then
       return -1;
  end;
  select gen_tbl_autoruleparamcc.currval into v_lastcounter from dual;
  for rec in (select col_id from tbl_autoruleparamcc where col_id between v_counter and v_lastcounter)
  loop
    update tbl_autoruleparamcc set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
end;