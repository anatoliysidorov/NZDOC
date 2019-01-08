SELECT s.Id,
       s.CalcParentId,
       s.IsFolder,
       s.IsGlobalResource,
       s.Name,
       s.isDeleted,
       s.FolderOrder,
       s.URL,
       s.Description,
       dbms_xmlgen.CONVERT(s.CustomData.getClobVal()) AS CustomData,
       s.Doctype,
       s.DoctypeName,
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
        AS STATE_ISFINISH,
       CASE
          WHEN :isFolder = 1
          THEN
           CASE
              WHEN NVL (:Case_Id, 0) <> 0
              THEN
                 (SELECT COUNT(*)
                    FROM vw_doc_documents doc_count
                   WHERE doc_count.IsFolder = 0
                         AND doc_count.CalcParentId = s.Id
                         <%=IfNotNull(":Case_Id", " AND doc_count.caseid = :Case_Id")%>
                         <%=IfNotNull(":CaseType_Id", " AND doc_count.casetypeid = :CaseType_Id")%>
                         <%=IfNotNull(":Task_Id", " AND doc_count.taskid = :Task_Id")%>
                         <%=IfNotNull(":ExtParty_Id", " AND doc_count.extpartyid = :ExtParty_Id")%>
                         <%=IfNotNull(":Team_Id", " AND doc_count.teamid = :Team_Id")%>
                         <%=IfNotNull(":CaseWorker_Id", " AND doc_count.caseworkerid = :CaseWorker_Id")%>
                         <%=IfNotNull(":IsGlobalResource", " AND NVL (doc_count.isglobalresource,0) = :IsGlobalResource")%>
                 )
                 +
                 (SELECT COUNT(*)
                    FROM vw_doc_documents doc_count
                   WHERE doc_count.IsFolder = 0
                         AND doc_count.CalcParentId = s.Id
                         <%=IfNotNull(":Case_Id", " AND doc_count.casetypeid = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = :Case_Id)")%>
                 )
                 +
                 (SELECT COUNT(*)
                    FROM vw_doc_documents doc_count
                   WHERE doc_count.IsFolder = 0
                         AND doc_count.CalcParentId = s.Id
                         <%=IfNotNull(":Case_Id", " AND :Task_Id IS NOT NULL")%>
                 )
             ELSE
                 (SELECT COUNT(*)
                    FROM vw_doc_documents doc_count
                   WHERE doc_count.IsFolder = 0
                         AND doc_count.CalcParentId = s.Id
                         <%=IfNotNull(":Case_Id", " AND doc_count.caseid = :Case_Id")%>
                         <%=IfNotNull(":CaseType_Id", " AND doc_count.casetypeid = :CaseType_Id")%>
                         <%=IfNotNull(":Task_Id", " AND doc_count.taskid = :Task_Id")%>
                         <%=IfNotNull(":ExtParty_Id", " AND doc_count.extpartyid = :ExtParty_Id")%>
                         <%=IfNotNull(":Team_Id", " AND doc_count.teamid = :Team_Id")%>
                         <%=IfNotNull(":CaseWorker_Id", " AND doc_count.caseworkerid = :CaseWorker_Id")%>
                         <%=IfNotNull(":IsGlobalResource", " AND NVL (doc_count.isglobalresource,0) = :IsGlobalResource")%>
                 )                     
             END

          ELSE
             0
       END        
         AS DocumentCount
  FROM (SELECT -1 AS Id,
               0 AS CalcParentId,
               1 AS IsFolder,
               0 AS IsGlobalResource,
               CAST ('Home folder' AS NVARCHAR2 (30)) AS Name,
               0 AS isDeleted,
               1 AS FolderOrder,
               NULL AS URL,
               NULL AS Description,
               NULL AS CustomData,
               NULL AS Doctype,
               NULL AS DoctypeName,
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
         WHERE 1=1 
             <%=IfNotNull(":Case_Id", " AND doc.caseid = :Case_Id")%>
             <%=IfNotNull(":CaseType_Id", " AND doc.casetypeid = :CaseType_Id")%>
             <%=IfNotNull(":Task_Id", " AND doc.taskid = :Task_Id")%>
             <%=IfNotNull(":ExtParty_Id", " AND doc.extpartyid = :ExtParty_Id")%>
             <%=IfNotNull(":Team_Id", " AND doc.teamid = :Team_Id")%>
             <%=IfNotNull(":CaseWorker_Id", " AND doc.caseworkerid = :CaseWorker_Id")%>
             <%=IfNotNull(":DocSysTypeCode", " AND UPPER (doc.docsystypecode) = :DocSysTypeCode")%>
             <%=IfNotNull(":WorkItem_Id", " AND doc.workitemid = :WorkItem_Id")%>
             <%=IfNotNull(":Container_Id", " AND doc.containerid = :Container_Id")%>
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
         WHERE :Case_Id IS NOT NULL 
           AND :Task_Id IS NULL
             <%=IfNotNull(":Case_Id", "AND doc.casetypeid = (SELECT col_casedict_casesystype FROM tbl_case WHERE col_id = :Case_Id)")%>
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
         WHERE :Case_Id IS NOT NULL 
             <%=IfNotNull(":Case_Id", "AND :Task_Id IS NOT NULL AND doc.taskid = :Task_Id")%>
       ) s
 WHERE 1=1
         <%=IfNotNull(":hideHomeFolder", " AND s.id <> -1")%>
         <%=IfNotNull(":id", " AND s.id = :id")%>
         <%=IfNotNull(":isFolder", " AND s.isfolder = :isFolder")%>
         <%=IfNotNull(":parentId", "AND s.calcparentid = :parentId")%>
         <%=IfNotNull(":IsGlobalResource", " AND s.isglobalresource = :IsGlobalResource")%>

<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>
