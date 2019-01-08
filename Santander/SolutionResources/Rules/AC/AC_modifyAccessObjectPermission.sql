DECLARE
	v_permissionId	integer;
	v_aclId			integer;
	v_aclType		NUMBER;

	v_errorcode		NUMBER;
	v_errormessage	NVARCHAR2(255);
BEGIN
	v_errorcode := 0;
	v_errormessage := '';

	IF (:accessObjectId IS NULL) THEN
		v_errormessage := 'AccessObjectId could not be empty';
		v_errorcode := 1;
		GOTO cleanup;
	END IF;
	IF (:accessSubjectId IS NULL) THEN
		v_errormessage := 'AccessSubjectId could not be empty';
		v_errorcode := 2;
		GOTO cleanup;
	END IF;
	IF (:permissionName = '' OR :permissionName IS NULL) THEN
		v_errormessage := 'PermissionName could not be empty';
		v_errorcode := 3;
		GOTO cleanup;
	END IF;

	SELECT p.COL_ID
	INTO v_permissionId
	FROM TBL_AC_PERMISSION p
	INNER JOIN TBL_AC_ACCESSOBJECT ao ON (p.COL_PERMISSIONACCESSOBJTYPE=ao.COL_ACCESSOBJACCESSOBJTYPE)
	WHERE ao.COL_ID = :accessObjectId
		AND p.COL_NAME=:permissionName;

	BEGIN
		SELECT COL_ID, COL_TYPE
		INTO v_aclId, v_aclType
		FROM TBL_AC_ACL
		WHERE COL_ACLACCESSOBJECT = :accessObjectId
			AND COL_ACLACCESSSUBJECT = :accessSubjectId
			AND COL_ACLPERMISSION = v_permissionId;
	EXCEPTION
		WHEN OTHERS THEN 
			v_aclId:=NULL;
			v_aclType:=NULL;
	END;

	BEGIN
		IF(:aclType IS NULL OR :aclType=0) THEN
			IF(v_aclId IS NOT NULL)THEN
				DELETE FROM TBL_AC_ACL
				WHERE COL_ID = v_aclId;
			END IF;
		ELSE
			IF(v_aclId IS NULL)THEN
				INSERT INTO TBL_AC_ACL(
					COL_ACLACCESSOBJECT,
					COL_ACLACCESSSUBJECT,
					COL_ACLPERMISSION,
					COL_TYPE,
					COL_CODE
				)VALUES(
					:accessObjectId,
					:accessSubjectId,
					v_permissionId,
					:aclType,
					sys_guid()
				);
			ELSE
				IF(v_aclType<>:aclType)THEN
					UPDATE TBL_AC_ACL
					SET COL_TYPE = :aclType
					WHERE COL_ID = v_aclId;
				END IF;
			END IF;
		END IF;
	EXCEPTION
		WHEN OTHERS THEN 
			v_errormessage := SQLERRM;
			v_errorcode := SQLCODE;
	END;

	<<cleanup>>
	:errorMessage := v_errormessage;
	:errorCode := v_errorcode; 
END;