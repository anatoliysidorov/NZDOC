SELECT
	GROUPID AS ID,
    GROUPID AS COL_ID,
	NAME AS NAME
FROM @TOKEN_SYSTEMDOMAINUSER@.ASF_GROUP
ORDER BY NAME ASC