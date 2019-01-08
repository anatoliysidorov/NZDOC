select
    t.id,
    t.name,
    t.isdeleted,
    t.isFolder,
    t.isGlobalResource,
    t.calcparentid,
    t.description,
    dbms_xmlgen.CONVERT(t.customdata.getStringVal()),
    t.doctype,
    t.url,
    t.ofDocument,
    f_getNameFromAccessSubject(t.createdby) as CreatedBy_Name,
    f_UTIL_getDrtnFrmNow(t.createddate) as CreatedDuration,
    f_getNameFromAccessSubject(t.modifiedby) as ModifiedBy_Name,
    f_UTIL_getDrtnFrmNow(t.modifieddate) as ModifiedDuration,
    t.isactualversion,
    t.versionindex,
    CASE
     WHEN NVL(docs.TASKID, 0) <> 0 THEN
      (select TASKSTATE_ISFINISH
         from vw_dcm_simpletask
        where id = docs.TASKID)
     WHEN NVL(docs.CASEID, 0) <> 0 THEN
      (select CASESTATE_ISFINISH
         from vw_dcm_simplecase
        where id = docs.CASEID)
     ELSE
      0
    END as STATE_ISFINISH
from
    (select
        vw_doc.id as id,
        vw_doc.name as name,
        vw_doc.isdeleted as isdeleted,
        vw_doc.isFolder as isFolder,
        vw_doc.isglobalresource as isGlobalResource,
        vw_doc.calcparentid as calcparentid,
        vw_doc.description as description,
        vw_doc.customdata as customdata,
        vw_doc.doctype as doctype,
        vw_doc.url as url,
        vw_doc.createdby as createdby,
        vw_doc.createddate as createddate,
        vw_doc.modifiedby as modifiedby,
        vw_doc.modifieddate as modifieddate,
        1 as isactualversion,
        NVL(vw_doc.versionindex,1) as versionindex,
        null as ofDocument
    from
        vw_doc_documents vw_doc
    where
        vw_doc.id = :documentid
    union all
    select
        doc_version.col_id as id,
        doc_version.col_name as name,
        doc_version.col_isdeleted as isdeleted,
        doc_version.col_isFolder as IsFolder,
        doc_version.col_isglobalresource as isGlobalResource,
        doc_version.col_parentid as calcparentid,
        doc_version.col_description as description,
        doc_version.col_customdata as customdata,
        doc_version.col_doctype as doctype,
        doc_version.col_url as url,
        doc_version.col_createdby as createdby,
        doc_version.col_createddate as createddate,
        doc_version.col_modifiedby as modifiedby,
        doc_version.col_modifieddate as modifieddate,
        0 as isactualversion,
        doc_version.col_versionindex as versionindex,
        doc_version.col_docversiondocid as ofDocument
    from
        tbl_doc_documentversion doc_version
    where
        doc_version.col_docversiondocid = :documentid) t
left join vw_doc_documents docs ON docs.id = :documentid
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>