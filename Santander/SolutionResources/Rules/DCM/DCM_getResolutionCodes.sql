SELECT *
FROM(
	SELECT r.col_id                                    AS Id, 
		   r.col_name                                  AS NAME, 
		   r.col_code                                  AS Code, 
		   r.col_isdeleted                             AS IsDeleted, 
		   r.col_type                                  AS TYPE,  
		   r.col_iconcode                              AS IconCode, 
		   r.col_theme                                 AS Theme
	FROM tbl_casesystyperesolutioncode tc
	LEFT JOIN tbl_stp_resolutioncode r	on tc.col_casetyperesolutioncode = r.col_id
	WHERE tc.col_tbl_dict_casesystype = (SELECT COL_CASEDICT_CASESYSTYPE from tbl_Case where col_id =:Case_Id)
	UNION 
		SELECT r.col_id                                AS Id, 
		   r.col_name                                  AS NAME, 
		   r.col_code                                  AS Code, 
		   r.col_isdeleted                             AS IsDeleted, 
		   r.col_type                                  AS TYPE, 
		   r.col_iconcode                              AS IconCode, 
		   r.col_theme                                 AS Theme
	FROM tbl_tasksystyperesolutioncode tc
	LEFT JOIN tbl_stp_resolutioncode r on tc.col_tbl_stp_resolutioncode = r.col_id
	WHERE tc.col_tbl_dict_tasksystype = (SELECT COL_TASKDICT_TASKSYSTYPE from tbl_Task where col_id =:Task_Id)
)
WHERE NVL(IsDeleted, 0) = 0
<%=Sort("@SORT@","@DIR@")%>