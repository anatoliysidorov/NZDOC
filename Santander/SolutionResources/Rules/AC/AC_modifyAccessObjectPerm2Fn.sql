DECLARE
  v_permissionvalue INTEGER;
  v_permissionid    INTEGER;
  v_param           NVARCHAR2(255);
  v_aclid           INTEGER;
  v_acltype         INTEGER;
  v_accessobjectId  INTEGER;
  v_aotype          INT;
  v_ObjectType      VARCHAR2(255);
  v_res             NUMBER;

  v_errorcode    INTEGER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_errorcode    := 0;
  v_errormessage := '';

  v_permissionvalue := NULL;

  :SuccessResponse := 'Updated access';

  IF (:IsPageElement IS NOT NULL) THEN
    -- Page Config Access execution
    IF (:PageConfigId IS NULL) THEN
      v_errormessage   := 'PageConfigId could not be empty';
      v_errorcode      := 101;
      :SuccessResponse := '';
      GOTO cleanup;
    END IF;
  
    BEGIN
      SELECT col_id INTO v_accessobjectId FROM tbl_ac_accessobject WHERE col_accessobjectuielement = :PageConfigId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      
        --  create a record in the AC_AccessObject table of type AC_AccessObjectType.col_code = "PAGE_ELEMENT"
        v_aotype := f_util_getidbycode(code => 'PAGE_ELEMENT', tablename => 'tbl_ac_accessobjecttype');
        INSERT INTO tbl_ac_accessobject
          (col_name, col_code, col_accessobjaccessobjtype, col_accessobjectuielement)
        VALUES
          ('Page element ' || to_char(:PageConfigId), f_UTIL_calcUniqueCode('PAGE_ELEMENT_' || to_char(:PageConfigId), 'tbl_ac_accessobject'), v_aotype, :PageConfigId)
        RETURNING col_id INTO v_accessobjectId;
    END;
  
    FOR cur1 IN (SELECT d.extract('/record/ID/text()').getnumberval() AS AccessSubjectId,d.extract('/record').getstringval() AS SubNode
                   FROM TABLE(XMLSequence(XMLType(:Input).extract('xmlData/record'))) d) LOOP
      FOR cur2 IN (SELECT t1.Name AS permName
                     FROM ((SELECT NAME, INSTR(cur1.SubNode, '<' || NAME) AS IsPermission
                              FROM (SELECT col_name AS NAME FROM tbl_ac_permission GROUP BY col_name) t)) t1
                    WHERE t1.IsPermission > 0) LOOP
        v_param := '/record/' || cur2.permName || '/text()';
      
        BEGIN
          v_permissionvalue := XMLType(cur1.SubNode).extract(v_param).getnumberval();
        EXCEPTION
          WHEN OTHERS THEN
            v_permissionvalue := NULL;
        END;
      
        SELECT p.col_id
          INTO v_permissionid
          FROM tbl_ac_permission p
          LEFT JOIN (SELECT col_id AS objectTypeId FROM TBL_AC_ACCESSOBJECTTYPE WHERE col_code = 'PAGE_ELEMENT') ot
            ON 1 = 1
         WHERE p.col_permissionaccessobjtype = ot.objectTypeId
           AND p.col_name = cur2.permName;
      
        BEGIN
          SELECT col_id, col_type
            INTO v_aclid, v_acltype
            FROM tbl_ac_acl
           WHERE col_aclaccessobject = v_accessobjectId
             AND col_aclaccesssubject = cur1.AccessSubjectId
             AND col_aclpermission = v_permissionid;
        EXCEPTION
          WHEN OTHERS THEN
            v_aclid   := NULL;
            v_acltype := NULL;
        END;
      
        BEGIN
          IF (nvl(v_permissionvalue, 0) = 0) THEN
            -- delete permission  
            IF (v_aclid IS NOT NULL) THEN
              DELETE FROM tbl_ac_acl WHERE col_id = v_aclid;
            END IF;
          ELSE
            -- insert new permission
            IF (v_aclid IS NULL) THEN
              INSERT INTO tbl_ac_acl
                (col_aclaccessobject, col_aclaccesssubject, col_aclpermission, col_type, col_code)
              VALUES
                (v_accessobjectId, cur1.AccessSubjectId, v_permissionid, v_permissionvalue, sys_guid());
            ELSE
              -- update existing permission
              IF (v_acltype <> v_permissionvalue) THEN
                UPDATE tbl_ac_acl SET col_type = v_permissionvalue WHERE col_id = v_aclid;
              END IF;
            END IF;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            v_errormessage := SUBSTR(SQLERRM, 1, 200);
            v_errorcode    := SQLCODE;
        END;
      END LOOP;
    END LOOP;
  
  ELSE
  
    -- Unit Managment Access execution
    IF (:AccessSubjectId IS NULL) THEN
      v_errormessage   := 'AccessSubjectId could not be empty';
      v_errorcode      := 102;
      :SuccessResponse := '';
      GOTO cleanup;
    END IF;
  
    -- validation on Id is Exist
    BEGIN
      SELECT col_type INTO v_ObjectType FROM TBL_AC_ACCESSSUBJECT WHERE col_id = :AccessSubjectId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errormessage := 'There is not exist Access Subject with id {{MESS_ACCESSSUBJECTID}}';
		v_res := LOC_i18n(
		  MessageText => v_errormessage,
		  MessageResult => v_errormessage,
		  MessageParams => NES_TABLE(
			Key_Value('MESS_ACCESSSUBJECTID', to_char(:AccessSubjectId))
		  )
		);	  
        v_errorcode    := 103;
        GOTO cleanup;
    END;
  
    FOR cur1 IN (SELECT d.extract('/record/ID/text()').getnumberval() AS AccessObjectId,d.extract('/record').getstringval() AS SubNode
                   FROM TABLE(XMLSequence(XMLType(:Input).extract('xmlData/record'))) d) LOOP
      FOR cur2 IN (SELECT t1.Name AS permName
                     FROM ((SELECT NAME, INSTR(cur1.SubNode, '<' || NAME) AS IsPermission
                              FROM (SELECT col_name AS NAME FROM tbl_ac_permission GROUP BY col_name) t)) t1
                    WHERE t1.IsPermission > 0) LOOP
        v_param := '/record/' || cur2.permName || '/text()';
      
        BEGIN
          v_permissionvalue := XMLType(cur1.SubNode).extract(v_param).getnumberval();
        EXCEPTION
          WHEN OTHERS THEN
            v_permissionvalue := NULL;
        END;
      
        SELECT p.col_id
          INTO v_permissionid
          FROM tbl_ac_permission p
         INNER JOIN tbl_ac_accessobject ao
            ON (p.col_permissionaccessobjtype = ao.col_accessobjaccessobjtype)
         WHERE ao.col_id = cur1.accessobjectid
           AND p.col_name = cur2.permName;
      
        BEGIN
          SELECT col_id, col_type
            INTO v_aclid, v_acltype
            FROM tbl_ac_acl
           WHERE col_aclaccessobject = cur1.accessobjectid
             AND col_aclaccesssubject = :AccessSubjectId
             AND col_aclpermission = v_permissionid;
        EXCEPTION
          WHEN OTHERS THEN
            v_aclid   := NULL;
            v_acltype := NULL;
        END;
      
        BEGIN
          IF (nvl(v_permissionvalue, 0) = 0) THEN
            -- delete permission  
            IF (v_aclid IS NOT NULL) THEN
              DELETE FROM tbl_ac_acl WHERE col_id = v_aclid;
            END IF;
          ELSE
            -- insert new permission
            IF (v_aclid IS NULL) THEN
              INSERT INTO tbl_ac_acl
                (col_aclaccessobject, col_aclaccesssubject, col_aclpermission, col_type, col_code)
              VALUES
                (cur1.accessobjectid, :AccessSubjectId, v_permissionid, v_permissionvalue, sys_guid());
            ELSE
              -- update existing permission
              IF (v_acltype <> v_permissionvalue) THEN
                UPDATE tbl_ac_acl SET col_type = v_permissionvalue WHERE col_id = v_aclid;
              END IF;
            END IF;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            v_errormessage := SUBSTR(SQLERRM, 1, 200);
            v_errorcode    := SQLCODE;
        END;
      END LOOP;
    END LOOP;
  
  END IF;

  <<cleanup>>
  :errorMessage := v_errormessage;
  :errorCode    := v_errorcode;
END;