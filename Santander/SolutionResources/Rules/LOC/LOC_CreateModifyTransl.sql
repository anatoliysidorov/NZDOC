DECLARE
	--custom 
	v_id           NUMBER;
	v_Description  NCLOB;
    v_IsDraft	   Integer;
    v_KeyID		   Integer;
    v_LangID	   Integer;
    v_PluralForm   Integer;
	v_Value		   NCLOB;
	--standard 
	v_errorcode    NUMBER;
	v_errormessage NVARCHAR2(255);
BEGIN
	--custom 
	v_id			:= :Id;
	v_Description	:= :DESCRIPTION;
    v_IsDraft		:= :ISDRAFT;
    v_KeyID			:= :KEYID;
    v_LangID		:= :LANGID;
    v_PluralForm	:= :PLURALFORM;
	v_Value			:= :VALUE;
	--standard 
	:affectedRows	:= 0;
	v_errorcode		:= 0;
	v_errormessage	:= '';

	--set assumed success message
	IF v_id IS NOT NULL THEN
		:SuccessResponse := 'Updated';
	ELSE
		:SuccessResponse := 'Created';
	END IF;
	:SuccessResponse := :SuccessResponse || ' ' || v_Value || ' translation';

	BEGIN
		--add new record or update existing one 
		IF v_id IS NULL THEN
			INSERT INTO tbl_LOC_Translation (col_Description, col_IsDraft, col_KeyID, col_LangID, col_PluralForm, col_Value, COL_UCODE) 
			VALUES 					                (v_Description,   v_IsDraft,   v_KeyID,   v_LangID,   v_PluralForm,   v_Value,   SYS_GUID()) 
			RETURNING col_id INTO v_id;
		ELSE
			UPDATE tbl_LOC_Translation
			SET col_Description = v_Description,
				col_IsDraft = v_IsDraft,
				col_KeyID = v_KeyID,
				col_LangID = v_LangID,
				col_PluralForm = v_PluralForm,
				col_Value = v_Value
			WHERE col_id = v_id;
		END IF;

		:affectedRows := SQL%ROWCOUNT;
		:recordId := v_id;

	EXCEPTION
		WHEN dup_val_on_index THEN
			:affectedRows    := 0;
			v_errorcode      := 101;
			v_errormessage   := 'There already exists a translation with the Key ID ' || v_KeyID || ' and Languege ID ' || v_LangID || ' and Plurar form ' || v_PluralForm;
			:SuccessResponse := '';
		WHEN OTHERS THEN
			:affectedRows    := 0;
			v_errorcode      := 102;
			v_errormessage   := substr(SQLERRM, 1, 200);
			:SuccessResponse := '';
	END;

	:errorCode    := v_errorcode;
	:errorMessage := v_errormessage;
END;