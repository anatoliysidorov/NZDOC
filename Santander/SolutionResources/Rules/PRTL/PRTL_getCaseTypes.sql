SELECT ct.id,
       ct.code,
       ct.description,
       ct.name,
       ct.isdeleted,
       ct.isdraftmodeavail,
       ct.colorcode,
       ct.iconcode,
       ct.priority_id,
       ct.procedure_id,
       ct.model_id,
       ct.usedatamodel,
       ct.rootobjectid,
       ct.rootobjectcode,
       ct.createformid
  FROM vw_dcm_casetype ct
 WHERE     NVL (ct.isdeleted, 0) = 0
       AND NVL (ct.showinportal, 0) = 1
       AND (CASE
               WHEN (1 IN (SELECT allowed
                             FROM TABLE (F_dcm_getcwaopermaccessmsfn (p_accessobjecttypecode => 'CASE_TYPE', p_permissioncode => 'CREATE'))
                            WHERE casetypeid = ct.id))
               THEN
                  1
               ELSE
                  0
            END) = 1
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>