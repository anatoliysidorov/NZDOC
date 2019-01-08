  SELECT cw.Id,
         cw.CaseWorker_Name,
         cw.CaseWorker_Photo,
         cw.CaseWorker_Email,
         cw.CaseWorker_Position,
         (SELECT col_teamorgchart
            FROM tbl_ppl_orgchart
           WHERE col_id = :OrgChart_Id)
            AS Team_Id
    FROM (SELECT cw.id AS Id,
                 cw.name AS CaseWorker_Name,
                 cw.photo AS CaseWorker_Photo,
                 cw.email AS CaseWorker_Email,
                 cw.position AS CaseWorker_Position
            FROM vw_ppl_activecaseworkersusers cw
           WHERE (((SELECT col_teamorgchart
                      FROM tbl_ppl_orgchart
                     WHERE col_id = :OrgChart_Id)
                      IS NULL)
                  AND (cw.id NOT IN (SELECT t.col_caseworkerchild
                                       FROM tbl_ppl_orgchartmap t
                                      WHERE t.col_orgchartorgchartmap = :OrgChart_Id)
                       AND cw.id NOT IN (SELECT t.col_caseworkerparent
                                           FROM tbl_ppl_orgchartmap t
                                          WHERE t.col_orgchartorgchartmap = :OrgChart_Id)))
                 OR (((SELECT col_teamorgchart
                         FROM tbl_ppl_orgchart
                        WHERE col_id = :OrgChart_Id)
                         IS NOT NULL)
                     AND (cw.id IN (SELECT cwi.col_tm_ppl_caseworker
                                      FROM tbl_CaseWorkerTeam cwi
                                     WHERE cwi.col_tbl_ppl_team = (SELECT col_teamorgchart
                                                                     FROM tbl_ppl_orgchart
                                                                    WHERE col_id = :OrgChart_Id)
                                    MINUS
                                    (SELECT t.col_caseworkerchild
                                       FROM tbl_ppl_orgchartmap t
                                      WHERE t.col_orgchartorgchartmap = :OrgChart_Id
                                     UNION
                                     SELECT t.col_caseworkerparent
                                       FROM tbl_ppl_orgchartmap t
                                      WHERE t.col_orgchartorgchartmap = :OrgChart_Id))))) cw
ORDER BY cw.CaseWorker_Name ASC