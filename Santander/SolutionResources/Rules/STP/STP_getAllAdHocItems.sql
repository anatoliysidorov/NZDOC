SELECT   ROWNUM AS id,
         ut.item_type,
         ut.item_type_name,
         ut.item_id,
         ut.item_name,
         ut.isdeleted,
		 ut.item_code
FROM    (SELECT 'TASKSYSTYPE' AS item_type,
                 'Task Type' AS item_type_name,
				 tt.col_code AS item_code,
                 tt.col_id AS item_id,
                 tt.col_name AS item_name,
                 NVL(tt.col_isdeleted,0) AS isdeleted
         FROM    tbl_dict_tasksystype tt
         UNION ALL
         SELECT 'PROCEDURE' AS item_type,
                'Procedure' AS item_type_name,
				pr.col_code AS item_code,
                pr.col_id AS item_id,
                pr.col_name AS item_name,
                NVL(pr.col_isdeleted,0) AS isdeleted
         FROM   tbl_procedure pr) ut
WHERE   (:isdeleted IS NULL
         OR ut.isdeleted = :isdeleted)
ORDER BY ut.item_type ASC,LOWER(item_name) ASC