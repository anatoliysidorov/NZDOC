SELECT ct.*, 
       f_dcm_getprocedurecasetype(casesystypeid => ct.id, procedureid => NULL) AS procedure_id
  FROM vw_dcm_casetype ct
 WHERE 
 	(:NEEDALL is not null or NVL(ct.isdeleted, 0) = 0)
    AND f_dcm_iscasetypedeletealwms(AccessObjectId => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = ct.id)) = 1

<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>