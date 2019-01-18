select cw.col_Name as ProductType
    from tbl_Case c 
    join tbl_cdm_briefings cb on cb.COL_BRIEFINGSCASE = c.COL_ID
    join tbl_dict_customword cw on cw.col_id = cb.COL_CDM_BRIEFINGBRIEFING_PRO
    where c.col_id = (select col_CaseTask as CASEID from tbl_Task where col_id = :TaskId)