select s1.RowNumber as RowNumber, s1.Notification as Notification
from
(select rownum as RowNumber, ntf.col_description as Notification
from tbl_notification ntf
inner join tbl_dict_notificationtype ntt on ntf.col_notifnotiftype = ntt.col_id
inner join tbl_subscription sbs on ntf.col_notificationsubscription = sbs.col_id
inner join tbl_caseworkersubscription cws on sbs.col_id = cws.col_cwsubscripsubscription
inner join vw_ppl_activecaseworkersusers cwu on cws.col_cwsubscriptioncaseworker = cwu.id
where cwu.accode = sys_context('CLIENTCONTEXT','AccessSubject')
order by ntf.col_createddate desc) s1
where s1.RowNumber <= :NumCount