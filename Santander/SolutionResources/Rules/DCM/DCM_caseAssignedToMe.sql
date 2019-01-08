declare
    v_result number;
    v_caseid integer;
begin
    v_caseid := :caseId;

    begin
        select count(*)
        into   v_result
        from   (select cas.col_id as caseid
                from   tbl_case cas
                       inner join tbl_ppl_workbasket wb
                               on cas.col_caseppl_workbasket = wb.col_id
                       inner join tbl_map_workbasketcaseworker mwbcw
                               on wb.col_id = mwbcw.col_map_wb_cw_workbasket
                       inner join vw_ppl_activecaseworkersusers cwu
                               on mwbcw.col_map_wb_cw_caseworker = cwu.id
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
                       inner join vw_ppl_activecaseworkersusers cwu
                               on wb.col_caseworkerworkbasket = cwu.id
                where  cwu.accode in (select accesssubject
                                      from   table(f_dcm_getproxyassignorlist())
                                     )
                       and wb.col_isdefault = 1)
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