DECLARE
	--INPUT
	v_TargetId INTEGER;
	v_TargetType NVARCHAR2(255);
	v_Page1RuleCode NVARCHAR2(255);
	v_Page2RuleCode NVARCHAR2(255);
	v_CustomDataRuleCode NVARCHAR2(255);

	--CALCULATED CASE
	v_CaseId integer;
	v_CaseName nvarchar2(255);
	v_CaseCustomData NCLOB;
	
	--CALCULATED TASK
	v_TaskId integer;
	v_TaskName nvarchar2(255);
	v_TaskCustomData NCLOB;
	
	--CALCULATED CASE PARTY
	v_CasePartyId integer;
	v_CasePartyName nvarchar2(255);
	v_UnitId integer;
	v_UnitType nvarchar2(255);
	v_UnitName nvarchar2(255);
	
	--CUSTOM PARAMS
	v_Page1Params NCLOB;
	v_Page2Params NCLOB;
	v_CustomDataParams NCLOB;
	
	--SYSTEM
	v_message NCLOB;

BEGIN
	--INPUT
	v_TargetId := :TargetId;
	v_TargetType := lower(:TargetType);
	v_Page1RuleCode := TRIM(:Page1RuleCode);
	v_Page2RuleCode := TRIM(:Page2RuleCode) ;
	v_CustomDataRuleCode := TRIM(:CustomDataRuleCode);
	
	--CALCULATED
	IF v_TargetType = 'task' THEN
		v_TaskId := v_TargetId;
		v_CaseId := f_DCM_getCaseIdByTaskId(v_TaskId);	
	ELSIF v_TargetType = 'case' THEN
		v_CaseId := v_TargetId;	
	END IF;
	
	--SYSTEM
	v_message := '';

	--GET CASE PAGE INFO
	OPEN :CUR_CASEPAGE FOR
        SELECT 'Case_Id' as NAME, TO_CHAR(v_CaseId) as VALUE
        FROM DUAL
		UNION ALL	
		SELECT 'app' as NAME, 'CaseDetailRuntime' as VALUE
        FROM DUAL
		UNION ALL	
		SELECT 'group' as NAME, 'FOM' as VALUE
        FROM DUAL
		UNION ALL	
		SELECT 'usePageConfig' as NAME, '1' as VALUE
        FROM DUAL
		UNION ALL
		SELECT 'EmbeddedMode' as NAME, '1' as VALUE
        FROM DUAL;		
	
	SELECT col_caseid, F_dcm_getcasecustomdata(col_id)
	INTO v_caseName, v_CaseCustomData
	FROM tbl_Case
	Where col_id = v_CaseId;
	

	--GET TASK PAGE INFO
	OPEN :CUR_TASKPAGE FOR
        SELECT 'Case_Id' as NAME, TO_CHAR(v_CaseId) as VALUE
        FROM DUAL
		UNION ALL
		SELECT 'Task_Id' as NAME, TO_CHAR(v_TaskId) as VALUE
        FROM DUAL
		UNION ALL		
		SELECT 'app' as NAME, 'TaskDetailRuntime' as VALUE
        FROM DUAL
		UNION ALL	
		SELECT 'group' as NAME, 'FOM' as VALUE
        FROM DUAL
		UNION ALL	
		SELECT 'usePageConfig' as NAME, '1' as VALUE
        FROM DUAL
		UNION ALL
		SELECT 'EmbeddedMode' as NAME, '1' as VALUE
        FROM DUAL;
		
	BEGIN
		SELECT col_taskid, F_dcm_gettaskcustomdata(col_id)
		INTO v_taskName, v_TaskCustomData
		FROM tbl_Task
		Where col_id = v_TaskId;
	EXCEPTION WHEN OTHERS THEN
		NULL;
	END;
	

	--GET CASE PARTY INFO (SUPPORT ONLY EXTERNAL PARTY FOR NOW)
	BEGIN
		SELECT ID, NAME, CALC_ID, lower(PARTYTYPE_CODE), CALC_NAME
		INTO v_CasePartyId, v_CasePartyName, v_UnitId, v_UnitType, v_UnitName
		FROM vw_ppl_caseparty
		WHERE case_id = v_CaseId AND NVL(CALC_ID, 0) > 0 AND lower(PARTYTYPE_CODE) = 'external_party' AND ROWNUM = 1;
	EXCEPTION WHEN OTHERS THEN
		v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: No external parties found in Case Party list');
		NULL;
	END;
	
	IF v_UnitType = 'external_party' THEN
		OPEN :CUR_CASEPARTYPAGE FOR
			SELECT 'ExternalParty_Id' as NAME, TO_CHAR(2) as VALUE
			FROM DUAL
			UNION ALL		
			SELECT 'app' as NAME, 'ExternalPartyDetailRuntime' as VALUE
			FROM DUAL
			UNION ALL	
			SELECT 'group' as NAME, 'FOM' as VALUE
			FROM DUAL
			UNION ALL	
			SELECT 'usePageConfig' as NAME, '1' as VALUE
			FROM DUAL
			UNION ALL
			SELECT 'EmbeddedMode' as NAME, '1' as VALUE
			FROM DUAL;
	END IF;
	
	--CALCULATE CUSTOM PARAMS
	IF v_Page1RuleCode IS NOT NULL THEN
		BEGIN
			v_Page1Params := f_UTIL_genericInvokerFn(ProcessorName => v_Page1RuleCode, TargetId => V_TargetId, TargetType => v_TargetType);
		EXCEPTION WHEN OTHERS THEN
			v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: invoke for ' || v_Page1RuleCode || ' - ' || SQLERRM);
			v_Page1Params := '';
		END;
	END IF;
	
	IF v_Page2RuleCode IS NOT NULL THEN
		BEGIN
			v_Page2Params := f_UTIL_genericInvokerFn(ProcessorName => v_Page2RuleCode, TargetId => V_TargetId, TargetType => v_TargetType);		
		EXCEPTION WHEN OTHERS THEN
			v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: invoke for ' || v_Page2RuleCode || ' - ' || SQLERRM);
			v_Page2Params := '';
		END;
	END IF;
	
	IF v_CustomDataRuleCode IS NOT NULL THEN
		BEGIN
			v_CustomDataParams := f_UTIL_genericInvokerFn(ProcessorName => v_CustomDataRuleCode, TargetId => V_TargetId, TargetType => v_TargetType);	
		EXCEPTION WHEN OTHERS THEN
			v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: invoke for ' || v_CustomDataParams || ' - ' || SQLERRM);
			v_CustomDataParams := '';
		END;		
	END IF;
	
	--GATHER ALL OUTPUT
	:CaseName := v_CaseName;
	:CaseCustomData := v_CaseCustomData;
	
	--CALCULATED TASK
	:TaskName := v_TaskName;
	:TaskCustomData := v_TaskCustomData;
	
	--CALCULATED CASE PARTY
	:CasePartyName := v_CasePartyName;
	:UnitId := v_UnitId;
	:UnitType := v_UnitType;
	:UnitName := v_UnitName; 
	
	--CUSTOM PARAMS
	:Page1Params := v_Page1Params;
	:Page2Params := v_Page2Params;
	:CustomDataParams := v_CustomDataParams;
	
	--INFO
	:TraceMessage := v_message;

END;