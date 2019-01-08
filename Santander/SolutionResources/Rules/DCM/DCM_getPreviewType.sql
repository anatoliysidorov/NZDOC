SELECT 
      a.ID AS ID,
      a.NAME AS NAME,
      a.TYPEID AS TYPEID,
      a.ICON AS ICON,
      a.TYPENAME AS TYPENAME
FROM (SELECT 
        c.col_id AS ID, 
        c.col_SUMMARY AS NAME, 
        c.col_caseid AS TYPEID, 
        ct.col_iconcode AS ICON, 
        ct.col_name AS TYPENAME
      FROM tbl_Case c
	  INNER JOIN TBL_DICT_CASESYSTYPE ct ON ct.col_id = c.COL_CASEDICT_CASESYSTYPE
      WHERE lower(:TYPE) = 'case'
            <%=IFNOTNULL(":PSEARCH", " and (lower(c.col_caseid) LIKE '%' || lower(:PSEARCH) || '%' OR lower(c.col_summary) LIKE lower('%' || :PSEARCH || '%'))")%>
            <%=IFNOTNULL(":CASETYPEID", " and c.COL_CASEDICT_CASESYSTYPE = :CASETYPEID")%>
      UNION ALL
      SELECT 
        t.col_id AS ID, 
        t.COL_NAME AS NAME, 
        NVL(t.col_taskid,'TASK-' ||TO_CHAR(t.col_id)) AS TYPEID, 
        tst.col_iconcode AS ICON, 
        tst.col_name AS TYPENAME
      FROM tbl_TASK t
      inner join  tbl_dict_tasksystype tst ON t.COL_TASKDICT_TASKSYSTYPE = tst.col_id
      WHERE lower(:TYPE) = 'task' 
		AND t.COL_PARENTID > 0
            <%=IFNOTNULL(":PSEARCH", " and (t.col_taskid like '%' || :PSEARCH || '%' OR lower(t.col_name) like lower('%' || :PSEARCH || '%'))")%>
      UNION ALL
      SELECT 
        e.COL_ID AS ID, 
        e.COL_NAME AS NAME, 
        NULL AS TYPEID, 
        NULL AS ICON, 
        pt.COL_NAME AS TYPENAME
      FROM tbl_externalparty e
      LEFT JOIN tbl_dict_partytype pt ON e.col_externalpartypartytype = pt.col_id
      WHERE lower(:TYPE) = 'externalparty'
            <%=IFNOTNULL(":PSEARCH", " and lower(e.col_name) like lower('%' || :PSEARCH || '%')")%>
    
) a
<%=IFNOTNULL(":COUNT", "WHERE ROWNUM <= :COUNT")%>
<%= IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1 ") %>

