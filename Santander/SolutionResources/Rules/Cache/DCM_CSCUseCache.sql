-- This rule required a parameters
--
-- CaseId  -NOT NULL, number
-- UseMode - NULL, 'CASE', 'TASK', text
-- Direction - 'COPY_TO_CACHE', 'UPDATE_FROM_CACHE', text
--
-- Set debug mode via v_CacheDebug - 'ON'/'OFF'
--
------------------------------------

DECLARE
  v_CaseId     NUMBER;
  v_UseMode    VARCHAR2(255);
  v_Direction  VARCHAR2(255); 
  v_CacheDebug    VARCHAR2(3);   
  v_cnt           NUMBER;  
             
BEGIN   
  v_CaseId    := :CaseId;
  v_UseMode   := :UseMode;
  v_Direction := :Direction;  
  
  --set debug mode
  v_CacheDebug := 'OFF'; -- OFF/ON

  IF v_CaseId IS NULL THEN RETURN 0; END IF;
  IF v_UseMode IS NOT NULL AND v_UseMode NOT IN ('CASE', 'TASK') THEN RETURN 0; END IF; 
  IF v_Direction NOT IN ('COPY_TO_CACHE', 'UPDATE_FROM_CACHE') THEN RETURN 0; END IF;
  IF v_CacheDebug NOT IN ('ON', 'OFF') THEN v_CacheDebug := 'OFF'; END IF;
  
  IF v_CacheDebug='ON' THEN
    DELETE FROM TBL_CSCACHELOG;    
    INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
    VALUES(TO_CHAR(SYSDATE,'dd/mm/yyyy hh24:mi:ss'), '---', 'START', 'f_DCM_CSCUseCache');
    INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
    VALUES(NULL, NULL, 'v_CaseId', TO_CHAR(v_CaseId));
    INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
    VALUES(NULL, NULL, 'v_UseMode', TO_CHAR(v_UseMode));
    INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
    VALUES(NULL, NULL, 'v_Direction', TO_CHAR(v_Direction));
  END IF;
   

  IF v_UseMode = 'CASE' THEN
    FOR rec IN
    (
    SELECT COL_ID, COL_CSTABLENAME, COL_RTTABLENAME, COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,
           COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2   
    FROM TBL_CSCACHETABLES
    WHERE COL_RTTABLENAME IN ('TBL_CASE', 'TBL_CW_WORKITEM', 'TBL_MAP_CASESTATEINITIATION', 
                              'TBL_HISTORY', 'TBL_DATEEVENT', 'TBL_AUTORULEPARAMETER', 
                              'TBL_CASEPARTY')
    ORDER BY COL_TABLEORDER ASC
    )
    LOOP
      IF rec.COL_RTTABLENAME IS NOT NULL AND rec.COL_CSTABLENAME IS NOT NULL THEN           
        IF v_Direction='COPY_TO_CACHE' THEN          

          IF v_CacheDebug='ON' THEN            
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES('---', '---', TO_CHAR(rec.COL_RTTABLENAME)||'=>'||TO_CHAR(rec.COL_CSTABLENAME), '---');
          END IF;

          v_cnt:=0;             
          IF rec.COL_SQLCOPYTOCACHE1 IS NOT NULL THEN       
            rec.COL_SQLCOPYTOCACHE1 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE1), '%CACHE_PLACEHOLDER_V_CASEID%', TO_CHAR(v_CaseId));
            rec.COL_SQLCOPYTOCACHE1 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE1), '%CACHE_PLACEHOLDER_USEMODE_TASK%', '1=0');
            rec.COL_SQLCOPYTOCACHE1 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE1), '%CACHE_PLACEHOLDER_USEMODE_CASE%', '1=1');
            EXECUTE IMMEDIATE TO_CHAR(rec.COL_SQLCOPYTOCACHE1);
            v_cnt:=  SQL%ROWCOUNT;
          END IF;
          IF v_CacheDebug='ON' THEN                      
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES(rec.COL_SQLCOPYTOCACHE1, NULL, 'SQLCOPYTOCACHE1', 
                   TO_CHAR(v_cnt)||' row(s) processed');
          END IF;
          
          v_cnt:=0; 
          IF rec.COL_SQLCOPYTOCACHE2 IS NOT NULL THEN 
            rec.COL_SQLCOPYTOCACHE2 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE2), '%CACHE_PLACEHOLDER_V_CASEID%', TO_CHAR(v_CaseId));
            rec.COL_SQLCOPYTOCACHE2 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE2), '%CACHE_PLACEHOLDER_USEMODE_TASK%', '1=0');
            rec.COL_SQLCOPYTOCACHE2 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE2), '%CACHE_PLACEHOLDER_USEMODE_CASE%', '1=1');
            EXECUTE IMMEDIATE TO_CHAR(rec.COL_SQLCOPYTOCACHE2);                        
            v_cnt:=  SQL%ROWCOUNT;
          END IF;
          IF v_CacheDebug='ON' THEN             
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES(rec.COL_SQLCOPYTOCACHE2, NULL, 'SQLCOPYTOCACHE2', 
                   TO_CHAR(v_cnt)||' row(s) processed');
          END IF;
        END IF;--v_Direction-'COPY_TO_CACHE'
        
        IF v_Direction='UPDATE_FROM_CACHE' THEN           
          IF v_CacheDebug='ON' THEN            
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES('---', '---', TO_CHAR(rec.COL_CSTABLENAME)||'=>'||TO_CHAR(rec.COL_RTTABLENAME), '---');
          END IF;

          v_cnt:=0;
          IF rec.COL_SQLUPDATEFROMCACHE1 IS NOT NULL THEN       
            EXECUTE IMMEDIATE TO_CHAR(rec.COL_SQLUPDATEFROMCACHE1); 
            v_cnt:=  SQL%ROWCOUNT;            
          END IF;
          IF v_CacheDebug='ON' THEN              
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES(rec.COL_SQLUPDATEFROMCACHE1, NULL, 'SQLUPDATEFROMCACHE1', 
                   TO_CHAR(v_cnt)||' row(s) processed');
          END IF;
          
          v_cnt:=0;
          IF rec.COL_SQLUPDATEFROMCACHE2 IS NOT NULL THEN 
            EXECUTE IMMEDIATE TO_CHAR(rec.COL_SQLUPDATEFROMCACHE2);  
            v_cnt:=  SQL%ROWCOUNT;               
          END IF;
          IF v_CacheDebug='ON' THEN                        
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES(rec.COL_SQLUPDATEFROMCACHE2, NULL, 'SQLUPDATEFROMCACHE2', 
                   TO_CHAR(v_cnt)||' row(s) processed');
          END IF;
        END IF;--v_Direction-'UPDATE_FROM_CACHE'      
      END IF;--tables are exists   
    END LOOP;--main loop case tables
  END IF;--CASE

  
  IF v_UseMode = 'TASK' THEN
    FOR rec IN
    (
    SELECT COL_ID, COL_CSTABLENAME, COL_RTTABLENAME, COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,
           COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2   
    FROM TBL_CSCACHETABLES
    WHERE COL_RTTABLENAME IN ('TBL_TASK', 'TBL_TW_WORKITEM', 'TBL_DATEEVENT', 'TBL_SLAEVENT',
                              'TBL_SLAACTION', 'TBL_MAP_TASKSTATEINITIATION', 'TBL_TASKDEPENDENCY',
                              'TBL_TASKEVENT', 'TBL_AUTORULEPARAMETER', 'TBL_HISTORY')
    ORDER BY COL_TABLEORDER ASC
    )
    LOOP
      IF rec.COL_RTTABLENAME IS NOT NULL AND rec.COL_CSTABLENAME IS NOT NULL THEN           
        IF v_Direction='COPY_TO_CACHE' THEN          

          IF v_CacheDebug='ON' THEN            
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES('---', '---', TO_CHAR(rec.COL_RTTABLENAME)||'=>'||TO_CHAR(rec.COL_CSTABLENAME), '---');
          END IF;

          v_cnt:=0;             
          IF rec.COL_SQLCOPYTOCACHE1 IS NOT NULL THEN       
            rec.COL_SQLCOPYTOCACHE1 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE1), '%CACHE_PLACEHOLDER_V_CASEID%', TO_CHAR(v_CaseId));
            rec.COL_SQLCOPYTOCACHE1 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE1), '%CACHE_PLACEHOLDER_USEMODE_TASK%', '1=0');
            rec.COL_SQLCOPYTOCACHE1 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE1), '%CACHE_PLACEHOLDER_USEMODE_CASE%', '1=1');
            EXECUTE IMMEDIATE TO_CHAR(rec.COL_SQLCOPYTOCACHE1);
            v_cnt:=  SQL%ROWCOUNT;
          END IF;
          IF v_CacheDebug='ON' THEN                      
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES(rec.COL_SQLCOPYTOCACHE1, NULL, 'SQLCOPYTOCACHE1', 
                   TO_CHAR(v_cnt)||' row(s) processed');
          END IF;
          
          v_cnt:=0; 
          IF rec.COL_SQLCOPYTOCACHE2 IS NOT NULL THEN 
            rec.COL_SQLCOPYTOCACHE2 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE2), '%CACHE_PLACEHOLDER_V_CASEID%', TO_CHAR(v_CaseId));
            rec.COL_SQLCOPYTOCACHE2 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE2), '%CACHE_PLACEHOLDER_USEMODE_TASK%', '1=0');
            rec.COL_SQLCOPYTOCACHE2 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE2), '%CACHE_PLACEHOLDER_USEMODE_CASE%', '1=1');
            EXECUTE IMMEDIATE TO_CHAR(rec.COL_SQLCOPYTOCACHE2);                        
            v_cnt:=  SQL%ROWCOUNT;
          END IF;
          IF v_CacheDebug='ON' THEN             
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES(rec.COL_SQLCOPYTOCACHE2, NULL, 'SQLCOPYTOCACHE2', 
                   TO_CHAR(v_cnt)||' row(s) processed');
          END IF;
        END IF;--v_Direction-'COPY_TO_CACHE'
        
        IF v_Direction='UPDATE_FROM_CACHE' THEN           
          IF v_CacheDebug='ON' THEN            
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES('---', '---', TO_CHAR(rec.COL_CSTABLENAME)||'=>'||TO_CHAR(rec.COL_RTTABLENAME), '---');
          END IF;

          v_cnt:=0;
          IF rec.COL_SQLUPDATEFROMCACHE1 IS NOT NULL THEN       
            EXECUTE IMMEDIATE TO_CHAR(rec.COL_SQLUPDATEFROMCACHE1); 
            v_cnt:=  SQL%ROWCOUNT;            
          END IF;
          IF v_CacheDebug='ON' THEN              
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES(rec.COL_SQLUPDATEFROMCACHE1, NULL, 'SQLUPDATEFROMCACHE1', 
                   TO_CHAR(v_cnt)||' row(s) processed');
          END IF;
          
          v_cnt:=0;
          IF rec.COL_SQLUPDATEFROMCACHE2 IS NOT NULL THEN 
            EXECUTE IMMEDIATE TO_CHAR(rec.COL_SQLUPDATEFROMCACHE2);  
            v_cnt:=  SQL%ROWCOUNT;               
          END IF;
          IF v_CacheDebug='ON' THEN                        
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES(rec.COL_SQLUPDATEFROMCACHE2, NULL, 'SQLUPDATEFROMCACHE2', 
                   TO_CHAR(v_cnt)||' row(s) processed');
          END IF;
        END IF;--v_Direction-'UPDATE_FROM_CACHE'      
      END IF;--tables are exists 
    END LOOP;--main loop case tables
  END IF;--TASK
  
  
  IF v_UseMode IS NULL THEN
    FOR rec IN
    (
    SELECT COL_ID, COL_CSTABLENAME, COL_RTTABLENAME, COL_SQLCOPYTOCACHE1, COL_SQLCOPYTOCACHE2,
           COL_SQLUPDATEFROMCACHE1,  COL_SQLUPDATEFROMCACHE2   
    FROM TBL_CSCACHETABLES
    ORDER BY COL_TABLEORDER ASC
    )
    LOOP
      IF rec.COL_RTTABLENAME IS NOT NULL AND rec.COL_CSTABLENAME IS NOT NULL THEN           
        IF v_Direction='COPY_TO_CACHE' THEN          

          IF v_CacheDebug='ON' THEN            
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES('---', '---', TO_CHAR(rec.COL_RTTABLENAME)||'=>'||TO_CHAR(rec.COL_CSTABLENAME), '---');
          END IF;

          v_cnt:=0;             
          IF rec.COL_SQLCOPYTOCACHE1 IS NOT NULL THEN       
            rec.COL_SQLCOPYTOCACHE1 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE1), '%CACHE_PLACEHOLDER_V_CASEID%', TO_CHAR(v_CaseId));
            rec.COL_SQLCOPYTOCACHE1 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE1), '%CACHE_PLACEHOLDER_USEMODE_TASK%', '1=0');
            rec.COL_SQLCOPYTOCACHE1 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE1), '%CACHE_PLACEHOLDER_USEMODE_CASE%', '1=1');
            EXECUTE IMMEDIATE TO_CHAR(rec.COL_SQLCOPYTOCACHE1);
            v_cnt:=  SQL%ROWCOUNT;
          END IF;
          IF v_CacheDebug='ON' THEN                      
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES(rec.COL_SQLCOPYTOCACHE1, NULL, 'SQLCOPYTOCACHE1', 
                   TO_CHAR(v_cnt)||' row(s) processed');
          END IF;
          
          v_cnt:=0; 
          IF rec.COL_SQLCOPYTOCACHE2 IS NOT NULL THEN 
            rec.COL_SQLCOPYTOCACHE2 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE2), '%CACHE_PLACEHOLDER_V_CASEID%', TO_CHAR(v_CaseId));
            rec.COL_SQLCOPYTOCACHE2 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE2), '%CACHE_PLACEHOLDER_USEMODE_TASK%', '1=0');
            rec.COL_SQLCOPYTOCACHE2 := REPLACE(TO_CHAR(rec.COL_SQLCOPYTOCACHE2), '%CACHE_PLACEHOLDER_USEMODE_CASE%', '1=1');
            EXECUTE IMMEDIATE TO_CHAR(rec.COL_SQLCOPYTOCACHE2);                        
            v_cnt:=  SQL%ROWCOUNT;
          END IF;
          IF v_CacheDebug='ON' THEN             
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES(rec.COL_SQLCOPYTOCACHE2, NULL, 'SQLCOPYTOCACHE2', 
                   TO_CHAR(v_cnt)||' row(s) processed');
          END IF;
        END IF;--v_Direction-'COPY_TO_CACHE'
        
        IF v_Direction='UPDATE_FROM_CACHE' THEN           
          IF v_CacheDebug='ON' THEN            
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES('---', '---', TO_CHAR(rec.COL_CSTABLENAME)||'=>'||TO_CHAR(rec.COL_RTTABLENAME), '---');
          END IF;

          v_cnt:=0;
          IF rec.COL_SQLUPDATEFROMCACHE1 IS NOT NULL THEN       
            EXECUTE IMMEDIATE TO_CHAR(rec.COL_SQLUPDATEFROMCACHE1); 
            v_cnt:=  SQL%ROWCOUNT;            
          END IF;
          IF v_CacheDebug='ON' THEN              
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES(rec.COL_SQLUPDATEFROMCACHE1, NULL, 'SQLUPDATEFROMCACHE1', 
                   TO_CHAR(v_cnt)||' row(s) processed');
          END IF;
          
          v_cnt:=0;
          IF rec.COL_SQLUPDATEFROMCACHE2 IS NOT NULL THEN 
            EXECUTE IMMEDIATE TO_CHAR(rec.COL_SQLUPDATEFROMCACHE2);  
            v_cnt:=  SQL%ROWCOUNT;               
          END IF;
          IF v_CacheDebug='ON' THEN                        
            INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
            VALUES(rec.COL_SQLUPDATEFROMCACHE2, NULL, 'SQLUPDATEFROMCACHE2', 
                   TO_CHAR(v_cnt)||' row(s) processed');
          END IF;
        END IF;--v_Direction-'UPDATE_FROM_CACHE'      
      END IF;--tables are exists   
    END LOOP;--main loop all tables
  END IF;--ALL  

  IF v_CacheDebug='ON' THEN    
    INSERT INTO TBL_CSCACHELOG(COL_BIGDATA1, COL_BIGDATA2, COL_DATA1,COL_DATA2)
    VALUES(TO_CHAR(SYSDATE,'dd/mm/yyyy hh24:mi:ss'), '---', 'END', 'f_DCM_CSCUseCache');
  END IF;

END;