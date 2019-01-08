DECLARE
  a_FormIds      NUMBER_ARRAY;
  v_id           TBL_MDM_FORM.COL_ID%TYPE;
  v_IdS          NCLOB;
  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);
BEGIN
  v_errorCode    := 0;
  v_errorMessage := '';
  :affectedRows  := 0;
  v_id           := NVL(:ID, 0);
  v_IdS          := :IDS;

  ---Input params check 
  IF (v_Id = 0 AND v_IdS IS NULL) THEN
    v_errorMessage := 'Id can not be empty';
    v_errorCode    := 101;
    GOTO cleanup;
  END IF;
  
  IF (v_Id <> 0) THEN
    DELETE FROM TBL_UIELEMENT_DOM_ATTRIBUTE 
     WHERE COL_FOM_UIELEMENT_ID 
        IN (SELECT COL_ID
              FROM TBL_FOM_UIELEMENT uie
             WHERE uie.COL_UIELEMENTFORM = v_id);

    DELETE FROM TBL_FOM_UIELEMENT WHERE COL_UIELEMENTFORM = v_id;
    DELETE FROM TBL_MDM_SEARCHPAGE WHERE COL_SEARCHPAGEMDM_FORM = v_id;
    DELETE FROM TBL_MDM_FORM WHERE COL_ID = v_id;

  ELSIF (v_IdS IS NOT NULL) THEN
    SELECT TO_NUMBER(COLUMN_VALUE)
      BULK COLLECT INTO a_FormIds
      FROM TABLE(ASF_SPLIT(v_Ids, ','));
    IF (a_FormIds.COUNT > 0) THEN
      DELETE FROM TBL_UIELEMENT_DOM_ATTRIBUTE 
       WHERE COL_FOM_UIELEMENT_ID 
          IN (SELECT COL_ID
                FROM TBL_FOM_UIELEMENT uie
               WHERE uie.COL_UIELEMENTFORM 
                  IN (SELECT COLUMN_VALUE FROM TABLE(a_FormIds)));

      DELETE FROM TBL_FOM_UIELEMENT WHERE COL_UIELEMENTFORM IN (SELECT COLUMN_VALUE FROM TABLE(a_FormIds));
      DELETE FROM TBL_MDM_SEARCHPAGE WHERE COL_SEARCHPAGEMDM_FORM IN (SELECT COLUMN_VALUE FROM TABLE(a_FormIds));
      DELETE FROM TBL_MDM_FORM WHERE COL_ID IN (SELECT COLUMN_VALUE FROM TABLE(a_FormIds));
    END IF;
  END IF;

  --get affected rows
  :affectedRows := SQL%ROWCOUNT;

  <<cleanup>>
  :errorMessage := v_errorMessage;
  :errorCode    := v_errorCode;
END;