select col_id as ID, col_activity as Activity from tbl_dict_casestate where col_isfinish = 1 and nvl(col_stateconfigcasestate,0) = nvl(:StateConfigId,0)