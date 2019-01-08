select 
   COL_ID AS ID,
   COL_ALLOWADDPEOPLE AS AllowAddPeople,
   COL_ALLOWDELETECOMMENT AS AllowDeleteComment,
   COL_ALLOWEDITCOMMENT AllowEditComment,
   COL_ALLOWJOINDISCUSSION AS AllowJoinDiscussion,
   COL_ALLOWLEAVEDISCUSSION AS AllowLeaveDiscussion,
   COL_ALLOWREMOVEPEOPLE AS AllowRemovePeople,
   COL_ALLOWCOMMENTDISCUSSION AS AllowCommentDiscussion,
   COL_ALLOWCREATEDISCUSSION AS AllowCreateDiscussion,
   <%= IfNotNull(":CASEID", "(select count(*) from tbl_case c inner join tbl_ppl_workbasket wb on wb.col_id = c.col_caseppl_workbasket inner join tbl_ppl_caseworker cw on cw.col_id = wb.col_caseworkerworkbasket inner join vw_users usr on usr.userid = cw.col_userid where c.col_id = :CASEID and usr.accesssubjectcode = '@TOKEN_USERACCESSSUBJECT@') as IsUserCaseOwner,") %>
   COL_ALLOWDELETEDISCUSSION AS AllowDeleteDiscussion
from tbl_threadsetting
where rownum = 1

