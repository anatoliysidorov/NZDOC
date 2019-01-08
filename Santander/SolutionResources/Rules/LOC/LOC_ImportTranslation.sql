DECLARE
    v_xml_input NCLOB;
    
BEGIN
    --select col_bigdata1 into v_xml_input from tbl_log where col_id = 5594;
    v_xml_input := :XML_INPUT;
    
    -- merge the translation table
    MERGE INTO TBL_LOC_TRANSLATION
    USING (
        with xml_table AS (
            SELECT ID, LANGID, LANGCODE, KEYID, KEYNAME, NAMESPACENAME, ISPLURAL, PLURALFORM, CONTEXT, VALUE
            FROM XMLTable('Translations/Translation'
            PASSING XMLTYPE((v_xml_input))
            COLUMNS 
                ID NUMBER PATH './ID',
                LANGID NUMBER PATH './LANGID',
                LANGCODE NVARCHAR2(255) PATH './LANGCODE',
                KEYID NUMBER PATH './KEYID',
                KEYNAME NVARCHAR2(255) PATH './KEYNAME',
                NAMESPACEID NUMBER PATH './NAMESPACEID',
                NAMESPACENAME NVARCHAR2(255) PATH './NAMESPACENAME',
                ISPLURAL NUMBER PATH './ISPLURAL',
                PLURALFORM NUMBER PATH './PLURALFORM',
                CONTEXT NVARCHAR2(255) PATH './CONTEXT',
                VALUE NCLOB PATH './VALUE'            
            )
        )
        Select xml_table.*, t_key.COL_ID AS BD_KEYID, t_lang.COL_ID AS BD_LANGID
        From xml_table
            Left Join tbl_LOC_Namespace t_ns ON (upper(trim(xml_table.NAMESPACENAME)) = upper(trim(t_ns.col_Name)))
            Left Join tbl_LOC_Key t_key ON (trim(xml_table.KEYNAME) = trim(t_key.COL_NAME) and nvl(trim(xml_table.CONTEXT), '0') = nvl(trim(t_key.COL_CONTEXT), '0') and t_key.COL_NAMESPACEID = t_ns.col_id)
            Left Join tbl_LOC_Pluralform t_plural ON (t_plural.COL_LANGUAGE = xml_table.LANGCODE)
            Left Join tbl_LOC_Languages t_lang ON (t_lang.COL_PLURALFORMID = t_plural.COL_ID)
    ) ON (COL_KEYID = BD_KEYID and COL_LANGID = BD_LANGID and NVL(COL_PLURALFORM, 0) = NVL(PLURALFORM, 0))
    WHEN MATCHED THEN
        UPDATE SET COL_VALUE = VALUE
    WHEN NOT MATCHED THEN
        INSERT  (
            COL_PLURALFORM, 
            COL_LANGID, 
            COL_KEYID, 
            COL_VALUE,
            COL_UCODE
        ) 
        VALUES 	(
            PLURALFORM, 
            BD_LANGID,
            BD_KEYID,
            VALUE,
            SYS_GUID()
        )
        WHERE ((DBMS_LOB.GETLENGTH(trim(value)) != 0 and DBMS_LOB.GETLENGTH(value) is not null)) 
          AND (BD_KEYID is not null)
          AND (BD_LANGID is not null);
EXCEPTION
    WHEN OTHERS THEN
        :errorcode      := 101;
        :errormessage   := substr(SQLERRM, 1, 200);
        --DBMS_OUTPUT.put_line(SQLERRM);
END;