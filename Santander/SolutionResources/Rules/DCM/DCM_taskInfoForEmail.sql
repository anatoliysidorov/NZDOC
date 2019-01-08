select 
f_form_getparambyname(cse.col_customdata.getStringval(),'EMAIL') as email,
f_form_getparambyname(cse.col_customdata.getStringval(),'FULL_NAME') as fullName
from tbl_case cs
inner join tbl_caseext cse on cs.col_id = cse.col_caseextcase
inner join tbl_task tsk on cs.col_id = tsk.col_casetask
where tsk.col_id = :TaskId