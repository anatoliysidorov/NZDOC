SELECT ID, Code, Description, NAME, IsDeleted, ShowDeleted
  FROM (SELECT col_id          AS ID,
               col_code        AS Code,
               col_description AS Description,
               col_name        AS NAME,
               col_isdeleted   AS IsDeleted,
               :ShowDeleted    AS ShowDeleted
          FROM tbl_stp_resolutioncode
         WHERE (UPPER(col_type) = UPPER(:TYPE))
           AND (:TYPE IS NOT NULL)
        UNION ALL
        SELECT rc.col_id          AS ID,
               rc.col_code        AS Code,
               rc.col_description AS Description,
               rc.col_name        AS NAME,
               rc.col_isdeleted   AS IsDeleted,
               :ShowDeleted       AS ShowDeleted
          FROM tbl_casesystyperesolutioncode cc
          LEFT JOIN tbl_stp_resolutioncode rc
            ON (rc.col_id = cc.col_casetyperesolutioncode)
         WHERE (cc.col_tbl_dict_casesystype = :CaseSysType_Id)
           AND (:CaseSysType_Id IS NOT NULL)
        UNION ALL
        SELECT rc.col_id          AS ID,
               rc.col_code        AS Code,
               rc.col_description AS Description,
               rc.col_name        AS NAME,
               rc.col_isdeleted   AS IsDeleted,
               :ShowDeleted       AS ShowDeleted
          FROM tbl_tasksystyperesolutioncode tc
          LEFT JOIN tbl_stp_resolutioncode rc
            ON (rc.col_id = tc.col_tbl_stp_resolutioncode)
			WHERE (tc.col_tbl_dict_tasksystype = :TaskSysType_Id)
				AND (:TaskSysType_Id IS NOT NULL)
        UNION ALL
        SELECT rc.col_id          AS ID,
               rc.col_code        AS Code,
               rc.col_description AS Description,
               rc.col_name        AS NAME,
               rc.col_isdeleted   AS IsDeleted,
               :ShowDeleted       AS ShowDeleted
          FROM tbl_map_taskstateinitiation tsi
         INNER JOIN tbl_tasktemplate tt
            ON tsi.col_map_taskstateinittasktmpl = tt.col_id
         INNER JOIN tbl_dict_tasksystype tst
            ON tt.col_tasktmpldict_tasksystype = tst.col_id
         INNER JOIN tbl_tasksystyperesolutioncode tstrc
            ON tst.col_id = tstrc.col_tbl_dict_tasksystype
         INNER JOIN tbl_stp_resolutioncode rc
            ON tstrc.col_tbl_stp_resolutioncode = rc.col_id
         WHERE --tsi.col_id = :TaskStateInit_Id
           --AND 
		   :TaskStateInit_Id IS NOT NULL
        UNION ALL
        SELECT rc.col_id          AS ID,
               rc.col_code        AS Code,
               rc.col_description AS Description,
               rc.col_name        AS NAME,
               rc.col_isdeleted   AS IsDeleted,
               :ShowDeleted       AS ShowDeleted
          FROM tbl_tasktemplate tt
         INNER JOIN tbl_dict_tasksystype tst
            ON tt.col_tasktmpldict_tasksystype = tst.col_id
         INNER JOIN tbl_tasksystyperesolutioncode tstrc
            ON tst.col_id = tstrc.col_tbl_dict_tasksystype
         INNER JOIN tbl_stp_resolutioncode rc
            ON tstrc.col_tbl_stp_resolutioncode = rc.col_id
         WHERE tt.col_id = :TaskTemplate_Id
           AND :TaskTemplate_Id IS NOT NULL
        UNION ALL
        SELECT rc.col_id          AS ID,
               rc.col_code        AS Code,
               rc.col_description AS Description,
               rc.col_name        AS NAME,
               rc.col_isdeleted   AS IsDeleted,
               :ShowDeleted       AS ShowDeleted
          FROM tbl_taskevent te
         INNER JOIN tbl_map_taskstateinitiation tsi
            ON te.col_taskeventtaskstateinit = tsi.col_id
         INNER JOIN tbl_tasktemplate tt
            ON tsi.col_map_taskstateinittasktmpl = tt.col_id
         INNER JOIN tbl_dict_tasksystype tst
            ON tt.col_tasktmpldict_tasksystype = tst.col_id
         INNER JOIN tbl_tasksystyperesolutioncode tstrc
            ON tst.col_id = tstrc.col_tbl_dict_tasksystype
         INNER JOIN tbl_stp_resolutioncode rc
            ON tstrc.col_tbl_stp_resolutioncode = rc.col_id
         WHERE te.col_id = :TaskEvent_Id
           AND :TaskEvent_Id IS NOT NULL
        UNION ALL
        SELECT rc.col_id                 AS ID,
               rc.col_code               AS Code,
               rc.col_description        AS Description,
               rc.col_name               AS NAME,
               nvl(rc.col_isdeleted, 0)  AS IsDeleted,
               :ShowDeleted              AS ShowDeleted
          FROM tbl_caseevent ce
         INNER JOIN tbl_map_casestateinitiation csi
            ON ce.col_caseeventcasestateinit = csi.col_id
         INNER JOIN tbl_dict_casesystype cst
            ON csi.col_casestateinit_casesystype = cst.col_id
         INNER JOIN tbl_casesystyperesolutioncode cstrc
            ON cst.col_id = cstrc.col_tbl_dict_casesystype
         INNER JOIN tbl_stp_resolutioncode rc
            ON cstrc.col_casetyperesolutioncode = rc.col_id
         WHERE ce.col_id = :CaskEvent_Id
           AND :CaskEvent_Id IS NOT NULL)
 WHERE nvl(IsDeleted, 0) = (CASE
                              WHEN :ShowDeleted = 1 THEN
                               nvl(IsDeleted, 0)
                              ELSE
                               0
                            END)
<%=Sort("@SORT@","@DIR@")%>