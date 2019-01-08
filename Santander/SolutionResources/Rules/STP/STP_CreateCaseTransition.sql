declare
    --input for each state we want to add
    v_name varchar2(255);
    v_code varchar2(255);
    v_iconcode varchar2(255);
    v_description nclob;
    v_sourceState integer;
    v_targetState integer;
    v_stateconfig integer;
     
    --possible flags
    v_isNextDefault integer;
     
    --calculated
    v_stateConfigCode varchar2(255);
    v_stateConfigName varchar2(255);
    v_calccode  varchar2(255);
    v_transition  varchar2(255);
    v_transitonid integer;
    v_res integer; 
begin
    v_name := :NAME;
    v_code := :CODE;
    v_iconcode := :ICONCODE;
    v_description := :DESCRIPTION;
    v_sourceState := :SOURCESTATE;
    v_targetState := :TARGETSTATE; 
    v_isNextDefault := NVL(:ISNEXTDEFAULT, 0); 
    v_stateconfig := :STATECONFIG; 
    :ErrorCode := 0;
    :ErrorMessage := '';
     
    -- validation if record is not exist
    IF NVL(v_stateconfig, 0) > 0 THEN
        v_res := f_UTIL_getId(errorcode    => :ErrorCode,
                              errormessage => :ErrorMessage,
                              id           => v_stateconfig,
                              tablename    => 'tbl_DICT_StateConfig');
        IF :ErrorCode > 0 THEN
            RETURN;
        END IF;
    END IF;

    SELECT UPPER(col_code), col_name
    INTO v_stateConfigCode, v_stateConfigName
    FROM tbl_DICT_StateConfig
    WHERE col_id = v_stateconfig;
     
    v_calccode := v_stateConfigCode || '_' || v_code;
    v_transition := 'root_CS_STATUS_' || v_calccode;
     
	BEGIN  
		--Create the Case Transition
		INSERT INTO tbl_DICT_CaseTransition
		(
			COL_NAME, 
			COL_CODE, 
			col_Description,
			COL_SOURCECASETRANSCASESTATE, 
			COL_TARGETCASETRANSCASESTATE, 
			COL_UCODE, 
			COL_TRANSITION
		)
		VALUES
		(
			v_name, 
			v_calccode,
			v_description,			
			v_sourceState, 
			v_targetState, 
			v_calccode, 
			v_transition
		)
		RETURNING col_id into v_transitonid;
		 
		IF v_isNextDefault = 1 THEN
			--Make sure there are no other default transitions out of this state
			UPDATE tbl_DICT_CaseTransition SET
				COL_ISNEXTDEFAULT = 0
			WHERE COL_SOURCECASETRANSCASESTATE = v_sourceState;
			 
			--Set the flag
			UPDATE tbl_DICT_CaseTransition SET 
				COL_ISNEXTDEFAULT = 1
			WHERE COL_ID = v_transitonid;
		END IF;
		 
		--Create an AC_AccessObject record for this Case Transition
		INSERT INTO TBL_AC_ACCESSOBJECT(
			COL_NAME,
			COL_CODE,
			COL_ACCESSOBJCASETRANSITION,
			COL_ACCESSOBJACCESSOBJTYPE
		) VALUES (
			'Case Transition ' || v_stateConfigName || ' ' || v_name,
			'CASE_TRANSITION_' || v_calccode,
			v_transitonid,
			f_util_getidbycode(code => 'CASE_TRANSITION', tablename => 'tbl_ac_accessobjecttype')
		);
		
  EXCEPTION
    WHEN dup_val_on_index THEN
      :ErrorCode      := 101;
      :ErrorMessage   := 'There already exists a case transition with the code ' || to_char(v_code);
    WHEN OTHERS THEN
      :ErrorCode      := 102;
      :ErrorMessage   := substr(SQLERRM, 1, 200);
  END;	
		
end;