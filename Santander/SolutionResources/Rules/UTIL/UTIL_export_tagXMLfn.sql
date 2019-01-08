DECLARE
v_select           VARCHAR2(32000);
v_from             VARCHAR2(32000);
v_where            VARCHAR2(32000);
v_is_join          PLS_INTEGER := 0;
v_cnt              PLS_INTEGER := 0;
v_type             VARCHAR2(50);
v_sql              VARCHAR2(4000);

v_columnName       NVARCHAR2(255);

v_tag              VARCHAR2(4000);
v_tag_dict         VARCHAR2(4000);
v_columnValue      VARCHAR2(255);
v_xml              XMLTYPE;

v_Nclob_with_XML   NCLOB := EMPTY_CLOB();

v_result           NUMBER;
v_ERRORCODE        NUMBER;	
v_errormessage	   VARCHAR2(255);
BEGIN

IF :tags_name IS NULL THEN 
	v_ERRORCODE := 1001;
	v_errormessage := 'Tags is empty';
	RETURN NULL;
END IF;

v_result := f_util_fill_tags(tags_name=>:tags_name);

dbms_lob.createtemporary(v_Nclob_with_XML,true);
DBMS_LOB.OPEN(v_Nclob_with_XML, 1);
dbms_lob.append(v_Nclob_with_XML, '<Tags>');

v_tag:= :tags_name;
dbms_lob.append(v_Nclob_with_XML, '<TagsName>'||v_tag||'</TagsName>');

v_tag_dict := :tags_name||',root_dict,root_CaseType';
FOR rec IN ( --I am going take a list of tables that nessecery for creating XML with case type
  --      It is main table               , it is ID for looking relations,    it used for alias for main table
SELECT 'TBL_'||upper(bo.Name)  table_name, bo.objectid,                     't' || ROWNUM AS alias_
FROM
@TOKEN_SYSTEMDOMAINUSER@.conf_boobject bo
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_version vrs on bo.componentid = vrs.componentid
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_environment env on vrs.versionid = env.depversionid
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT tob ON bo.objectid = tob.objectid
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_tag tag ON tag.tagid = tob.tagid 
WHERE env.code in (select value from config where name ='ENV_ID')
AND EXISTS (SELECT 1 FROM TABLE(split_casetype_list(v_tag))
WHERE COLUMN_VALUE = tag.code)
ORDER BY bo.objectid ASC
--env.code = 'DCM_CATS_v2_Production.tenant41'
) LOOP
v_select := 'SELECT Xmlagg( XMLELEMENT("'||rec.table_name||'", XMLFOREST(';
v_from := ' FROM '||rec.table_name ||' '||rec.alias_;
v_where := ' WHERE 1 = 1 ';
--dbms_output.put_line(rec.table_name||' '||rec.objectid);

            FOR column_tab IN (SELECT column_name, Initcap(SUBSTR (column_name, 5)) AS Tag_name, ROW_number() OVER ( ORDER BY column_id)rn, COUNT(column_name) OVER() rn_cnt  FROM user_tab_columns
                                                  WHERE table_name = rec.table_name
                                                  AND column_name NOT IN ('COL_ID', 'COL_CREATEDBY', 'COL_CREATEDDATE', 'COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_MODIFIEDBY', 'COL_MODIFIEDDATE', 'COL_OWNER','COL_LOCKEDEXPDATE')
                                                  ORDER BY column_id
                              )LOOP -- It is loop in list of column current table 

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
                                   v_select := v_select || 'j'||column_tab.rn||'.'||join_table.col_select||' as "'||join_table.Tag_name||'"';
                                   --
                                   v_sql:= 'SELECT COUNT(*) FROM '||rec.table_name||' where '||join_table.col_name ||' IS NULL ';
                                   EXECUTE IMMEDIATE v_sql INTO v_cnt;
                                   IF v_cnt = 0 THEN
                                     v_type := ' INNER';
                                   ELSE
                                     v_type := ' LEFT';
                                     v_cnt := 0;
                                   END IF;
                                   
                                   v_from := v_from ||v_type||' JOIN '||join_table.tab_name||' j'||column_tab.rn||' ON '||rec.alias_||'.'||join_table.col_name||' = j'||column_tab.rn||'.COL_ID';

                                END LOOP;
                                
                                IF v_is_join = 0 THEN
                                v_select := v_select || rec.alias_||'.'||column_tab.column_name||' as "'||column_tab.Tag_name||'"';
                                END IF;
                                
                              

                                IF column_tab.rn <> column_tab.rn_cnt THEN
                                  v_select := v_select ||',';
                                END IF;
                               v_is_join := 0;
                              END LOOP;

v_select := v_select || ') ) )';


/*dbms_output.put_line(v_select \*|| v_from ||v_where*\);
dbms_output.put_line(v_from);
dbms_output.put_line(v_where);*/

EXECUTE IMMEDIATE v_select || v_from || v_where INTO v_xml;

		IF v_xml IS NOT NULL THEN 
			 dbms_lob.append(v_Nclob_with_XML, v_xml.getClobVal());
		END IF;
v_select := NULL;
v_from := NULL;
v_where := NULL;

--dbms_output.put_line('********************');

END LOOP;

dbms_lob.append(v_Nclob_with_XML, '</Tags>');


RETURN v_Nclob_with_XML;

END;