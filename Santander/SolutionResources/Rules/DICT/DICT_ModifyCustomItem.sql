DECLARE
  v_RawType NVARCHAR2(4000);
  v_Name NVARCHAR2(4000);
  v_Code NVARCHAR2(255);
  v_Value NVARCHAR2(255);
  v_ParentCategoryId NUMBER;
  v_DenyThisParent NUMBER;
  v_Description NCLOB;
  v_Count NUMBER;
  v_newitemid NUMBER;
  v_IsDeleted NUMBER;
  v_id NUMBER;
  v_style NVARCHAR2(255);
  v_rowstyle NVARCHAR2(255);
  v_colorcode    		NVARCHAR2(7);
  v_iconcode           NVARCHAR2(255);
  v_isId      NUMBER;
  v_errorcode NUMBER;
  v_errormessage NVARCHAR2(255);
  v_result NUMBER;
  
BEGIN
  v_RawType       := :RawType;
  v_Name          := :Name;
  v_ParentCategoryId := :ParentCategoryId;
  v_Description    := :Description;
  v_style := :pStyle;
  v_rowstyle := :pRowStyle;
  v_iconcode     := :IconCode;
  v_colorcode    := :ColorCode;
  v_Code := :pCode;
  v_Value := :pValue;
  v_id := :pID;
  v_IsDeleted := :IsDeleted;
  v_errorcode    := 0;
  v_errormessage := '';
  :SuccessResponse := '';
  
  
    -- validation on ParentCategoryId is Exist
    IF NVL(v_ParentCategoryId, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_ParentCategoryId,
                             tablename    => 'TBL_DICT_CUSTOMCATEGORY');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
	
  IF (v_RawType IS NULL) THEN
      v_errorcode := 20;
      v_errormessage := '$t(RawType can not be empty) ';
  END IF;
  
  IF (v_Name IS NULL) THEN
      v_errorcode := 20;
      v_errormessage := v_errormessage || '$t(Name can not be empty) ';
  END IF;
  
  IF (v_Code IS NULL) THEN
      v_errorcode := 20;
      v_errormessage := v_errormessage ||'$t(CODE can not be empty) ';
  END IF;
  
  IF (v_id IS NULL) THEN
      v_errorcode := 20;
      v_errormessage := v_errormessage || '$t(Id can not be empty) ';
  END IF;
  
  IF (v_errorcode > 0) THEN
	GOTO cleanup;
  END IF;
  
  IF v_ParentCategoryId = v_id THEN
    v_errorCode    := 107;
    v_errorMessage := 'Please select another Category as parent';
    GOTO cleanup;
  END IF;

  
    IF (v_RawType = 'WORD') THEN 
		-- validation on Id is Exist
		IF NVL(v_id, 0) > 0 THEN
		  v_isId := f_UTIL_getId(errorcode    => v_errorcode,
								 errormessage => v_errormessage,
								 id           => v_id,
								 tablename    => 'TBL_DICT_CUSTOMWORD');
		  IF v_errorcode > 0 THEN
			GOTO cleanup;
		  END IF;
		END IF;
	
        IF(v_ParentCategoryId IS NULL) THEN
          BEGIN
              SELECT COUNT(COL_CODE)
              INTO v_Count
              FROM TBL_DICT_CUSTOMWORD dl
              WHERE lower(dl.COL_CODE) = lower(v_Code) AND COL_WORDCATEGORY IS NULL AND dl.COL_ID <> v_id;
              
              IF v_Count > 0 THEN
                 v_errorcode := 10;
                 v_errormessage := 'For RowType, WORD Code have to be Unique';
                 GOTO cleanup;
              END IF;
          END;
        ELSE
           BEGIN
              SELECT COUNT(dl.COL_CODE)
              INTO v_Count
              FROM TBL_DICT_CUSTOMWORD dl
              INNER JOIN TBL_DICT_CUSTOMCATEGORY dc ON dc.COL_ID = dl.COL_WORDCATEGORY
              WHERE lower(dl.COL_CODE) = lower(v_Code) AND dl.COL_WORDCATEGORY = v_ParentCategoryId AND dl.COL_ID <> v_id;
              
              IF v_Count > 0 THEN
                v_errorcode := 21;
                --v_errormessage := 'RawType WORD. The CODE has to be unique for all Words in the ParentFolder: ' || v_ParentCategoryId;
				v_errormessage := 'RawType WORD. The CODE has to be unique for all Words in the ParentFolder: {{MESS_PARENTFOLDERID}}';
				v_result := LOC_i18n(
					MessageText => v_errormessage,
					MessageResult => v_errormessage,
					MessageParams => NES_TABLE(
						Key_Value('MESS_PARENTFOLDERID', v_ParentCategoryId)
					)
				);
				GOTO cleanup;
              END IF;
           END;
        END IF;
        
       BEGIN
       --update word
        UPDATE TBL_DICT_CUSTOMWORD
        SET
             COL_NAME = v_Name
            ,COL_DESCRIPTION = v_Description
            ,COL_CODE = v_Code
            ,COL_VALUE = v_Value
            ,COL_ISDELETED = v_IsDeleted
            ,COL_WORDCATEGORY = v_ParentCategoryId
            ,col_style = v_style
            ,col_rowstyle = v_rowstyle
        WHERE COL_ID = v_id;
        --:SuccessResponse := 'Updated ' || v_name || ' word';          
		:SuccessResponse := 'Updated {{MESS_NAME}} word';
		v_result := LOC_i18n(
			MessageText => :SuccessResponse,
			MessageResult => :SuccessResponse,
			MessageParams => NES_TABLE(
				Key_Value('MESS_NAME', v_name)
			)
		);
          EXCEPTION 
            WHEN NO_DATA_FOUND THEN
              v_errorcode := 11;
              v_errormessage := 'RawType WORD. Error on UPDATE record.';
              GOTO cleanup;
            WHEN DUP_VAL_ON_INDEX  THEN
              v_errorcode := 12;
              v_errormessage := 'RawType WORD. Error on UPDATE record.';
              GOTO cleanup;
      END;
	  :AffectedRows := 1;
	  :RecordId := v_id;
    ELSIF (v_RawType = 'CATEGORY') THEN 
		-- validation on Id is Exist
		IF NVL(v_id, 0) > 0 THEN
		  v_isId := f_UTIL_getId(errorcode    => v_errorcode,
								 errormessage => v_errormessage,
								 id           => v_id,
								 tablename    => 'TBL_DICT_CUSTOMCATEGORY');
		  IF v_errorcode > 0 THEN
			GOTO cleanup;
		  END IF;
		END IF;
	
        IF(v_ParentCategoryId IS NULL) THEN
          BEGIN
              SELECT COUNT(COL_CODE)
              INTO v_Count
              FROM TBL_DICT_CUSTOMCATEGORY dl
              WHERE lower(dl.COL_CODE) = lower(v_Code) AND COL_CATEGORYCATEGORY IS NULL AND dl.COL_ID <> v_id;
              
              IF v_Count > 0 THEN
                 v_errorcode := 13;
                 v_errormessage := 'For RawType, CATEGORY Code have to be Unique';
                 GOTO cleanup;
              END IF;
          END;
        ELSE
           BEGIN
		      /* Search is this requested parent is children of current folder */
			  BEGIN
				  SELECT id
				  INTO v_denyThisParent
				  FROM (SELECT dl.col_id AS id, dl.COL_CATEGORYCATEGORY AS ParentId, col_name AS NAME, LEVEL AS NestingLevel
						FROM TBL_DICT_CUSTOMCATEGORY dl
						START WITH dl.col_id = v_id
						CONNECT BY PRIOR dl.col_id = dl.COL_CATEGORYCATEGORY)
				  WHERE id = v_ParentCategoryId;
			
			  EXCEPTION
			    WHEN NO_DATA_FOUND THEN
				v_denyThisParent := NULL;
			  END;
		  
			  IF v_DenyThisParent IS NOT NULL THEN
			    v_errorCode      := 106;
			    v_errorMessage   := 'Denyed to move parent to children Category';
			    :SuccessResponse := '';
			    GOTO cleanup;
			  END IF;

			  SELECT COUNT(dl.COL_CODE)
              INTO v_Count
              FROM TBL_DICT_CUSTOMCATEGORY dl
              INNER JOIN TBL_DICT_CUSTOMCATEGORY dc ON dc.COL_ID = dl.COL_CATEGORYCATEGORY
              WHERE lower(dl.COL_CODE) = lower(v_Code) AND dl.COL_CATEGORYCATEGORY = v_ParentCategoryId AND dl.COL_ID <> v_id;
              
              IF v_Count > 0 THEN
                v_errorcode := 22;
                --v_errormessage := 'RawType CATEGORY. The CODE has to be unique for all Categories in the ParentFolder: ' || v_ParentCategoryId;
				v_errormessage := 'RawType CATEGORY. The CODE has to be unique for all Categories in the ParentFolder: {{MESS_PARENTFOLDERID}}';
				v_result := LOC_i18n(
					MessageText => v_errormessage,
					MessageResult => v_errormessage,
					MessageParams => NES_TABLE(
						Key_Value('MESS_PARENTFOLDERID', v_ParentCategoryId)
					)
				);
                GOTO cleanup;
              END IF;
           END;
        END IF;
      
       BEGIN
       --update category
        UPDATE TBL_DICT_CUSTOMCATEGORY
        SET
           COL_NAME = v_Name
            ,COL_CODE = v_Code
            ,COL_DESCRIPTION = v_Description
            ,COL_CATEGORYCATEGORY = v_ParentCategoryId
            ,COL_ISDELETED = v_IsDeleted
            ,COL_ICONCODE = v_iconcode
            ,COL_COLORCODE = v_colorcode
          WHERE COL_ID = v_id;
            --:SuccessResponse := 'Updated ' || v_name || ' category';          
			:SuccessResponse := 'Updated {{MESS_NAME}} category';
			v_result := LOC_i18n(
				MessageText => :SuccessResponse,
				MessageResult => :SuccessResponse,
				MessageParams => NES_TABLE(
					Key_Value('MESS_NAME', v_name)
				)
			);
          EXCEPTION 
            WHEN NO_DATA_FOUND THEN
              v_errorcode := 14;
              v_errormessage := 'RawType CATEGORY. Error on UPDATE record.';
              GOTO cleanup;
            WHEN DUP_VAL_ON_INDEX  THEN
              v_errorcode := 15;
              v_errormessage := 'RawType CATEGORY. Error on UPDATE record.';
              GOTO cleanup;
      END;
     :AffectedRows := 1;
	 :RecordId := v_id;
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