declare 
  v_caseTypeId number;  
begin
  v_caseTypeId := :CaseTypeId;

--normalize orders
   for rec in (select col_id as sconfigId
    from tbl_som_config
    where col_som_configsom_model in (select col_id
                                      from tbl_som_model
                                      where col_som_modelmdm_model = (select mm.col_id
                                                                      from tbl_mdm_model mm
                                                                inner join tbl_dict_casesystype ct on ct.col_casesystypemodel =  mm.col_id
                                                                where ct.col_id = v_caseTypeId)))
loop  
      
    for recAttr in (select col_id as Id, rownum as RN
                  from tbl_som_resultattr
                  where col_som_resultattrsom_config = rec.sconfigId
                  order by col_sorder)
    loop  
        update tbl_som_resultattr
        set col_sorder = recAttr.RN
        where col_id = recAttr.Id;  
    end loop;
  end loop;

end;