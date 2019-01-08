DECLARE
  v_countDeletedRecords     INTEGER;
  v_listNotAllowDelete      NVARCHAR2(32767);
  v_sql                     VARCHAR2(32767);
  v_template_delete         VARCHAR2(255);
  v_Id                      INTEGER;
  v_Ids                     NVARCHAR2(4000);
  v_isDetailedInfo          BOOLEAN;
  v_countCases              INTEGER;
  v_countStatisticalReports INTEGER;
  v_count                   INTEGER;
  v_temp                    NVARCHAR2(255);
  v_result                  NUMBER;
  v_MessageParams           NES_TABLE := NES_TABLE();
  localhash                 ecxtypes.params_hash;
  v_createdby               NVARCHAR2(255);
  v_domain                  NVARCHAR2(255);
  v_UseDataModel            NUMBER;
BEGIN

  :SuccessResponse          := EMPTY_CLOB();
  :affectedRows             := 0;
  :ErrorMessage             := '';
  :ErrorCode                := 0;
  v_Ids                     := :Ids;
  v_Id                      := :Id;
  v_template_delete         := '  
    DELETE FROM #TABLE_NAME#  
    WHERE #PRIMARY_KEY# = #VALUE_KEY# 
  ';
  v_countStatisticalReports := 0;
  v_countCases              := 0;
  v_count                   := 0;
  v_countDeletedRecords     := 0;
  v_temp                    := '';
  v_createdby               := '@TOKEN_USERACCESSSUBJECT@';
  v_domain                  := '@TOKEN_DOMAIN@';

  --Input param check
  IF v_Ids IS NULL AND v_Id IS NULL THEN
    :ErrorMessage := 'Id can not be empty';
    :ErrorCode    := 101;
    RETURN;
  END IF;

  IF (v_Id IS NOT NULL) THEN
    v_Ids            := TO_CHAR(v_id);
    v_isDetailedInfo := FALSE;
  ELSE
    v_isDetailedInfo := TRUE;
  END IF;

  FOR mRec IN (SELECT COLUMN_VALUE AS id FROM TABLE(ASF_SPLIT(v_Ids, ','))) LOOP
  
    -- validation on delete
    SELECT COUNT(*) INTO v_countCases FROM TBL_CASE WHERE COL_CASEDICT_CASESYSTYPE = mRec.id;
    SELECT SUM(cnt)
      INTO v_countStatisticalReports
      FROM (SELECT COUNT(*) AS cnt
              FROM tbl_StatCaseDay
             WHERE COL_STATCASEDAYCASESYSTYPE = mRec.id
            UNION ALL
            SELECT COUNT(*)
              FROM tbl_StatCaseMonth
             WHERE COL_STATCASEMONTHCASESYSTYPE = mRec.id
            UNION ALL
            SELECT COUNT(*)
              FROM tbl_StatCaseWeek
             WHERE COL_STATCASEWEEKCASESYSTYPE = mRec.id);
  
    IF (v_countCases > 0 OR v_countStatisticalReports > 0) THEN
      BEGIN
      
        SELECT col_Name INTO v_temp FROM TBL_DICT_CASESYSTYPE WHERE col_Id = mRec.id;
      
        IF (v_isDetailedInfo) THEN
          v_listNotAllowDelete := v_listNotAllowDelete || '<br>' || v_temp || ' $t(related with:)';
        END IF;
      
        IF (v_countCases > 0) THEN
          --v_listNotAllowDelete := v_listNotAllowDelete || ' ' || v_countCases  || ' Case(s); ';
          v_listNotAllowDelete := v_listNotAllowDelete || ' $t(MESS_CASES, {"count":'||v_countCases||',"ns":"Rule"})';
          --v_MessageParams.EXTEND(1);
          --v_MessageParams(v_MessageParams.LAST) := Key_Value('MESS_CASES_COUNT', v_countCases);
        END IF;
      
        IF (v_countStatisticalReports > 0) THEN
          --v_listNotAllowDelete := v_listNotAllowDelete || ' ' || v_countStatisticalReports  || ' Statistical Report(s); ';
          v_listNotAllowDelete := v_listNotAllowDelete || ' $t(INV_MESS_STAT_REPORT)';
          v_MessageParams.EXTEND(1);
          v_MessageParams(v_MessageParams.LAST) := Key_Value('MESS_STAT_REPORT_COUNT', v_countStatisticalReports);
        END IF;
      
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      CONTINUE;
    END IF;
  
    DELETE FROM TBL_AC_ACL WHERE COL_ACLACCESSOBJECT IN (SELECT COL_ID FROM TBL_AC_ACCESSOBJECT WHERE COL_ACCESSOBJECTCASESYSTYPE = mRec.id);
  
    DELETE FROM TBL_AC_ACCESSOBJECT WHERE COL_ACCESSOBJECTCASESYSTYPE = mRec.id;
  
    -- delete Documents
    v_count := f_doc_destroydocumentfn(case_id                 => NULL,
                                       casetype_id             => mRec.id,
                                       caseworker_id           => NULL,
                                       errorcode               => :ErrorCode,
                                       errormessage            => :ErrorMessage,
                                       extparty_id             => NULL,
                                       ids                     => NULL,
                                       task_id                 => NULL,
                                       team_id                 => NULL,
                                       token_domain            => '@TOKEN_DOMAIN@',
                                       token_useraccesssubject => '@TOKEN_USERACCESSSUBJECT@');
  
    DELETE FROM TBL_TASKTEMPLATE WHERE COL_PROCEDURETASKTEMPLATE IN (SELECT COL_ID FROM TBL_PROCEDURE WHERE COL_PROCEDUREDICT_CASESYSTYPE = mRec.id);
  
    /*  -- TODO
        -- delete MDM Model
        BEGIN
          SELECT col_usedatamodel INTO v_UseDataModel FROM tbl_dict_casesystype WHERE col_id = mRec.id;
        EXCEPTION
          WHEN OTHERS THEN
            v_UseDataModel := NULL;
        END;
        IF NVL(v_UseDataModel, 0) = 1 THEN
          BEGIN
            localhash('CaseTypeId') := mRec.id;
            localhash('SolutionVersion') := :SolutionVersion;
            v_result := QUEUE_addWithHash(v_code            => sys_guid(),
                                          v_domain          => v_domain,
                                          v_createddate     => SYSDATE,
                                          v_createdby       => v_createdby,
                                          v_owner           => v_createdby,
                                          v_scheduleddate   => SYSDATE,
                                          v_objecttype      => 1,
                                          v_processedstatus => 1,
                                          v_processeddate   => SYSDATE,
                                          v_errorstatus     => 0,
                                          v_parameters      => localhash,
                                          v_priority        => 0,
                                          v_objectcode      => 'root_DOM_deleteModelBOs_cs',
                                          v_error           => '');
          END;
        END IF;
    */
  
    -- delete Custom Milestone
    v_result := f_dcm_cleanupmsdata(casesystypeid => mRec.id, customstateconfigid => NULL, errorcode => :ErrorCode, errormessage => :ErrorMessage);
  
    -- delete from table
    -- TODO table must be output in user interface
    FOR rec IN (SELECT 'TBL_ASSOCPAGE' AS TableName,
                       'COL_ASSOCPAGEDICT_CASESYSTYPE' AS ColumnName
                  FROM Dual
                UNION ALL
                SELECT 'TBL_AUTORULEPARAMETER',
                       'COL_AUTORULEPARAMCASESYSTYPE'
                  FROM Dual
                UNION ALL
                SELECT 'TBL_CUSTOMATTRIBUTE',
                       'COL_CUSTOMATTRIBUTECASETYPE'
                  FROM Dual
                UNION ALL
                SELECT 'TBL_CASESYSTYPERESOLUTIONCODE',
                       'COL_TBL_DICT_CASESYSTYPE'
                  FROM Dual
                UNION ALL
                SELECT 'TBL_NOTE',
                       'COL_DICT_CASESYSTYPENOTE'
                  FROM Dual
                UNION ALL
                SELECT 'TBL_MAP_CASESTATEINITTMPL',
                       'COL_CASESTATEINITTP_CASETYPE'
                  FROM Dual
                UNION ALL
                SELECT 'TBL_MAP_CASESTATEINITIATION',
                       'COL_CASESTATEINIT_CASESYSTYPE'
                  FROM Dual
                UNION ALL
                SELECT 'TBL_PARTICIPANT',
                       'COL_PARTICIPANTCASESYSTYPE'
                  FROM Dual
                /*                UNION ALL
                SELECT 'TBL_PROCEDURE', 'COL_PROCEDUREDICT_CASESYSTYPE'
                  FROM Dual */
                UNION ALL
                SELECT 'TBL_STP_AVAILABLEADHOC',
                       'COL_CASESYSTYPE'
                  FROM Dual
                UNION ALL
                SELECT 'TBL_AC_ACCESSOBJECT',
                       'COL_ACCESSOBJECTCASESYSTYPE'
                  FROM Dual
                UNION ALL
                SELECT 'TBL_CASELINKTMPL',
                       'COL_CASELINKTMPLCHILDCASETYPE'
                  FROM Dual
                UNION ALL
                SELECT 'TBL_CASELINKTMPL',
                       'COL_CASELINKTMPLPRNTCASETYPE'
                  FROM Dual
                UNION ALL
                SELECT 'TBL_FOM_PAGE',
                       'COL_PAGECASESYSTYPE'
                  FROM Dual
                UNION ALL
                SELECT 'TBL_DICT_CASESYSTYPE',
                       'COL_ID'
                  FROM Dual) LOOP
      v_sql := REPLACE(v_template_delete, '#PRIMARY_KEY#', rec.ColumnName);
      v_sql := REPLACE(v_sql, '#TABLE_NAME#', rec.TableName);
      v_sql := REPLACE(v_sql, '#VALUE_KEY#', mRec.id);
      --dbms_output.put_line('sql delete: ' || v_sql);
      EXECUTE IMMEDIATE v_sql;
    END LOOP;
  
    v_countDeletedRecords := v_countDeletedRecords + 1;
  END LOOP;

  --get affected rows
  :affectedRows := SQL%ROWCOUNT;

  IF (v_listNotAllowDelete IS NOT NULL) THEN
  
    /*IF(LENGTH(v_listNotAllowDelete) > 255) THEN
    v_listNotAllowDelete := SUBSTR(v_listNotAllowDelete, 1, 255) || '...';
      END IF;*/
  
    :ErrorCode := 102;
  
    IF (v_isDetailedInfo) THEN
      --:ErrorMessage := 'Count of deleted Case Type(s): ' || v_countDeletedRecords || CHR(13)||CHR(10);
      --:ErrorMessage := :ErrorMessage || 'List of not deleted Case Type(s): ' || v_listNotAllowDelete;
    
      v_MessageParams.EXTEND(2);
      v_MessageParams(v_MessageParams.LAST - 1) := KEY_VALUE('MESS_COUNT', v_countDeletedRecords);
      v_MessageParams(v_MessageParams.LAST) := KEY_VALUE('MESS_LIST_NOT_DELETED', v_listNotAllowDelete);
    
      :ErrorMessage := 'Count of deleted Case Types: {{MESS_COUNT}} <br>List of not deleted Case Types: {{MESS_LIST_NOT_DELETED}}';
    ELSE
      --:ErrorMessage := 'You can''t delete this Case Type, because it relates with: ' || v_listNotAllowDelete;    
    
      v_MessageParams.EXTEND(1);
      v_MessageParams(v_MessageParams.LAST) := KEY_VALUE('MESS_LIST_NOT_DELETED', v_listNotAllowDelete);
    
      :ErrorMessage := 'You can''t delete this Case Type, because it relates with: {{MESS_LIST_NOT_DELETED}}';
    END IF;
  
    v_result := LOC_i18n(MessageText => :ErrorMessage, MessageParams => v_MessageParams, DisableEscapeValue => TRUE, MessageResult => :ErrorMessage);
  ELSE
    --:SuccessResponse := 'Deleted ' || v_countDeletedRecords || ' items';
    v_result := LOC_i18n(MessageText   => 'Deleted {{MESS_COUNT}} items',
                         MessageResult => :SuccessResponse,
                         MessageParams => NES_TABLE(Key_Value('MESS_COUNT', v_countDeletedRecords)));
  END IF;

END;