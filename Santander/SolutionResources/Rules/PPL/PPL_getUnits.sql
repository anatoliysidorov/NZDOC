SELECT units.*
  FROM (SELECT s.col_id AS id,
                s.col_name AS name,
                s.col_code AS code,
                TO_CHAR(s.col_description) AS description,
                'SKILL' AS objecttype,
                s.col_skillaccesssubject AS accesssubjectid,
                NULL AS groupid,
                NULL AS groupname,
                NULL AS owner,
                NULL AS ownername,
                NULL AS TASKPULLERFN,
                NULL AS CASEPULLERFN,
                NULL AS CASETASKPULLERFN,
                NULL AS ROLEID,
                NULL AS ROLENAME,
                --BASIC
                f_getNameFromAccessSubject(s.col_createdBy) as CreatedBy_Name,
                f_UTIL_getDrtnFrmNow(s.col_createdDate) AS CreatedDuration,
                f_getNameFromAccessSubject(s.col_modifiedBy) as ModifiedBy_Name,
                f_UTIL_getDrtnFrmNow(s.col_modifiedDate) AS ModifiedDuration
          FROM tbl_ppl_skill s
        UNION ALL
        SELECT t.col_id AS id,
               t.col_name AS name,
               t.col_code AS code,
               TO_CHAR(t.col_description) AS description,
               'TEAM' AS objecttype,
               t.col_teamaccesssubject AS accesssubjectid,
               t.col_groupid AS groupid,
               ag.NAME AS groupname,
               NULL AS owner,
               NULL AS ownername,
               NULL AS TASKPULLERFN,
               NULL AS CASEPULLERFN,
               NULL AS CASETASKPULLERFN,
               NULL AS ROLEID,
               NULL AS ROLENAME,
                --BASIC
                f_getNameFromAccessSubject(t.col_createdBy) as CreatedBy_Name,
                f_UTIL_getDrtnFrmNow(t.col_createdDate) AS CreatedDuration,
                f_getNameFromAccessSubject(t.col_modifiedBy) as ModifiedBy_Name,
                f_UTIL_getDrtnFrmNow(t.col_modifiedDate) AS ModifiedDuration
          FROM tbl_ppl_team t
          LEFT JOIN VW_PPL_APPBASEGROUP ag ON t.col_groupid = ag.id
        UNION ALL
        SELECT b.col_id AS id,
               b.col_name AS name,
               b.col_code AS code,
               TO_CHAR(b.col_description) AS description,
               'BUSINESSROLE' AS objecttype,
               b.col_businessroleaccesssubject AS accesssubjectid,
               NULL AS groupid,
               NULL AS groupname,
               NULL AS owner,
               NULL AS ownername,
               NULL AS TASKPULLERFN,
               NULL AS CASEPULLERFN,
               NULL AS CASETASKPULLERFN,
               b.col_roleid AS ROLEID,
               (Select TRIM(SUBSTR(rolename, 1, INSTR(rolename,'(', 1,1)-1)) From vw_role temp Where temp.ROLEID = b.col_roleid) AS ROLENAME,
                --BASIC
                f_getNameFromAccessSubject(b.col_createdBy) as CreatedBy_Name,
                f_UTIL_getDrtnFrmNow(b.col_createdDate) AS CreatedDuration,
                f_getNameFromAccessSubject(b.col_modifiedBy) as ModifiedBy_Name,
                f_UTIL_getDrtnFrmNow(b.col_modifiedDate) AS ModifiedDuration
          FROM tbl_ppl_businessrole b
        UNION ALL
        SELECT w.id AS id,
               w.name AS name,
               w.code AS code,
               TO_CHAR(w.description) AS description,
               'WORKBASKET' AS objecttype,
               NULL AS accesssubjectid,
               NULL AS groupid,
               NULL AS groupname,
               w.wbowner AS owner,
               w.wbownername AS ownername,
               w.TASKPULLERFN AS TASKPULLERFN,
               w.CASEPULLERFN AS CASEPULLERFN,
               w.CASETASKPULLERFN AS CASETASKPULLERFN,
               NULL AS ROLEID,
               NULL AS ROLENAME,
                --BASIC
                f_getNameFromAccessSubject(w.CreatedBy) as CreatedBy_Name,
                f_UTIL_getDrtnFrmNow(w.CreatedDate) AS CreatedDuration,
                f_getNameFromAccessSubject(w.ModifiedBy) as ModifiedBy_Name,
                f_UTIL_getDrtnFrmNow(w.ModifiedDate) AS ModifiedDuration
          FROM (SELECT wb.col_id AS id,
                       wb.col_name AS name,
                       wb.col_code AS code,
                       wb.col_description AS description,
                       wb.col_caseworkerworkbasket AS wbowner,
                       NVL(cw.name, cw.firstname || ' ' || cw.lastname) AS wbownername,
                       wb.COL_PROCESSORCODE AS TASKPULLERFN,
                       wb.COL_PROCESSORCODE2 AS CASEPULLERFN,
                       wb.COL_PROCESSORCODE3 AS CASETASKPULLERFN,
                       wb.col_CreatedDate as CreatedDate,
                       wb.col_ModifiedDate as ModifiedDate,
                       wb.col_ModifiedBy as ModifiedBy,
                       wb.col_CreatedBy as CreatedBy
                  FROM tbl_ppl_workbasket wb 
                  LEFT JOIN tbl_dict_workbaskettype wbt ON wb.col_workbasketworkbaskettype = wbt.col_id
                  LEFT JOIN vw_ppl_caseworkersusers cw ON wb.col_caseworkerworkbasket = cw.id
                 WHERE UPPER(wbt.col_code) = 'GROUP') w) units,
       user_tables tabs
 WHERE tabs.table_name = 'TBL_PPL_' || UPPER(:OBJECTTYPE) AND units.objecttype = UPPER(:OBJECTTYPE)
 <%=Sort("@SORT@","@DIR@")%>