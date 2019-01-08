SELECT ue.col_id AS id,
       ue.col_uielementdashboard AS dashboardid,
       ue.col_uielementwidget AS widgetid,
       ue.col_jsondata AS jsondata,
       ue.col_positionindex AS positionindex,
       ue.col_description AS description,
       ue.col_iseditable AS iseditable,
       ue.col_rulevisibility AS rulevisibility,
       ue.col_code AS uielementcode,
       f_fom_isuielementallowed(accessobjectid => ao.col_id, accesstype => 'VIEW', accessobjecttype => 'DASHBOARD_ELEMENT') AS isviewable,
       f_fom_isuielementallowed(accessobjectid => ao.col_id, accesstype => 'ENABLE', accessobjecttype => 'DASHBOARD_ELEMENT') AS isenable
  FROM    tbl_fom_uielement ue
       LEFT JOIN
          tbl_ac_accessobject ao
       ON ao.col_accessobjectuielement = ue.col_id
 WHERE (:ID IS NULL OR (ue.col_id = :ID))
       AND (:DashboardId IS NULL OR (ue.col_uielementdashboard = :DashboardId))