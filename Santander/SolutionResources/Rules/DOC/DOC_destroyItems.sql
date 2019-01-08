DECLARE
  v_RawTypes NVARCHAR2(4000);
  v_Item_Ids NVARCHAR2(4000);
  v_errorcode NUMBER;
  v_errormessage NVARCHAR2(255);
  v_index     NUMBER := 1;
  v_cur_id    NUMBER;
  v_result    NUMBER;
  v_NewItemId NUMBER;
BEGIN
  v_errormessage := '';
  v_errorcode    := 0;
  v_RawTypes     := :RawTypes;
  v_Item_Ids     := :ItemIds;
  FOR rec IN
  (SELECT TO_CHAR(column_value) AS RawType
  FROM TABLE(ASF_SPLIT(v_RawTypes, '|||'))
  )
  LOOP
	SELECT itemid 
	INTO   v_cur_id 
	FROM   (SELECT 
					To_number(column_value) AS ItemId, 
					ROWNUM                  AS RN 
			FROM   TABLE(Asf_split(v_item_ids, '|||'))) 
	WHERE  rn = v_index; 
	

    IF (rec.RawType     = 'DOCUMENT') THEN
      v_result         := f_DOC_destroyDocFn( Docid => v_cur_id, Errorcode => v_ErrorCode, Errormessage => v_ErrorMessage);
      IF(v_result      <> 0) THEN
        v_errorMessage := 'There was an error with a document id'||v_cur_id|| chr(10)|| v_errorMessage;
        ROLLBACK;
        GOTO cleanup;
      END IF;
    ELSIF (rec.RawType  = 'FOLDER') THEN
      v_result         := f_DOC_destroyFolderFn(FolderId => v_cur_id, Errorcode => v_ErrorCode, Errormessage => v_ErrorMessage);
      IF(v_result      <> 0) THEN
        v_errorMessage := 'There was an error with a folder id '||v_cur_id|| chr(10)|| v_errorMessage;
        ROLLBACK;
        GOTO cleanup;
      END IF;
    ELSE
      v_errorcode    := 12;
      v_errormessage := 'Raw Type '|| rec.rawtype||' is not recognized';
      ROLLBACK;
      GOTO cleanup;
    END IF;
    v_index := v_index+1;
  END LOOP;
  <<cleanup>>
  :ErrorMessage := v_ErrorMessage;
  :ErrorCode    := v_errorcode;
  DBMS_OUTPUT.PUT_LINE(v_ErrorMessage);
END;
