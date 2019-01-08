declare
	v_name varchar2(255);
	v_code varchar2(255);
	v_description nclob;
	v_stateconfig varchar2(255);
	 
	--possible flags
	v_isDefaultOnCreate integer; --0 or 1
	v_isStart integer; --0 or 1
	v_isFinish integer; --0 or 1
	 
	--calculated
	v_stateid number; --tbl_DICT_CaseState.col_id
	v_stateConfigCode varchar2(255);
	v_stateConfigName varchar2(255);
	v_calccode  varchar2(255);
	v_activity  varchar2(255);
	v_count integer;
	v_res integer;

 
begin
	v_name := :NAME;
	v_code := :CODE;
	v_description := :DESCRIPTION;
	v_stateconfig := :STATECONFIG;
	v_isDefaultOnCreate := :ISDEFAULTONCREATE;
	v_isStart := NVL(:ISSTART, 0);
	v_isFinish := NVL(:ISFINISH, 0);
	:ErrorMessage := '';
	:ErrorCode := 0;
	
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
	 
	SELECT UPPER(col_code), col_Name
	INTO v_stateConfigCode, v_stateConfigName
	FROM tbl_DICT_StateConfig
	WHERE col_id = v_stateconfig;

	-- Unique Case State Code 
	v_calccode := v_stateConfigCode || '_' || v_code; 
	 
	--Case State Config
	v_activity := 'root_CS_STATUS_' || v_calccode;

	BEGIN	
		
		INSERT INTO tbl_dict_CaseState
		(
			COL_STATECONFIGCASESTATE, 
			COL_NAME, 
			COL_CODE, 
			col_Description,
			COL_UCODE, 
			COL_ACTIVITY
		)
		VALUES
		(
			v_stateconfig, 
			v_name, 
			v_calccode, 
			v_description,
			v_calccode, 
			v_activity
		)
		RETURNING col_id into v_stateid;
					
		-- Create a record in DICT_CseSt_DtEvTp to track modification
		INSERT INTO tbl_dict_csest_dtevtp
		(
			col_csest_dtevtpcasestate, 
			col_csest_dtevtpdateeventtype
		)
		VALUES
		(
			v_stateid, 
			f_UTIL_getIdByCode(CODE=> 'DATE_CASE_MODIFIED', TableName => 'tbl_dict_dateeventtype')
		);
				   
		-- Determine if this is the default Case State for new Cases
		IF v_isDefaultOnCreate = 1 THEN

			-- Make sure that this State Config doesn't have any other States with the Default flags
			SELECT COUNT(*) INTO v_count
			FROM tbl_dict_CaseState
			WHERE COL_STATECONFIGCASESTATE = v_stateconfig 
				  AND COL_IsDefaultOnCreate = 1;

			IF(v_count > 0) THEN
				-- Exit with an error    
				:ErrorCode := 101;
				:ErrorMessage := 'Milestone has more than one states with default on create flag.';    
				RETURN;
			END IF;

			-- Set the flags on the state
			UPDATE tbl_dict_CaseState SET 
				COL_IsDefaultOnCreate = 1, 
				COL_IsDefaultOnCreate2 = 1
			WHERE col_id = v_stateid;
					 
			-- Case state date event        
			INSERT INTO tbl_dict_csest_dtevtp
			(
				col_csest_dtevtpcasestate, 
				col_csest_dtevtpdateeventtype
			)
			VALUES
			(
				v_stateid, 
				f_UTIL_getIdByCode(CODE=> 'DATE_CASE_CREATED', TableName => 'tbl_dict_dateeventtype')
			);  
		 
		END IF;
		 
		-- Set additional flags depending on whether it's NEW, IN PROCESS, or CLOSED
		IF v_isStart = 1 AND v_isFinish = 0 THEN
			-- Set the flag in the state
			UPDATE tbl_dict_CaseState SET 
				COL_IsStart = 1
			WHERE col_id = v_stateid;
		 
			-- Case state setup
			INSERT INTO tbl_dict_casestatesetup
			(
				col_CaseStateSetupCaseState, 
				col_code,
				col_notnulloverwrite,
				col_nulloverwrite,
				col_forcedoverwrite,
				col_forcednull )
			VALUES
			(
				v_stateid, 
				'RESOLUTION',
				NULL,
				NULL,
				NULL,
				1
			);
			 
			INSERT INTO tbl_dict_casestatesetup
			(
				col_CaseStateSetupCaseState, 
				col_code, 
				col_notnulloverwrite,
				col_nulloverwrite,
				col_forcedoverwrite,
				col_forcednull )
			VALUES
			(
				v_stateid, 
				'DATECLOSED', 
				NULL,
				NULL,
				NULL,
				1
			);
			  
			-- Case state date event        
			INSERT INTO tbl_dict_csest_dtevtp
			(
				col_csest_dtevtpcasestate, 
				col_csest_dtevtpdateeventtype
			)
			VALUES
			(
				v_stateid, 
				f_UTIL_getIdByCode(CODE=> 'DATE_CASE_NEW', TableName => 'tbl_dict_dateeventtype')
			);

		ELSIF v_isStart = 0 AND v_isFinish = 0 THEN

			-- Case state setup
			INSERT INTO tbl_dict_casestatesetup
			(
				col_CaseStateSetupCaseState,
				col_code, 
				col_notnulloverwrite,
				col_nulloverwrite,
				col_forcedoverwrite,
				col_forcednull 
			)
			VALUES
			(
				v_stateid, 
				'RESOLUTION', 
				NULL,
				NULL,
				NULL,
				1
			);
			 
			INSERT INTO tbl_dict_casestatesetup
			(
				col_CaseStateSetupCaseState, 
				col_code,
				col_notnulloverwrite,
				col_nulloverwrite,
				col_forcedoverwrite,
				col_forcednull 
			)
			VALUES
			(
				v_stateid, 
				'DATECLOSED', 
				NULL,
				NULL,
				NULL,
				1
			);
			  
			-- Case state date event        
			INSERT INTO tbl_dict_csest_dtevtp
			(
				col_csest_dtevtpcasestate, 
				col_csest_dtevtpdateeventtype
			)
			VALUES
			(
				v_stateid, 
				f_UTIL_getIdByCode(CODE=> 'DATE_CASE_IN_PROCESS', TableName => 'tbl_dict_dateeventtype')
			);
		ELSIF v_isStart = 0 AND v_isFinish = 1 THEN

			-- Set the flag in the state
			UPDATE tbl_dict_CaseState SET 
				COL_IsFinish = 1
			WHERE col_id = v_stateid;
		 
			--case state setup
			INSERT INTO tbl_dict_casestatesetup
			(
				col_CaseStateSetupCaseState, 
				col_code, 
				col_notnulloverwrite,
				col_nulloverwrite,
				col_forcedoverwrite,
				col_forcednull 
			)
			VALUES
			(
				v_stateid,
				'RESOLUTION',
				NULL,
				NULL,
				1,
				NULL
			);
			 
			INSERT INTO tbl_dict_casestatesetup
			(
				col_CaseStateSetupCaseState,
				col_code, 
				col_notnulloverwrite,
				col_nulloverwrite,
				col_forcedoverwrite,
				col_forcednull 
			)
			VALUES
			(
				v_stateid, 
				'DATECLOSED', 
				NULL,
				NULL,
				1,
				NULL
			);
			  
			-- Case state date event        
			INSERT INTO tbl_dict_csest_dtevtp
			(
				col_csest_dtevtpcasestate, 
				col_csest_dtevtpdateeventtype
			)
			VALUES
			(
				v_stateid, 
				f_UTIL_getIdByCode(CODE=> 'DATE_CASE_CLOSED', TableName => 'tbl_dict_dateeventtype')
			);
		END IF;
			
		--Create an AC_AccessObject record for this Case State
		INSERT INTO TBL_AC_ACCESSOBJECT(
			COL_NAME,
			COL_CODE,
			COL_ACCESSOBJECTCASESTATE,
			COL_ACCESSOBJACCESSOBJTYPE
		) VALUES (
			'Case State ' || v_stateConfigName || ' ' || v_name,
			'CASE_STATE_' || v_calccode,
			v_stateid,
			f_util_getidbycode(code => 'CASE_STATE', tablename => 'tbl_ac_accessobjecttype')
		);
				
		:OUTPUT_STATEID := v_stateid;
	
	EXCEPTION
		WHEN dup_val_on_index THEN
		  :ErrorCode      := 101;
		  :ErrorMessage   := 'There already exists a case state with the code ' || to_char(v_code);
		WHEN OTHERS THEN
		  :ErrorCode      := 102;
		  :ErrorMessage   := substr(SQLERRM, 1, 200);
	END;

end;