SELECT r.col_id AS Id,
       r.col_name AS NAME,
       r.col_code AS Code,
       r.col_description AS Description,
       r.col_isdeleted AS IsDeleted,
       r.col_type AS TYPE,
       r.col_textstyle AS TextStyle,
       r.col_cellstyle AS CellStyle,
       r.col_rowstyle AS RowStyle,
       r.col_iconcode AS IconCode,
       r.col_theme AS Theme
       
FROM tbl_stp_resolutioncode r
    INNER JOIN tbl_tasksystyperesolutioncode tstrc ON r.col_id = tstrc.col_tbl_stp_resolutioncode
    INNER JOIN tbl_dict_tasksystype tst ON tst.col_id = tstrc.col_tbl_dict_tasksystype AND tst.col_code = :TaskTypeCode
  
WHERE NVL(r.col_isdeleted, 0) = 0
    AND LOWER(r.col_type) = 'task'
<%=Sort("@SORT@","@DIR@")%>