select cst.col_id                  as Id,
       cst.col_code                as TransitionCode,
       cst.col_name                as TransitionName,
       cst.col_iconcode            as TransitionIconCode,
       csts.col_activity           as NextActivity,
       csts.col_code               as NextActivity_Code,
       dim.col_code                as CaseNextStateInitMethod,
       csts.col_defaultorder       as DefaultOrder,
       csts.col_isdeleted          as IsDeleted,
       csts.col_isdefaultoncreate2 as IsDefaultOnCreate2,
       csts.col_isdefaultoncreate  as IsDefaultOnCreate,
       csts.col_isstart            as IsStart,
       csts.col_isresolve          as IsResolve,
       csts.col_isfinish           as IsFinish,
       csts.col_isassign           as IsAssign,
       csts.col_isfix              as IsFix
from   tbl_dict_casetransition cst
       inner join tbl_dict_casestate csss on cst.col_sourcecasetranscasestate = csss.col_id
       inner join tbl_dict_casestate csts on cst.col_targetcasetranscasestate = csts.col_id
       inner join tbl_cw_workitem cwi on csss.col_id = cwi.col_cw_workitemdict_casestate
       inner join tbl_case cs on cwi.col_id = cs.col_cw_workitemcase
       left join tbl_map_casestateinitiation mcsi on cs.col_id = mcsi.col_map_casestateinitcase and csts.col_id = mcsi.col_map_csstinit_csst
       left join tbl_dict_initmethod dim on mcsi.col_casestateinit_initmethod = dim.col_id
       left join tbl_fom_uielement uect on cst.col_id = uect.col_uielementcasetransition and cs.col_casedict_casesystype = uect.col_uielementcasesystype
       left join tbl_fom_uielement ue on cst.col_id = ue.col_uielementcasetransition and uect.col_uielementcasesystype is null
where  case when uect.col_id is not null then nvl(uect.col_ishidden,0)
            when ue.col_id is not null then nvl(ue.col_ishidden,0)
            else 0 end = 0
and    cs.col_id = :CaseId
ORDER BY DefaultOrder ASC