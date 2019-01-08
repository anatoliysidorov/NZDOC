SELECT ue.col_id AS id,
       ue.col_uielementpage AS pageid,
       dbms_xmlgen.CONVERT(ue.col_jsondata) AS jsondata,
       dbms_xmlgen.CONVERT(ue.col_config) AS config,
       ue.col_positionindex AS positionindex,
       ue.col_regionid AS regionid,
       ue.col_description AS description,
       'element_' || TO_CHAR(ue.col_id) AS code,
       ue.col_iseditable AS iseditable,
       ue.col_parentid AS parentid,
       CASE
         WHEN nvl(f_fom_isuielementallowed(accessobjectid => ao.col_id, accesstype => 'VIEW'), 0) = 1 THEN
          (CASE
            WHEN nvl(f_fom_isuielementvisible(entity_id     => :EntityId,
                                              function_name => EXTRACTVALUE(XMLTYPE(CASE
                                                                                      WHEN nvl(dbms_lob.getlength(ue.col_config), 0) = 0 THEN
                                                                                       TO_CLOB('<CustomData><Attributes></Attributes></CustomData>')
                                                                                      ELSE
                                                                                       TO_CLOB(ue.col_config)
                                                                                    END),
                                                                            '/CustomData/Attributes/RULEVISIBILITY')),
                     0) = 1 THEN
             1
            ELSE
             0
          END)
         ELSE
          0
       END AS isvisible,
       CASE
         WHEN nvl(f_fom_isuielementallowed(accessobjectid => ao.col_id, accesstype => 'ENABLE'), 0) = 1 THEN
          (CASE
            WHEN nvl(f_fom_isuielementvisible(entity_id     => :EntityId,
                                              function_name => EXTRACTVALUE(XMLTYPE(CASE
                                                                                      WHEN nvl(dbms_lob.getlength(ue.col_config), 0) = 0 THEN
                                                                                       TO_CLOB('<CustomData><Attributes></Attributes></CustomData>')
                                                                                      ELSE
                                                                                       TO_CLOB(ue.col_config)
                                                                                    END),
                                                                            '/CustomData/Attributes/RULEREADONLY')),
                     0) = 1 THEN
             1
            ELSE
             0
          END)
         ELSE
          0
       END AS isenable

  FROM tbl_fom_uielement ue
  LEFT JOIN tbl_ac_accessobject ao
    ON ao.col_accessobjectuielement = ue.col_id
 WHERE 1 = 1
      <%= IfNotNull(":ID", " AND ue.col_id = :ID ") %>
      <%= IfNotNull(":PageId", " AND ue.col_uielementpage = :PageId ") %>
      <%= IfNotNull(":RegionId", " AND ue.col_regionid = :RegionId ") %>
ORDER BY ue.col_regionid, ue.col_positionindex ASC