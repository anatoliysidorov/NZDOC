SELECT ct.id,
       ct.col_id,
       ct.code,
       ct.colorcode,
       ct.description,
       ct.name,
       ct.isdeleted,
       ct.isdraftmodeavail,
       ct.showinportal,
       ct.iconcode,
       ct.priority_id,
       ct.procedure_id,
       ct.model_id,
       ct.usedatamodel,
       ct.rootobjectid,
       ct.rootobjectcode,
       ct.createformid
  FROM vw_dcm_casetype ct
 WHERE (:ISDELETED IS NULL OR NVL(ct.isdeleted, 0) = :ISDELETED)
   AND (nvl(:NEEDALL, 0) = 1 OR f_dcm_iscasetypeaccess(accessobjectid => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = ct.id),
                                                       permissioncode => :PERMISSIONCODE) = 1)
   AND (:PSEARCH IS NULL OR (lower(ct.name) LIKE lower('%' || :PSEARCH || '%')))
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>