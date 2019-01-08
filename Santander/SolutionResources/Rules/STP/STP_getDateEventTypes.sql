SELECT dt.COL_ID AS ID,
       dt.COL_NAME AS NAME,
       dt.COL_CODE AS CODE,
       dt.COL_TYPE AS TYPE,
       dt.COL_ISDELETED AS ISDELETED
FROM TBL_DICT_DATEEVENTTYPE dt
WHERE (dt.COL_TYPE = :TYPE OR (:TYPE IS NULL AND dt.COL_TYPE IS NOT NULL))
<%=IfNotNull("@ExcludedTypes@", " AND dt.COL_CODE NOT IN (select column_value from table(asf_split('@ExcludedTypes@',','))) ")%>