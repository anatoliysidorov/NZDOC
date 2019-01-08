/*BEFORE DEPLOYMENT*/

DECLARE
  v_sql_varchar2 VARCHAR2(32000);
  v_clob         CLOB;

/********************************************************************/
FUNCTION check_obj(v_name IN VARCHAR2)
RETURN NUMBER
IS 
  v_cnt          PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_cnt 
  FROM user_objects 
  WHERE object_name = UPPER(v_name);
RETURN v_cnt;
END;
/********************************************************************/
PROCEDURE p_util_createMessage(v_code IN VARCHAR2,
                                                 v_body IN VARCHAR2)
IS 
PRAGMA AUTONOMOUS_TRANSACTION ;
BEGIN
INSERT INTO MESSAGES
  (CODE, BODY, CREATEDDATE)
 VALUES 
  (v_code, v_body, SYSDATE);

COMMIT;
END;
/********************************************************************/
PROCEDURE exec_sql (v_text_sql IN CLOB )
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

          EXECUTE IMMEDIATE v_text_sql;

COMMIT;
EXCEPTION  
WHEN OTHERS THEN
p_util_createMessage(v_code => 'Before deployment', v_body => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/********************************************************************/
BEGIN
  /*===SYSTEM TYPES AND OBJECTS FIRST ===*/

    exec_sql('CREATE OR REPLACE TYPE Key_Value FORCE AS OBJECT (
    KEY_        NVARCHAR2(100),
    VALUE_    NVARCHAR2(32767))');

    exec_sql('CREATE OR REPLACE TYPE NES_TABLE AS TABLE OF Key_value');

IF check_obj('T_TABLE_CASETYPE') = 0 THEN
    exec_sql('create or replace TYPE "T_TABLE_CASETYPE" as TABLE OF VARCHAR2(255)');
END IF;

  exec_sql('CREATE OR REPLACE TYPE "SPLIT_TBL" as table of varchar2(32767)');

  exec_sql('CREATE OR REPLACE PACKAGE EcxTypes AUTHID DEFINER IS
    TYPE Params_Hash IS TABLE OF VARCHAR2(1024) INDEX BY VARCHAR2(1024);
  END EcxTypes;');
  
IF check_obj('PARAMS') = 0 THEN
  exec_sql('CREATE OR REPLACE TYPE PARAMS AS TABLE OF VARCHAR2(4000)');
END IF;



  /*===UTILITY FUNCTIONS ===*/
IF check_obj('LIST_COLLECT') = 0 THEN 
	 exec_sql('CREATE OR REPLACE FUNCTION LIST_COLLECT (
    P_ARRAY SPLIT_TBL,
    P_DELIMITER IN VARCHAR2 := NULL,
    P_ISUNIQUE IN NUMBER := 0
  )
  RETURN CLOB
  IS
    vList      CLOB;
    vListCount PLS_INTEGER;
    vListItem VARCHAR2(32767);
  BEGIN
    vListCount := P_ARRAY.COUNT;
    IF (vListCount >= 1) THEN
      vList := P_ARRAY(1);
      vListItem := vList;
    END IF;
    
    FOR i in 2..vListCount LOOP
      IF NOT((P_ISUNIQUE <> 0) and (vListItem = P_ARRAY(i))) THEN
        vList := vList || P_DELIMITER || P_ARRAY(i);
        vListItem := P_ARRAY(i);
      END IF;    
    END LOOP;
    RETURN vList;
  END;');  
 END IF;
  
  exec_sql('CREATE OR REPLACE 
  FUNCTION F_GETJSONPARS_FROMHASH
  (
  v_Hash         IN EcxTypes.Params_Hash
  ) RETURN NCLOB 
  AS
  BEGIN
  DECLARE
  v_data nvarchar2(32767) := ''['';
  Idx VARCHAR2(1024) := v_Hash.FIRST();
  BEGIN
  WHILE Idx IS NOT NULL LOOP
  v_data := v_data || ''{"name": "'' || Idx || ''", "value": "'' || v_Hash(Idx) || ''"},'';
  Idx := v_Hash.NEXT(Idx);
  END LOOP; 

  v_data := substr(v_data, 1, length(v_data) - 1);
  v_data := v_data || '']'';

  RETURN v_data;
  END;
  END F_GETJSONPARS_FROMHASH;');


  /*===CREATE DEPENDENT FUNCTION PLACEHOLDERS===*/
   exec_sql(q'#create or replace FUNCTION LOC_i18n
    (
        MessageText        IN NCLOB,
        MessageResult      OUT NCLOB,
        MessageParams      IN NES_TABLE := null,
        MessageParams2     IN NCLOB     := null,
        DisableEscapeValue IN BOOLEAN   := FALSE
    )
    return number
    is
        v_JSON_text NCLOB;
        l_row pls_integer;
        v_Value NVARCHAR2(32767 CHAR);
    begin
        MessageResult := EMPTY_CLOB();
        dbms_lob.createtemporary(MessageResult, true);
        If (DBMS_LOB.GETLENGTH(trim(MessageParams2)) != 0 and DBMS_LOB.GETLENGTH(MessageParams2) is not null) Then
            v_JSON_text := MessageParams2;
        ELSIF (MessageParams IS NULL) THEN
          v_JSON_text := N'{}';
        ELSE
            l_row := MessageParams.first;
            while l_row is not null loop
                v_Value := TO_NCHAR(REGEXP_REPLACE(MessageParams(l_row).VALUE_, '([/\|"])', '\\\1'));
                if (l_row > 1) then
                    v_JSON_text := v_JSON_text || N',"' || MessageParams(l_row).KEY_ || N'": "' || v_Value || N'"';
                else 
                    v_JSON_text := N'"' || MessageParams(l_row).KEY_ || N'": "' || v_Value || N'"';
                end if;
                l_row:= MessageParams.next(l_row);
            end loop;
            If (DisableEscapeValue and MessageParams.count > 0) Then
              v_JSON_text := v_JSON_text || N',"interpolation": {"escapeValue": false}';
            End if;
            v_JSON_text := N'{' || v_JSON_text || N'}';
        End if;
        DBMS_LOB.OPEN(MessageResult, 1);
        dbms_lob.append(MessageResult, N'{"message": "' || MessageText || N'", "params": ' || v_JSON_text || N'}');
        return 0;
    end;#');
/*q'#'#'*/
  /*===CREATE DEPENDENT FUNCTION PLACEHOLDERS===*/
IF check_obj('F_DBG_CREATEDEBUGSESSION') = 0 THEN 
  exec_sql('CREATE OR REPLACE FUNCTION f_DBG_createDebugSession
  (
  CaseId IN NUMBER
 )
  RETURN nvarchar2
  AS 
PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
     RETURN ''TEMP'';
  END;');
END IF;
IF check_obj('F_DBG_ADDDEBUGTRACE') = 0 THEN 
  exec_sql('CREATE OR REPLACE FUNCTION f_DBG_addDebugTrace
  (
CaseId IN number 
,Location IN nvarchar2 
,Message IN nclob 
,Rule IN nvarchar2 
,TaskId IN number 
,Who_called_me IN VARCHAR2 DEFAULT NULL
,param_value params DEFAULT NULL
,param_name IN VARCHAR2 DEFAULT NULL
,call_stack IN VARCHAR2 DEFAULT NULL
  )
  RETURN NUMBER IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
     RETURN 0;
  END;');
END IF;
IF check_obj('F_DBG_CLEARSESSIONS') = 0 THEN 
  exec_sql('CREATE OR REPLACE FUNCTION f_DBG_clearSessions
  (
  SuccessResponse OUT nvarchar2 
  )
  RETURN NUMBER
  AS 
  PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
     RETURN 0;
  END;');
END IF;
IF check_obj('F_DBG_DELETEDEBUGSESSION') = 0 THEN 
  exec_sql('CREATE OR REPLACE FUNCTION f_DBG_deleteDebugSession
  (
  CaseId IN number 
  )
  RETURN NUMBER
  AS 
  PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
     RETURN 0;
  END;');  
 END IF; 
IF check_obj('P_UTIL_UPDATE_LOG') = 0 THEN 
  exec_sql('CREATE OR REPLACE PROCEDURE P_util_update_log 
  (XmlIdLog     IN NUMBER,
  Message       IN NVARCHAR2,
  IsError       IN PLS_INTEGER,
  import_status IN NVARCHAR2 DEFAULT NULL)
  IS
  PRAGMA AUTONOMOUS_TRANSACTION; 
  v_xmltID      NUMBER;
  v_isError     PLS_INTEGER;
  v_message     NVARCHAR2(4000);
  v_sysdate     NVARCHAR2(50) :=  to_char(SYSTIMESTAMP,''mm/dd/yyyy hh24.mi.ss.ff'');
  BEGIN
      NULL;
  END;');
END IF;	
  /*============================================*/
    
  exec_sql('
  CREATE OR REPLACE 
  FUNCTION QUEUE_addWithHash
  (
    v_Code             IN NVARCHAR2,
    v_Domain           IN NVARCHAR2,
    v_CreatedDate      IN DATE,
    v_CreatedBy        IN NVARCHAR2,
    v_Owner            IN NVARCHAR2,
    v_ScheduledDate    IN DATE,
    v_ObjectType       IN INTEGER,
    v_ProcessedStatus  IN INTEGER,
    v_ProcessedDate    IN DATE,
    v_ErrorStatus      IN INTEGER,
    v_Parameters       IN EcxTypes.Params_Hash,
    v_Priority         IN INTEGER,
    v_ObjectCode       IN NVARCHAR2,
    v_Error            IN NCLOB
  ) RETURN NUMBER 
  AS
  BEGIN
    DECLARE
    Ret Number;
    BEGIN
     Ret:= QUEUE_CREATEEVENT(
      v_Code             => v_Code,
      v_Domain           => v_Domain,
      v_CreatedDate      => v_CreatedDate,
      v_CreatedBy        => v_CreatedBy,
      v_Owner            => v_Owner,
      v_ScheduledDate    => v_ScheduledDate,
      v_ObjectType       => v_ObjectType,
      v_ProcessedStatus  => v_ProcessedStatus,
      v_ProcessedDate    => v_ProcessedDate,
      v_ErrorStatus      => v_ErrorStatus,
      v_Parameters       => F_GETJSONPARS_FROMHASH(v_Hash=>v_Parameters),
      v_Priority         => v_Priority,
      v_ObjectCode       => v_ObjectCode,
      v_Error            => v_Error
      );
    
    
    RETURN Ret;
    END;
    END QUEUE_addWithHash;');  


IF check_obj('SPLIT_CASETYPE_LIST') = 0 THEN   
exec_sql(q'#CREATE OR REPLACE FUNCTION split_casetype_list (list_case_type IN NVARCHAR2 )
    RETURN "T_TABLE_CASETYPE"
    IS
    v_table_casetype "T_TABLE_CASETYPE";

    BEGIN
      SELECT regexp_substr(list_case_type,'[['||chr(58)||'alnum'||chr(58)||']_]+',1,LEVEL)
      BULK COLLECT INTO v_table_casetype
    FROM dual
    CONNECT BY regexp_substr(list_case_type,'[['||chr(58)||'alnum'||chr(58)||']_]+',1,LEVEL) IS NOT NULL;
    RETURN v_table_casetype;
    END split_casetype_list;#');
END IF;


exec_sql(q'#
CREATE OR REPLACE PROCEDURE P_UTIL_createErrTables
AUTHID CURRENT_USER
IS
PRAGMA AUTONOMOUS_TRANSACTION;
v_listOfTable     VARCHAR2(32500);
v_cnt             PLS_INTEGER := 0;
v_sql_cnt         VARCHAR2(8000);
v_sql_dropTBL     VARCHAR2(8000);
BEGIN

v_listOfTable := 'TBL_STP_RESOLUTIONCODE,TBL_STP_PRIORITY,TBL_DICT_TASKSYSTYPE,TBL_TASKSYSTYPERESOLUTIONCODE,TBL_DICT_STATECONFIG,TBL_DICT_LINKTYPE,';
v_listOfTable := v_listOfTable||'TBL_DICT_WORKACTIVITYTYPE,TBL_DICT_PARTYTYPE,TBL_DICT_DOCUMENTTYPE,TBL_FOM_FORM,TBL_FOM_PAGE,TBL_FOM_UIELEMENT,';
v_listOfTable := v_listOfTable||'TBL_FOM_CODEDPAGE,TBL_FOM_DASHBOARD,TBL_FOM_WIDGET,TBL_AC_ACCESSOBJECTTYPE,TBL_AC_PERMISSION,';
v_listOfTable := v_listOfTable||'TBL_AC_ACCESSOBJECT,TBL_INT_INTEGTARGET,TBL_LOC_NAMESPACE,TBL_LOC_PLURALFORM,TBL_LOC_LANGUAGES,TBL_LOC_KEY,';
v_listOfTable := v_listOfTable||'TBL_LOC_KEYSOURCES,TBL_LOC_TRANSLATION,TBL_DICT_MESSAGETYPE,TBL_MESSAGEPLACEHOLDER,TBL_MESSAGE,';
v_listOfTable := v_listOfTable||'TBL_DICT_STATECONFIGTYPE,TBL_DICT_CASESTATE,TBL_DICT_ASSOCPAGETYPE,TBL_DICT_PROCEDUREINCASETYPE';

  v_sql_cnt := 'select count(*) from USER_TABLES WHERE TABLE_NAME = ''ER$';
  v_sql_dropTBL := 'DROP TABLE ER$';
  FOR rec IN (SELECT column_value, SUBSTR(column_value,5) errTable  FROM TABLE(split_casetype_list(v_listOfTable))) LOOP

      EXECUTE IMMEDIATE v_sql_cnt||rec.errTable||'''' INTO v_cnt;
      IF v_cnt > 0 THEN
         EXECUTE IMMEDIATE v_sql_dropTBL||rec.errTable;
      END IF;

      dbms_errlog.create_error_log(dml_table_name => rec.column_value,
                                   err_log_table_name => 'ER$'||rec.errTable,
                                   skip_unsupported => TRUE);

  END LOOP;
COMMIT;
END;#');

-- cache v2
v_clob := EMPTY_CLOB();
DBMS_LOB.CREATETEMPORARY(v_clob,true);
DBMS_LOB.OPEN(v_clob, 1);
DBMS_LOB.APPEND(v_clob, q'$ CREATE OR REPLACE FUNCTION f_DCM_CSCreateCache 

-- Thi func prepare all data for cache

RETURN NUMBER AUTHID CURRENT_USER AS 

BEGIN

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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF; $');
  
  
DBMS_LOB.APPEND(v_clob, q'$  



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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF;  $');



DBMS_LOB.APPEND(v_clob, q'$  


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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

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
    BEGIN
      IF v_cnt=1 THEN EXECUTE IMMEDIATE v_SQLCREATECSTABLE1; END IF;      
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    EXECUTE IMMEDIATE v_SQLCREATECSTABLE2;
  END IF; 
  
  
END;

return 0;

END; $');

--DBMS_LOB.APPEND(v_clob, q'$   $');
--DBMS_LOB.APPEND(v_clob, q'$   $');

EXECUTE IMMEDIATE v_clob; 

FOR CUR IN 
    (SELECT OBJECT_NAME, OBJECT_TYPE, OWNER 
    FROM ALL_OBJECTS 
    WHERE UPPER(OBJECT_TYPE) = UPPER('FUNCTION') 
    AND UPPER(OWNER) = UPPER((SELECT SYS_CONTEXT ('USERENV', 'CURRENT_SCHEMA') FROM DUAL))
    AND STATUS = 'INVALID' ) 
LOOP 
    BEGIN
        IF CUR.OBJECT_TYPE = 'PACKAGE BODY' THEN 
            EXECUTE IMMEDIATE 'alter ' || CUR.OBJECT_TYPE || ' "' ||  CUR.OWNER || '"."' || CUR.OBJECT_NAME || '" compile body'; 
        ELSE 
            EXECUTE IMMEDIATE 'alter ' || CUR.OBJECT_TYPE || ' "' ||  CUR.OWNER || '"."' || CUR.OBJECT_NAME || '" compile'; 
        END IF; 
    EXCEPTION
        WHEN OTHERS THEN 
            IF CUR.OBJECT_TYPE = 'PACKAGE BODY' THEN
                INSERT INTO MESSAGES (CODE, BODY, CREATEDDATE)
                VALUES ('BEFORE DEPLOYMENT' || sys_guid(), 'error when try to compile body of function '''||CUR.OBJECT_NAME||'''', sysdate); 
                --DBMS_OUTPUT.PUT_LINE('error when try to compile body of function '''||CUR.OBJECT_NAME||'''');  
            ELSE 
                INSERT INTO MESSAGES (CODE, BODY, CREATEDDATE)
                VALUES ('BEFORE DEPLOYMENT' || sys_guid(), 'error when try to compile function '''||CUR.OBJECT_NAME||'''', sysdate); 
                --DBMS_OUTPUT.PUT_LINE('error when try to compile function '''||CUR.OBJECT_NAME||''''); 
            END IF; 
    END;
END LOOP; 

EXCEPTION
   WHEN OTHERS THEN
      INSERT INTO MESSAGES
    (CODE, BODY, CREATEDDATE)
    VALUES
    ('BEFORE DEPLOYMENT' || sys_guid(), 
    DBMS_UTILITY.format_error_stack, sysdate);
    
      INSERT INTO MESSAGES
    (CODE, BODY, CREATEDDATE)
    VALUES
    ('BEFORE DEPLOYMENT' || sys_guid(), 
    DBMS_UTILITY.format_error_backtrace, sysdate);
END;