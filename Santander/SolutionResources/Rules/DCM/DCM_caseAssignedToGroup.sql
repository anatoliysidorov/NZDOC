declare
    v_result number;
    v_caseid integer;
begin
    v_caseid := :caseId;

    begin
        select count(*)
        into   v_result
        from   (
                select cas.col_id as caseid
                from   tbl_case cas
                       inner join tbl_ppl_workbasket wb
                               on cas.col_caseppl_workbasket = wb.col_id
                       inner join tbl_map_workbasketbusnessrole mwbbr
                               on wb.col_id = mwbbr.col_map_wb_br_workbasket
                       inner join tbl_caseworkerbusinessrole cwbr
                               on mwbbr.col_map_wb_wr_businessrole =
                                  cwbr.col_tbl_ppl_businessrole
                       inner join vw_ppl_activecaseworkersusers cwu
                               on cwbr.col_br_ppl_caseworker = cwu.id
                       inner join tbl_dict_workbaskettype wbt
                               on wb.col_workbasketworkbaskettype = wbt.col_id
                where  cwu.accode in (select accesssubject
                                      from   table(f_dcm_getproxyassignorlist())
                                     )
                union all
                select cas.col_id as caseid
                from   tbl_case cas
                       inner join tbl_ppl_workbasket wb
                               on cas.col_caseppl_workbasket = wb.col_id
                       inner join tbl_map_workbasketteam mwbt
                               on wb.col_id = mwbt.col_map_wb_tm_workbasket
                       inner join tbl_caseworkerteam cwt
                               on mwbt.col_map_wb_tm_team = cwt.col_tbl_ppl_team
                       inner join vw_ppl_activecaseworkersusers cwu
                               on cwt.COL_TM_PPL_CASEWORKER = cwu.id
                       inner join tbl_dict_workbaskettype wbt
                               on wb.col_workbasketworkbaskettype = wbt.col_id
                where  cwu.accode in (select accesssubject
                                      from   table(f_dcm_getproxyassignorlist())
                                     ))
               s1
        where  s1.caseid = v_caseid;
    exception
        when NO_DATA_FOUND then
          v_result := 0;
    end;

    return case
             when v_result > 0 then 1
             else 0
           end;
end;