DECLARE

  TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

  v_sourceId    NUMBER;
  v_name        NVARCHAR2(255);
  v_code        NVARCHAR2(255);
  v_iconcode    NVARCHAR2(255);
  v_calccode    NVARCHAR2(255);
  v_activity    NVARCHAR2(255);
  v_StCgId      NUMBER;
  v_CsStId_trg  NUMBER;
  v_CsStId_src  NUMBER;
  v_transitonid NUMBER;
  v_transition  NVARCHAR2(255);
  v_res         NUMBER;
  v_isCloneWithOptions NUMBER;
  arr_CsStIds t_ids;
  v_cnt NUMBER;
  v_tmp NUMBER;
  v_result NUMBER;

  --standard  
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_sourceId := :sourceId;
  v_name     := :NAME;
  v_code     := :CODE;
  v_iconcode := :IconCode;
  v_isCloneWithOptions := :isCloneWithOptions;
  
  --standard  
  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';

  ---Input params check
  IF v_sourceId IS NULL THEN
    v_errormessage := 'SourceId can not be empty';
    v_errorcode    := 101;
    GOTO cleanup;
  END IF;

  BEGIN
  
	IF v_isCloneWithOptions IS NOT NULL THEN	
		-- Generate UNIQUE name
		v_cnt := 0;
		v_tmp := 0;
		
		loop			
			v_tmp := v_tmp + 1;
			v_name := :NAME || '_' || v_tmp;
            v_code := :CODE || '_' || v_tmp;
			
			SELECT COUNT(*) into v_cnt
			FROM tbl_dict_stateconfig 
			where (col_name = v_name or col_code = v_code)
                  and col_id <> v_sourceId;
			exit when v_cnt = 0;
		end loop;				
	
	END IF;
  
    -- clone StateConfig record
    BEGIN
      FOR rec IN (SELECT col_isdeleted, col_config, col_type, col_name, col_stateconfstateconftype FROM tbl_dict_stateconfig WHERE col_id = v_sourceId) LOOP
        INSERT INTO tbl_dict_stateconfig
          (col_isdeleted, col_config, col_type, col_name, col_code, col_iconcode, col_stateconfstateconftype)
        VALUES
          (rec.col_isdeleted, rec.col_config, rec.col_type, v_name, v_code, v_iconcode, rec.col_stateconfstateconftype)
        RETURNING col_id INTO v_StCgId;
      
        :recordId        := v_StCgId;
        :SuccessResponse := 'Milestone ' || rec.col_name || ' was cloned to milestone ' || v_name;
        :affectedRows    := 1;
      END LOOP;
    EXCEPTION
      WHEN dup_val_on_index THEN
        :affectedRows    := 0;
        v_errorcode      := 102;
        v_errormessage   := 'There already exists a milestone with the code ' || v_code;
        :SuccessResponse := '';
        GOTO cleanup;
    END;
  
    -- clone CaseState records
    FOR rec IN (SELECT col_id,
                       col_name,
                       col_description,
                       col_isdefaultoncreate2,
                       col_isdefaultoncreate,
                       col_isstart,
                       col_isresolve,
                       col_isfinish,
                       UPPER(REPLACE(REPLACE(col_name, chr(10), ''), ' ', '_')) AS calccode
                  FROM tbl_dict_casestate
                 WHERE col_stateconfigcasestate = v_sourceId) LOOP
      v_CsStId_src := rec.col_id;
    
      -- Unique Case State Code 
      v_calccode := UPPER(v_code) || '_' || UPPER(rec.calccode);
    
      --Case State Config
      v_activity := 'root_CS_STATUS_' || v_calccode;
    
      INSERT INTO tbl_dict_casestate
        (col_stateconfigcasestate,
         col_name,
         col_code,
         col_description,
         col_ucode,
         col_activity,
         col_isdefaultoncreate2,
         col_isdefaultoncreate,
         col_isstart,
         col_isresolve,
         col_isfinish)
      VALUES
        (v_StCgId,
         rec.col_name,
         v_calccode,
         rec.col_description,
         v_calccode,
         v_activity,
         rec.col_isdefaultoncreate2,
         rec.col_isdefaultoncreate,
         rec.col_isstart,
         rec.col_isresolve,
         rec.col_isfinish)
      RETURNING col_id INTO v_CsStId_trg;
    
      -- array of references CaseStateId_old - CaseStateId_new
      arr_CsStIds(v_CsStId_src) := v_CsStId_trg;
    
      -- clone DICT_CseSt_DtEvTp records
      FOR rec_csest IN (SELECT col_csest_dtevtpdateeventtype FROM tbl_dict_csest_dtevtp WHERE col_csest_dtevtpcasestate = v_CsStId_src) LOOP
      
        INSERT INTO tbl_dict_csest_dtevtp
          (col_csest_dtevtpcasestate, col_csest_dtevtpdateeventtype)
        VALUES
          (v_CsStId_trg, rec_csest.col_csest_dtevtpdateeventtype);
      END LOOP;
    
      -- clone DICT_CaseStateSetup records
      FOR rec_css IN (SELECT col_code, col_notnulloverwrite, col_nulloverwrite, col_forcedoverwrite, col_forcednull
                        FROM tbl_dict_casestatesetup
                       WHERE col_CaseStateSetupCaseState = v_CsStId_src) LOOP
      
        INSERT INTO tbl_dict_casestatesetup
          (col_CaseStateSetupCaseState, col_code, col_notnulloverwrite, col_nulloverwrite, col_forcedoverwrite, col_forcednull)
        VALUES
          (v_CsStId_trg,
           rec_css.col_code,
           rec_css.col_notnulloverwrite,
           rec_css.col_nulloverwrite,
           rec_css.col_forcedoverwrite,
           rec_css.col_forcednull);
      
      END LOOP;
    
      --Create an AC_AccessObject record for this Case State
      INSERT INTO tbl_ac_accessobject
        (col_name, col_code, col_accessobjectcasestate, col_accessobjaccessobjtype)
      VALUES
        ('Case State ' || UPPER(v_code) || ' ' || rec.col_name,
         'CASE_STATE_' || v_calccode,
         v_CsStId_trg,
         f_util_getidbycode(code => 'CASE_STATE', tablename => 'tbl_ac_accessobjecttype'));
    
    END LOOP;
  
    -- clone CaseTransition records
    FOR rec IN (SELECT ct.col_name,
                       ct.col_sourcecasetranscasestate,
                       ct.col_targetcasetranscasestate,
                       ct.col_isprevdefault,
                       ct.col_isnextdefault,
                       ct.col_manualonly,
                       ct.col_description,
                       UPPER(REPLACE(REPLACE(cs_src.col_name || '_TO_' || cs_trg.col_name, chr(10), ''), ' ', '_')) AS calccode
                  FROM tbl_dict_casetransition ct
                  LEFT JOIN tbl_dict_casestate cs_src
                    ON cs_src.col_id = ct.col_sourcecasetranscasestate
                  LEFT JOIN tbl_dict_casestate cs_trg
                    ON cs_trg.col_id = ct.col_targetcasetranscasestate
                 WHERE ct.col_sourcecasetranscasestate IN (SELECT col_id FROM tbl_dict_casestate WHERE nvl(col_stateconfigcasestate, 0) = v_sourceId)
                   AND ct.col_targetcasetranscasestate IN (SELECT col_id FROM tbl_dict_casestate WHERE nvl(col_stateconfigcasestate, 0) = v_sourceId)) LOOP
    
      v_calccode   := UPPER(v_code) || '_' || rec.calccode;
      v_transition := 'root_CS_STATUS_' || v_calccode;
    
      INSERT INTO tbl_dict_casetransition
        (col_name,
         col_code,
         col_description,
         col_sourcecasetranscasestate,
         col_targetcasetranscasestate,
         col_ucode,
         col_transition,
         col_isprevdefault,
         col_isnextdefault,
         col_manualonly)
      VALUES
        (rec.col_name,
         v_calccode,
         rec.col_description,
         arr_CsStIds(rec.col_sourcecasetranscasestate),
         arr_CsStIds(rec.col_targetcasetranscasestate),
         v_calccode,
         v_transition,
         rec.col_isprevdefault,
         rec.col_isnextdefault,
         rec.col_manualonly)
      RETURNING col_id INTO v_transitonid;
    
      --Create an AC_AccessObject record for this Case Transition
      INSERT INTO tbl_ac_accessobject
        (col_name, col_code, col_accessobjcasetransition, col_accessobjaccessobjtype)
      VALUES
        ('Case Transition ' || UPPER(v_code) || ' ' || rec.col_name,
         'CASE_TRANSITION_' || v_calccode,
         v_transitonid,
         f_util_getidbycode(code => 'CASE_TRANSITION', tablename => 'tbl_ac_accessobjecttype'));
    
    END LOOP;
	
	IF v_isCloneWithOptions IS NOT NULL THEN
	
		
		-- Update MAP data
		FOR rec IN (SELECT cst.col_id 
					FROM tbl_dict_casesystype cst
					WHERE cst.col_stateconfigcasesystype = v_sourceId
						  AND (SELECT COUNT(*)
							  FROM tbl_Case c
							  WHERE c.COL_CASEDICT_CASESYSTYPE = cst.col_Id) <> 0)
		LOOP
					
			
			-- Update CaseType
			UPDATE TBL_DICT_CASESYSTYPE 
			SET	col_stateconfigcasesystype = v_StCgId
			WHERE col_Id = rec.col_Id;		
					
			v_result := F_STP_SYNCCASESTATEINITTMPLSFN(rec.col_id, v_errorcode, v_errormessage);
			IF v_errorcode <> 0 THEN
			   -- Code 20512 does not mean anything and was selected randomly.
			   raise_application_error(-20512, v_errormessage); 
			END IF;
			
		END LOOP;
			
	END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      -- Clear added records
      v_res := f_stp_destroycasestatedetail(errorcode => v_errorcode, errormessage => v_errormessage, stateconfig => v_StCgId);
      DELETE FROM tbl_dict_stateconfig WHERE col_id = v_StCgId;
    
      :affectedRows    := 0;
      v_errorcode      := 104;
      v_errormessage   := Substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;