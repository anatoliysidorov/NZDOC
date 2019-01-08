SELECT s.Id,
       s.CalcParentId,
       s.IsFolder,
       s.IsGlobalResource,
       s.Name,
       s.isDeleted,
       s.FolderOrder,
       s.URL,
       s.Description,
       s.CustomData,
       s.Doctype,
       s.DoctypeName,
       s.DocumentCount,
       s.CreatedBy_Name,
       s.CreatedDuration,
       s.ModifiedBy_Name,
       s.ModifiedDuration,
       s.IsEditable,
       s.VersionIndex,
       s.DocSysTypeId AS DocSysTypeId,
       s.WorkitemId AS WorkitemId,
       s.ContainerId AS ContainerId,
       s.IsPrimary AS IsPrimary,
       s.DocFormat AS DocFormat,
       s.ContainerFrom AS ContainerFrom,
       s.ContainerTo AS ContainerTo,
       s.WorkbasketId AS WorkbasketId,
       CASE
          WHEN NVL (:Task_Id, 0) <> 0
          THEN
             (SELECT MAX(TASKSTATE_ISFINISH)
                FROM vw_dcm_simpletask
               WHERE id = :Task_Id)
          WHEN NVL (:Case_Id, 0) <> 0
          THEN
             (SELECT CASESTATE_ISFINISH
                FROM vw_dcm_simplecase
               WHERE id = :Case_Id)
          ELSE
             0
       END
          AS STATE_ISFINISH
  FROM (SELECT -1 AS Id,
               0 AS CalcParentId,
               1 AS IsFolder,
               NULL AS IsGlobalResource,
               CAST ('Home folder' AS NVARCHAR2 (30)) AS Name,
               0 AS isDeleted,
               1 AS FolderOrder,
               NULL AS URL,
               NULL AS Description,
               NULL AS CustomData,
               NULL AS Doctype,
               NULL AS DoctypeName,
               NULL AS DocumentCount,
               NULL AS CreatedBy_Name,
               NULL AS CreatedDuration,
               NULL AS ModifiedBy_Name,
               NULL AS ModifiedDuration,
               0 AS IsEditable,
               NULL AS VersionIndex,
               NULL AS DocSysTypeId,
               NULL AS WorkitemId,
               NULL AS ContainerId,
               NULL AS IsPrimary,
               NULL AS DocFormat,
               NULL AS ContainerFrom,
               NULL AS ContainerTo,
               NULL AS WorkbasketId
          FROM DUAL
        UNION ALL
        SELECT doc.id AS ID,
               doc.calcparentid AS CalcParentId,
               doc.isfolder AS IsFolder,
               NVL (doc.IsGlobalResource, 0) AS IsGlobalResource,
               doc.name AS Name,
               doc.isdeleted AS isDeleted,
               doc.folderorder AS FolderOrder,
               doc.url AS URL,
               doc.description AS Description,
               doc.customdata AS CustomData,
               doc.doctype AS Doctype,
               doc.doctypename AS DoctypeName,
               CASE
                  WHEN :isFolder = 1
                  THEN
                     (SELECT COUNT (*)
                        FROM vw_doc_documents doc_count
                       WHERE     (:CaseType_Id IS NULL OR doc_count.casetypeid = :CaseType_Id)
                             AND (:Case_Id IS NULL
                                  OR (   :Task_Id IS NOT NULL
                                      OR doc_count.caseid = :Case_Id
                                      OR doc_count.casetypeid = (SELECT col_casedict_casesystype
                                                                   FROM tbl_case
                                                                  WHERE col_id = :Case_Id)))
                             AND (:Task_Id IS NULL OR doc_count.taskid = :Task_Id)
                             AND (:ExtParty_Id IS NULL OR doc_count.extpartyid = :ExtParty_Id)
                             AND (:Team_Id IS NULL OR doc_count.teamid = :Team_Id)
                             AND (:CaseWorker_Id IS NULL OR doc_count.caseworkerid = :CaseWorker_Id)
                             AND (:IsGlobalResource IS NULL OR NVL (doc_count.IsGlobalResource, 0) = :IsGlobalResource)
                             AND doc_count.IsFolder = 0
                             AND doc_count.CalcParentId = doc.id)
                  ELSE
                     0
               END
                  AS DocumentCount,
               f_getNameFromAccessSubject (doc.createdby) AS CreatedBy_Name,
               f_UTIL_getDrtnFrmNow (doc.createddate) AS CreatedDuration,
               f_getNameFromAccessSubject (doc.modifiedby) AS ModifiedBy_Name,
               f_UTIL_getDrtnFrmNow (doc.modifieddate) AS ModifiedDuration,
               CASE WHEN (:Case_Id IS NOT NULL AND doc.casetypeid IS NOT NULL) THEN 0 ELSE 1 END AS IsEditable,
               CASE WHEN doc.isfolder = 0 THEN NVL (doc.VersionIndex, 1) ELSE NULL END AS VersionIndex,
               doc.DocSysTypeId AS DocSysTypeId,
               doc.WorkItemId AS WorkitemId,
               doc.ContainerId AS ContainerId,
               doc.IsPrimary AS IsPrimary,
               doc.ContainerTypeName AS DocFormat,
               doc.ContainerFrom AS ContainerFrom,
               doc.ContainerTo AS ContainerTo,
               doc.WorkbasketId AS WorkbasketId
          FROM vw_doc_documents doc
         WHERE     (:CaseType_Id IS NULL OR doc.casetypeid = :CaseType_Id)
               AND (:Case_Id IS NULL
                    OR (   :Task_Id IS NOT NULL
                        OR doc.caseid = :Case_Id
                        OR doc.casetypeid = (SELECT col_casedict_casesystype
                                               FROM tbl_case
                                              WHERE col_id = :Case_Id)))
               AND (:Task_Id IS NULL OR doc.taskid = :Task_Id)
               AND (:ExtParty_Id IS NULL OR doc.extpartyid = :ExtParty_Id)
               AND (:Team_Id IS NULL OR doc.teamid = :Team_Id)
               AND (:CaseWorker_Id IS NULL OR doc.caseworkerid = :CaseWorker_Id)
               AND (:IsGlobalResource IS NULL OR NVL (doc.IsGlobalResource, 0) = :IsGlobalResource)
               AND (:DocSysTypeCode IS NULL OR UPPER (doc.DocSysTypeCode) = :DocSysTypeCode)
               AND (:WorkItem_Id IS NULL OR doc.WorkItemId = :WorkItem_Id)
               AND (:Container_Id IS NULL OR doc.ContainerId = :Container_Id)
               AND (   NVL (:CaseType_Id, 0) <> 0
                    OR NVL (:Case_Id, 0) <> 0
                    OR NVL (:Task_Id, 0) <> 0
                    OR NVL (:ExtParty_Id, 0) <> 0
                    OR NVL (:Team_Id, 0) <> 0
                    OR NVL (:CaseWorker_Id, 0) <> 0
                    OR NVL (:IsGlobalResource, 0) <> 0
                    OR NVL (:WorkItem_Id, 0) <> 0
                    OR NVL (:Container_Id, 0) <> 0
                    OR NVL (:id, 0) <> 0)) s
 WHERE     (:id IS NULL OR s.id = :id)
       AND (:parentId IS NULL OR s.CalcParentId = :parentId)
       AND (:isFolder IS NULL OR s.IsFolder = :isFolder)
       AND (:hideHomeFolder IS NULL OR s.id <> -1)


/*        SELECT doc_doc.*
          FROM  tbl_doc_document doc_doc 
           LEFT JOIN tbl_doc_docCase doc_DocCase
          ON doc_doc.col_id = doc_DocCase.col_DocCaseDocument
          where 
          doc_DocCase.COL_DOCCASECASE = :Case_Id*/