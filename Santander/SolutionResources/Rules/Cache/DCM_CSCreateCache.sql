DECLARE
  v_cnt  NUMBER; 
  v_columnsList   VARCHAR2(32000); 
  v_columnsList2  VARCHAR2(32000); 
  v_columnsList3  VARCHAR2(32000); 
  v_RTTableName   VARCHAR2(255); 
  v_CSTableName   VARCHAR2(255);  
  v_CacheDebug    VARCHAR2(3);
  v_CreateCacheTables    VARCHAR2(3);
  v_commitMode    VARCHAR2(255);  
  v_SQLCREATECSTABLE1     VARCHAR2(32000);  
  v_SQLCREATECSTABLE2     VARCHAR2(32000);  
  v_SQLCOPYTOCACHE1       VARCHAR2(32000);  
  v_SQLCOPYTOCACHE2       VARCHAR2(32000);
  v_SQLUPDATEFROMCACHE1   VARCHAR2(32000);
  v_SQLUPDATEFROMCACHE2   VARCHAR2(32000);  
            
BEGIN  

  --for non AppBase debuging just add AUTHID CURRENT_USER into return string row
  --example is:  RETURN NUMBER AUTHID CURRENT_USER
  
  -- ON COMMIT DELETE ROWS instead ON COMMIT PRESERVE ROWS

  --set debug mode
  v_CacheDebug := 'OFF'; -- OFF/ON
  v_CreateCacheTables := 'YES'; -- YES/NO
    
  IF v_CacheDebug='ON' THEN v_commitMode:='COMMIT PRESERVE ROWS'; END IF;
  IF v_CacheDebug='OFF' THEN v_commitMode:='COMMIT DELETE ROWS'; END IF;

  IF v_CacheDebug NOT IN ('ON', 'OFF') THEN v_commitMode:='COMMIT PRESERVE ROWS'; END IF;
  IF v_CreateCacheTables NOT IN ('NO', 'YES') THEN v_CreateCacheTables :='YES'; END IF;

  --PRODUCTION settings must be next
  --v_CacheDebug := 'OFF';
  --v_CreateCacheTables := 'YES';

  --prepare a data
  DELETE FROM TBL_CSCACHETABLES;


  -- =========================================================
  --
  -- TBL_CASE => TBL_CSCASE
  --
  -- =========================================================

  v_RTTableName := 'TBL_CASE';
  v_CSTableName := 'TBL_CSCASE';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName||
                       ' WHERE COL_ID= %CACHE_PLACEHOLDER_V_CASEID% ';
  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';
  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                                COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName,1,           
         v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
          v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;


  -- =========================================================
  --
  --TBL_CW_WORKITEM => TBL_CSCW_WORKITEM
  --
  -- =========================================================

  v_RTTableName := 'TBL_CW_WORKITEM';
  v_CSTableName := 'TBL_CSCW_WORKITEM';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName||
                       ' WHERE COL_ID IN (SELECT COL_CW_WORKITEMCASE FROM TBL_CASE '||
                       ' WHERE COL_ID= %CACHE_PLACEHOLDER_V_CASEID% ) ';

  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';

  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                                COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName,2,           
        v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
         v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;

    

  -- =========================================================
  --        
  --TBL_MAP_CASESTATEINITIATION => TBL_CSMAP_CASESTATEINIT
  --
  -- =========================================================

  v_RTTableName := 'TBL_MAP_CASESTATEINITIATION';
  v_CSTableName := 'TBL_CSMAP_CASESTATEINIT';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName||
                       ' WHERE COL_MAP_CASESTATEINITCASE= %CACHE_PLACEHOLDER_V_CASEID% ';

  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';

  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                                COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName,3,           
        v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
         v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;
  
    

  -- =========================================================
  --
  --TBL_HISTORY => TBL_CSHISTORY
  --
  -- =========================================================

  v_RTTableName := 'TBL_HISTORY';
  v_CSTableName := 'TBL_CSHISTORY';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName||
                       ' WHERE (( %CACHE_PLACEHOLDER_USEMODE_CASE% ) AND'||
                       ' (COL_HISTORYCASE= %CACHE_PLACEHOLDER_V_CASEID% ))'||
                       ' OR'||
                       ' (( %CACHE_PLACEHOLDER_USEMODE_TASK% ) AND'||
                       ' (COL_HISTORYTASK IN (SELECT COL_ID FROM TBL_TASK '||
                       ' WHERE COL_CASETASK = %CACHE_PLACEHOLDER_V_CASEID% )))';

  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';

  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                               COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName,4,           
        v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
         v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;
  
 


  -- =========================================================
  -- 
  --TBL_TASK => TBL_CSTASK
  --
  -- =========================================================
  v_RTTableName := 'TBL_TASK';
  v_CSTableName := 'TBL_CSTASK';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% ';

  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';

  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                               COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName, 5,           
        v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
         v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;
 



  -- =========================================================
  --
  --TBL_TW_WORKITEM => TBL_CSTW_WORKITEM
  --
  -- =========================================================
  v_RTTableName := 'TBL_TW_WORKITEM';
  v_CSTableName := 'TBL_CSTW_WORKITEM';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName||
                       ' WHERE COL_ID IN (SELECT COL_TW_WORKITEMTASK FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% )';

  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';

  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                               COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName, 6,           
        v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
         v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;



  -- =========================================================
  --
  --TBL_DATEEVENT => TBL_CSDATEEVENT
  --
  -- =========================================================
  v_RTTableName := 'TBL_DATEEVENT';
  v_CSTableName := 'TBL_CSDATEEVENT';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName||
                       ' WHERE (( %CACHE_PLACEHOLDER_USEMODE_TASK% )'||
                       ' AND (COL_DATEEVENTTASK IN (SELECT COL_ID FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% )))'||
                       ' OR (( %CACHE_PLACEHOLDER_USEMODE_CASE% )'||
                       ' AND (COL_DATEEVENTCASE= %CACHE_PLACEHOLDER_V_CASEID% ))';

  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';

  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                               COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName, 7,          
        v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
         v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;



  -- =========================================================
  --
  --TBL_SLAEVENT => TBL_CSSLAEVENT
  --
  -- =========================================================
  v_RTTableName := 'TBL_SLAEVENT';
  v_CSTableName := 'TBL_CSSLAEVENT';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName||
                       ' WHERE COL_SLAEVENTTASK IN (SELECT COL_ID FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% )';

  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';

  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                               COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName, 8,          
        v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
         v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;



  -- =========================================================
  --
  --TBL_SLAACTION => TBL_CSSLAACTION
  --
  -- =========================================================
  v_RTTableName := 'TBL_SLAACTION';
  v_CSTableName := 'TBL_CSSLAACTION';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName||
                       ' WHERE COL_SLAACTIONSLAEVENT IN (SELECT COL_ID FROM TBL_SLAEVENT'||
                       ' WHERE COL_SLAEVENTTASK IN (SELECT COL_ID FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% ))';

  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';

  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                               COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName, 9,           
        v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
         v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;



  -- =========================================================
  -- 
  --TBL_MAP_TASKSTATEINITIATION => TBL_CSMAP_TASKSTATEINIT
  --
  -- =========================================================
  v_RTTableName := 'TBL_MAP_TASKSTATEINITIATION';
  v_CSTableName := 'TBL_CSMAP_TASKSTATEINIT';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName||                       
                       ' WHERE COL_MAP_TASKSTATEINITTASK IN (SELECT COL_ID FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% )';

  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';

  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                               COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName, 10,           
        v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
         v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;



  -- =========================================================
  --
  --TBL_TASKDEPENDENCY => TBL_CSTASKDEPENDENCY
  --
  -- =========================================================
  v_RTTableName := 'TBL_TASKDEPENDENCY';
  v_CSTableName := 'TBL_CSTASKDEPENDENCY';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName||                
                       ' WHERE (COL_TSKDPNDCHLDTSKSTATEINIT IN (SELECT COL_ID FROM TBL_MAP_TASKSTATEINITIATION'||       
                       ' WHERE COL_MAP_TASKSTATEINITTASK IN (SELECT COL_ID FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% )))'||
                       ' AND '||
                       ' (COL_TSKDPNDPRNTTSKSTATEINIT IN (SELECT COL_ID FROM TBL_MAP_TASKSTATEINITIATION'||       
                       ' WHERE COL_MAP_TASKSTATEINITTASK IN (SELECT COL_ID FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% )))';

  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';

  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                               COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName, 11,           
        v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
         v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;
  


  -- =========================================================
  --
  --TBL_TASKEVENT => TBL_CSTASKEVENT
  --
  -- =========================================================
  v_RTTableName := 'TBL_TASKEVENT';
  v_CSTableName := 'TBL_CSTASKEVENT';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName||                
                       ' WHERE COL_TASKEVENTTASKSTATEINIT IN (SELECT COL_ID FROM TBL_MAP_TASKSTATEINITIATION'||       
                       ' WHERE COL_MAP_TASKSTATEINITTASK IN (SELECT COL_ID FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% ))';

  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';

  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                               COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName, 12,           
        v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
         v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;



  -- =========================================================
  --
  --TBL_AUTORULEPARAMETER => TBL_CSAUTORULEPARAMETER
  --
  -- =========================================================
  v_RTTableName := 'TBL_AUTORULEPARAMETER';
  v_CSTableName := 'TBL_CSAUTORULEPARAMETER';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName|| 
                       ' WHERE 1=1 '||
                       /*--SELECT ALL RULE PARAMETERS RELATED TO TASK STATE INITIATION               
                       '(COL_RULEPARAM_TASKSTATEINIT IN (SELECT COL_ID FROM TBL_MAP_TASKSTATEINITIATION'||       
                       ' WHERE COL_MAP_TASKSTATEINITTASK IN (SELECT COL_ID FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% )))'||*/

                       ' OR'||

                       /*--SELECT ALL RULEPARAMETERS FOR TASK EVENTS*/
                       ' (( %CACHE_PLACEHOLDER_USEMODE_TASK% ) AND'||
                       ' (COL_TASKEVENTAUTORULEPARAM IN (SELECT COL_ID FROM TBL_TASKEVENT'||       
                       ' WHERE COL_TASKEVENTTASKSTATEINIT IN (SELECT COL_ID FROM TBL_MAP_TASKSTATEINITIATION'||
                       ' WHERE COL_MAP_TASKSTATEINITTASK IN (SELECT COL_ID FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% ))))) '||

                       ' OR'||

                       /*--SELECT ALL RULEPARAMETERS FOR AUTOMATIC TASKS*/ 
                       ' (( %CACHE_PLACEHOLDER_USEMODE_TASK% ) AND'||                      
                       ' (COL_AUTORULEPARAMETERTASK IN (SELECT COL_ID FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% ))) '||

                       ' OR'||

                       /*--SELECT ALL RULEPARAMETERS FOR TASK DEPENDENCIES*/
                       ' (( %CACHE_PLACEHOLDER_USEMODE_TASK% ) AND'||                      
                       ' (COL_AUTORULEPARAMTASKDEP IN (SELECT COL_ID FROM TBL_TASKDEPENDENCY'||       
                       ' WHERE COL_TSKDPNDPRNTTSKSTATEINIT IN (SELECT COL_ID FROM TBL_MAP_TASKSTATEINITIATION'||
                       ' WHERE COL_MAP_TASKSTATEINITTASK IN (SELECT COL_ID FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% )) '||
                       ' AND COL_TSKDPNDCHLDTSKSTATEINIT IN (SELECT COL_ID FROM TBL_MAP_TASKSTATEINITIATION'||
                       ' WHERE COL_MAP_TASKSTATEINITTASK IN (SELECT COL_ID FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% ))))) '||

                       ' OR'||

                       /*--SELECT ALL RULE PARAMETERS RELATED TO CASE STATE INITIATION
                       ' (col_ruleparam_casestateinit IN (SELECT COL_ID FROM tbl_map_casestateinitiation'||
                       ' WHERE col_map_casestateinitcase= %CACHE_PLACEHOLDER_V_CASEID% ))'||
                       ' OR'||*/

                       /*--SELECT ALL RULE PARAMETERS RELATED TO SLA ACTIONS*/
                       ' (( %CACHE_PLACEHOLDER_USEMODE_TASK% ) AND'||                      
                       ' (COL_AUTORULEPARAMSLAACTION IN (SELECT COL_ID FROM TBL_SLAACTION'||       
                       ' WHERE COL_SLAACTIONSLAEVENT IN (SELECT COL_ID FROM TBL_SLAEVENT'||
                       ' WHERE COL_SLAEVENTTASK IN (SELECT COL_ID FROM TBL_TASK'||
                       ' WHERE COL_CASETASK= %CACHE_PLACEHOLDER_V_CASEID% ))))) '||

                       ' OR'||

                       /*--SELECT ALL RULE PARAMETERS RELATED TO CASE COMMON EVENTS*/
                       ' (( %CACHE_PLACEHOLDER_USEMODE_CASE% ) AND'||
                       ' (COL_AUTORULEPARAMCOMMONEVENT IN (SELECT COL_ID FROM  TBL_COMMONEVENT'||
                       ' WHERE COL_COMMONEVENTCASE= %CACHE_PLACEHOLDER_V_CASEID% )))'
                       ;

  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';

  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                                COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName, 13,           
        v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
         v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;

  
  -- =========================================================
  --
  --TBL_CASEPARTY => TBL_CSCASEPARTY
  --
  -- =========================================================

  v_RTTableName := 'TBL_CASEPARTY';
  v_CSTableName := 'TBL_CSCASEPARTY';
  v_columnsList := NULL; 
  v_columnsList2:= NULL; 
  v_columnsList3:= NULL; 

  FOR rec IN 
  ( SELECT COLUMN_NAME
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME=v_RTTableName AND 
          COLUMN_NAME  NOT IN ('COL_LOCKEDBY', 'COL_LOCKEDDATE', 'COL_LOCKEDEXPDATE')
    ORDER BY COLUMN_NAME ASC
  )
  LOOP
    v_columnsList :=v_columnsList||rec.COLUMN_NAME||', ';
    v_columnsList3 :=v_columnsList3||'cs.'||rec.COLUMN_NAME||', ';
    IF rec.COLUMN_NAME NOT IN ('COL_ID')  THEN
      v_columnsList2 :=v_columnsList2||rec.COLUMN_NAME||'=cs.'||rec.COLUMN_NAME||', ';
    END IF;
  END LOOP;

  v_columnsList:=SUBSTR(v_columnsList, 1, LENGTH(v_columnsList) - 2);
  v_columnsList2:=SUBSTR(v_columnsList2, 1, LENGTH(v_columnsList2) - 2);
  v_columnsList3:=SUBSTR(v_columnsList3, 1, LENGTH(v_columnsList3) - 2);

  v_SQLCREATECSTABLE1 :='DROP TABLE '||v_CSTableName;
  v_SQLCREATECSTABLE2 :='CREATE GLOBAL TEMPORARY TABLE '||v_CSTableName||' ON '||v_commitMode||
                        ' AS (SELECT * FROM '||v_RTTableName||' WHERE 1=2)';

  v_SQLCOPYTOCACHE1 := 'INSERT INTO '||v_CSTableName||' ('||v_columnsList||')'||
                       ' SELECT '||v_columnsList||' FROM '||v_RTTableName||
                       ' WHERE (( %CACHE_PLACEHOLDER_USEMODE_CASE% ) AND'||
                       ' (COL_CASEPARTYCASE= %CACHE_PLACEHOLDER_V_CASEID% ))'/*||
                       ' OR'||
                       ' (( %CACHE_PLACEHOLDER_USEMODE_TASK% ) AND'||
                       ' (COL_HISTORYTASK IN (SELECT COL_ID FROM TBL_TASK '||
                       ' WHERE COL_CASETASK = %CACHE_PLACEHOLDER_V_CASEID% )))'*/;

  v_SQLCOPYTOCACHE2:=NULL;

  v_SQLUPDATEFROMCACHE1 :='MERGE INTO '||v_RTTableName||' rt '||
                          ' USING ( SELECT '||v_columnsList ||
                          ' FROM '||v_CSTableName||' ) cs ON (rt.COL_ID=cs.COL_ID)'||
                          ' WHEN MATCHED THEN UPDATE  SET '|| v_columnsList2||
                          ' WHEN NOT MATCHED THEN INSERT ('|| v_columnsList||')'||
                          ' VALUES ('|| v_columnsList3||')';

  v_SQLUPDATEFROMCACHE2 :=NULL;

  INSERT INTO TBL_CSCACHETABLES(COL_CSTABLENAME, COL_COLUMNLIST, COL_RTTABLENAME, COL_TABLEORDER, 
                               COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,  
                                COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2)
  VALUES(v_CSTableName, v_columnsList, v_RTTableName, 14,           
        v_SQLCOPYTOCACHE1,v_SQLCOPYTOCACHE2, 
         v_SQLUPDATEFROMCACHE1, v_SQLUPDATEFROMCACHE2);

  IF v_CreateCacheTables='YES' THEN
  v_cnt :=0;
  SELECT COUNT(1) INTO v_cnt FROM USER_TABLES WHERE TABLE_NAME=v_CSTableName;
    IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;  
  
  
END;