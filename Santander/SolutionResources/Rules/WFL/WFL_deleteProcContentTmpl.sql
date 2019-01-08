declare
  v_procedureid Integer;
begin
  v_procedureid := :ProcedureId;

  delete from tbl_taskeventtmpl
  where col_taskeventtptaskstinittp in
    (select col_id from tbl_map_taskstateinittmpl where col_map_taskstinittpltasktpl in
      (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid));

  delete from tbl_autoruleparamtmpl
  where col_taskeventtpautoruleparmtp in
    (select col_id from tbl_taskeventtmpl
     where col_taskeventtptaskstinittp in
       (select col_id from tbl_map_taskstateinittmpl where col_map_taskstinittpltasktpl in
         (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid)));

  delete from tbl_autoruleparamtmpl
  where col_autoruleparamtptaskdeptp in
   (select col_id from tbl_taskdependencytmpl
    where col_taskdpchldtptaskstinittp in
     (select col_id from tbl_map_taskstateinittmpl
      where col_map_taskstinittpltasktpl in
       (select col_id from tbl_tasktemplate
        where col_proceduretasktemplate = v_procedureid))
  and col_taskdpprnttptaskstinittp in
   (select col_id from tbl_map_taskstateinittmpl
    where col_map_taskstinittpltasktpl in
     (select col_id from tbl_tasktemplate
      where col_proceduretasktemplate = v_procedureid)));

  delete from tbl_taskdependencytmpl
  where col_taskdpchldtptaskstinittp in
   (select col_id from tbl_map_taskstateinittmpl
    where col_map_taskstinittpltasktpl in
     (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid));

  delete from tbl_map_taskstateinittmpl
  where col_map_taskstinittpltasktpl in
   (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid);

  /*VV*/
  delete from tbl_casedependencytmpl
  where col_casedpcldtplcasestinittpl in
  (select col_id from tbl_map_casestateinittmpl
   where col_map_casestinittpltasktpl in
   (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid));
   /* I dont know do we need this
   and 
   col_casedpprttplcasestinittpl in
  (select col_id from tbl_map_casestateinittmpl
   where col_map_casestinittpltasktpl in
   (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid));  
  */ 

  delete from tbl_MAP_CaseStateInitTmpl
  where col_MAP_CaseStInitTplTaskTpl in
   (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid);
  /*VV*/   
   
   
  delete from tbl_slaactiontmpl
  where col_slaactiontpslaeventtp in
    (select col_id from tbl_slaeventtmpl
     where col_slaeventtptasktemplate in
       (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid));

  delete from tbl_slaeventtmpl
  where col_slaeventtptasktemplate in
    (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid);

end;