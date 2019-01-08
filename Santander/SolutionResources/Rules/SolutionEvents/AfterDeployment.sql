/*AFTER DEPLOYMENT*/

DECLARE

  v_str clob := empty_clob();
  v_count         NUMBER;
  v_tenant_schema NVARCHAR2(255);
  query           CLOB;
  v_Result        NUMBER;
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

exec_sql('begin P_UTIL_createErrTables; end;');

/*CASE QUEUE FUNCTIONS*/
exec_sql('create or replace FUNCTION f_DCM_invalidateCase 
/* Invalidates Case. Called from rules: DCM_startCaseTasks, DCM_startCaseTasksFn, DCM_closeCaseTasks, DCM_closeTaskProc. */
(
CaseId IN number 
)

RETURN NUMBER

AS 
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

declare
  v_CaseId Integer;
  v_status nvarchar2(255);
  v_count number;
begin
  v_CaseId := CaseId;
  v_status := ''INVALID'';
  select count(*) into v_count from tbl_casequeue where col_casecasequeue = v_CaseId and col_dict_vldtnstatcasequeue = (select col_id from tbl_dict_validationstatus where col_code = v_status);
  if (v_count is null) or (v_count = 0) then
    insert into tbl_casequeue (col_casecasequeue, col_dict_vldtnstatcasequeue, col_casequeueprocessingstatus)
      values (v_CaseId, (select col_id from tbl_dict_validationstatus where col_code = v_status), (select col_id from tbl_dict_processingstatus where col_code = ''NEW''));
    commit;
  end if;
end;

return 0;

END;');

exec_sql('create or replace FUNCTION f_DCM_validateCase 
(
CaseId IN number 
)
RETURN NUMBER

AS 
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

declare
  v_CaseId Integer;
  v_status nvarchar2(255);
begin
  v_CaseId := CaseId;
  v_status := ''INVALID'';
  delete from tbl_casequeue where col_casecasequeue = v_CaseId and col_dict_vldtnstatcasequeue = (select col_id from tbl_dict_validationstatus where col_code = v_status);
  commit;
  /*
  update tbl_casequeue set col_casequeueprocessingstatus = 1 where col_casecasequeue = v_CaseId and col_dict_vldtnstatcasequeue = (select col_id from tbl_dict_validationstatus where col_code = v_status);
  update tbl_casequeue
  set col_casequeueprocessingstatus = (select col_id from tbl_dict_processingstatus where col_code = ''PROCESSED''),
  col_dict_vldtnstatcasequeue = (select col_id from tbl_dict_validationstatus where col_code = ''VALID'')
  where col_casecasequeue = v_CaseId and col_dict_vldtnstatcasequeue = (select col_id from tbl_dict_validationstatus where col_code = v_status);
  */
end;

return 0;

END;');

/*DEBUG FUNCTIONS*/
exec_sql('CREATE OR REPLACE FUNCTION f_DBG_createDebugSession

(

CaseId IN NUMBER
)

RETURN nvarchar2

AS 
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

declare
  v_result number;
  v_CaseId Integer;
  v_session nvarchar2(255);
  v_User nvarchar2(255);
begin
  v_CaseId := CaseId;
  v_session := sys_context(''CLIENTCONTEXT'', ''SessionGuid''); 
  v_User := sys_context(''CLIENTCONTEXT'', ''AccessSubject'');

   
    MERGE INTO tbl_debugsession
    USING (SELECT 
             v_session AS sess,
             nvl(v_CaseId,0) Case_ID 
           FROM dual
          )
    ON (col_code =  sess)
    WHEN MATCHED THEN UPDATE 
      SET col_debugsessioncase = Case_ID
    WHEN NOT MATCHED THEN 
      INSERT (col_code, col_sessionuser, col_debugsessioncase)
      VALUES (sess, sys_context(''CLIENTCONTEXT'', ''AccessSubject''), Case_ID);  
    begin
      select col_code 
             into v_session 
       from tbl_debugsession 
       where col_sessionuser = v_User 
       AND col_code = v_session;
      exception
      when NO_DATA_FOUND then
      v_session := null;
    end;
  COMMIT;
  return v_session;
end;
END;');

exec_sql( 'CREATE OR REPLACE FUNCTION f_DBG_addDebugTrace
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
declare
  v_result number;
  v_CaseId Integer;
  v_TaskId Integer;
  v_session nvarchar2(255);
  v_SessionId Integer;
  v_location nvarchar2(255);
  v_message nclob;
  v_rule nvarchar2(255);
  v_User nvarchar2(255);
    v_str  varchar2(32000);
begin
  v_CaseId := CaseId;
  v_TaskId := TaskId;
  v_User := sys_context(''CLIENTCONTEXT'', ''AccessSubject'');
  v_location := Location;
  v_message := Message;
  v_rule := Rule;
  v_SessionId := nvl(f_DBG_findDebugSession(CaseId => v_CaseId), 0);
  if v_SessionId > 0 then
FOR rec IN (SELECT p_n.column_value ||'' => ''||nvl(p_v.column_value ,''null'')||chr(13)||chr(10)  str
            FROM
             (SELECT column_value , 
                   rownum rn 
              FROM TABLE(split_casetype_list(param_name))) p_n,
             (SELECT column_value , 
                   rownum rn 
              FROM TABLE(param_value)
              ) p_v
              WHERE p_n.rn = p_v.rn
           ) LOOP
v_str := v_str || rec.str;
END LOOP;

  INSERT INTO tbl_debugtrace 
      (col_taskid, 
       col_location, 
       col_message, 
       col_rule, 
       col_debugtracedebugsession,
       col_accuratetime,
       col_param_value,
       col_Who_Called_Me,
       col_CallStack) 
  VALUES  (v_taskid, 
      v_location, 
      v_message, 
      v_rule, 
      v_sessionid, 
      systimestamp,
      v_str,
      Who_called_me,
      call_stack); 
  ELSE
    return -1;
  end if;
end;
COMMIT;
return 0;

END;
');

exec_sql('CREATE OR REPLACE FUNCTION f_DBG_createDBGTrace
(
CaseId IN number 
,Location IN nvarchar2 
,Message IN nclob 
,Rule IN nvarchar2 
,TaskId IN number 
,who_called_me  IN VARCHAR2 DEFAULT NULL
,Params_Value IN params DEFAULT NULL
,Params_name IN VARCHAR2 DEFAULT NULL
,called_stack IN VARCHAR2 DEFAULT NULL)

RETURN NUMBER
AS 
  v_result number;
  v_CaseId Integer;
  v_TaskId Integer;
  v_Rule nvarchar2(255);
  v_Message nclob;
  v_Location nvarchar2(255);
BEGIN
  v_CaseId := CaseId;
  v_Location := Location;
  v_Message := Message;
  v_Rule := Rule;
  v_TaskId := TaskId;

  IF f_DBG_findDebugSession(CaseId => v_CaseId) IS NOT NULL THEN 
    v_result := f_DBG_addDebugTrace(CaseId        => v_CaseId, 
                                    Location      => v_Location, 
                                    Message       => v_Message, 
                                    Rule          => v_Rule, 
                                    TaskId        => v_TaskId,
                                    Who_called_me => who_called_me,
                                    param_value   => Params_Value,
                                    param_name    => Params_name,
                                    call_stack    => called_stack);
  END IF;

return 0;

END;'
);

exec_sql('CREATE OR REPLACE FUNCTION f_DBG_clearSessions
(
SuccessResponse OUT nvarchar2 
)

RETURN NUMBER

AS 
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

DECLARE
  v_AffectedRows PLS_INTEGER := 0;
  v_result NUMBER;
BEGIN
  DELETE FROM TBL_DEBUGTRACE;
  DELETE FROM TBL_DEBUGSESSION;
  v_AffectedRows := SQL%ROWCOUNT;
  v_Result := LOC_i18n(
    MessageText => ''Deleted {{MESS_COUNT}} Sessions'',
    MessageResult => SuccessResponse,
    MessageParams => NES_TABLE(KEY_VALUE(''MESS_COUNT'', v_AffectedRows))
  );
END;

return 0;

END;');


exec_sql('CREATE OR REPLACE FUNCTION f_DBG_deleteDebugSession
(
CaseId IN number 
)
RETURN NUMBER
AS 
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
declare
  v_result number;
  v_CaseId Integer;
  v_session nvarchar2(255);
  v_SessionId Integer;
  v_User nvarchar2(255);
begin
  v_CaseId := CaseId;
  v_User := sys_context(''CLIENTCONTEXT'', ''AccessSubject'');
  v_SessionId := nvl(f_DBG_findDebugSession(CaseId => v_CaseId), 0);
  if v_SessionId > 0 then
    delete from tbl_debugtrace where col_debugtracedebugsession = v_SessionId;
    delete from tbl_debugsession where col_id = v_SessionId;
  ELSE
    COMMIT;
    return -1;
  end if;
end;
COMMIT;
return 0;
END;');

/*OTHER FUNCTIONS*/
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
  
    v_isError  := NVL(IsError,0);
    v_message  := Message;
    v_xmltID   := XmlIdLog;

    IF length(v_message) < 100 THEN 
      v_message := RPAD(v_message,100);
    END IF;  

    UPDATE tbl_importxml 
       SET col_notes = col_notes || v_message || v_sysdate || CHR(13)||CHR(10),
           col_error_cnt = col_error_cnt + v_isError,
           col_importstatus = import_status,
           col_errorlog = CASE WHEN v_isError = 1 THEN col_errorlog||Message ELSE col_errorlog END 
     WHERE col_id  = v_xmltID;


    COMMIT;
 
END;    
');



/* 
 A script below change a AppBase's generated triggers 
 for cache tables only.

 Please, do not remove it.
 Added by VV Sept, 2017
 
 START

 BI_TBL_CASECC
*/
exec_sql( ' CREATE OR REPLACE TRIGGER BI_TBL_CASECC
BEFORE INSERT ON TBL_CASECC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_Case.nextval INTO :new.col_Id FROM dual;

  END IF;

  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;
END;');
/* 
 BI_TBL_CW_WORKITEMCC
 */
exec_sql(' CREATE OR REPLACE TRIGGER BI_TBL_CW_WORKITEMCC
BEFORE INSERT ON TBL_CW_WORKITEMCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_CW_Workitem.nextval INTO :new.col_Id FROM dual;

  END IF;

  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');
/* 
 BI_TBL_MAP_CASESTATEINITCC
 */
exec_sql(' CREATE OR REPLACE TRIGGER BI_TBL_MAP_CASESTATEINITCC
BEFORE INSERT ON TBL_MAP_CASESTATEINITCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_MAP_CaseStateInitiat.nextval INTO :new.col_Id FROM dual;

  END IF;


  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');
/* 
 BI_TBL_CASEDEPENDENCYCC
 */
exec_sql(' CREATE OR REPLACE TRIGGER BI_TBL_CASEDEPENDENCYCC
BEFORE INSERT ON TBL_CASEDEPENDENCYCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_CaseDependency.nextval INTO :new.col_Id FROM dual;

  END IF;


  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');
/* 
 BI_TBL_CASEEVENTCC
 */
exec_sql( ' CREATE OR REPLACE TRIGGER BI_TBL_CASEEVENTCC
BEFORE INSERT ON TBL_CASEEVENTCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_CaseEvent.nextval INTO :new.col_Id FROM dual;

  END IF;

  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');
/* 
 BI_TBL_AUTORULEPARAMCC
 */
exec_sql( ' CREATE OR REPLACE TRIGGER BI_TBL_AUTORULEPARAMCC
BEFORE INSERT ON TBL_AUTORULEPARAMCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_AutoRuleParameter.nextval INTO :new.col_Id FROM dual;

  END IF;


  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');
/* 
 BI_TBL_HISTORYCC
 */
exec_sql(' CREATE OR REPLACE TRIGGER BI_TBL_HISTORYCC
BEFORE INSERT ON TBL_HISTORYCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_History.nextval INTO :new.col_Id FROM dual;

  END IF;

  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');
/* 
 BI_TBL_DATEEVENTCC
 */
exec_sql( ' CREATE OR REPLACE TRIGGER BI_TBL_DATEEVENTCC
BEFORE INSERT ON TBL_DATEEVENTCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_DateEvent.nextval INTO :new.col_Id FROM dual;

  END IF;

  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');
/* 
 BI_TBL_TASKCC
 */
exec_sql( ' CREATE OR REPLACE TRIGGER BI_TBL_TASKCC
BEFORE INSERT ON TBL_TASKCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_Task.nextval INTO :new.col_Id FROM dual;

  END IF;

  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');
/* 
 BI_TBL_TW_WORKITEMCC
 */
exec_sql(' CREATE OR REPLACE TRIGGER BI_TBL_TW_WORKITEMCC
BEFORE INSERT ON TBL_TW_WORKITEMCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_TW_Workitem.nextval INTO :new.col_Id FROM dual;

  END IF;

  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');
/* 
 BI_TBL_SLAEVENTCC
 */
exec_sql(' CREATE OR REPLACE TRIGGER BI_TBL_SLAEVENTCC
BEFORE INSERT ON TBL_SLAEVENTCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_SLAEvent.nextval INTO :new.col_Id FROM dual;

  END IF;

  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');
/* 
 BI_TBL_SLAACTIONCC
 */
exec_sql(' CREATE OR REPLACE TRIGGER BI_TBL_SLAACTIONCC
BEFORE INSERT ON TBL_SLAACTIONCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_SLAAction.nextval INTO :new.col_Id FROM dual;

  END IF;

  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');
/* 
BI_TBL_MAP_TASKSTATEINITCC
 */
exec_sql( ' CREATE OR REPLACE TRIGGER BI_TBL_MAP_TASKSTATEINITCC
BEFORE INSERT ON TBL_MAP_TASKSTATEINITCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_MAP_TaskStateInitiat.nextval INTO :new.col_Id FROM dual;

  END IF;

  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');
/* 
BI_TBL_TASKDEPENDENCYCC
 */
exec_sql(' CREATE OR REPLACE TRIGGER BI_TBL_TASKDEPENDENCYCC
BEFORE INSERT ON TBL_TASKDEPENDENCYCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_TaskDependency.nextval INTO :new.col_Id FROM dual;

  END IF;

  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');
/* 
BI_TBL_TASKEVENTCC
 */
exec_sql( ' CREATE OR REPLACE TRIGGER BI_TBL_TASKEVENTCC
BEFORE INSERT ON TBL_TASKEVENTCC FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN

    SELECT gen_tbl_TaskEvent.nextval INTO :new.col_Id FROM dual;

  END IF;

  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate

    INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE

    FROM dual;

END;');

/* 
 A script below change a AppBase's generated triggers 
 for documents tables.

 Please, do not remove it.
 Added by Aleksey Andreev August, 2018
*/ 
-- Added CreatedBy, CreatedDate, ModifiedBy, ModifiedDate
-- by Ilya Brezhnev, 20-Nov-2018, DCM-6157
-- bi_tbl_DOC_Document 
exec_sql( 'CREATE OR REPLACE TRIGGER bi_tbl_DOC_Document
BEFORE INSERT ON tbl_DOC_Document 
FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN
    SELECT gen_tbl_DOC_Document.nextval INTO :new.col_Id FROM dual;
  END IF;
  
  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate
  INTO :new.COL_CREATEDBY, :new.COL_CREATEDDATE
  FROM dual;

END;');
-- bu_tbl_DOC_Document
exec_sql( 'CREATE OR REPLACE TRIGGER bu_tbl_DOC_Document
BEFORE UPDATE ON tbl_DOC_Document 
FOR EACH ROW
BEGIN
  
  SELECT SYS_CONTEXT (''CLIENTCONTEXT'', ''AccessSubject''), sysdate
  INTO :new.COL_MODIFIEDBY, :new.COL_MODIFIEDDATE
  FROM dual;
  
END;');
-- bi_tbl_DOC_DocumentVersion
exec_sql('CREATE OR REPLACE TRIGGER bi_tbl_DOC_DocumentVersion
BEFORE INSERT ON tbl_DOC_DocumentVersion 
FOR EACH ROW
BEGIN

  IF :new.col_Id IS NULL THEN
    SELECT gen_tbl_DOC_DocumentVersion.nextval INTO :new.col_Id FROM dual;
  END IF;

END;');

-- bu_tbl_DOC_DocumentVersion
exec_sql('CREATE OR REPLACE TRIGGER bu_tbl_DOC_DocumentVersion
BEFORE UPDATE ON tbl_DOC_DocumentVersion 
FOR EACH ROW
BEGIN

  NULL;

END;');

IF check_obj('SPLIT_TBL') = 0 THEN 
 exec_sql('CREATE OR REPLACE TYPE "SPLIT_TBL" as table of varchar2(32767)');
END IF;
IF check_obj('ECXTYPES') = 0 THEN 
 exec_sql( 'CREATE OR REPLACE PACKAGE EcxTypes AUTHID DEFINER IS
    TYPE Params_Hash IS TABLE OF VARCHAR2(1024) INDEX BY VARCHAR2(1024);
  END EcxTypes;');
END IF;  
 exec_sql('create or replace FUNCTION extract_Clob_value_from_xml
      (
      Input IN nclob
      ,Path IN varchar2      )
      RETURN NCLOB
      AS
      BEGIN
      declare
        v_input    xmltype;
        v_path     varchar2(255);
        v_result   NCLOB := EMPTY_CLOB();
      begin
        v_input := xmltype(Input);
        v_path := Path;
        begin
        v_result := v_input.extract(v_path).getClobval();
        EXCEPTION
        WHEN SELF_IS_NULL  THEN   
       /*   when others then*/
        v_result := null;
        end;
        return v_result;
      end;
      end extract_Clob_value_from_xml;');

  
   exec_sql('ALTER TABLE TBL_DEBUGTRACE MODIFY col_accuratetime timestamp');
   exec_sql('ALTER TABLE TBL_HISTORY MODIFY COL_ACTIVITYTIMEDATE timestamp');
   exec_sql('ALTER TABLE TBL_HISTORYCC MODIFY COL_ACTIVITYTIMEDATE timestamp');


  exec_sql('create or replace package p_ObjectAdded is
  TYPE ObjAddedType    IS TABLE OF NUMBER INDEX BY VARCHAR2(64);
function f_SOM_setObjectAdded
(
ObjectAdded IN OUT ObjAddedType,
ObjectId In Integer
)
return number;
function f_SOM_getObjectAdded
(
ObjectAdded IN OUT ObjAddedType,
ObjectId In Integer
)
return number;
function f_SOM_clearObjectAdded
(
ObjectAdded IN OUT ObjAddedType,
ObjectId In Integer
)
return number;
end p_ObjectAdded;');
 exec_sql('create or replace package body p_ObjectAdded as
function f_SOM_setObjectAdded
(
ObjectAdded IN OUT ObjAddedType,
ObjectId In Integer
)
return number
as
begin

declare
  v_result number;
  v_ObjectId Integer;
begin
  v_ObjectId := ObjectId;
  ObjectAdded(v_ObjectId) := 1;
  /* update tbl_fom_object set col_isadded = 1 where col_id = v_ObjectId; */
  return 1;
end;
end f_SOM_setObjectAdded;
function f_SOM_getObjectAdded
(
ObjectAdded IN OUT ObjAddedType,
ObjectId In Integer
)
return number
as
begin

declare
  v_result number;
  v_ObjectId Integer;
begin
  v_ObjectId := ObjectId;
  v_result := ObjectAdded(v_ObjectId);
  /*
  begin
    select col_isadded into v_result from tbl_fom_object where col_id = v_ObjectId;
    exception
    when NO_DATA_FOUND then
    v_result := 0;
  end;
  */
  return nvl(v_result,0);
end;
end f_SOM_getObjectAdded;
function f_SOM_clearObjectAdded
(
ObjectAdded IN OUT ObjAddedType,
ObjectId In Integer
)
return number
as
begin

declare
  v_result number;
  v_ObjectId Integer;
begin
  v_ObjectId := ObjectId;
  ObjectAdded(v_ObjectId) := 0;
  /* update tbl_fom_object set col_isadded = 0 where col_id = v_ObjectId; */
  return 1;
end;
end f_SOM_clearObjectAdded;
end p_ObjectAdded;');

-- CREATE  A CACHE V2
BEGIN
v_Result := f_DCM_CSCreateCache();
EXCEPTION
   WHEN OTHERS THEN
      INSERT INTO MESSAGES (CODE, BODY, CREATEDDATE)
      VALUES ('AFTER DEPLOYMENT' || sys_guid(), DBMS_UTILITY.format_error_stack, sysdate);
    
      INSERT INTO MESSAGES (CODE, BODY, CREATEDDATE)
      VALUES ('AFTER DEPLOYMENT' || sys_guid(), DBMS_UTILITY.format_error_backtrace, sysdate);
        
END; 

-- COMPILE ALL INVALID FUNCTIONS
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
                VALUES ('AFTER DEPLOYMENT' || sys_guid(), 'error when try to compile body of function '''||CUR.OBJECT_NAME||'''', sysdate); 
                --DBMS_OUTPUT.PUT_LINE('error when try to compile body of function '''||CUR.OBJECT_NAME||'''');  
            ELSE 
                INSERT INTO MESSAGES (CODE, BODY, CREATEDDATE)
                VALUES ('AFTER DEPLOYMENT' || sys_guid(), 'error when try to compile function '''||CUR.OBJECT_NAME||'''', sysdate); 
                --DBMS_OUTPUT.PUT_LINE('error when try to compile function '''||CUR.OBJECT_NAME||''''); 
            END IF; 
    END;
END LOOP; 


-- CREATE INDEXES FOR QUEUE_EVENT
select count(*) into v_count
from user_indexes
where upper(index_name) = 'IND_QUEUE_EVENT_OBJCODE';

if v_count = 0 then
    exec_sql('CREATE INDEX IND_QUEUE_EVENT_OBJCODE ON QUEUE_EVENT (LOWER("OBJECTCODE"))');
end if;

select count(*) into v_count
from user_indexes
where upper(index_name) = 'IND_QUEUE_EVENT_CDATE';

if v_count = 0 then
   exec_sql('CREATE INDEX IND_QUEUE_EVENT_CDATE ON QUEUE_EVENT (TRUNC("CREATEDDATE"))');
end if;


EXCEPTION
   WHEN OTHERS THEN
      INSERT INTO MESSAGES
    (CODE, BODY, CREATEDDATE)
    VALUES
    ('AFTER DEPLOYMENT' || sys_guid(), DBMS_UTILITY.format_error_stack, sysdate);
    
  INSERT INTO MESSAGES
    (CODE, BODY, CREATEDDATE)
    VALUES
    ('AFTER DEPLOYMENT' || sys_guid(), DBMS_UTILITY.format_error_backtrace, sysdate);
    
end;