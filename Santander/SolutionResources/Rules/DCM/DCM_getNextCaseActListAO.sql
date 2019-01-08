SELECT cst.col_id                  AS ID, 
       cst.col_name                AS TransitionName, 
       cst.col_iconcode            AS TransitionIconCode, 
       csts.col_activity           AS NextActivity, 
       csts.col_code               AS NextActivity_Code, 
       dim.col_code                AS CaseNextStateInitMethod, 
       csts.col_defaultorder       AS DEFAULTORDER, 
       csts.col_isdeleted          AS ISDELETED, 
       csts.col_isdefaultoncreate2 AS ISDEFAULTONCREATE2, 
       csts.col_isdefaultoncreate  AS ISDEFAULTONCREATE, 
       csts.col_isstart            AS ISSTART, 
       csts.col_isresolve          AS ISRESOLVE, 
       csts.col_isfinish           AS ISFINISH, 
       csts.col_isassign           AS ISASSIGN, 
       csts.col_isfix              AS ISFIX 
FROM   tbl_dict_casetransition cst 
       inner join tbl_dict_casestate csss 
               ON cst.col_sourcecasetranscasestate = csss.col_id 
       inner join tbl_dict_casestate csts 
               ON cst.col_targetcasetranscasestate = csts.col_id 
       inner join tbl_cw_workitem cwi 
               ON csss.col_id = cwi.col_cw_workitemdict_casestate 
       inner join tbl_case cs 
               ON cwi.col_id = cs.col_cw_workitemcase 
       left join tbl_map_casestateinitiation mcsi 
              ON cs.col_id = mcsi.col_map_casestateinitcase 
                 AND csts.col_id = mcsi.col_map_csstinit_csst 
       left join tbl_dict_initmethod dim 
              ON mcsi.col_casestateinit_initmethod = dim.col_id 
WHERE  f_dcm_iscasetransitionallow(AccessObjectId => (select Id from table(f_dcm_getCaseTransAOList()) where CaseTransitionId = cst.col_id)) = 1
  AND  cs.col_id = :CaseId
ORDER BY DEFAULTORDER ASC