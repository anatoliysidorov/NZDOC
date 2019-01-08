DECLARE
v_sql_code                          VARCHAR2(4000);
v_inputTableName                    VARCHAR2(50);
v_cnt                               PLS_INTEGER;
v_fieldMerge                        VARCHAR2(50);
v_tagName                           VARCHAR2(255);
v_partOfXml                         XMLTYPE;
BEGIN
v_inputTableName := UPPER(:InputTableName);
v_fieldMerge     := :fieldMerge;
v_partOfXml      := :partOfXml;
v_tagName        := :tagName;

IF v_inputTableName IS NULL THEN
  RETURN -1;
END IF;

  SELECT COUNT(*)
  INTO v_cnt
  FROM USER_TABLES
  WHERE UPPER(TABLE_NAME) = v_inputTableName;

IF v_cnt = 0 THEN
  RETURN -1;
END IF;

IF v_fieldMerge NOT IN ('code', 'ucode') THEN
  RETURN -1;
END IF;

v_sql_code := 'UPDATE '|| v_inputTableName|| ' SET col_isdeleted = 1 ';
v_sql_code := v_sql_code||'WHERE NOT EXISTS (SELECT 1 FROM ';
v_sql_code := v_sql_code||q'$ XMLTABLE ('$'||v_tagName||q'$' $';
v_sql_code := v_sql_code||' PASSING '||CHR(58)||'1';
v_sql_code := v_sql_code||' COLUMNS '||fieldMerge||q'$ NVARCHAR2(255) PATH './$'||initcap(fieldMerge)||q'$') $';
v_sql_code := v_sql_code||' WHERE col_'||fieldMerge||' = '||fieldMerge||') AND col_createdby = ''IMPORT'' AND (col_modifiedby IS NULL OR col_modifiedby = ''IMPORT'')';



EXECUTE IMMEDIATE v_sql_code USING v_partOfXml;
    IF SQL%ROWCOUNT >0 THEN
       p_util_update_log ( XmlIdLog => :XmlId, Message => '        Soft deleted from '||v_inputTableName||' '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;

RETURN 0;
EXCEPTION WHEN OTHERS 
	THEN 
p_util_update_log ( XmlIdLog => :XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
  RETURN -1;
END;