DECLARE
v_cnt  NUMBER;
v_sql  VARCHAR2(4000);
BEGIN
	FOR rec IN (
SELECT 'TBL_'||upper(bo.Name)  table_name
FROM
@TOKEN_SYSTEMDOMAINUSER@.conf_boobject bo
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_version vrs on bo.componentid = vrs.componentid
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_environment env on vrs.versionid = env.depversionid
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT tob ON bo.objectid = tob.objectid
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_tag tag ON tag.tagid = tob.tagid AND tag.code IN (SELECT * FROM TABLE(split_casetype_list(:tags_name)))
WHERE env.code in (select value from config where name ='ENV_ID')
ORDER BY bo.objectid ASC)
LOOP
	
SELECT COUNT(*) 
INTO v_cnt
FROM user_tab_columns
WHERE table_name = rec.table_name AND column_name = 'COL_UCODE';

IF v_cnt = 0 THEN 
--	v_sql := 'ALTER TABLE '||rec.table_name||' ADD ( COL_UCODE NVARCHAR2(255))';
--  EXECUTE IMMEDIATE v_sql;
continue;
END IF;

v_sql := 'SELECT COUNT(*) FROM '||rec.table_name||' WHERE col_ucode IS NULL';
EXECUTE IMMEDIATE v_sql INTO v_cnt;

    IF v_cnt > 0 THEN
			v_sql := 'UPDATE '||rec.table_name||'  SET col_ucode = sys_guid()  WHERE col_ucode IS NULL';
     EXECUTE IMMEDIATE v_sql;
    END IF;

END LOOP;
COMMIT;
RETURN 0;

END;