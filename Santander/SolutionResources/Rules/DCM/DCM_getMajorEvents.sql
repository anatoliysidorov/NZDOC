SELECT dt.col_id AS ID,
       F_getnamefromaccesssubject(dt.col_performedby) AS PerformedBy_Name,
       F_util_getdrtnfrmnow(dt.col_datevalue) AS PerformedDuration,
       dt.col_datevalue AS PerformedDate,
       det.col_code AS dateeventtype_Code,
       det.col_name AS dateeventtype_Name,
       -------------------------------------------
       f_getNameFromAccessSubject(dt.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(dt.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(dt.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(dt.col_modifiedDate) AS ModifiedDuration
       -------------------------------------------
  FROM tbl_dateevent dt 
LEFT JOIN tbl_dict_dateeventtype det ON det.col_id = dt.col_dateevent_dateeventtype
 WHERE (NVL(:Task_Id, 0) = 0 AND dt.col_dateeventcase = :Case_Id) OR (dt.col_dateeventtask = :Task_Id)
<%=Sort("@SORT@","@DIR@")%>