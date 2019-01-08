WITH pr AS (
	SELECT
	(SELECT COUNT(*) 
	FROM TBL_LOC_TRANSLATION t
	WHERE t.COL_VALUE IS NOT NULL AND (:LANGID IS NULL OR t.COL_LANGID = :LANGID) AND LENGTH(TRIM(t.COL_VALUE)) != 0) AS TOTAL_COMPLETED,
	--
	(SELECT SUM(pf.COL_PLURALFORMS) 
	FROM TBL_LOC_PLURALFORM pf
	INNER JOIN TBL_LOC_LANGUAGES lng ON lng.COL_PLURALFORMID = pf.COL_ID
	WHERE (:LANGID IS NULL OR lng.COL_ID = :LANGID)) AS SUM_PLURALFORMS,
	--
	((SELECT SUM(tlp.COL_PLURALFORMS) 
	FROM TBL_LOC_PLURALFORM tlp
	INNER JOIN TBL_LOC_LANGUAGES tll ON tll.COL_PLURALFORMID = tlp.COL_ID
	WHERE (:LANGID IS NULL OR tll.COL_ID = :LANGID)) *
	(SELECT COUNT(tlk.COL_ID) 
	FROM TBL_LOC_KEY tlk 
	WHERE tlk.COL_ISPLURAL = 1)) AS TOTAL_PLURAL,
	--	
	((SELECT count(*) 
	FROM TBL_LOC_LANGUAGES tll
	WHERE (:LANGID IS NULL OR tll.COL_ID = :LANGID)) *
    (SELECT COUNT(tlk.COL_ID) 
	FROM TBL_LOC_KEY tlk 
	WHERE nvl(tlk.COL_ISPLURAL,0) = 0)) AS TOTAL_NOT_PLURAL,

	(SELECT COUNT(*) 
	FROM TBL_LOC_LANGUAGES tll
	WHERE (:LANGID IS NULL OR tll.COL_ID = :LANGID)) AS LANGUAGES_COUNT

	FROM DUAL),

	cnt AS (
	SELECT tlt.COL_KEYID AS KEYID,
		COUNT(*) AS KEY_COMPLETE
	FROM TBL_LOC_TRANSLATION tlt
	WHERE tlt.COL_VALUE IS NOT NULL AND (:LANGID IS NULL OR tlt.COL_LANGID = :LANGID) AND LENGTH(TRIM(tlt.COL_VALUE)) != 0
	GROUP BY tlt.COL_KEYID)

  SELECT * FROM (
    SELECT	tbl.COL_ID AS ID,
      tbl.COL_NAME AS NAME,
      tbl.COL_CONTEXT AS CONTEXT,
      tbl.COL_DESCRIPTION AS DESCRIPTION,
      tbl.COL_ISDELETED AS IsDeleted,
      tbl.COL_ISNEW AS IsNew,
      tbl.COL_ISPLURAL AS IsPlural,
      tbl.COL_NAMESPACEID AS NamespaceID,
      tbl2.COL_NAME AS NamespaceName,
      cnt.KEY_COMPLETE,
      tbl.COL_CREATEDDATE AS CREATEDDATE,
      --
      ROUND((NVL(cnt.KEY_COMPLETE, 0)) / (CASE WHEN tbl.COL_ISPLURAL = 1 THEN pr.SUM_PLURALFORMS ELSE pr.LANGUAGES_COUNT END), 3) AS KEY_PROGRESS,
      ROUND((pr.TOTAL_COMPLETED) / (pr.TOTAL_PLURAL + pr.TOTAL_NOT_PLURAL), 3) AS GENERAL_PROGRESS, 
      --
      F_GETNAMEFROMACCESSSUBJECT(tbl.COL_CREATEDBY) AS CreatedBy_Name,
      F_UTIL_GETDRTNFRMNOW(tbl.COL_CREATEDDATE) AS CreatedDuration,
      F_GETNAMEFROMACCESSSUBJECT(tbl.COL_MODIFIEDBY) AS ModifiedBy_Name,
      F_UTIL_GETDRTNFRMNOW(tbl.COL_MODIFIEDDATE) AS ModifiedDuration,
       dbms_xmlgen.CONVERT(F_LOC_getTranslationXML(tbl.COL_ID, :LANGID)) AS Translation
    FROM TBL_LOC_KEY tbl
      LEFT JOIN TBL_LOC_NAMESPACE tbl2 ON tbl.COL_NAMESPACEID = tbl2.COL_ID
      LEFT JOIN pr ON 1 = 1
      LEFT JOIN cnt ON cnt.KEYID = tbl.COL_ID
    ) q
    WHERE (:ID IS NULL OR q.ID = :ID)
      AND (:KEYNAME IS NULL OR LOWER(q.NAME) LIKE '%' || LOWER(:KEYNAME) || '%')
      AND (:Key IS NULL OR LOWER(q.NAME) LIKE '%' || LOWER(:Key) || '%')
      AND (:Context IS NULL OR LOWER(q.CONTEXT) LIKE '%' || LOWER(:Context) || '%')
      AND (:Status IS NULL OR 
          (:Status = 'NEW' AND NVL(q.IsNew, 0) = 1) OR
          (:Status = 'DELETED' AND NVL(q.IsDeleted, 0) = 1))
      AND (NVL(:Plural, 0) = 0 OR q.IsPlural = 1)
      AND (:Namespace IS NULL OR q.NamespaceID IN (SELECT COLUMN_VALUE FROM TABLE(ASF_SPLIT(:Namespace, ','))))
      AND (:Description IS NULL OR LOWER(q.DESCRIPTION) LIKE '%' || LOWER(:Description) || '%')
      AND (:Progress IS NULL OR q.KEY_PROGRESS = :Progress)
      AND (:CreatedDateStart IS NULL OR TRUNC(q.CREATEDDATE) >= TRUNC(TO_DATE(TO_CHAR(:CreatedDateStart))))
      AND (:CreatedDateEnd IS NULL OR TRUNC(q.CREATEDDATE) <= TRUNC(TO_DATE(TO_CHAR(:CreatedDateEnd))))
<%=Sort("@SORT@","@DIR@")%>