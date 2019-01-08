    SELECT s1.Child_Id AS Id,
           s1.Parent_Id AS Parent_Id,
           s1.ParentId AS ParentId,
           s1.ParentName AS ParentName,
           s1.Child_Id AS Child_Id,
           s1.ChildId AS ChildId,
           s1.ChildName AS ChildName,
           CONNECT_BY_ISCYCLE IsCycle,
           SYS_CONNECT_BY_PATH(NVL(s1.ChildName, 'Unknown'), '<-') AS PATH,
           s1.ChildName AS CaseWorker_Name,
           s1.ChildPhoto AS CaseWorker_Photo,
           s1.ChildEmail AS CaseWorker_Email,
           s1.ChildPosition AS CaseWorker_Position,
           s1.OrgChartId AS OrgChartId
      FROM (SELECT ocm.col_caseworkerparent AS Parent_Id,
                   cwp.id AS ParentId,
                   cwp.name AS ParentName,
                   ocm.col_caseworkerchild AS Child_Id,
                   cwc.id AS ChildId,
                   cwc.name AS ChildName,
                   cwc.photo AS ChildPhoto,
                   cwc.email AS ChildEmail,
                   cwc.Position AS ChildPosition,
                   ocm.col_orgchartorgchartmap AS OrgChartId
              FROM tbl_ppl_orgchartmap ocm
                   LEFT JOIN vw_ppl_caseworkersusers cwc
                      ON ocm.col_caseworkerchild = cwc.id
                   LEFT JOIN vw_ppl_caseworkersusers cwp
                      ON ocm.col_caseworkerparent = cwp.id
             WHERE ocm.col_orgchartorgchartmap = :OrgChart_Id) s1
START WITH s1.Parent_Id IS NULL
CONNECT BY NOCYCLE PRIOR s1.Child_Id = s1.Parent_Id
  ORDER BY s1.ChildName