DECLARE 
    v_input  XMLTYPE; 
    v_result NUMBER; 
    v_cur    SYS_REFCURSOR; 
BEGIN 
    IF :Input IS NULL THEN 
      v_input := Xmltype('<CustomData><Attributes></Attributes></CustomData>'); 
    ELSE 
      v_input := Xmltype(:Input); 
    END IF; 

    OPEN v_cur FOR 
      SELECT ROWNUM AS id, 
             item_type, 
             item_id, 
             item_name, 
             item_description 
      FROM   (SELECT 'TASKSYSTYPE'       AS item_type, 
                     tst.col_id          AS item_id, 
                     tst.col_name        AS item_name, 
                     tst.col_description AS item_description, 
                     NULL                AS Ext_Id 
              FROM   tbl_stp_availableadhoc aah 
                     inner join tbl_dict_tasksystype tst 
							ON (:Case_Id IS NULL AND Aah.col_tasksystype = tst.col_id) 
								OR (:Case_Id IS NOT NULL AND Aah.col_tasksystype = tst.col_id AND Aah.col_casesystype IN 
									(
										SELECT tbl_case.col_casedict_casesystype 
										FROM   tbl_case 
										WHERE  col_id = :Case_Id
									) 
								) 
              WHERE  tst.col_isdeleted = 0 
                      OR tst.col_isdeleted IS NULL 
              UNION ALL 
              SELECT 'PROCEDURE'        AS item_type, 
                     tp.col_id          AS item_id, 
                     tp.col_name        AS item_name, 
                     tp.col_description AS item_description, 
                     tp.col_id          AS Ext_Id 
              FROM   tbl_stp_availableadhoc aah 
                     inner join tbl_procedure tp 
							ON (:Case_Id IS NULL AND tp.col_id = Aah.col_procedure) 
								OR (:Case_Id IS NOT NULL AND tp.col_id = Aah.col_procedure AND Aah.col_casesystype IN 
									(
										SELECT tbl_case.col_casedict_casesystype 
										FROM   tbl_case 
										WHERE  col_id = :Case_Id
									) 
								) 
              WHERE  ( tp.col_isdeleted = 0 
                        OR tp.col_isdeleted IS NULL )) 
      ORDER  BY item_type ASC, 
                item_name ASC; 

    :cur_item := v_cur; 
END; 