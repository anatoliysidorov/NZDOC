DECLARE
  v_Ids                     NVARCHAR2(32767);
  v_Id                      PLS_INTEGER;
  v_sql                     VARCHAR2(32767);
  v_template_delete         VARCHAR2(255);
  v_listNotAllowDelete      NVARCHAR2(4000);
  v_temp                    TBL_DICT_TASKSYSTYPE.COL_NAME%TYPE;
  v_countDeletedRecords     PLS_INTEGER := 0;
  v_countTasks              PLS_INTEGER := 0;
  v_countTaskTemplates      PLS_INTEGER := 0;
  v_countStatisticalReports PLS_INTEGER := 0;
  v_isDetailedInfo          BOOLEAN;
  v_MessageParams           NES_TABLE := NES_TABLE();
  v_result                  NUMBER;
BEGIN
  :SuccessResponse := '';
  v_Ids := :Ids;
  v_Id := :Id;
  :affectedRows := 0;
  :ErrorCode := 0;
  :ErrorMessage := '';
  v_template_delete := 'Delete From #TABLE_NAME# Where #PRIMARY_KEY# = #VALUE_KEY#';
  
  --Input param check
  IF (v_Ids IS NULL AND v_Id IS NULL) THEN
    :ErrorMessage := 'Id can not be empty';
    :ErrorCode := 101;
    RETURN;
  END IF;

  IF (v_Id IS NOT NULL) THEN
    v_Ids := TO_CHAR(v_Id);
    v_isDetailedInfo := FALSE;
  ELSE
    v_isDetailedInfo := TRUE;
  END IF;

  FOR mRec IN (SELECT COLUMN_VALUE AS id
                 FROM TABLE (ASF_SPLIT(v_Ids, ',')))
  LOOP

    -- validation on delete
    SELECT COUNT(*)
      INTO v_countTasks
      FROM TBL_TASK
      WHERE COL_TASKDICT_TASKSYSTYPE = mRec.ID;

    SELECT COUNT(*)
      INTO v_countTaskTemplates
      FROM TBL_TASKTEMPLATE
      WHERE COL_TASKTMPLDICT_TASKSYSTYPE = mRec.ID;

    SELECT SUM(cnt)
      INTO v_countStatisticalReports
      FROM (SELECT COUNT(*) AS cnt
          FROM TBL_STATDAY
          WHERE COL_STATDAYDICT_TASKSYSTYPE = mRec.ID
          UNION ALL
        SELECT COUNT(*) AS cnt
          FROM TBL_STATMONTH
          WHERE COL_STATMONTHDICT_TASKSYSTYPE = mRec.ID
          UNION ALL
        SELECT COUNT(*) AS cnt
          FROM TBL_STATWEEK
          WHERE COL_STATWEEKDICT_TASKSYSTYPE = mRec.ID);

    IF (v_countTasks > 0 OR v_countTaskTemplates > 0 OR v_countStatisticalReports > 0)
    THEN
      BEGIN
        SELECT COL_NAME
          INTO v_temp
          FROM TBL_DICT_TASKSYSTYPE
         WHERE COL_ID = mRec.ID;

        IF (v_isDetailedInfo) THEN
          v_listNotAllowDelete := v_listNotAllowDelete || '<br>' || v_temp || ' $t(related with:)';
        END IF;
        
        IF (v_countTasks > 0) THEN
          v_listNotAllowDelete := v_listNotAllowDelete || ' $t(MESS_TASK, {"count":' || v_countTasks || ', "ns":"Rule"})';
        END IF;

        IF (v_countTaskTemplates > 0) THEN
          v_listNotAllowDelete := v_listNotAllowDelete || ' $t(MESS_TASK_TEMPLATES, {"count":' || v_countTaskTemplates || ', "ns":"Rule"})';
        END IF;

        IF (v_countStatisticalReports > 0) THEN
          v_listNotAllowDelete := v_listNotAllowDelete || ' $t(MESS_STAT_REPORT, {"count":' || v_countStatisticalReports || ', "ns":"Rule" })';
        END IF;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
      END;
      CONTINUE;
    END IF;

    DELETE FROM TBL_AC_ACL
      WHERE COL_ACLACCESSOBJECT IN (SELECT COL_ID
            FROM TBL_AC_ACCESSOBJECT
            WHERE COL_ACCESSOBJECTTASKSYSTYPE = mRec.ID);

    -- delete from tables
    -- TODO table must be output in user interface
    FOR rec IN (SELECT 'TBL_ACTION' AS TableName,
                       'COL_ACTIONDICT_TASKSYSTYPE' AS ColumnName
        FROM DUAL
        UNION ALL
      SELECT 'TBL_ASSOCPAGE',
             'COL_ASSOCPAGEDICT_TASKSYSTYPE'
        FROM DUAL
        UNION ALL
      SELECT 'TBL_DYNAMICTASK',
             'COL_DYNAMICTASKTASKSYSTYPE'
        FROM DUAL
        UNION ALL
      SELECT 'TBL_PARTICIPANT',
             'COL_PARTICIPANTTASKSYSTYPE'
        FROM DUAL
        UNION ALL
      SELECT 'TBL_SLAEVENT',
             'COL_SLAEVENTDICT_TASKSYSTYPE'
        FROM DUAL
        UNION ALL
      SELECT 'TBL_MAP_TASKSTATEINITIATION',
             'COL_TASKSTATEINIT_TASKSYSTYPE'
        FROM DUAL
        UNION ALL
      SELECT 'TBL_AUTORULEPARAMETER',
             'COL_TASKSYSTYPEAUTORULEPARAM'
        FROM DUAL
        UNION ALL
      SELECT 'TBL_TASKSYSTYPERESOLUTIONCODE',
             'COL_TBL_DICT_TASKSYSTYPE'
        FROM DUAL
        UNION ALL
      SELECT 'TBL_STP_AVAILABLEADHOC',
             'COL_TASKSYSTYPE'
        FROM DUAL
        UNION ALL
      SELECT 'TBL_AC_ACCESSOBJECT',
             'COL_ACCESSOBJECTTASKSYSTYPE'
        FROM DUAL
        UNION ALL
      SELECT 'TBL_DICT_TASKSYSTYPE',
             'COL_ID'
        FROM DUAL)
    LOOP
      v_sql := REPLACE(v_template_delete, '#PRIMARY_KEY#', rec.COLUMNNAME);
      v_sql := REPLACE(v_sql, '#TABLE_NAME#', rec.TABLENAME);
      v_sql := REPLACE(v_sql, '#VALUE_KEY#', mRec.ID);
      -- dbms_output.put_line('sql delete: ' || v_sql);
      EXECUTE IMMEDIATE v_sql;
    END LOOP;

    v_countDeletedRecords := v_countDeletedRecords + 1;
  END LOOP;

  --get affected rows
  :affectedRows := v_countDeletedRecords;

  IF (v_listNotAllowDelete IS NOT NULL)
  THEN
    :ErrorCode := 102;
    IF (v_isDetailedInfo) THEN
      :ErrorMessage := 'Count of deleted Task Type: {{MESS_COUNT}}'
                    || '<br>List of not deleted Task Types: {{MESS_LIST_NOT_DELETED}}';
      v_MessageParams.EXTEND(2);
      v_MessageParams(v_MessageParams.LAST - 1) := Key_Value('MESS_COUNT', v_countDeletedRecords);
      v_MessageParams(v_MessageParams.LAST) := Key_Value('MESS_LIST_NOT_DELETED', v_listNotAllowDelete);
    ELSE
      :ErrorMessage := 'You cannot delete this Task Type, because it relates with:{{MESS_LIST_NOT_DELETED}}';
      v_MessageParams.EXTEND(1);
      v_MessageParams(v_MessageParams.LAST) := Key_Value('MESS_LIST_NOT_DELETED', v_listNotAllowDelete);
    END IF;
    v_result := LOC_I18N(
      MessageText => :ErrorMessage,
      MessageParams => v_MessageParams,
      DisableEscapeValue => TRUE,
      MessageResult => :ErrorMessage
    );
  ELSE
    v_result := LOC_I18N(
      MessageText => 'Deleted {{MESS_COUNT}} items',
      MessageParams => NES_TABLE(Key_Value('MESS_COUNT', v_countDeletedRecords)),
      MessageResult => :SuccessResponse
    );
  END IF;
END;