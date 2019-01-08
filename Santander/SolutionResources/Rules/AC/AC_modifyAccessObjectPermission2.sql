DECLARE
  v_permissionvalue  INTEGER;
  v_permissionid     INTEGER;
  v_param            NVARCHAR2(255);
  v_aclid            INTEGER;
  v_acltype          INTEGER;
  v_accessobjectId   INTEGER;
  v_accessobjectType INTEGER;
  v_aotype           INTEGER;
  v_ObjectType       VARCHAR2(255);
  v_res              NUMBER;

  v_errorcode    INTEGER;
  v_errormessage NVARCHAR2(255);
  v_count        INTEGER;

  v_name         NVARCHAR2(255);
  v_code         NVARCHAR2(255);

  v_IsUIElement  INTEGER;
  v_UIElementId  INTEGER;
  v_UIElementError NVARCHAR2(255);

BEGIN
  v_errorcode    := 0;
  v_errormessage := '';

  v_permissionvalue := NULL;

  :SuccessResponse := 'Updated access';

  --determinating builder and messages
  IF (:IsPageElement IS NOT NULL) THEN
    v_IsUIElement := :IsPageElement;
    v_UIElementId := :PageConfigId;
    v_UIElementError := 'PageConfigId could not be empty';
    v_code := 'PAGE_ELEMENT';
    v_name := 'Page element ';
  ELSIF (:IsDashboardElement IS NOT NULL) THEN
    v_IsUIElement := :IsDashboardElement;
    v_UIElementId := :DashboardConfigId;
    v_UIElementError := 'DashboardConfigId could not be empty';
    v_code := 'DASHBOARD_ELEMENT';
    v_name := 'Dashboard element ';
  END IF;
  --end

  IF (v_IsUIElement IS NOT NULL) THEN
    -- Page Config Access execution
    IF (v_UIElementId IS NULL) THEN
      v_errormessage   := v_UIElementError;
      v_errorcode      := 101;
      :SuccessResponse := '';
      GOTO cleanup;
    END IF;

    v_aotype := f_util_getidbycode(code => v_code, tablename => 'tbl_ac_accessobjecttype');

    BEGIN
      SELECT col_id INTO v_accessobjectId FROM tbl_ac_accessobject WHERE col_accessobjectuielement = v_UIElementId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --  create a record in the AC_AccessObject table of type AC_AccessObjectType.col_code = "PAGE_ELEMENT"
        INSERT INTO tbl_ac_accessobject
          (col_name, col_code, col_accessobjaccessobjtype, col_accessobjectuielement)
        VALUES
          (v_name || to_char(v_UIElementId), f_UTIL_calcUniqueCode( v_code || '_' || to_char(v_UIElementId), 'tbl_ac_accessobject'), v_aotype, v_UIElementId)
        RETURNING col_id INTO v_accessobjectId;
    END;

    FOR cur1 IN (SELECT d.extract('/record/ID/text()').getnumberval() AS AccessSubjectId,
                        d.extract('/record').getstringval() AS SubNode
                   FROM TABLE(XMLSequence(XMLType(:Input).extract('xmlData/record'))) d) LOOP
      FOR cur2 IN (SELECT t1.Code AS permCode
                     FROM ((SELECT Code,
                                   INSTR(cur1.SubNode, '<' || NVL(Code, 0)) AS IsPermission
                              FROM (SELECT col_code AS Code FROM tbl_ac_permission WHERE col_permissionaccessobjtype = v_aotype) t)) t1
                    WHERE t1.IsPermission > 0) LOOP
        v_param := '/record/' || cur2.permCode || '/text()';

        BEGIN
          v_permissionvalue := XMLType(cur1.SubNode).extract(v_param).getnumberval();
        EXCEPTION
          WHEN OTHERS THEN
            v_permissionvalue := NULL;
        END;

        SELECT col_id
          INTO v_permissionid
          FROM tbl_ac_permission
         WHERE col_permissionaccessobjtype = v_aotype
           AND col_code = cur2.permCode;

        BEGIN
          SELECT col_id,
                 col_type
            INTO v_aclid,
                 v_acltype
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
            v_errormessage   := SUBSTR(SQLERRM, 1, 200);
            v_errorcode      := SQLCODE;
            :SuccessResponse := '';
            GOTO cleanup;
        END;
      END LOOP;
    END LOOP;

  ELSE

    -- Unit Management Access execution
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
        v_res          := LOC_i18n(MessageText   => v_errormessage,
                                   MessageResult => v_errormessage,
                                   MessageParams => NES_TABLE(Key_Value('MESS_ACCESSSUBJECTID', to_char(:AccessSubjectId))));
        v_errorcode    := 103;
        GOTO cleanup;
    END;

    -- get Access Object Type

    v_count := 1;
    FOR cur1 IN (SELECT d.extract('/record').getstringval() AS SubNode FROM TABLE(XMLSequence(XMLType(:Input).extract('xmlData/record'))) d) LOOP
      BEGIN
        SELECT extractvalue(XMLType(:Input), 'xmlData/record[' || to_char(v_count) || ']/ID/text()') INTO v_accessobjectId FROM dual;
        IF v_accessobjectid IS NULL THEN
          EXIT;
        END IF;

        SELECT col_accessobjaccessobjtype INTO v_accessobjectType FROM tbl_ac_accessobject WHERE col_id = v_accessobjectId;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_errormessage := 'There is not exist Access Object Type with id {{MESS_ACCESSOBJECTID}}';
          v_res          := LOC_i18n(MessageText   => v_errormessage,
                                     MessageResult => v_errormessage,
                                     MessageParams => NES_TABLE(Key_Value('MESS_ACCESSOBJECTID', to_char(v_accessobjectId))));

          v_errorcode := 104;
          GOTO cleanup;
      END;
      v_count := v_count + 1;
      FOR cur2 IN (SELECT t1.Code AS permCode
                     FROM ((SELECT Code,
                                   INSTR(cur1.SubNode, '<' || NVL(Code, 0)) AS IsPermission
                              FROM (SELECT col_code AS Code FROM tbl_ac_permission WHERE col_permissionaccessobjtype = v_accessobjectType) t)) t1
                    WHERE t1.IsPermission > 0) LOOP
        v_param := '/record/' || cur2.permCode || '/text()';
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
         WHERE ao.col_id = v_accessobjectId
           AND p.col_code = cur2.permCode;

        BEGIN
          SELECT col_id,
                 col_type
            INTO v_aclid,
                 v_acltype
            FROM tbl_ac_acl
           WHERE col_aclaccessobject = v_accessobjectId
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
                (v_accessobjectId, :AccessSubjectId, v_permissionid, v_permissionvalue, sys_guid());
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

  --GENERATE SECURITY CACHE FOR ALL CASE TYPES
  v_res := f_DCM_createCTAccessCache();

  <<cleanup>>
  :errorMessage := v_errormessage;
  :errorCode    := v_errorcode;
END;