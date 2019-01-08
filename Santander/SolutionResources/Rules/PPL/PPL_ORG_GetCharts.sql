SELECT col_id AS id,
       col_code AS code,
       col_description AS description,
       col_name AS name,
       --col_config AS config
       dbms_xmlgen.CONVERT(col_config) AS config
  FROM tbl_ppl_orgchart
 WHERE ((:Team_Id IS NOT NULL OR :CaseSysType_Id IS NOT NULL AND :OrgChart_Id IS NULL)
        <%= IfNotNull(":Team_Id", "AND (col_teamorgchart = :Team_Id)") %>
        <%= IfNotNull(":CaseSysType_Id", "AND (col_casesystypeorgchart = :CaseSysType_Id)") %>)
       --OR (:OrgChart_Id IS NULL AND :Team_Id IS NULL AND :CaseSysType_Id IS NULL AND col_casesystypeorgchart IS NULL AND col_teamorgchart IS NULL)
       OR (:OrgChart_Id IS NOT NULL AND col_id = :OrgChart_Id)
       OR (:IsPrimary IS NOT NULL AND COL_ISPRIMARY = :IsPrimary)
       