DECLARE
  v_Id                  INTEGER;
  v_Ids                 NVARCHAR2(32767);
  v_listNotAllowDelete  NVARCHAR2(32767);
  v_tempName            NVARCHAR2(255);
  count_                INTEGER;
  v_countDeletedRecords INTEGER;
  v_isDetailedInfo      boolean;
  v_errCode             NUMBER;
  v_errMsg              NVARCHAR2(255);
  v_return              number;
  v_result              NUMBER;
  v_MessageParams       NES_TABLE := NES_TABLE();

BEGIN
  :SuccessResponse := EMPTY_CLOB();
  :ErrorCode            := 0;
  :ErrorMessage         := '';
  :affectedRows         := 0;
  v_Id                  := :Id;
  v_Ids                 := :Ids;
  count_                := 0;
  v_countDeletedRecords := 0;

  ---Input params check 
  IF v_Id IS NULL AND v_Ids IS NULL THEN
    :ErrorMessage := 'Id can not be empty';
    :ErrorCode    := 101;
    RETURN;
  END IF;

  IF (v_Id IS NOT NULL) THEN
    v_Ids            := TO_CHAR(v_id);
    v_isDetailedInfo := false;
  ELSE
    v_isDetailedInfo := true;
  END IF;

  ---Check for default page
  SELECT COUNT(COL_ID)
  INTO count_
  FROM tbl_fom_page
  WHERE NVL(col_systemdefault, 0) = 1
    AND COL_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) AS id FROM TABLE(ASF_SPLIT(v_Ids, ',')));
  
  IF (count_ >= 1) THEN
	:ErrorCode := 102;
	:ErrorMessage := 'You can not delete the default page!';
	RETURN;
  END IF;
  
  FOR mRec IN (SELECT COLUMN_VALUE AS id FROM TABLE(ASF_SPLIT(v_Ids, ','))) LOOP
  
    SELECT COUNT(*)
      INTO count_
      FROM tbl_AssocPage
     WHERE COL_ASSOCPAGEPAGE = mRec.id;
  
    IF count_ > 0 THEN
      BEGIN
        SELECT col_Name
          INTO v_tempName
          FROM tbl_fom_page
         WHERE col_Id = mRec.id;
      
        v_listNotAllowDelete := v_listNotAllowDelete || ', ' || v_tempName;
      
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    
      CONTINUE;
    END IF;
  
    -- delete from ac_acl
    DELETE FROM tbl_ac_acl
     WHERE col_aclaccessobject IN
           (SELECT col_id
              FROM tbl_ac_accessobject
             WHERE col_accessobjectuielement IN
                   (SELECT col_id
                      FROM tbl_fom_uielement
                     WHERE col_parentid in
                           (SELECT col_id
                              FROM tbl_fom_uielement
                             WHERE col_uielementpage = mRec.id)));
    DELETE FROM tbl_ac_acl
     WHERE col_aclaccessobject IN
           (SELECT col_id
              FROM tbl_ac_accessobject
             WHERE col_accessobjectuielement IN
                   (SELECT col_id
                      FROM tbl_fom_uielement
                     WHERE col_uielementpage = mRec.id));
  
    -- delete from ac_accessobject
    DELETE FROM tbl_ac_accessobject
     WHERE col_accessobjectuielement IN
           (SELECT col_id
              FROM tbl_fom_uielement
             WHERE col_parentid in
                   (SELECT col_id
                      FROM tbl_fom_uielement
                     WHERE col_uielementpage = mRec.id));
    DELETE FROM tbl_ac_accessobject
     WHERE col_accessobjectuielement IN
           (SELECT col_id
              FROM tbl_fom_uielement
             WHERE col_uielementpage = mRec.id);

    -- delete relations between UI elements and DOM Attributes
    DELETE FROM TBL_UIELEMENT_DOM_ATTRIBUTE
        WHERE COL_FOM_UIELEMENT_ID
        IN (SELECT uie.COL_ID
            FROM TBL_FOM_UIELEMENT uie
            WHERE uie.col_parentid in
               (SELECT uie2.col_id
                  FROM tbl_fom_uielement uie2
                 WHERE uie2.col_uielementpage = mRec.id));

    DELETE FROM TBL_UIELEMENT_DOM_ATTRIBUTE
        WHERE COL_FOM_UIELEMENT_ID
        IN (SELECT uie.COL_ID
            FROM TBL_FOM_UIELEMENT uie
            WHERE uie.col_uielementpage = mRec.id);

    -- delete from fom_pageconfig
    DELETE tbl_fom_uielement
     WHERE col_parentid in
           (SELECT col_id
              FROM tbl_fom_uielement
             WHERE col_uielementpage = mRec.id);
    DELETE FROM tbl_fom_uielement WHERE col_uielementpage = mRec.id;
  
    -- delete from fom_page
    DELETE FROM tbl_fom_page tfp WHERE tfp.col_id = mRec.id;
  
    -- delete some localization key for the page
    v_return      := f_LOC_ImportKey(ErrorCode    => v_errCode,
                                     ErrorMessage => v_errMsg,
                                     NAMESPACE    => 'Builder',
                                     SourceId     => mRec.ID,
                                     SourceType   => 'Page',
                                     XML_INPUT    => null);
    :ErrorMessage := v_errMsg;
    :ErrorCode    := v_errCode;
  
    v_countDeletedRecords := v_countDeletedRecords + 1;
  
  END LOOP;

  --get affected rows
  :affectedRows := SQL%ROWCOUNT;

  IF (v_listNotAllowDelete IS NOT NULL) THEN
    v_listNotAllowDelete := SUBSTR(v_listNotAllowDelete,
                                   2,
                                   LENGTH(v_listNotAllowDelete));
  
    :ErrorCode := 102;
  
    IF (v_isDetailedInfo) THEN
      v_MessageParams.EXTEND(2);
      v_MessageParams(v_MessageParams.LAST - 1) := KEY_VALUE('MESS_COUNT',
                                                             v_countDeletedRecords);
      v_MessageParams(v_MessageParams.LAST) := KEY_VALUE('MESS_LIST_NOT_DELETED',
                                                         v_listNotAllowDelete);
    
      :ErrorMessage := 'Count of deleted Pages: {{MESS_COUNT}} <br>You can''t delete Pages: {{MESS_LIST_NOT_DELETED}}<br> Some Associated Pages with Page exist.<br> Remove the links and try again...';
    ELSE
      :ErrorMessage := 'You can''t delete this Page.<br> Some Associated Pages with Page exist.<br> Remove the links and try again...';
    END IF;
  
    v_result := LOC_i18n(MessageText        => :ErrorMessage,
                         MessageParams      => v_MessageParams,
                         DisableEscapeValue => TRUE,
                         MessageResult      => :ErrorMessage);
  ELSE
    v_result := LOC_i18n(MessageText   => 'Deleted {{MESS_COUNT}} items',
                         MessageResult => :SuccessResponse,
                         MessageParams => NES_TABLE(Key_Value('MESS_COUNT',
                                                              v_countDeletedRecords)));
  END IF;
END;