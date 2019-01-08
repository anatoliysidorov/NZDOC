SELECT col_id                 AS id,
       col_docfolderdocfolder AS parentfolder, 
       col_name               AS name, 
       col_createdby          AS createdby, 
       col_createddate        AS createddate, 
       col_isdeleted          AS isDeleted, 
       'CASETYPE'             AS belongsto, 
       'FOLDER'               AS rawtype,
	   level	             AS FolderLevel,
	   Lpad(col_name,Length(col_name) + LEVEL * 3 - 3,'-') AS dname
FROM   tbl_docfolder 
WHERE  col_docfoldercasesystype = :CaseTypeId 
	AND (:IsDeleted IS NULL OR NVL(col_isDeleted,0) = :IsDeleted)
CONNECT BY PRIOR col_id = col_docfolderdocfolder 
START WITH NVL(col_docfolderdocfolder,0) = 0
ORDER SIBLINGS BY col_name