SELECT col_id                                      AS Id,
       col_code                                    AS Code,
       col_name                                    AS NAME,
       col_description                             AS Description,
       col_processorcode                           AS ProcessorCode,
       col_actiontype_taskeventtype                AS EventType_Id,
       f_getnamefromaccesssubject (col_createdby)  AS Createdby_Name,
       f_util_getdrtnfrmnow (col_createddate)      AS CreatedDuration,
       f_getnamefromaccesssubject (col_modifiedby) AS Modifiedby_Name,
       f_util_getdrtnfrmnow (col_modifieddate)     AS ModifiedDuration
  FROM tbl_dict_actiontype
 WHERE     (:Id IS NULL OR col_id = :Id)
       AND (:CaseType IS NULL OR NVL (col_iscasetype, 0) = 1)
       AND (:PROCEDURE IS NULL OR NVL (col_isprocedure, 0) = 1)
       AND (:TaskType IS NULL OR NVL (col_istasktype, 0) = 1)
       AND (:Party IS NULL OR NVL (col_isparty, 0) = 1)
       AND (:DocType IS NULL OR NVL (col_isdoctype, 0) = 1)
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>