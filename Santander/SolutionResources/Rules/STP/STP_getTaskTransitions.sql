SELECT ct.col_id AS ID,
       ct.col_name AS NAME,
       ct.col_description AS Description,
       ct.col_code AS code,
       ct.col_manualonly AS manualonly,
       ss.col_id AS source_id,
       ss.col_code AS source_code,
       ss.col_activity AS source_activity,
       ss.col_name AS source_name,
       st.col_id AS target_id,
       st.col_code AS target_code,
       st.col_activity AS target_activity,
       st.col_name AS target_name,
       ss.col_name || ' to ' || st.col_name AS calc_name,
       f_getNameFromAccessSubject(ct.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(ct.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(ct.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(ct.col_modifiedDate) AS ModifiedDuration
  FROM tbl_dict_tasktransition ct
       LEFT JOIN tbl_dict_taskstate ss
          ON (ct.col_sourcetasktranstaskstate = ss.col_id)
       LEFT JOIN tbl_dict_taskstate st
          ON (ct.col_targettasktranstaskstate = st.col_id)
 WHERE (:Id IS NULL OR ct.col_id = :Id)
<%=Sort("@SORT@","@DIR@")%> 