DECLARE  

 v_CaseId           NUMBER;  
 v_CaseSysTypeId    NUMBER;
 v_Count            NUMBER;
 v_Session          NVARCHAR2(255);
 v_queryData        VARCHAR(2000);
 v_queryExec        VARCHAR(2000); 
     
  --errors variables
  v_errorCode     NUMBER;
  v_errorMessage  NVARCHAR2(255);
 
BEGIN
    
  v_CaseId := :CaseId;

  v_errorMessage  := NULL;
  v_errorCode     := NULL;
  v_CaseSysTypeId := NULL;
  v_Count         := NULL;
  v_Session       := SYS_GUID();
  v_queryData     := NULL;
  v_queryExec     := NULL;

  IF v_CaseId IS NULL THEN
    v_errorCode :=101;
    v_errorMessage :='Case Id is missing';
    GOTO cleanup;
  END IF;
  
  BEGIN
    SELECT COL_CASEDICT_CASESYSTYPE INTO v_CaseSysTypeId
    FROM TBL_CASE
    WHERE COl_ID=v_CaseId;
  EXCEPTION 
    WHEN NO_DATA_FOUND THEN
      v_errorCode :=101;
      v_errorMessage :='Casesystype Id not found';
      GOTO cleanup;
  END;
  
  BEGIN
    SELECT COUNT(1) INTO v_Count
    FROM TBL_MDM_MODEL mm
    INNER JOIN TBL_DOM_MODEL dm ON dm.col_dom_modelmdm_model = mm.col_id
    INNER JOIN TBL_DOM_OBJECT do ON do.col_dom_objectdom_model = dm.col_id
    INNER JOIN tbl_dict_casesystype ct on ct.col_casesystypemodel =  mm.col_id
    where ct.col_id = v_CaseSysTypeId
          AND UPPER(do.col_type) IN ('ROOTBUSINESSOBJECT', 'BUSINESSOBJECT');
  EXCEPTION WHEN OTHERS THEN NULL;
  END;

  IF NVL(v_Count, 0)=0 THEN GOTO cleanup; END IF;

  --clean up
  DELETE FROM TBL_DOM_CACHE;

  --main query
  FOR rec IN
  (
    SELECT do.COL_ID AS OBJECTID,
           do.COL_CODE AS OBJECTCODE,
           'TBL_'||UPPER(NVL(do.col_code,'UNKNOWN_TBL_NAME')) AS TABLENAME,
           do.COL_ISROOT AS ISROOT,
           do.COL_NAME AS OBJECTNAME,
           do.COL_TYPE AS OBJECTTYPE,
           p.COL_ID AS PATHID,
           p.COL_CODE AS RELCODE,
           'COL_'||UPPER(NVL(p.COL_CODE, 'UNKNOWN_COL_NAME')) AS RELCOLUMNNAME,
           p.COL_NAME AS RELNAME,
           p.COL_FOM_PATHFOM_PATH AS RELPARENTID,
           LEVEL AS LVL,
           CONNECT_BY_ISLEAF AS ISLEAF,
           do1.COL_CODE AS PARENT_OBJECTCODE,
          'TBL_'||UPPER(NVL(do1.col_code,'UNKNOWN_TBL_NAME')) AS PARENT_TABLENAME
      FROM TBL_MDM_MODEL mm
      INNER JOIN TBL_DOM_MODEL dm ON dm.col_dom_modelmdm_model = mm.col_id
      INNER JOIN TBL_DOM_OBJECT do ON do.col_dom_objectdom_model = dm.col_id
      INNER JOIN tbl_fom_path p ON do.COL_DOM_OBJECT_PATHTOPRNTEXT = p.col_id
      LEFT OUTER JOIN TBL_DOM_OBJECT do1 ON p.COL_FOM_PATHFOM_PATH=do1.COL_DOM_OBJECT_PATHTOPRNTEXT
      INNER JOIN tbl_dict_casesystype ct on ct.col_casesystypemodel =  mm.col_id
    WHERE ct.col_id = v_CaseSysTypeId
            AND UPPER(do.col_type) IN ('ROOTBUSINESSOBJECT', 'BUSINESSOBJECT')    
      START WITH p.COL_FOM_PATHFOM_PATH  IS NULL
      CONNECT BY NOCYCLE PRIOR p.COL_ID = p.COL_FOM_PATHFOM_PATH
  )
  LOOP
    v_queryData   :=NULL;
    v_queryExec   :=NULL;
    
    --data processing
    --do select from root object
    IF rec.ISROOT=1 AND rec.RELPARENTID IS NULL THEN
      v_queryData :='INSERT INTO TBL_DOM_CACHE(COL_PARENTRECORDID, COL_OBJECTTABLENAME, COL_SESSION, COL_ITEMID, COL_RECORDID) '||
                    '(SELECT '||TO_CHAR(rec.PATHID)||', '''||TO_CHAR(rec.TABLENAME)||''', '''||TO_CHAR(v_Session)||''', '||
                    'COl_ID, ''CUSTOM_BO_CLEANUP_DATA'' FROM '||TO_CHAR(rec.TABLENAME)||
                    ' WHERE '||TO_CHAR(rec.RELCOLUMNNAME)||'='||TO_CHAR(v_CaseId)||')';
    END IF;

    --do select from child objects
    IF rec.ISROOT=0 AND rec.RELPARENTID IS NOT NULL THEN          
      v_queryData :='INSERT INTO TBL_DOM_CACHE(COL_PARENTRECORDID, COL_OBJECTTABLENAME, COL_SESSION, COL_ITEMID, COL_RECORDID) '||
                    '(SELECT '||TO_CHAR(rec.PATHID)||', '''||TO_CHAR(rec.TABLENAME)||''', '''||TO_CHAR(v_Session)||''', '||
                    'COl_ID, ''CUSTOM_BO_CLEANUP_DATA'' FROM '||TO_CHAR(rec.TABLENAME)||
                    ' WHERE '||TO_CHAR(rec.RELCOLUMNNAME)||' IN (SELECT COL_ITEMID FROM TBL_DOM_CACHE WHERE COL_OBJECTTABLENAME='''||
                    TO_CHAR(rec.PARENT_TABLENAME)||''' AND COL_RECORDID=''CUSTOM_BO_CLEANUP_DATA'' AND COL_SESSION='''||TO_CHAR(v_Session)||'''))';
    END IF;

    --delete query processing
    v_queryExec :='INSERT INTO TBL_DOM_CACHE(COL_PARENTRECORDID, COL_OBJECTTABLENAME, COL_SESSION, COL_RECORDID, COL_SORDER) '||
                  'VALUES ('||TO_CHAR(rec.PATHID)||', '''||TO_CHAR(rec.TABLENAME)||''', '''||TO_CHAR(v_Session)||''', '||
                  '''CUSTOM_BO_CLEANUP_QUERY'' ,'||TO_CHAR(rec.LVL)||')';

    IF v_queryData IS NOT NULL THEN EXECUTE IMMEDIATE v_queryData; END IF;
    IF v_queryExec IS NOT NULL THEN EXECUTE IMMEDIATE v_queryExec; END IF;
  END LOOP;


  --main clean up data query
  FOR rec IN
  (
    SELECT COL_OBJECTTABLENAME AS TABLENAME
    FROM TBL_DOM_CACHE 
    WHERE COL_RECORDID='CUSTOM_BO_CLEANUP_QUERY'
    ORDER BY COL_SORDER DESC
  )
  LOOP
    v_queryExec:=NULL;
    v_queryExec:='DELETE FROM '||TO_CHAR(rec.TABLENAME)||
                 ' WHERE COL_ID IN (SELECT COL_ITEMID FROM TBL_DOM_CACHE WHERE COL_OBJECTTABLENAME='''||
                 TO_CHAR(rec.TABLENAME)||''' AND COL_RECORDID=''CUSTOM_BO_CLEANUP_DATA'' AND COL_SESSION='''||TO_CHAR(v_Session)||''')';

   IF v_queryExec IS NOT NULL THEN EXECUTE IMMEDIATE v_queryExec; END IF;   
  END LOOP;
  
  --clean up
  DELETE FROM TBL_DOM_CACHE;
      
  v_errorCode :=NULL;
  v_errorMessage :=NULL;

  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
  
  --error block
  <<cleanup>>
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;    

END;