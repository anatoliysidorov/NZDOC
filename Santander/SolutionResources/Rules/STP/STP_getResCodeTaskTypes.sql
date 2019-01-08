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
       r.col_theme AS Theme,
       (SELECT list_collect(CAST(COLLECT(To_char(tt.col_code) ORDER BY to_char(tt.col_code)) AS split_tbl), ', ', 1) AS ids
          FROM tbl_dict_tasksystype tt
          INNER JOIN tbl_tasksystyperesolutioncode ttrc
            ON tt.col_id = ttrc.col_tbl_dict_tasksystype
          WHERE r.col_id = ttrc.col_tbl_stp_resolutioncode) TaskTypeCodes
       
FROM tbl_stp_resolutioncode r
WHERE NVL(r.col_isdeleted, 0) = 0
    AND LOWER(r.col_type) = 'task'
    AND (:ID IS NULL OR (:ID IS NOT NULL AND r.col_Id = :ID))
    AND (:Code IS NULL OR (:Code IS NOT NULL AND lower(r.col_Code) = lower(:Code)))
