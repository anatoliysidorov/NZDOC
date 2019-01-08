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
  
  select gen_tbl_caseevent.nextval into v_counter from dual;
  begin
    insert into tbl_caseevent(col_processorcode,col_caseeventcasestateinit,col_taskeventmomentcaseevent,col_taskeventtypecaseevent,col_caseeventorder,
                              col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
      (select ce.col_processorcode,csi2.col_id,ce.col_taskeventmomntcaseeventtp,ce.col_taskeventtypecaseeventtp,ce.col_caseeventorder,
              v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
         from tbl_caseeventtmpl ce
         --JOIN TO DESIGN TIME CASESTATEINITIATION RECORDS
         inner join tbl_map_casestateinittmpl csi on ce.col_caseeventtpcasestinittp = csi.col_id
         inner join tbl_case cs on csi.col_casestateinittp_casetype = cs.col_casedict_casesystype
         --JOIN TO RUNTIME CASESTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME CASESTATEINITIATION RECORDS
         inner join tbl_map_casestateinitiation csi2 on cs.col_id = csi2.col_map_casestateinitcase and csi.col_map_csstinittp_csst = csi2.col_map_csstinit_csst
         where cs.col_id = v_CaseId);
    exception
      when DUP_VAL_ON_INDEX then
        :ErrorCode := 100;
      when OTHERS then
        :ErrorCode := 100;
  end;
  
  if :ErrorCode != 100 then
    select gen_tbl_caseevent.currval into v_lastcounter from dual;
    for rec in (select col_id from tbl_caseevent where col_id between v_counter and v_lastcounter)
    loop
      update tbl_caseevent set col_code = sys_guid() where col_id = rec.col_id;
    end loop;
  end if;
end;