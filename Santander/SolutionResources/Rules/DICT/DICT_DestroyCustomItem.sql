DECLARE
  v_RawType NVARCHAR2(255);
  v_errormessage NVARCHAR2(255);
  v_errorcode NUMBER;
  v_id NUMBER;
  v_CategoryId NUMBER; 
  v_WordOrder NUMBER;
  v_result NUMBER;
BEGIN
  v_errormessage   := '';
  v_errorcode      := 0;
  v_RawType       := :RawType;
  v_id := :pID;
  :ErrorMessage := '';
  :ErrorCode    := 0;
  :SuccessResponse := '';
  
 IF (v_RawType IS NULL) THEN
      v_errorcode := 20;
      v_errormessage := '$t(RawType can not be empty) ';
  END IF;
  
   IF (v_id IS NULL) THEN
      v_errorcode := 20;
      v_errormessage := v_errormessage || '$t(Id can not be empty) ';
  END IF;
  
  IF (v_errorcode > 0) THEN
    GOTO cleanup;
  END IF;
  
  
    IF (v_RawType = 'WORD') THEN 
      
      SELECT COL_WORDCATEGORY, 
             COL_WORDORDER 
        INTO v_CategoryId, 
             v_WordOrder
        FROM TBL_DICT_CUSTOMWORD
       WHERE COL_ID = v_Id;
         
      DELETE FROM TBL_DICT_CUSTOMWORD
      WHERE COL_ID = v_id;
      :SuccessResponse := 'Deleted word';          
      
    UPDATE TBL_DICT_CUSTOMWORD SET
             COL_WORDORDER = COL_WORDORDER - 1
       WHERE COL_WORDCATEGORY = v_CategoryId
         AND COL_WORDORDER > v_WordOrder;
           
    ELSIF (v_RawType = 'CATEGORY') THEN 
       FOR rec IN (SELECT COL_ID FROM TBL_DICT_CUSTOMCATEGORY WHERE COL_CATEGORYCATEGORY = v_id)
       LOOP
         DELETE FROM TBL_DICT_CUSTOMWORD
         WHERE COL_WORDCATEGORY = rec.COL_ID;
       END LOOP;   
       
       DELETE FROM TBL_DICT_CUSTOMWORD
       WHERE COL_WORDCATEGORY = v_id;
      DELETE FROM TBL_DICT_CUSTOMCATEGORY
      WHERE COL_CATEGORYCATEGORY = v_id;
      DELETE FROM TBL_DICT_CUSTOMCATEGORY
      WHERE COL_ID = v_id;
      :SuccessResponse := 'Deleted category';          
    ELSE 
      v_errorcode := 30;
      --v_errormessage := 'Raw Type ' || v_RawType ||' is not recognized!';
	  v_errormessage := 'Raw Type {{MESS_RAWTYPE}} is not recognized!';
	  v_result := LOC_i18n(
	  MessageText => v_errormessage,
	  MessageResult => v_errormessage,
	  MessageParams => NES_TABLE(
		Key_Value('MESS_RAWTYPE', v_RawType)
	  )
	);
      GOTO cleanup;
    END IF;
  
<<cleanup>>
:ErrorMessage := v_ErrorMessage;
:ErrorCode    := v_errorcode;

END;