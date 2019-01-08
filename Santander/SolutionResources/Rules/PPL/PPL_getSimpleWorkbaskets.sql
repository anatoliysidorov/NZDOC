WITH s AS
 (SELECT wb.col_id AS Id,
         wb.col_name AS Name,
         wb.col_code AS Code,
         NVL(cw.col_isdeleted, 0) AS IsDeleted,
         wb.col_caseworkerworkbasket AS Caseworker_Id,
         wb.col_workbasketexternalparty AS ExternalParty_Id,
         wb.col_workbasketteam AS Team_Id,
         wb.col_workbasketskill AS Skill_Id,
         wb.col_workbasketbusinessrole AS BusinessRole_Id,
         u.accesssubjectcode AS AccessSubjectCode,
         CASE
           WHEN NVL(cw.col_id, 0) > 0 THEN
            'Case Worker'
           WHEN NVL(wb.col_workbasketteam, 0) > 0 THEN
            'Team'
           WHEN NVL(wb.col_workbasketexternalparty, 0) > 0 THEN
            'External Party'
           WHEN NVL(wb.col_workbasketskill, 0) > 0 THEN
            'Skill'
           WHEN NVL(wb.col_workbasketbusinessrole, 0) > 0 THEN
            'Business Role'
           ELSE
            'Group Workbasket'
         END AS CalcType
    FROM tbl_ppl_workbasket wb
    LEFT JOIN tbl_dict_workbaskettype wbt
      ON wbt.col_id = wb.col_workbasketworkbaskettype
    LEFT JOIN tbl_ppl_caseworker cw
      ON (cw.col_id = wb.col_caseworkerworkbasket AND wbt.col_code = 'PERSONAL')
    LEFT JOIN vw_users u
      ON u.userid = cw.col_userid
   WHERE 1 = 1
    <%=IfNotNull(":WorkBasketType_Code", " AND lower(wbt.col_code) = lower(:WorkBasketType_Code)")%>
    <%=IfNotNull(":AccessSubjectCode", " AND u.accesssubjectcode = :AccessSubjectCode")%>
    <%=IfNotNull(":Name", " AND lower(wb.col_name) LIKE '%' || lower(:Name) || '%'")%>
    <%=IfNotNull(":IsDeleted", " AND nvl(cw.col_isdeleted, 0) = :IsDeleted")%>

   ORDER BY wb.col_name)

SELECT s.Id,
       s.Name,
       s.Code,
       s.IsDeleted,
       s.Caseworker_Id,
       s.ExternalParty_Id,
       s.Team_Id,
       s.Skill_Id,
       s.BusinessRole_Id,
       s.AccessSubjectCode,
       s.CalcType
  FROM s
 WHERE :Id IS NOT NULL AND s.id = :Id
UNION ALL
SELECT s.Id,
       s.Name,
       s.Code,
       s.IsDeleted,
       s.Caseworker_Id,
       s.ExternalParty_Id,
       s.Team_Id,
       s.Skill_Id,
       s.BusinessRole_Id,
       s.AccessSubjectCode,
       s.CalcType
  FROM s
 WHERE :Id IS NOT NULL AND s.id != :Id AND nvl(s.IsDeleted,0) = 0
UNION ALL
SELECT s.Id,
       s.Name,
       s.Code,
       s.IsDeleted,
       s.Caseworker_Id,
       s.ExternalParty_Id,
       s.Team_Id,
       s.Skill_Id,
       s.BusinessRole_Id,
       s.AccessSubjectCode,
       s.CalcType
  FROM s
 WHERE :Id IS NULL