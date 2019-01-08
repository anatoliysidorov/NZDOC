DECLARE
v_select           VARCHAR2(32000);
v_from             VARCHAR2(32000);
v_on               VARCHAR2(320);
v_when_matched     VARCHAR2(32000);
v_wen_not_matched  VARCHAR2(32000);
v_values           VARCHAR2(32000);
v_is_join          PLS_INTEGER := 0;
v_path             VARCHAR2(4000);

v_tag              VARCHAR2(255);

v_allXMLClob       NCLOB;
v_allXML           XMLTYPE;
v_xml              XMLTYPE;
v_tag_dict         VARCHAR2(255);
v_xml_text         VARCHAR2(32750);
v_table_name       VARCHAR2(255);
BEGIN

IF :XmlId IS NOT NULL THEN
   SELECT col_xmldata
   INTO  v_allXMLClob
   FROM tbl_importxml
   WHERE col_id = :XmlId;

   v_allXML := xmltype(v_allXMLClob).extract('/CaseType/Tags');

END IF;
	 v_tag := v_allXML.extract('/Tags/TagsName/text()').getStringval();

   p_util_update_log ( XmlIdLog => XmlId, Message => '  Start load Tags '||v_tag, IsError => 0);

   v_tag_dict := v_tag||',root_dict,root_CaseType';

FOR rec IN ( --I am going take a list of tables that nessecery for creating XML with case type
  --      It is main table               , it is ID for looking relations,    it used for alias for main table
SELECT 'TBL_'||upper(bo.Name)  table_name, bo.objectid,                     't' || ROWNUM AS alias_
FROM @TOKEN_SYSTEMDOMAINUSER@.conf_boobject bo
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_version vrs on bo.componentid = vrs.componentid
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_environment env on vrs.versionid = env.depversionid
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT tob ON bo.objectid = tob.objectid
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_tag tag ON tag.tagid = tob.tagid
WHERE env.code in (select value from config where name ='ENV_ID')
AND EXISTS (SELECT 1 FROM TABLE(split_casetype_list(v_tag))
WHERE COLUMN_VALUE = tag.code)
ORDER BY (SELECT COUNT(*) FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_BORELATION cr WHERE cr.sourceobjectid = bo.objectid OR cr.targetobjectid = bo.objectid) ASC
) LOOP

v_path := '/Tags/'||rec.table_name;
v_xml := v_allXML.extract(v_path);
IF v_xml IS NULL THEN
  CONTINUE;
END IF;

v_select := 'MERGE INTO '||rec.table_name||' USING ( SELECT ';
v_from := ' FROM XMLTABLE('''||rec.table_name ||'''' ||' PASSING '||chr(58)||'1 COLUMNS ';
v_on := ')) ON ( ';
v_when_matched := ' WHEN MATCHED THEN UPDATE SET ';
v_wen_not_matched := ' WHEN NOT MATCHED THEN INSERT (';
v_values := ' VALUES (';

            FOR column_tab IN (SELECT column_name, Initcap(SUBSTR (column_name, 5)) AS Tag_name,
                               ROW_number() OVER ( ORDER BY decode(column_name, 'COL_UCODE', -1, 'COL_CODE', -2,  column_id))rn, COUNT(column_name) OVER() rn_cnt,
                                 data_type , char_col_decl_length , data_precision, data_scale,
                              (SELECT DISTINCT first_value(COLUMN_NAME) OVER (ORDER BY LENGTH(column_name) DESC ) FROM USER_TAB_COLUMNS WHERE TABLE_NAME = REC.TABLE_NAME
                                  AND column_name IN ('COL_UCODE', 'COL_CODE')) merge_join_column
                                              FROM user_tab_columns
                                                  WHERE table_name = rec.table_name
                                                  AND column_name NOT IN ('COL_ID', 'COL_CREATEDBY', 'COL_CREATEDDATE', 'COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_MODIFIEDBY', 'COL_MODIFIEDDATE', 'COL_OWNER','COL_LOCKEDEXPDATE')
                                                  ORDER BY decode(column_name, 'COL_UCODE', -1, 'COL_CODE', -2,  column_id) ASC
                              )LOOP -- It is loop in list of column current table


                                IF column_tab.rn != 1 THEN
                                  v_select := v_select ||', ';
                                  v_from := v_from ||', ';
                                  IF (column_tab.column_name != column_tab.merge_join_column) AND (column_tab.rn != 2) THEN
                                      v_when_matched := v_when_matched ||', ';
                                  END IF;
                                  v_wen_not_matched := v_wen_not_matched||', ';
                                  v_values := v_values ||', ';
                                END IF;

                                FOR join_table IN (
                                SELECT 'TBL_'||upper(bo.name) tab_name, 'COL_'||UPPER(cbr.name) col_name,
                                Initcap(cbr.name) Tag_name,
                                COALESCE(otc.COLUMN_NAME, otc1.COLUMN_NAME) col_select
                                FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_BORELATION cbr

                                INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_boobject bo ON cbr.targetobjectid = bo.objectid
                                --exists - choose table with needed tags
                                AND EXISTS (SELECT 1 FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT tob , @TOKEN_SYSTEMDOMAINUSER@.conf_tag tag WHERE
                                 bo.objectid = tob.objectid AND tag.tagid = tob.tagid AND tag.code IN (SELECT * FROM TABLE(split_casetype_list(v_tag_dict))))
                                LEFT JOIN user_tab_columns otc ON  'TBL_'||upper(bo.name) = otc.TABLE_NAME AND otc.COLUMN_NAME = 'COL_UCODE'
                                LEFT JOIN user_tab_columns otc1 ON  'TBL_'||upper(bo.name) = otc1.TABLE_NAME AND otc1.COLUMN_NAME = 'COL_CODE'
                                WHERE cbr.sourceobjectid = rec.objectid AND cbr.sourcecardinalitytype = 2
                                AND column_tab.Tag_name = INITCAP(cbr.name)
                                UNION
                                SELECT 'TBL_'||upper(bo.name) tab_name, 'COL_'||UPPER(cbr.name) col_name,
                                Initcap(cbr.name) Tag_name,
                                COALESCE(otc.COLUMN_NAME, otc1.COLUMN_NAME) col_select
                                FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_BORELATION cbr
                                INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_boobject bo ON cbr.sourceobjectid = bo.objectid
                                AND EXISTS (SELECT 1 FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT tob , @TOKEN_SYSTEMDOMAINUSER@.conf_tag tag WHERE
                                 bo.objectid = tob.objectid AND tag.tagid = tob.tagid AND tag.code IN (SELECT * FROM TABLE(split_casetype_list(v_tag_dict))))
                                LEFT JOIN user_tab_columns otc ON  'TBL_'||upper(bo.name) = otc.TABLE_NAME AND otc.COLUMN_NAME = 'COL_UCODE'
                                LEFT JOIN user_tab_columns otc1 ON  'TBL_'||upper(bo.name) = otc1.TABLE_NAME AND otc1.COLUMN_NAME = 'COL_CODE'
                                WHERE cbr.targetobjectid = rec.objectid
                                AND cbr.sourcecardinalitytype = 1
                                AND cbr.targetcardinalitytype = 2
                                AND column_tab.Tag_name = INITCAP(cbr.name)
                                )
                                LOOP -- it is loop in related table and column
                                   v_is_join := 1; -- It mean that current column takes from joined table
                                   v_select := v_select || '( SELECT COL_ID FROM '||join_table.tab_name||' WHERE COL_UCODE = '||column_tab.Tag_name||') '||column_tab.Tag_name;
                                END LOOP;

                                IF v_is_join = 0 THEN
                                v_select := v_select || column_tab.Tag_name ||' ';

                                END IF;
                                      CASE WHEN  v_is_join = 1 THEN
                                           v_from := v_from || column_tab.Tag_name ||'  NVARCHAR2(255) PATH ''./'||column_tab.Tag_name||'''';
                                           WHEN column_tab.data_type IN ( 'NVARCHAR2', 'VARCHAR2')  THEN
                                           v_from := v_from || column_tab.Tag_name ||' '||column_tab.data_type||'('||column_tab.char_col_decl_length||') PATH ''./'||column_tab.Tag_name||'''' ;
                                           WHEN column_tab.data_type = 'NUMBER' AND column_tab.data_precision IS NOT NULL THEN
                                           v_from := v_from || column_tab.Tag_name ||' '||column_tab.data_type||'('||column_tab.data_precision||','||column_tab.data_scale||') PATH ''./'||column_tab.Tag_name||'''' ;
                                      ELSE
                                           v_from := v_from || column_tab.Tag_name ||' '||column_tab.data_type||' PATH ''./'||column_tab.Tag_name||'''' ;
                                      END CASE;
                                    v_wen_not_matched := v_wen_not_matched ||column_tab.column_name;
                                    v_values := v_values || column_tab.Tag_name;
                                    IF column_tab.column_name = column_tab.merge_join_column  THEN
                                      v_on := v_on ||' '||column_tab.column_name||' = ' ||column_tab.Tag_name||')'; --
                                    ELSE
                                      v_when_matched := v_when_matched ||column_tab.column_name ||' = '||column_tab.Tag_name  ;
                                    END IF;

                               v_is_join := 0;
                              END LOOP;

v_wen_not_matched := v_wen_not_matched || ')';
v_values := v_values || ')';

/*dbms_output.put_line(v_select);
dbms_output.put_line(v_from);
dbms_output.put_line(v_on);
dbms_output.put_line(v_when_matched);
dbms_output.put_line(v_wen_not_matched);
dbms_output.put_line(v_values);
v_xml_text := v_xml.getStringVal(); 
*/

begin

v_table_name := rec.table_name;

EXECUTE IMMEDIATE v_select ||' '|| v_from ||' '|| v_on ||' '|| v_when_matched||' ' || v_wen_not_matched||' ' || v_values USING v_xml;

p_util_update_log ( XmlIdLog => XmlId, Message => ' Merged '||rec.table_name||' with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message =>v_table_name||' '||dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1); 

end;

v_select := NULL;
v_from := NULL;
v_when_matched := NULL;
v_wen_not_matched :=NULL;
v_values := NULL;




END LOOP;
   p_util_update_log ( XmlIdLog => XmlId, Message => '  End load Tags '||v_tag, IsError => 0);
 RETURN 0;
 
EXCEPTION WHEN OTHERS THEN 
p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1); 
 RETURN -1;
END;