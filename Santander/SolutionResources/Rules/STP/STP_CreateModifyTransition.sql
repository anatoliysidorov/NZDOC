DECLARE
   v_id               NUMBER;
   v_name             NVARCHAR2(255);
   v_code             NVARCHAR2(255);
   v_description      NCLOB;
   v_sourcestate_id   NUMBER;
   v_targetstate_id   NUMBER;
   v_typestate        NVARCHAR2(255);
   v_transition       NVARCHAR2(255);
   v_statecofig_Code  NVARCHAR2(255);
   v_ucode            NVARCHAR2(255);
   v_count            NUMBER;

   v_errorcode        NUMBER;
   v_errormessage     NVARCHAR2(255);
BEGIN
   v_id := :Id;
   v_name := :NAME;
   v_code := :Code;
   v_description := :Description;
   v_transition := :Transition;
   v_sourcestate_id := :SrcState_Id;
   v_targetstate_id := :TrgState_Id;
   v_typestate := :TypeState;
   v_count := 0;

   :affectedRows := 0;
   v_errorcode := 0;
   v_errormessage := '';

   -- Input params validation
   IF (v_typestate IS NULL)
   THEN
      v_errormessage := 'TypeState can not be empty';
      v_errorcode := 103;
      GOTO cleanup;
   END IF;

   IF (v_sourcestate_id IS NULL OR v_targetstate_id IS NULL)
   THEN
      v_errormessage := 'SourceStateId or TargetStateId can not be empty';
      v_errorcode := 104;
      GOTO cleanup;
   END IF;

   IF (UPPER(v_typestate) NOT IN ('TASK', 'CASE'))
   THEN
      v_errormessage := 'TypeState can not be other type, than TASK or CASE';
      v_errorcode := 105;
      GOTO cleanup;
   END IF;

   --set success message
   IF v_id IS NOT NULL
   THEN
      :SuccessResponse := 'Updated';
   ELSE
      :SuccessResponse := 'Created';
   END IF;

   :SuccessResponse :=
         :SuccessResponse
      || ' '
      || v_name
      || ' '
      || LOWER(v_typestate)
      || ' transition';

   BEGIN
      --add new record
      IF v_id IS NULL
      THEN
	  	 v_ucode := SYS_GUID();
         IF UPPER(v_typestate) = 'CASE'
         THEN
			 BEGIN
				 SELECT
				 stc.col_code
				 INTO v_statecofig_Code
				 FROM TBL_DICT_CASESTATE st
				 LEFT JOIN TBL_DICT_STATECONFIG stc on stc.col_id = St.Col_Stateconfigcasestate
				 WHERE st.col_id = v_sourcestate_id;
				 EXCEPTION WHEN NO_DATA_FOUND THEN
				 v_statecofig_Code:= 'CASE_TR';
			 END;
            INSERT INTO TBL_DICT_CASETRANSITION
			  ( col_code,
				col_name,
				col_transition,
				col_description,
				col_sourcecasetranscasestate,
				col_targetcasetranscasestate,
				col_ucode)
			  VALUES
			  ( v_statecofig_Code||'_'||v_code,
				v_name,
				v_ucode,
				v_description,
				v_sourcestate_id,
				v_targetstate_id,
				v_ucode )
			RETURNING col_id INTO v_id;
         ELSE
			 BEGIN
				 SELECT
				 stc.col_code
				 INTO v_statecofig_Code
				 FROM TBL_DICT_TASKSTATE st
				 LEFT JOIN TBL_DICT_STATECONFIG stc on stc.col_id = St.Col_Stateconfigtaskstate
				 WHERE st.col_id = v_sourcestate_id;
				 EXCEPTION WHEN NO_DATA_FOUND THEN
				 v_statecofig_Code:= 'TASK_TR';
			 END;
            INSERT	INTO TBL_DICT_TASKTRANSITION
			  ( col_code,
				col_name,
				COL_TRANSITION,
				col_description,
				col_sourcetasktranstaskstate,
				col_targettasktranstaskstate,
				col_ucode
				)
			  VALUES(
				v_statecofig_Code||'_'||v_code,
				v_name,
				v_ucode,
				v_description,
				v_sourcestate_id,
				v_targetstate_id,
				v_ucode
				)
			RETURNING col_id INTO v_id;
         END IF;
         
        :affectedRows := 1;
        :recordId := v_id;
      ELSE  
          -- update existing one
          IF UPPER(v_typestate) = 'CASE'
          THEN
             UPDATE TBL_DICT_CASETRANSITION
                SET col_name = v_name,
                    --col_transition = v_transition,
                    col_description = v_description,
                    col_sourcecasetranscasestate = v_sourcestate_id,
                    col_targetcasetranscasestate = v_targetstate_id
              WHERE col_id = v_id;
          ELSE
             UPDATE TBL_DICT_TASKTRANSITION
                SET col_name = v_name,
                    --col_transition = v_transition,
                    col_description = v_description,
                    col_sourcetasktranstaskstate = v_sourcestate_id,
                    col_targettasktranstaskstate = v_targetstate_id
              WHERE col_id = v_id;
          END IF;

          :affectedRows := 1;
          :recordId := v_id;
      END IF;

   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         :affectedRows := 0;
         v_errorcode := 101;
         v_errormessage :=
               'There already exists a '
            || LOWER(v_typestate)
            || ' transtition with the code '
            || TO_CHAR(v_code);
         :SuccessResponse := '';
      WHEN OTHERS
      THEN
         :affectedRows := 0;
         v_errorcode := 102;
         v_errormessage := SUBSTR(SQLERRM, 1, 200);
         :SuccessResponse := '';
   END;

  <<cleanup>>
   :errorCode := v_errorcode;
   :errorMessage := v_errormessage;
END;