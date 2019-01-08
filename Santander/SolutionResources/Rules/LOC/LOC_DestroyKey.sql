DECLARE
  v_id           NUMBER;
  v_IdS          NCLOB;
  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);
  v_Exist        NUMBER;
BEGIN
  v_errorCode    := 0;
  v_errorMessage := '';
  :affectedRows  := 0;
  v_id           := :ID;
  v_IdS          := :IDS;

  ---Input params check 
  IF (v_Id IS NULL AND v_IdS IS NULL)
  THEN
    v_errorMessage := 'Id can not be empty';
    v_errorCode    := 101;
    GOTO cleanup;
  END IF;

  ---Check if there are Keys with this KeyID
  /*SELECT COUNT(*) INTO v_Exist FROM tbl_LOC_Translation WHERE tbl_LOC_Translation.col_KeyID = v_id;

  IF v_Exist > 0 THEN
    v_errorMessage := 'You can not delete this Key';
    v_errorMessage := v_errorMessage || '<br>There are one or more Translations referencing this Key.';
    v_errorMessage := v_errorMessage || '<br>Change the Key value of those Translations and try again.';
    v_errorCode    := 102;
    GOTO cleanup;
  ELSE
    DELETE tbl_LOC_Key WHERE col_id = v_id;
  END IF;*/
  IF (v_Id IS NOT NULL) THEN
    DELETE FROM TBL_LOC_TRANSLATION WHERE col_KeyID = v_id;
    DELETE FROM TBL_LOC_KEYSOURCES WHERE COL_KEYID = v_id;
    DELETE FROM tbl_LOC_Key WHERE COL_ID = v_id;
  ELSIF (v_IdS IS NOT NULL) THEN
    DELETE FROM TBL_LOC_TRANSLATION 
     WHERE col_KeyID IN (SELECT TO_NUMBER(COLUMN_VALUE) AS ID FROM TABLE(ASF_SPLIT(v_Ids, ',')));
     
    DELETE FROM TBL_LOC_KEYSOURCES WHERE COL_KEYID IN (SELECT TO_NUMBER(COLUMN_VALUE) AS ID FROM TABLE(ASF_SPLIT(v_Ids, ',')));
    
    DELETE FROM tbl_LOC_Key 
     WHERE COL_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) AS ID FROM TABLE(ASF_SPLIT(v_Ids, ',')));
  END IF;

  --get affected rows
  :affectedRows := SQL%ROWCOUNT;

  <<cleanup>>
  :errorMessage := v_errorMessage;
  :errorCode    := v_errorCode;
END;