SELECT *
FROM(
	SELECT  
		tv.id as ID		
	FROM vw_dcm_simpletask2 tv
        LEFT JOIN  vw_dcm_taskslaprimaryevent6 tse  ON tse.nexttaskid = tv.col_id AND tse.prevtaskid = tv.col_id
	WHERE      
		tv.Workbasket_id = :WorkbasketId
		AND NVL(tv.TASKSTATE_ISFINISH, 0) = 0
	ORDER BY
		tse.PREVSLADATETIME DESC NULLS LAST, tse.NEXTSLADATETIME NULLS LAST, Priority_Value ASC NULLS LAST
)
WHERE ROWNUM <= :NumberOfRecords