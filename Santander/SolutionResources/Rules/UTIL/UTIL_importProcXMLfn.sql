declare
  v_input                       xmltype;
  v_input_clob                  NCLOB := Empty_clob();
  v_result                      NVARCHAR2(32000);
  v_notes                       NCLOB;
  v_code                        NVARCHAR2(255);
  v_procedureid                 Integer;
  v_casetypeid                  Integer;
  v_xmlresult                   xmltype;
  v_xmlresult2                  xmltype;
  v_xmlresult3                  xmltype;
  v_count                       Integer;
  v_cnt                         PLS_INTEGER;
  v_path                        VARCHAR2(255);
  v_level                       Integer;
  v_parentid                    Integer;
  v_taskDepId                   NUMBER;
  v_ar_param                    NVARCHAR2(255);
  v_ar_value                    NVARCHAR2(255);
  v_dict                        NVARCHAR2(255);
  v_procType                    NVARCHAR2(255);    
BEGIN

  if Input is not null then
    v_input := XMLType(Input);
    v_input_clob := v_input.getClobVal();
  end if;
    v_level := 1;
    v_parentid := 0;
    v_procType := :procType;  
    v_path := 'count(CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition)';    
SELECT y.column_value.getstringval()
    INTO v_count
    FROM xmltable(v_path passing v_input) y ;	 
FOR idx IN 1..v_count LOOP 

   /**********************************************************************************/

   --Extracting tbl_dict_taskstate
   /**********************************************************************************/


BEGIN
  
  
v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/TaskState');
-- Task states for Proc
   MERGE INTO tbl_dict_taskstate
   USING (
      SELECT Code, Activity, Name, CanAssign, DefaultOrder, Description, IsAssign, IsDefaultonCreate,IsDefaultonCreate2,
          IsDeleted, IsFinish, IsHidden, IsResolve, IsStart, dbms_xmlgen.convert(StyleInfo,1) StyleInfo, Ucode,  Iconcode,
          (SELECT col_id FROM tbl_dict_stateconfig WHERE lower(col_code) = lower(Config)) Config, length(dbms_xmlgen.convert(StyleInfo,1)) xmlleng
          FROM XMLTABLE('TaskState'
              PASSING v_xmlresult
              COLUMNS
                       Code         NVARCHAR2(255) PATH './Code',
                       Activity     NVARCHAR2(255) PATH './Activity',
                       Name         NVARCHAR2(255) PATH './Name',
                       CanAssign    NUMBER PATH './CanAssign',
                       DefaultOrder NUMBER PATH './DefaultOrder',
                       Description  NCLOB PATH './Description',
                       IsAssign     NUMBER PATH './IsAssign',
                       IsDefaultonCreate NUMBER PATH './IsDefaultonCreate',
                       IsDefaultonCreate2 NUMBER PATH './IsDefaultonCreate2',
                       IsDeleted    NUMBER PATH './IsDeleted',
                       IsFinish     NUMBER PATH './IsFinish',
                       IsHidden     NUMBER PATH './IsHidden',
                       IsResolve    NUMBER PATH './IsResolve',
                       IsStart      NUMBER PATH './IsStart',
                       StyleInfo    NCLOB path './StyleInfo',
                       Ucode        NVARCHAR2(255) PATH './Ucode',
                       Config       NVARCHAR2(255) PATH './StateConfig',
                       Iconcode     NVARCHAR2(255) PATH './Iconcode'
                       )
   WHERE  Config IS NOT NULL
   )
   ON (lower(col_code) = lower(Code) AND nvl(col_stateconfigtaskstate,-1) = nvl(Config,-1)  )
   WHEN MATCHED THEN
     UPDATE  SET col_activity = Activity, col_description = Description,  col_isdeleted = IsDeleted,
     col_name = Name,  col_canassign = CanAssign, col_isassign = IsAssign,
     col_isdefaultoncreate = IsDefaultonCreate,  col_isdefaultoncreate2 = IsDefaultonCreate2, 
     col_isfinish = IsFinish, col_iconcode = Iconcode,
     col_ishidden = IsHidden, col_isresolve = IsResolve, col_isstart = IsStart,
     col_defaultorder = DefaultOrder, col_styleinfo = decode (xmlleng,0 ,NULL,  xmltype(StyleInfo)), col_ucode = Ucode
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
   WHEN NOT MATCHED THEN
     INSERT
     (col_activity, col_canassign, col_code, col_defaultorder, col_description,
      col_isassign, col_isdefaultoncreate, col_isdefaultoncreate2, col_isdeleted, col_isfinish,
      col_ishidden, col_isresolve, col_isstart, col_name, col_styleinfo , col_ucode , col_stateconfigtaskstate, col_iconcode  )
     VALUES
     (Activity, CanAssign, Code,  DefaultOrder, Description,
      IsAssign, IsDefaultonCreate, IsDefaultonCreate2, IsDeleted, IsFinish,
      IsHidden, IsResolve,  IsStart,  Name,  decode (xmlleng,0 ,NULL,  xmltype(StyleInfo)), Ucode , Config, Iconcode );
      
  p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_DICT_TASKSTATE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
   /**********************************************************************************/

   --Extracting tbl_DICT_TASKSTATESETUP
   /**********************************************************************************/

BEGIN
v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/TaskStateSetup');
v_xmlresult2 := v_input.extract('/CaseType/Dictionary/TaskState');
v_xmlresult3 := v_input.extract('/CaseType/TaskState');
   MERGE INTO tbl_DICT_TASKSTATESETUP
   USING (
SELECT CASE WHEN ts.Config IS NULL THEN
  (SELECT col_id FROM tbl_dict_taskstate WHERE col_code = ts.Code AND col_stateconfigtaskstate IS NULL)
          WHEN ts.Config IS NOT NULL THEN
  (SELECT col_id FROM tbl_dict_taskstate WHERE col_ucode = tss.TaskState)
   END  taskstateId ,
   tss.*
FROM
(      SELECT Code, FofsedNull, Name, ForcedOverWrite, NotNullOverWrite, NullOverWrite, Ucode, TaskState
          FROM XMLTABLE('TaskStateSetup'
              PASSING v_xmlresult
              COLUMNS
                       Code         NVARCHAR2(255) PATH './Code',
                       FofsedNull   NUMBER PATH './FofsedNull',
                       Name         NVARCHAR2(255) PATH './Name',
                       ForcedOverWrite    NUMBER PATH './ForcedOverWrite',
                       NotNullOverWrite     NUMBER PATH './NotNullOverWrite',
                       NullOverWrite NUMBER PATH './NullOverWrite',
                       Ucode         NVARCHAR2(255) PATH './Ucode',
                       TaskState     NVARCHAR2(255) PATH './TaskState'
                       )
) tss
JOIN
(    SELECT Code, Ucode , Config
          FROM XMLTABLE('TaskState'
              PASSING v_xmlresult2
              COLUMNS
                       Code         NVARCHAR2(255) PATH './Code',
                       Ucode        NVARCHAR2(255) PATH './Ucode',
                       Config       NVARCHAR2(255) PATH './StateConfig'
                       )
         UNION                     
         SELECT Code, Ucode , Config
                FROM XMLTABLE('TaskState'
                    PASSING v_xmlresult3
                    COLUMNS
                             Code         NVARCHAR2(255) PATH './Code',
                             Ucode        NVARCHAR2(255) PATH './Ucode',
                             Config       NVARCHAR2(255) PATH './StateConfig'
                             )                       
) ts
ON tss.TaskState = ts.Ucode
   )
   ON (col_code = Code AND col_taskstatesetuptaskstate = taskstateId)
   WHEN MATCHED THEN
     UPDATE  SET col_forcednull = FofsedNull, col_forcedoverwrite = ForcedOverWrite, col_name =  Name,
     col_notnulloverwrite = NotNullOverWrite,  col_nulloverwrite = NullOverWrite, col_ucode = Ucode
   WHEN NOT MATCHED THEN
     INSERT
     (col_code, col_forcednull, col_forcedoverwrite, col_name, col_notnulloverwrite, col_taskstatesetuptaskstate, col_nulloverwrite, col_Ucode   )
     VALUES
     (Code, FofsedNull, ForcedOverWrite, Name, NotNullOverWrite, taskstateId, NullOverWrite, Ucode );

  p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_DICT_TASKSTATESETUP with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
  /**********************************************************************************/
  --EXTRACTING PROCEDURE
  /**********************************************************************************/

  BEGIN
    v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/Procedure');
    v_xmlresult2 := v_input.extract('/CaseType/Dictionary/CaseState');


    v_code := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Procedure/Code/text()');
    DECLARE
    v_casestate      NVARCHAR2(255);

    BEGIN
      v_casestate := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Procedure/CaseState/text()');

      IF v_casestate IS NOT NULL THEN

                SELECT COUNT(*) /*It means that record belong to default state machine */
                  INTO v_cnt
               FROM tbl_dict_casestate
               WHERE col_ucode =  v_casestate ;


               IF v_cnt = 0 THEN
                     SELECT col_ucode INTO
                     v_casestate
                     FROM (
                     SELECT Code, Ucode, StateConfig
                      FROM XMLTABLE('CaseState'
                        PASSING v_xmlresult2
                        COLUMNS
                                 Code nvarchar2(255) PATH './Code',
                                 Ucode nvarchar2(255) PATH './Ucode',
                                 StateConfig NVARCHAR2(255) PATH './Config'
                                 )
                         ) state_,
                       tbl_dict_casestate tst
                      WHERE  Ucode =  v_casestate
                      AND tst.col_code = Code
                      AND tst.col_stateconfigcasestate IS NULL;

               END IF;

     END IF;


    MERGE INTO tbl_procedure
    USING
    (  SELECT v_code CODE, Name, Description, RootTaskTypeCode, CustomDataProcessor, RetrieveCustomDataProcessor,
              UpdateCustomDataProcessor, CustomValidator, IsDefault, IsDeleted, ConfigProc,
              (SELECT col_id FROM tbl_dict_casestate WHERE  col_ucode = v_casestate  ) CaseStateId,
              (SELECT COL_ID FROM tbl_dict_procedureincasetype WHERE col_code = ProcInCaseType) ProcInCaseType 
       FROM XMLTABLE('Procedure'
                        PASSING v_xmlresult
                        COLUMNS
                                 Name nvarchar2(255) PATH './Name',
                                 ConfigProc NCLOB PATH './ConfigProc',
                                 Description NCLOB PATH './Description',
                                 RootTaskTypeCode NVARCHAR2(255) PATH './RootTaskTypeCode',
                                 CustomDataProcessor NVARCHAR2(255) PATH './CustomDataProcessor',
                                 RetrieveCustomDataProcessor NVARCHAR2(255) PATH './RetrieveCustomDataProcessor',
                                 UpdateCustomDataProcessor NVARCHAR2(255) PATH './UpdateCustomDataProcessor',
                                 CustomValidator NVARCHAR2(255) PATH './CustomValidator',
                                 IsDefault NUMBER PATH './IsDefault',
                                 IsDeleted NUMBER PATH './IsDeleted',
                                 ProcInCaseType NVARCHAR2(255) PATH './ProcInCaseType'
                                 ) 

    )
    ON (col_code = code)
    WHEN MATCHED THEN
      UPDATE SET col_customdataprocessor = CustomDataProcessor, col_customvalidator = CustomValidator, col_description = Description,
      col_isdefault = IsDefault, col_isdeleted = IsDeleted, col_name = Name, col_retcustdataprocessor = RetrieveCustomDataProcessor,
      col_updatecustdataprocessor = UpdateCustomDataProcessor, col_procedurecasestate = CaseStateId, col_proceduredict_casesystype = v_casetypeid,
      col_config = ConfigProc, col_procprocincasetype = ProcInCaseType
    WHEN NOT MATCHED THEN
    INSERT (col_code, col_name, col_roottasktypecode, col_proceduredict_casesystype, col_procedurecasestate,
      col_updatecustdataprocessor, col_retcustdataprocessor, col_customvalidator, col_customdataprocessor, col_isdefault, col_isdeleted, col_config, col_procprocincasetype  )
    VALUES  (code, Name, RootTaskTypeCode, v_casetypeid, CaseStateId,
      UpdateCustomDataProcessor, RetrieveCustomDataProcessor, CustomValidator, CustomDataProcessor, IsDefault, IsDeleted, ConfigProc, ProcInCaseType);

  p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_PROCEDURE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
    begin
    SELECT col_id
      INTO  v_procedureid
      FROM tbl_procedure
     WHERE col_code = v_code;

     exception when no_data_found then
               IF XmlId IS NOT NULL THEN 
                 p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Procedure wasn''t found by code '||v_code , IsError => 1);                 
               END IF;

      return 'Procedure wasn''t found by code '||v_code;

     end;


       SELECT COUNT(*) INTO v_cnt FROM tbl_tasktemplate 
       WHERE (col_proceduretasktemplate = v_procedureid OR col_proceduretasktemplate IS NULL)
       AND col_name = 'root';

       
    IF v_cnt = 0 THEN
        INSERT INTO tbl_tasktemplate
              (col_name, col_parentttid, col_taskorder, col_depth, col_leaf, col_proceduretasktemplate, col_icon, col_systemtype, col_taskid  ) 
        VALUES 
              ('root',v_parentid,1,0,0, v_procedureid,'folder', 'Root', 'root')
        RETURNING col_id INTO v_parentid;
    ELSE 
        SELECT col_id INTO v_parentid
         FROM tbl_tasktemplate 
         WHERE (col_proceduretasktemplate = v_procedureid OR col_proceduretasktemplate IS NULL)
         AND col_name = 'root'; 
    END IF;


   UPDATE tbl_tasktemplate
   SET COL_PROCEDURETASKTEMPLATE =  v_procedureid
   WHERE col_name ='root' AND COL_PROCEDURETASKTEMPLATE IS NULL;

 end; 

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 

/*************************************************************/
 --EXTRACTING TASK TYPES
/*************************************************************/

 BEGIN
   v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/TaskType');
     MERGE INTO TBL_DICT_TASKSYSTYPE
      USING ( SELECT  Code, Name,  Description, CustomDataProcessor, 
              DateEventCustDataProc, IsDeleted, ProcessorCode, 
              RetCustDataProcessor, UpdateCustDataProcessor, 
              (SELECT col_id FROM tbl_dict_executionmethod WHERE col_code = TaskSysTypeExecMethod) TaskSysTypeExecMethod,
              (SELECT col_id FROM tbl_dict_stateconfig WHERE col_code = StateConfig) StateConfig,
              RouteCustomDataProcessor, IconCode
            FROM XMLTABLE('TaskType'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Description NCLOB PATH './Description',
                       CustomDataProcessor NVARCHAR2(255) PATH './CustomDataProcessor',
                       DateEventCustDataProc NVARCHAR2(255) PATH './DateEventCustDataProc',
                       IsDeleted NUMBER  PATH './IsDeleted',                       
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',
                       RetCustDataProcessor NVARCHAR2(255) PATH './RetCustDataProcessor', 
                       UpdateCustDataProcessor NVARCHAR2(255) PATH './UpdateCustDataProcessor', 
                       TaskSysTypeExecMethod NVARCHAR2(255) PATH './TaskSysTypeExecMethod', 
                       StateConfig NVARCHAR2(255) PATH './StateConfig',
                       RouteCustomDataProcessor NVARCHAR2(255) PATH './RouteCustomDataProcessor',
                       IconCode NVARCHAR2(255) PATH './IconCode'
                       )
      )                 
      ON (col_code = Code)
      WHEN MATCHED THEN
        UPDATE  SET
        col_name = Name , col_description = Description, col_customdataprocessor = CustomDataProcessor,
        col_processorcode = ProcessorCode,   col_retcustdataprocessor = RetCustDataProcessor,
        col_updatecustdataprocessor = UpdateCustDataProcessor, col_tasksystypeexecmethod = TaskSysTypeExecMethod,
        col_isdeleted = IsDeleted, col_stateconfigtasksystype = StateConfig, 
        col_dateeventcustdataproc = DateEventCustDataProc,
        col_routecustomdataprocessor = RouteCustomDataProcessor, 
        col_iconcode =  IconCode 
        WHEN NOT MATCHED THEN
      INSERT
         (col_code  , col_name      , col_description, col_customdataprocessor,   col_processorcode,
          col_retcustdataprocessor, col_updatecustdataprocessor ,  col_tasksystypeexecmethod , col_isdeleted, 
          col_stateconfigtasksystype, col_dateeventcustdataproc, 
          col_routecustomdataprocessor, col_iconcode)
      VALUES
         (Code, Name, Description, CustomDataProcessor, ProcessorCode,
         RetCustDataProcessor, UpdateCustDataProcessor,  TaskSysTypeExecMethod, IsDeleted,
         StateConfig,  DateEventCustDataProc,
         RouteCustomDataProcessor, IconCode);

  p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_DICT_TASKSYSTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/*************************************************************/

--EXTRACTING TBL_TASKSYSTYPERESOLUTIONCODE
/*************************************************************/

 BEGIN
 
 
   v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/TaskSysTypeResolutionCode');

MERGE INTO tbl_tasksystyperesolutioncode
USING 
( SELECT tst.col_id AS TaskTypeId,
         rc.col_id AS ResolutionCodeId
  FROM 
(SELECT  ResolutionCode, TaskType
            FROM XMLTABLE('TaskSysTypeResolutionCode'
              PASSING v_xmlresult
              COLUMNS
                       ResolutionCode NVARCHAR2(255) PATH './ResolutionCode',
                       TaskType NVARCHAR2(255) PATH './TaskType'
                       )) tstrc
  JOIN TBL_DICT_TASKSYSTYPE tst ON tst.col_code = tstrc.TaskType 
  JOIN tbl_stp_resolutioncode rc ON rc.col_code = tstrc.ResolutionCode AND rc.col_type = 'TASK'
)  
ON (col_tbl_stp_resolutioncode = ResolutionCodeId AND col_tbl_dict_tasksystype = TaskTypeId)
WHEN NOT MATCHED THEN 
  INSERT (col_tbl_stp_resolutioncode, col_tbl_dict_tasksystype)
  VALUES (ResolutionCodeId, TaskTypeId);  

  p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_TASKSYSTYPERESOLUTIONCODE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
    
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;   
/******************************************************************************/


/*************************************************************/

--TASKTEMPLATE   TBL_MAP_TASKSTATEINITIATION
/*************************************************************/

BEGIN
  
/*  IF v_input.existsnode('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/TaskTemplates') = 0  AND v_input.existsnode('/CaseType/ProcedureAddition['||idx||']/TaskTemplatesTMPL') = 0 THEN 

         IF XmlId IS NOT NULL THEN 
            p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition      TaskTemplates and TaskTemplatesTMPL for ProcedureAddition are empty', IsError => 1, import_status =>'FAILURE' );
         END IF;


    return 'TaskTemplates and TaskTemplatesTMPL for ProcedureAddition are empty';
  end if;*/
  
 v_count := 1;
  v_path := '/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/TaskTemplates';
  v_xmlresult := v_input.extract(v_path);


  if v_xmlresult is null then
  
  v_result := f_UTIL_extract_values_recurs(Input => v_input, 
                                           Path => v_path, 
                                           TaskTemplateLevel => v_level + 1, 
                                           ParentId => v_parentid, 
                                           CaseTypeId => v_casetypeid, 
                                           ProcedureId => v_procedureid,
                                           XmlId => XmlId);
  
  end if;
  
--TASKTEMPLATE   TBL_MAP_TASKSTATEINITMPL                                           
  v_count := 1;
  v_path := '/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/TaskTemplatesTMPL';
  v_xmlresult := v_input.extract(v_path);


  IF v_xmlresult IS  NOT NULL  THEN 
          v_result := f_UTIL_extract_values_recursTM(Input => v_input, 
                                                   Path => v_path, 
                                                   TaskTemplateLevel => v_level + 1, 
                                                   ParentId => v_parentid, 
                                                   CaseTypeId => v_casetypeid, 
                                                   ProcedureId => v_procedureid,
                                                   XmlId => XmlId);                                           
  END IF;                                            
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;                                            

      /*************************************************************/

      --TaskDependency
      /*************************************************************/

 BEGIN  
      v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/Taskdependency');
        v_xmlresult2 := v_input.extract('/CaseType/Dictionary/TaskState');        
   v_count := 0;
  SELECT y.column_value.getstringval()
    INTO v_count
    FROM xmltable('count(Taskdependency)' passing v_xmlresult) y ;


  DECLARE

  v_MapTskstinitTsksChld       NVARCHAR2(255);
  v_MapTskstinitTsksPr         NVARCHAR2(255);

  BEGIN
  FOR i IN 1..v_count LOOP
    v_code := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Taskdependency['||i||']/Code/text()');

    v_MapTskstinitTsksChld := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Taskdependency['||i||']/MapTskstinitTsksChld/text()');

    SELECT COUNT(*)
      INTO v_cnt
      FROM tbl_dict_taskstate
    WHERE col_ucode = v_MapTskstinitTsksChld;


    IF v_cnt = 0 THEN
         SELECT col_ucode INTO
           v_MapTskstinitTsksChld
           FROM (
           SELECT Code, Ucode, StateConfig
            FROM XMLTABLE('TaskState'
              PASSING v_xmlresult2
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Ucode nvarchar2(255) PATH './Ucode',
                       StateConfig NVARCHAR2(255) PATH './StateConfig'
                       )
               ) state_,
             tbl_dict_taskstate tst
            WHERE  Ucode =  v_MapTskstinitTsksChld
            AND tst.col_code = Code
            AND tst.col_stateconfigtaskstate IS NULL;

    END IF;


        v_MapTskstinitTsksPr := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Taskdependency['||i||']/MapTskstinitTsksPr/text()');

    SELECT COUNT(*)
      INTO v_cnt
      FROM tbl_dict_taskstate
    WHERE col_ucode = v_MapTskstinitTsksPr;


    IF v_cnt = 0 THEN
         SELECT col_ucode INTO
           v_MapTskstinitTsksPr
           FROM (
           SELECT Code, Ucode, StateConfig
            FROM XMLTABLE('TaskState'
              PASSING v_xmlresult2
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Ucode nvarchar2(255) PATH './Ucode',
                       StateConfig NVARCHAR2(255) PATH './StateConfig'
                       )
               ) state_,
             tbl_dict_taskstate tst
            WHERE  Ucode =  v_MapTskstinitTsksPr
            AND tst.col_code = Code
            AND tst.col_stateconfigtaskstate IS NULL;

    END IF;


 

  
    MERGE INTO tbl_taskdependency
    USING (
    SELECT
     v_code AS code,
     f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Taskdependency['||i||']/ProcessorCode/text()') ProcessorCode,
     f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Taskdependency['||i||']/Type/text()') Type_,
     (      SELECT mti.col_id
        FROM tbl_tasktemplate tt,
             tbl_map_taskstateinitiation  mti,
             TBL_DICT_TASKSTATE tst
      WHERE mti.col_map_taskstateinittasktmpl = tt.col_id
        AND tt.col_code = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Taskdependency['||i||']/TaskTemplateCodeChld/text()')
        AND  mti.col_map_tskstinit_tskst = tst.col_id
        AND tst.col_ucode = v_MapTskstinitTsksChld) tskdpndchldtskstateinit,
     (SELECT mti.col_id
        FROM tbl_tasktemplate tt,
             tbl_map_taskstateinitiation  mti,
             TBL_DICT_TASKSTATE tst
      WHERE mti.col_map_taskstateinittasktmpl = tt.col_id
        AND tt.col_code = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Taskdependency['||i||']/TaskTemplateCodePr/text()')
        AND  mti.col_map_tskstinit_tskst = tst.col_id
        AND tst.col_ucode = v_MapTskstinitTsksPr
     ) tskdpndprnttskstateinit
    FROM dual)
    ON (col_code = code)
    WHEN MATCHED THEN
      UPDATE SET col_processorcode =ProcessorCode , col_type = Type_ ,
      col_tskdpndchldtskstateinit = tskdpndchldtskstateinit,
      col_tskdpndprnttskstateinit = tskdpndprnttskstateinit
    WHEN NOT MATCHED THEN
    INSERT
    (col_code, col_processorcode, col_type , col_tskdpndchldtskstateinit , col_tskdpndprnttskstateinit )
    VALUES
    (v_code  , ProcessorCode, Type_, tskdpndchldtskstateinit ,tskdpndprnttskstateinit);


     SELECT col_id
     INTO  v_taskDepId
     FROM tbl_taskdependency
     WHERE col_code = v_code;



      DECLARE
      v_path_cnt NVARCHAR2(255);

      BEGIN
        v_path_cnt := 'count(Taskdependency['||i||']/AutoruleParams)';
      SELECT y.column_value.getstringval()
        INTO v_cnt
        FROM xmltable(v_path_cnt passing v_xmlresult) y ;


       FOR j IN 1..v_cnt LOOP


    v_ar_param := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Taskdependency['||i||']/AutoruleParams['||j||']/ParamCode/text()');
    v_ar_value := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Taskdependency['||i||']/AutoruleParams['||j||']/ParamValue/text()');

    IF v_ar_param IS NOT NULL THEN
       MERGE INTO tbl_autoruleparameter
       USING (
       SELECT
       f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Taskdependency['||i||']/AutoruleParams['||j||']/Code/text()') code,
       v_ar_param ar_param,
       v_ar_value ar_value
       FROM dual)
       ON (col_code = code)
       WHEN MATCHED THEN UPDATE
         SET col_autoruleparamtaskdep = v_taskDepId,  col_paramcode = ar_param, col_paramvalue =  ar_value
       WHEN NOT MATCHED THEN
       INSERT
       (col_code, col_autoruleparamtaskdep, col_paramcode , col_paramvalue )
       VALUES
       (code, v_taskDepId, ar_param, ar_value);


       v_ar_param := NULL;
       v_ar_value := NULL;
     END IF;

     END LOOP;

    END;

  END LOOP;
 p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_TASKDEPENDENCY with '||v_count||' rows', IsError => 0);  
 p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged depended TBL_AUTORULEPARAMETER with '||v_cnt||' rows', IsError => 0);   
  END;

 

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
      /*************************************************************/

      --TBL_TASKDEPENDENCYTMPL
      /*************************************************************/

 BEGIN  
      v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/TaskdependencyTMPL');
        v_xmlresult2 := v_input.extract('/CaseType/Dictionary/TaskState');        
   v_count := 0;
  SELECT y.column_value.getstringval()
    INTO v_count
    FROM xmltable('count(TaskdependencyTMPL)' passing v_xmlresult) y ;


  DECLARE

  v_MapTskstinitTsksChld       NVARCHAR2(255);
  v_MapTskstinitTsksPr         NVARCHAR2(255);

  BEGIN
  FOR i IN 1..v_count LOOP
    v_code := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskdependencyTMPL['||i||']/Code/text()');

    v_MapTskstinitTsksChld := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskdependencyTMPL['||i||']/MapTskstinitTsksChld/text()');

    SELECT COUNT(*)
      INTO v_cnt
      FROM tbl_dict_taskstate
    WHERE col_ucode = v_MapTskstinitTsksChld;


    IF v_cnt = 0 THEN
         SELECT col_ucode INTO
           v_MapTskstinitTsksChld
           FROM (
           SELECT Code, Ucode, StateConfig
            FROM XMLTABLE('TaskState'
              PASSING v_xmlresult2
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Ucode nvarchar2(255) PATH './Ucode',
                       StateConfig NVARCHAR2(255) PATH './StateConfig'
                       )
               ) state_,
             tbl_dict_taskstate tst
            WHERE  Ucode =  v_MapTskstinitTsksChld
            AND tst.col_code = Code
            AND tst.col_stateconfigtaskstate IS NULL;

    END IF;


        v_MapTskstinitTsksPr := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskdependencyTMPL['||i||']/MapTskstinitTsksPr/text()');

    SELECT COUNT(*)
      INTO v_cnt
      FROM tbl_dict_taskstate
    WHERE col_ucode = v_MapTskstinitTsksPr;


    IF v_cnt = 0 THEN
         SELECT col_ucode INTO
           v_MapTskstinitTsksPr
           FROM (
           SELECT Code, Ucode, StateConfig
            FROM XMLTABLE('TaskState'
              PASSING v_xmlresult2
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Ucode nvarchar2(255) PATH './Ucode',
                       StateConfig NVARCHAR2(255) PATH './StateConfig'
                       )
               ) state_,
             tbl_dict_taskstate tst
            WHERE  Ucode =  v_MapTskstinitTsksPr
            AND tst.col_code = Code
            AND tst.col_stateconfigtaskstate IS NULL;

    END IF;


 

  
    MERGE INTO tbl_taskdependencytmpl
    USING (
    SELECT
     v_code AS code,
     f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskdependencyTMPL['||i||']/ProcessorCode/text()') ProcessorCode,
     f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskdependencyTMPL['||i||']/Type/text()') Type_,
     (      SELECT mti.col_id
        FROM tbl_tasktemplate tt,
             tbl_map_taskstateinittmpl  mti,
             TBL_DICT_TASKSTATE tst
      WHERE mti.col_map_taskstinittpltasktpl  = tt.col_id
        AND tt.col_code = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskdependencyTMPL['||i||']/TaskTemplateCodeChld/text()')
        AND  mti.col_map_tskstinittpl_tskst  = tst.col_id
        AND tst.col_ucode = v_MapTskstinitTsksChld) tskdpndchldtskstateinit,
     (SELECT mti.col_id
        FROM tbl_tasktemplate tt,
             tbl_map_taskstateinittmpl  mti,
             TBL_DICT_TASKSTATE tst
      WHERE mti.col_map_taskstinittpltasktpl  = tt.col_id
        AND tt.col_code = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskdependencyTMPL['||i||']/TaskTemplateCodePr/text()')
        AND  mti.col_map_tskstinittpl_tskst  = tst.col_id
        AND tst.col_ucode = v_MapTskstinitTsksPr
     ) tskdpndprnttskstateinit
    FROM dual)
    ON (col_code = code)
    WHEN MATCHED THEN
      UPDATE SET col_processorcode =ProcessorCode , col_type = Type_ ,
      col_taskdpchldtptaskstinittp  = tskdpndchldtskstateinit,
      col_taskdpprnttptaskstinittp  = tskdpndprnttskstateinit
    WHEN NOT MATCHED THEN
    INSERT
    (col_code, col_processorcode, col_type , col_taskdpchldtptaskstinittp  , col_taskdpprnttptaskstinittp  )
    VALUES
    (v_code  , ProcessorCode, Type_, tskdpndchldtskstateinit ,tskdpndprnttskstateinit);


     SELECT col_id
     INTO  v_taskDepId
     FROM tbl_taskdependencytmpl
     WHERE col_code = v_code;



      DECLARE
      v_path_cnt NVARCHAR2(255);

      BEGIN
        v_path_cnt := 'count(TaskdependencyTMPL['||i||']/AutoruleParams)';
      SELECT y.column_value.getstringval()
        INTO v_cnt
        FROM xmltable(v_path_cnt passing v_xmlresult) y ;


       FOR j IN 1..v_cnt LOOP


    v_ar_param := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskdependencyTMPL['||i||']/AutoruleParams['||j||']/ParamCode/text()');
    v_ar_value := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskdependencyTMPL['||i||']/AutoruleParams['||j||']/ParamValue/text()');

    IF v_ar_param IS NOT NULL THEN
       MERGE INTO tbl_autoruleparamtmpl
       USING (
       SELECT
       f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskdependencyTMPL['||i||']/AutoruleParams['||j||']/Code/text()') code,
       v_ar_param ar_param,
       v_ar_value ar_value
       FROM dual)
       ON (col_code = code)
       WHEN MATCHED THEN UPDATE
         SET col_autoruleparamtptaskdeptp  = v_taskDepId,  col_paramcode = ar_param, col_paramvalue =  ar_value
       WHEN NOT MATCHED THEN
       INSERT
       (col_code, col_autoruleparamtptaskdeptp , col_paramcode , col_paramvalue )
       VALUES
       (code, v_taskDepId, ar_param, ar_value);


       v_ar_param := NULL;
       v_ar_value := NULL;
     END IF;

     END LOOP;

    END;

  END LOOP;
 p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_TASKDEPENDENCYTMPL with '||v_count||' rows', IsError => 0);  
 p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged depended TBL_AUTORULEPARAMTMPL with '||v_cnt||' rows', IsError => 0);   
  END;
  

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 

  /***************************************************************************************************/

  -- TBL_SLAEVENT
  /***************************************************************************************************/

 BEGIN
     v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/SlaEvent');
MERGE INTO TBL_SLAEVENT
USING(
SELECT Code, Intervalds,  Intervalym, Isrequired, MaxAttempts, SlaEventOrder, 
       (SELECT col_id FROM tbl_dict_slaeventtype WHERE col_code = SlaEventType) SlaEventType,
       (SELECT col_id FROM tbl_tasktemplate WHERE col_code = TaskTemplate) TaskTemplate,
       (SELECT col_id FROM TBL_DICT_DATEEVENTTYPE WHERE col_code = DateEventType) DateEventType,
       (SELECT col_id FROM TBL_DICT_SLAEVENTLEVEL WHERE col_code = SlaEventLevel) SlaEventLevel,
       (SELECT col_id FROM tbl_dict_casesystype WHERE col_code = CaseType) CaseType
            FROM XMLTABLE('SlaEvent'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Intervalds NVARCHAR2(255) PATH './Intervalds',
                       Intervalym NVARCHAR2(255) PATH './Intervalym',
                       Isrequired NUMBER PATH './Isrequired',
                       MaxAttempts NUMBER PATH './MaxAttempts',
                       SlaEventOrder NUMBER PATH './SlaEventOrder', 
                       SlaEventType NVARCHAR2(255) PATH './SlaEventType', 
                       TaskTemplate NVARCHAR2(255) PATH './TaskTemplate', 
                       DateEventType NVARCHAR2(255)  PATH './DateEventType',
                       SlaEventLevel NVARCHAR2(255)  PATH './SlaEventLevel',
                       CaseType NVARCHAR2(255) PATH './CaseType'
                       )
)
    ON (col_code = Code)
    WHEN MATCHED THEN
      UPDATE  SET col_intervalds = Intervalds,  col_intervalym = Intervalym,
      col_isrequired = Isrequired, col_maxattempts = MaxAttempts, col_slaeventorder =  SlaEventOrder,
      col_slaeventdict_slaeventtype = SlaEventType, col_slaeventtasktemplate = TaskTemplate,
      col_slaevent_dateeventtype = DateEventType, col_slaevent_slaeventlevel = SlaEventLevel,
      col_slaeventslacase = CaseType
      WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
    WHEN NOT MATCHED THEN
      INSERT (col_code, col_intervalds, col_intervalym, col_isrequired, col_maxattempts,
      col_slaeventorder, col_slaeventdict_slaeventtype, col_slaeventtasktemplate, 
      col_slaevent_dateeventtype,  col_slaevent_slaeventlevel, col_slaeventslacase )
      VALUES (Code, Intervalds, Intervalym, Isrequired, MaxAttempts,
      SlaEventOrder, SlaEventType, TaskTemplate, 
      DateEventType, SlaEventLevel, CaseType);

   p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_SLAEVENT with '||SQL%ROWCOUNT||' rows', IsError => 0);  
        
 EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;    

/***************************************************************************************************/
-- TBL_SLAEVENTTMPL
/***************************************************************************************************/

 BEGIN
     v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/SlaEventTMPL');
MERGE INTO TBL_SLAEVENTTMPL
USING(
SELECT Code, Intervalds,  Intervalym, Isrequired, MaxAttempts, SlaEventOrder, 
       (SELECT col_id FROM tbl_dict_slaeventtype WHERE col_code = SlaEventType) SlaEventType,
       (SELECT col_id FROM tbl_tasktemplate WHERE col_code = TaskTemplate) TaskTemplate,
       (SELECT col_id FROM TBL_DICT_DATEEVENTTYPE WHERE col_code = DateEventType) DateEventType,
       (SELECT col_id FROM TBL_DICT_SLAEVENTLEVEL WHERE col_code = SlaEventLevel) SlaEventLevel,
       (SELECT col_id FROM tbl_dict_casesystype WHERE col_code = CaseType) CaseType
            FROM XMLTABLE('SlaEventTMPL'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Intervalds NVARCHAR2(255) PATH './Intervalds',
                       Intervalym NVARCHAR2(255) PATH './Intervalym',
                       Isrequired NUMBER PATH './Isrequired',
                       MaxAttempts NUMBER PATH './MaxAttempts',
                       SlaEventOrder NUMBER PATH './SlaEventOrder', 
                       SlaEventType NVARCHAR2(255) PATH './SlaEventType', 
                       TaskTemplate NVARCHAR2(255) PATH './TaskTemplate', 
                       DateEventType NVARCHAR2(255)  PATH './DateEventType',
                       SlaEventLevel NVARCHAR2(255)  PATH './SlaEventLevel',
                       CaseType NVARCHAR2(255) PATH './CaseType'
                       )
)
    ON (col_code = Code)
    WHEN MATCHED THEN
      UPDATE  SET col_intervalds = Intervalds,  col_intervalym = Intervalym,
      col_isrequired = Isrequired, col_maxattempts = MaxAttempts, col_slaeventorder =  SlaEventOrder,
      col_slaeventtp_slaeventtype  = SlaEventType, col_slaeventtptasktemplate  = TaskTemplate,
      col_slaeventtp_dateeventtype  = DateEventType, col_slaeventtp_slaeventlevel  = SlaEventLevel,
      COL_SLAEVENTTMPLDICT_CST = CaseType
      WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
    WHEN NOT MATCHED THEN
      INSERT (col_code, col_intervalds, col_intervalym, col_isrequired, col_maxattempts,
      col_slaeventorder, col_slaeventtp_slaeventtype , col_slaeventtptasktemplate , 
      col_slaeventtp_dateeventtype, col_slaeventtp_slaeventlevel, COL_SLAEVENTTMPLDICT_CST)
      VALUES (Code, Intervalds, Intervalym, Isrequired, MaxAttempts,
      SlaEventOrder, SlaEventType, TaskTemplate, 
      DateEventType, SlaEventLevel, CaseType);

   p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_SLAEVENTTMPL with '||SQL%ROWCOUNT||' rows', IsError => 0);  
          
 EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;      

/***************************************************************************************************/
-- TBL_SLAACTION
/***************************************************************************************************/

 BEGIN
   v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/SlaAction');
MERGE INTO tbl_slaaction
USING(
SELECT Code, ActionOrder,  Name, Processorcode,  
(SELECT col_id FROM TBL_SLAEVENT WHERE col_code = SlaEventCode) SlaEventCode
            FROM XMLTABLE('SlaAction'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       ActionOrder NVARCHAR2(255) PATH './ActionOrder',
                       Name NVARCHAR2(255) PATH './Name',
                       Processorcode NVARCHAR2(255) PATH './Processorcode',                       
                       SlaEventCode NUMBER PATH './SlaEventCode',
                       SlaEventLevel NUMBER PATH './SlaEventLevel'
                       )
)         
ON (col_code = Code)
WHEN MATCHED THEN
 UPDATE  SET col_actionorder =  ActionOrder,  col_name = Name,
             col_processorcode = Processorcode,  col_slaactionslaevent = SlaEventCode
WHEN NOT MATCHED THEN
INSERT (col_code,  col_actionorder,  col_name,  col_processorcode,  col_slaactionslaevent)
VALUES (Code, ActionOrder, Name, Processorcode, SlaEventCode);

   p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_SLAACTION with '||SQL%ROWCOUNT||' rows', IsError => 0);  
   
 EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;      

/***************************************************************************************************/
-- TBL_SLAACTIONTMPL
/***************************************************************************************************/

 BEGIN
   v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/SlaActionTMPL');
MERGE INTO tbl_slaactionTMPL
USING(
SELECT Code, ActionOrder,  Name, Processorcode,  
(SELECT col_id FROM TBL_SLAEVENTTMPL WHERE col_code = SlaEventCode) SlaEventCode
            FROM XMLTABLE('SlaActionTMPL'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       ActionOrder NVARCHAR2(255) PATH './ActionOrder',
                       Name NVARCHAR2(255) PATH './Name',
                       Processorcode NVARCHAR2(255) PATH './Processorcode',                       
                       SlaEventCode NUMBER PATH './SlaEventCode',
                       SlaEventLevel NUMBER PATH './SlaEventLevel'
                       )
)         
ON (col_code = Code)
WHEN MATCHED THEN
 UPDATE  SET col_actionorder =  ActionOrder,  col_name = Name,
             col_processorcode = Processorcode,  col_slaactiontpslaeventtp  = SlaEventCode
WHEN NOT MATCHED THEN
INSERT (col_code,  col_actionorder,  col_name,  col_processorcode,  col_slaactiontpslaeventtp )
VALUES (Code, ActionOrder, Name, Processorcode, SlaEventCode);

   p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_SLAACTIONTMPL with '||SQL%ROWCOUNT||' rows', IsError => 0);  
   
 EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/******************************************************************************/

--tbl_commonevent
/******************************************************************************/
begin
  v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/CommonEvent');
   MERGE INTO tbl_commonevent
   USING (
   SELECT Code, EventOrder, ProcessorCode, Name, 
         (SELECT col_id FROM tbl_dict_commoneventtype WHERE col_code = CommonEventType) CommonEventType,
         (SELECT col_id FROM tbl_dict_casesystype WHERE col_code = CaseType) CaseType,
         (SELECT col_id FROM tbl_tasktemplate WHERE col_code = TaskTemplate )TaskTemplate,
         (SELECT col_id FROM tbl_dict_tasksystype WHERE col_code = TaskType) TaskType,
         (SELECT col_id FROM tbl_dict_taskeventmoment WHERE col_code = TaskEventMoment) TaskEventMoment,
         (SELECT col_id FROM tbl_dict_taskeventsynctype WHERE col_code = TaskEventSyncType) TaskEventSyncType,
         (SELECT col_id FROM tbl_dict_taskeventtype WHERE col_code = TaskEventType) TaskEventType,
         (SELECT col_id FROM tbl_procedure WHERE col_code = Procedure_) Procedure_,
         IsProcessed, LinkCode, Ucode                          
            FROM XMLTABLE('CommonEvent'
              PASSING v_xmlresult
              COLUMNS
                       Code     NVARCHAR2(255) PATH './Code',
                       EventOrder NUMBER   PATH './EventOrder',
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',
                       Name  NVARCHAR2(255) PATH './Name',
                       CommonEventType  NVARCHAR2(255) PATH './CommonEventType',
                       CaseType   NVARCHAR2(255) PATH './CaseType',
                       TaskTemplate   NVARCHAR2(255) PATH './TaskTemplate',
                       TaskType  NVARCHAR2(255) PATH './TaskType',
                       TaskEventMoment    NVARCHAR2(255) PATH './TaskEventMoment',
                       TaskEventSyncType NVARCHAR2(255) PATH './TaskEventSyncType',
                       TaskEventType NVARCHAR2(255) PATH './TaskEventType',
                       Procedure_  NVARCHAR2(255) PATH './Procedure',
                       IsProcessed  NUMBER PATH './IsProcessed',                       
                       LinkCode   NVARCHAR2(255) PATH './LinkCode',
                       Ucode  NVARCHAR2(255) PATH './Ucode'                     
                       )
)
   ON (col_ucode = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_code  = Code, col_eventorder  = EventOrder, col_processorcode  = ProcessorCode, 
     col_name  = Name, col_comeventcomeventtype  = CommonEventType, col_commoneventcasetype  = CaseType, 
     col_commoneventtasktmpl  = TaskTemplate, col_commoneventtasktype  = TaskType, 
     col_commoneventeventmoment  = TaskEventMoment, col_commoneventeventsynctype  = TaskEventSyncType, 
     col_commoneventtaskeventtype  = TaskEventType, col_commoneventprocedure = Procedure_,
     col_isprocessed  =  IsProcessed, col_linkcode  = LinkCode   
     WHEN NOT MATCHED THEN
       INSERT (col_code,   col_eventorder , col_processorcode  , col_name , 
               col_comeventcomeventtype , col_commoneventcasetype , col_commoneventtasktmpl  , 
               col_commoneventtasktype  , col_commoneventeventmoment ,  
               col_commoneventeventsynctype  , col_commoneventtaskeventtype , col_commoneventprocedure  , 
               col_isprocessed  , col_linkcode , col_ucode   )
       VALUES (Code, EventOrder, ProcessorCode, NAME,
               CommonEventType, CaseType, TaskTemplate, 
               TaskType, TaskEventMoment, 
               TaskEventSyncType, TaskEventType, Procedure_,
               IsProcessed, LinkCode, Ucode);

  p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_COMMONEVENT with '||SQL%ROWCOUNT||' rows', IsError => 0); 
  

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/******************************************************************************/

--tbl_commoneventtmpl
/******************************************************************************/
begin
  v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/CommonEventTmpl');
   MERGE INTO tbl_commoneventtmpl
   USING (
   SELECT Code, EventOrder, ProcessorCode, Name, 
         (SELECT col_id FROM tbl_dict_commoneventtype WHERE col_code = CommonEventType) CommonEventType,
         (SELECT col_id FROM tbl_dict_casesystype WHERE col_code = CaseType) CaseType,
         (SELECT col_id FROM tbl_tasktemplate WHERE col_code = TaskTemplate )TaskTemplate,
         (SELECT col_id FROM tbl_dict_tasksystype WHERE col_code = TaskType) TaskType,
         (SELECT col_id FROM tbl_dict_taskeventmoment WHERE col_code = TaskEventMoment) TaskEventMoment,
         (SELECT col_id FROM tbl_dict_taskeventsynctype WHERE col_code = TaskEventSyncType) TaskEventSyncType,
         (SELECT col_id FROM tbl_dict_taskeventtype WHERE col_code = TaskEventType) TaskEventType,
         (SELECT col_id FROM tbl_procedure WHERE col_code = Procedure_) Procedure_,
          Ucode                          
            FROM XMLTABLE('CommonEventTmpl'
              PASSING v_xmlresult
              COLUMNS
                       Code     NVARCHAR2(255) PATH './Code',
                       EventOrder NUMBER   PATH './EventOrder',
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',
                       Name  NVARCHAR2(255) PATH './Name',
                       CommonEventType  NVARCHAR2(255) PATH './CommonEventType',
                       CaseType   NVARCHAR2(255) PATH './CaseType',
                       TaskTemplate   NVARCHAR2(255) PATH './TaskTemplate',
                       TaskType  NVARCHAR2(255) PATH './TaskType',
                       TaskEventMoment    NVARCHAR2(255) PATH './TaskEventMoment',
                       TaskEventSyncType NVARCHAR2(255) PATH './TaskEventSyncType',
                       TaskEventType NVARCHAR2(255) PATH './TaskEventType',
                       Procedure_  NVARCHAR2(255) PATH './Procedure',
                       Ucode  NVARCHAR2(255) PATH './Ucode'                     
                       )
)
   ON (col_ucode = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_code  = Code, col_eventorder  = EventOrder, col_processorcode  = ProcessorCode, 
     col_name  = Name, col_comeventtmplcomeventtype   = CommonEventType, col_commoneventtmplcasetype   = CaseType, 
     col_commoneventtmpltasktmpl   = TaskTemplate, col_commoneventtmpltasktype   = TaskType, 
     col_comevttmplevtmmnt   = TaskEventMoment, col_comevttmplevtsynct   = TaskEventSyncType, 
     col_comevttmpltaskevtt   = TaskEventType, col_commoneventtmplprocedure  = Procedure_   
     WHEN NOT MATCHED THEN
       INSERT (col_code,   col_eventorder , col_processorcode  , col_name , 
               col_comeventtmplcomeventtype  , col_commoneventtmplcasetype  , col_commoneventtmpltasktmpl   , 
               col_commoneventtmpltasktype   , col_comevttmplevtmmnt  ,  
               col_comevttmplevtsynct   , col_comevttmpltaskevtt  , col_commoneventtmplprocedure   , 
                col_ucode   )
       VALUES (Code, EventOrder, ProcessorCode, NAME,
               CommonEventType, CaseType, TaskTemplate, 
               TaskType, TaskEventMoment, 
               TaskEventSyncType, TaskEventType, Procedure_,
               Ucode);

  p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged tbl_commoneventtmpl with '||SQL%ROWCOUNT||' rows', IsError => 0); 
  

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;


 /***************************************************************************************************/

 -- tbl_dict_tasktransition
 /***************************************************************************************************/

 /*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/ 
  BEGIN
  v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/TaskTransition');
   v_xmlresult2 := v_input.extract('/CaseType/Dictionary/TaskState');
   v_xmlresult3 := v_input.extract('/CaseType/TaskState');
  MERGE INTO  tbl_dict_tasktransition
 
 USING (
 SELECT ttr.*,
    CASE WHEN ts.Config IS NULL THEN
                (SELECT col_id FROM tbl_dict_taskstate WHERE col_code = ts.Code AND col_stateconfigtaskstate IS NULL)
            WHEN ts.Config IS NOT NULL THEN
                (SELECT col_id FROM tbl_dict_taskstate WHERE col_ucode = ttr.Source)
       END CodeSourceId,
       CASE WHEN ts2.Config IS NULL THEN
                (SELECT col_id FROM tbl_dict_taskstate WHERE col_code = ts2.Code AND col_stateconfigtaskstate IS NULL)
            WHEN ts2.Config IS NOT NULL THEN
                (SELECT col_id FROM tbl_dict_taskstate WHERE col_ucode = ttr.Target)
       END CodeTargetId
 FROM 
( SELECT Code, Ucode, Description, ManualOnly, Name, Transition, 
        Source ,
        Target
          FROM XMLTABLE('TaskTransition'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Ucode nvarchar2(255) PATH './Ucode',
                       Name nvarchar2(255) PATH './Name',
                       ManualOnly NUMBER PATH './ManualOnly',
                       Description NCLOB PATH './Description',
                       Transition NVARCHAR2(255) PATH './Transition',
                       Source NVARCHAR2(255) PATH './Source',
                       Target NVARCHAR2(255) PATH './Target')
   
   
  ) ttr
  JOIN 
    (    SELECT Code, Ucode , Config
                FROM XMLTABLE('TaskState'
                    PASSING v_xmlresult2
                    COLUMNS
                             Code         NVARCHAR2(255) PATH './Code',
                             Ucode        NVARCHAR2(255) PATH './Ucode',
                             Config       NVARCHAR2(255) PATH './StateConfig'
                             )
         UNION                     
         SELECT Code, Ucode , Config
                FROM XMLTABLE('TaskState'
                    PASSING v_xmlresult3
                    COLUMNS
                             Code         NVARCHAR2(255) PATH './Code',
                             Ucode        NVARCHAR2(255) PATH './Ucode',
                             Config       NVARCHAR2(255) PATH './StateConfig'
                             )
    ) ts ON ttr.Source = ts.Ucode
  JOIN 
  (  SELECT Code, Ucode , Config
                FROM XMLTABLE('TaskState'
                    PASSING v_xmlresult2
                    COLUMNS
                             Code         NVARCHAR2(255) PATH './Code',
                             Ucode        NVARCHAR2(255) PATH './Ucode',
                             Config       NVARCHAR2(255) PATH './StateConfig'
                             )
         UNION                     
         SELECT Code, Ucode , Config
                FROM XMLTABLE('TaskState'
                    PASSING v_xmlresult3
                    COLUMNS
                             Code         NVARCHAR2(255) PATH './Code',
                             Ucode        NVARCHAR2(255) PATH './Ucode',
                             Config       NVARCHAR2(255) PATH './StateConfig'
                             )
  )  ts2 ON ttr.Target = ts2.Ucode
  )
   ON (col_code = Code AND col_sourcetasktranstaskstate = CodeSourceId AND col_targettasktranstaskstate = CodeTargetId )
   WHEN MATCHED THEN
     UPDATE  SET  col_description = Description,  col_manualonly = ManualOnly,
     col_name = Name, col_transition = Transition
  WHEN NOT MATCHED THEN
    INSERT (col_code, col_description, col_manualonly, col_name, col_transition, col_sourcetasktranstaskstate, col_targettasktranstaskstate, col_ucode )
    VALUES (Code, Description, ManualOnly, Name, Transition, CodeSourceId, CodeTargetId, Ucode);

   p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_DICT_TASKTRANSITION with '||SQL%ROWCOUNT||' rows', IsError => 0);  
   
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
  /***************************************************************************************************/

 -- TBL_FOM_UIELEMENT
 /***************************************************************************************************/

BEGIN
  v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/FomUiElement'); 

  MERGE INTO TBL_FOM_UIELEMENT
   USING (
      SELECT Code,  Description, IsDelete, IsHidden, NAME ,
      (SELECT col_id FROM TBL_FOM_UIELEMENT WHERE col_code =  ParentCode) ParentCode , 
      ProcessorCode, Title, UiElementOrder,
      (SELECT col_id FROM tbl_dict_casesystype WHERE col_code = CaseType) CaseType,
      (SELECT col_id  FROM tbl_dict_casetransition WHERE col_ucode = CaseTtansition) CaseTtansition, /*default transition*/
      (SELECT col_id FROM tbl_dict_tasksystype WHERE col_code = TaskType) TaskType,
      (SELECT col_id FROM tbl_dict_tasktransition  WHERE col_ucode = TaskTtansition) TaskTtansition, /*default transition*/
      (SELECT col_id FROM tbl_fom_uielementtype  WHERE col_code = UserElementType) UserElementType,
      (SELECT col_id FROM tbl_dict_casestate  WHERE col_ucode = CaseState) CaseState,  /*default*/
      (SELECT col_id FROM tbl_dict_taskstate  WHERE col_ucode = TaskState) TaskState, /*default*/
      Config, IsEditable, RegionId, PositionIndex, JsonData, RuleVisibility, ElementCode, 
      (SELECT col_id FROM tbl_fom_page fp WHERE col_code = UIElementPage)  UIElementPage,
      (SELECT col_id FROM tbl_fom_widget WHERE col_code = FomWidget) FomWidget,
      (SELECT col_id FROM tbl_fom_dashboard WHERE col_code = FomDashboard) FomDashboard,
      (SELECT col_id FROM tbl_dom_object WHERE col_ucode = DomObject) DomObject,
      (SELECT col_id FROM tbl_mdm_form WHERE col_code = MdmForm) MdmForm,
      (SELECT col_id FROM tbl_som_config WHERE col_code = SomConfig) SomConfig,      
      UserEditable      
      FROM XMLTABLE('FomUiElement'
      PASSING v_xmlresult
          COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Description NCLOB PATH './Description',
                       IsDelete NUMBER PATH './IsDelete',
                       IsHidden NUMBER PATH './IsHidden',
                       Name NVARCHAR2(255) PATH './Name',                       
                       ParentCode NVARCHAR2(255) PATH './ParentCode',
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',
                       Title NVARCHAR2(255) PATH './Title',
                       UiElementOrder NUMBER PATH './UiElementOrder',
                       CaseType NVARCHAR2(255) PATH './CaseType',
                       CaseTtansition NVARCHAR2(255) PATH './CaseTtansition',
                       TaskType NVARCHAR2(255) PATH './TaskType',
                       TaskTtansition NVARCHAR2(255) PATH './TaskTtansition',
                       UserElementType NVARCHAR2(255) PATH './UserElementType',
                       TaskState NVARCHAR2(255) PATH './TaskState',
                       CaseState NVARCHAR2(255) PATH './CaseState',
                       Config NCLOB PATH './Config',
                       IsEditable NUMBER PATH './IsEditable',
                       RegionId NUMBER PATH './RegionId',
                       PositionIndex NUMBER PATH './PositionIndex',
                       JsonData NCLOB PATH './JsonData',
                       RuleVisibility NVARCHAR2(255) PATH './RuleVisibility',
                       ElementCode NVARCHAR2(255) PATH './ElementCode',
                       UIElementPage NVARCHAR2(255) PATH './UIElementPage',
                       FomWidget NVARCHAR2(255) PATH './FomWidget',
                       FomDashboard NVARCHAR2(255) PATH './FomDashboard',
                       UserEditable NUMBER PATH './UserEditable',
                       DomObject  NVARCHAR2(255) PATH './DomObject',
                       MdmForm  NVARCHAR2(255) PATH './MdmForm',
                       SomConfig  NVARCHAR2(255) PATH './SomConfig'
      ) 
)
   ON (col_code = Code)
   WHEN MATCHED THEN
      UPDATE  SET col_description = Description, col_isdeleted = IsDelete, col_ishidden = IsHidden,
      col_name = NAME, col_parentid = ParentCode, col_processorcode = ProcessorCode,
      col_title = Title, col_uielementorder = UiElementOrder, col_uielementcasestate = CaseState,
      col_uielementcasesystype = CaseType, col_uielementcasetransition = CaseTtansition, col_uielementtaskstate = TaskState ,
      col_uielementtasksystype = TaskType, col_uielementtasktransition = TaskTtansition, col_uielementuielementtype = UserElementType
      ,col_config =  to_clob(dbms_xmlgen.convert(Config,1)), col_iseditable = IsEditable,
      col_regionid = RegionId, col_positionindex = PositionIndex, col_jsondata = to_clob(dbms_xmlgen.convert(JsonData,1)) ,
      col_rulevisibility = RuleVisibility, col_elementcode = ElementCode, col_uielementpage =  UIElementPage,
      col_uielementdashboard = FomDashboard, col_uielementwidget = FomWidget, col_usereditable = UserEditable,
      col_uielementobject = DomObject,
      col_uielementform = MdmForm,
      col_fom_uielementsom_config = SomConfig
      WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
   WHEN NOT MATCHED THEN
      INSERT ( col_code ,
      col_description, col_isdeleted,
      col_ishidden , col_name ,
      col_parentid, col_processorcode,
      col_title, col_uielementorder, col_uielementcasestate,
      col_uielementcasesystype, col_uielementcasetransition,
      col_uielementtaskstate, col_uielementtasksystype,
      col_uielementtasktransition, col_uielementuielementtype ,
      col_config, col_iseditable, 
      col_regionid, col_positionindex,
      col_jsondata, col_rulevisibility, 
      col_elementcode, col_uielementpage,
      col_uielementdashboard , col_uielementwidget, 
      col_usereditable,
      col_uielementobject,
      col_uielementform,
      col_fom_uielementsom_config  
      )
      VALUES (Code ,
      Description, nvl(IsDelete,0),
      nvl(IsHidden,0), Name,
      ParentCode, ProcessorCode,
      Title, UiElementOrder, CaseState,
      CaseType, CaseTtansition,
      TaskState, TaskType,
      TaskTtansition, UserElementType,
      to_clob(dbms_xmlgen.convert(Config,1)),IsEditable,
      RegionId, PositionIndex,
      to_clob(dbms_xmlgen.convert(JsonData,1)), RuleVisibility,
      ElementCode, UIElementPage,
      FomDashboard, FomWidget,
      UserEditable,
      DomObject, 
      MdmForm,
      SomConfig      
      );
   p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_FOM_UIELEMENT with '||SQL%ROWCOUNT||' rows', IsError => 0);  

MERGE INTO TBL_FOM_UIELEMENT
   USING (
      SELECT CODE,
      (SELECT col_id FROM TBL_FOM_UIELEMENT WHERE col_code =  ParentCode) ParentCode 
      FROM XMLTABLE('FomUiElement'
      PASSING v_xmlresult
          COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       ParentCode NVARCHAR2(255) PATH './ParentCode'
      ) 
)
   ON (col_code = Code)
   WHEN MATCHED THEN
      UPDATE  SET col_parentid = ParentCode;   

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
   /***************************************************************************************************/

 -- TBL_AC_ACCESSSUBJECT
 /***************************************************************************************************/

 BEGIN
    v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/AccessSubject');
 MERGE INTO TBL_AC_ACCESSSUBJECT
 USING(
SELECT Code, Name, Type
            FROM XMLTABLE('AccessSubject'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Type NVARCHAR2(255) PATH './Type'
                       )
               )
ON (col_code = Code)
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_Type = Type
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_Type )
  VALUES (Code, Name, Type);
 
   p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_AC_ACCESSSUBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0);  
    
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
   /***************************************************************************************************/

 -- tbl_AC_ACCESSOBJECT
 /***************************************************************************************************/

 BEGIN
    v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/AccessObject');
   v_xmlresult2 := v_input.extract('/CaseType/Dictionary/CaseState');
   v_xmlresult3 := v_input.extract('/CaseType/Dictionary');

 MERGE INTO tbl_AC_ACCESSOBJECT
USING
(SELECT CASE WHEN ts.Config IS NULL THEN
         (SELECT col_id FROM tbl_dict_casestate WHERE col_code = ts.Code AND col_stateconfigcasestate   IS NULL)
       WHEN ts.Config IS NOT NULL THEN
         (SELECT col_id FROM tbl_dict_casestate WHERE col_ucode = tss.CaseState)
   END  casestateId ,
   tss.*
FROM
(
SELECT
 Code, Name,
 (SELECT col_id FROM tbl_ac_accessobjecttype WHERE col_code = AccessObjectTypeCode) AccessObjectTypeCode,
 CaseState, /*default*/
 (SELECT col_id FROM tbl_dict_casesystype WHERE col_code = CaseTypeCode) CaseTypeCode,
 (SELECT col_id FROM tbl_dict_tasksystype WHERE col_code = TaskTypeCode) TaskTypeCode,
 (SELECT col_id FROM tbl_fom_uielement WHERE col_code = UserElement) UserElement,
 (SELECT col_id FROM tbl_dict_casetransition WHERE col_code = CaseTransition) CaseTransition,
 (SELECT col_id FROM tbl_dict_accesstype WHERE col_code = AccessTypeCode) AccessTypeCode
FROM 
XMLTABLE ('AccessObject'
PASSING v_xmlresult 
  COLUMNS  
            Code NVARCHAR2(255) PATH './Code',
            Name NVARCHAR2(255) PATH './Name',
            AccessObjectTypeCode NVARCHAR2(255) PATH './AccessObjectTypeCode',
            CaseState NVARCHAR2(255) PATH './CaseStateCode',
            CaseTypeCode NVARCHAR2(255) PATH './CaseTypeCode',
            TaskTypeCode NVARCHAR2(255) PATH './TaskTypeCode', 
            UserElement NVARCHAR2(255) PATH './UserElement',
            CaseTransition NVARCHAR2(255) PATH './CaseTransition', 
            AccessTypeCode NVARCHAR2(255) PATH './AccessTypeCode'
)                       
) tss
LEFT JOIN
(    SELECT Code, Ucode , Config
          FROM XMLTABLE('CaseState'
              PASSING v_xmlresult2
              COLUMNS
                       Code         NVARCHAR2(255) PATH './Code',
                       Ucode        NVARCHAR2(255) PATH './Ucode',
                       Config       NVARCHAR2(255) PATH './Config'
                       )
    union
     SELECT Code, Ucode , Config
          FROM XMLTABLE('CaseState'
              PASSING v_xmlresult3
              COLUMNS
                       Code         NVARCHAR2(255) PATH './Code',
                       Ucode        NVARCHAR2(255) PATH './Ucode',
                       Config       NVARCHAR2(255) PATH './Config'
                       )
) ts
ON tss.CaseState = ts.Ucode                       

)
ON (col_code = Code)
WHEN MATCHED THEN UPDATE
  SET col_name = NAME,col_accessobjaccessobjtype = AccessObjectTypeCode ,col_accessobjcasetransition = CaseTransition,
  col_accessobjectaccesstype = AccessTypeCode,col_accessobjectcasestate = casestateId ,col_accessobjectcasesystype = CaseTypeCode ,
  col_accessobjecttasksystype = TaskTypeCode ,col_accessobjectuielement = UserElement
WHEN NOT MATCHED THEN
INSERT
 (col_code, col_name, col_accessobjaccessobjtype, col_accessobjcasetransition,
 col_accessobjectaccesstype, col_accessobjectcasestate, col_accessobjectcasesystype,
 col_accessobjecttasksystype, col_accessobjectuielement)
VALUES
 (code, NAME,AccessObjectTypeCode, CaseTransition, AccessTypeCode, casestateId, CaseTypeCode, TaskTypeCode, UserElement);
 
   p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged tbl_AC_ACCESSOBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0);  
      
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/***************************************************************************************************/

 -- tbl_ASSOCPAGE
/***************************************************************************************************/

BEGIN
   v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/Assocpage');
   SELECT y.column_value.getstringval()
    INTO v_count
    FROM xmltable('count(Assocpage)' passing v_xmlresult) y ;


 FOR i IN 1..v_count LOOP

MERGE INTO tbl_ASSOCPAGE
USING
(SELECT f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/Code/text()') Code,
/*@@@@@*/

 f_UTIL_extract_clob_from_xml(Input => v_input_clob, Path => '/CaseType/Assocpage['||i||']/Description/text()') Description,
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/IsDeleted/text()') IsDeleted,
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/Owner/text()') Owner,
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/Order/text()') Order_,
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/Pagecode/text()') Pagecode,
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/Pageparam/text()') Pageparam,
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/Required/text()') Required,
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/Title/text()') Title,
  (SELECT col_id FROM tbl_DICT_ASSOCPAGETYPE WHERE col_code =
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/AssocpageType/text()')) AssocpageType,
  (SELECT col_id FROM tbl_fom_codedpage WHERE col_code =
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/CodedPage/text()')) CodedPage,
  (SELECT col_id FROM tbl_dict_casesystype WHERE col_code =
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/CaseType/text()')) CaseType,
  (SELECT col_id FROM tbl_dict_tasksystype WHERE col_code =
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/TaskType/text()')) TaskType,
  (SELECT col_id FROM tbl_fom_form WHERE col_code =
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/Form/text()')) Form,
  (SELECT col_id FROM tbl_tasktemplate WHERE col_code =
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/TaskTemplate/text()')) TaskTemplate,
  (SELECT col_id FROM tbl_dict_partytype WHERE col_code =
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/PartyType/text()')) PartyType,
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/AllowAspx/text()') AllowAspx,
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/AllowCodedPage/text()') AllowCodedPage,
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/AllowForm/text()') AllowForm,
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/AllowFormInTab/text()') AllowFormInTab,
 (SELECT col_id FROM tbl_fom_page WHERE col_code =
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/FomPage/text()')) FomPage,
 (SELECT col_id FROM tbl_dict_workactivitytype WHERE col_code =
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/WorkActivityType/text()')) WorkActivityType,
 (SELECT col_id FROM tbl_dict_documenttype WHERE col_code =
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/DocTypeCode/text()')) DocTypeCode,
 (SELECT col_id FROM tbl_mdm_form WHERE col_code =
 f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Assocpage['||i||']/MDMFormCode/text()')) MDMFormCode
 
FROM dual
)
ON (col_code = Code)
WHEN MATCHED THEN UPDATE
  SET  col_description = Description, col_isdeleted = IsDeleted,   col_owner = Owner,
  col_order = Order_, col_pagecode = Pagecode, col_pageparams = Pageparam,
  col_required = Required, col_title = Title, col_assocpageassocpagetype = AssocpageType,
  col_assocpagecodedpage = CodedPage,col_assocpagedict_casesystype = CaseType,col_assocpagedict_tasksystype = TaskType,
  col_assocpageform= Form, col_assocpagetasktemplate = TaskTemplate,col_partytypeassocpage = PartyType,
  col_assocpagepage = FomPage, col_dict_watypeassocpage = WorkActivityType,
  col_assocpagedict_doctype = DocTypeCode,  col_assocpagemdm_form = MDMFormCode
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT
 ( col_code, col_description, col_isdeleted, col_owner,
   col_order, col_pagecode,  col_pageparams,  col_required,  col_title,  col_assocpageassocpagetype,
   col_assocpagecodedpage , col_assocpagedict_casesystype,  col_assocpagedict_tasksystype ,
   col_assocpageform , col_assocpagetasktemplate , col_partytypeassocpage, col_assocpagepage , col_dict_watypeassocpage,
   col_assocpagedict_doctype , col_assocpagemdm_form
 )
VALUES
 (Code,  Description, IsDeleted, Owner,
 Order_, Pagecode, Pageparam, Required, Title, AssocpageType,
 CodedPage, CaseType, TaskType,
 Form, TaskTemplate, PartyType, FomPage, WorkActivityType,
 DocTypeCode, MDMFormCode);

END LOOP;
 
   p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged tbl_ASSOCPAGE with '||v_count||' rows', IsError => 0);  
 
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/***************************************************************************************************/

 -- TBL_DICT_TSKST_DTEVTP
/***************************************************************************************************/

 BEGIN
  v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/TaskStateDateEventType');
   SELECT y.column_value.getstringval()
    INTO v_count
    FROM xmltable('count(TaskStateDateEventType)' passing v_xmlresult) y ;


DECLARE
DataEvent NUMBER;
TaskState NUMBER;
v_cntt  PLS_INTEGER;

BEGIN
 FOR i IN 1..v_count LOOP


SELECT COUNT(*)
INTO
v_cnt
FROM tbl_dict_taskstate cst
WHERE cst.col_ucode = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskStateDateEventType['||i||']/TaskState/text()');


IF v_cnt = 0 THEN
  v_cnt := NULL;
  CONTINUE;
END IF;


SELECT col_id
       INTO
       TaskState
FROM
tbl_dict_taskstate cst
WHERE cst.col_ucode = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskStateDateEventType['||i||']/TaskState/text()')
;


SELECT col_id
       INTO
       DataEvent
FROM
tbl_dict_dateeventtype det
WHERE det.col_code = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskStateDateEventType['||i||']/DateEventType/text()');




SELECT COUNT(*)
INTO
v_cntt
FROM TBL_DICT_TSKST_DTEVTP detp
WHERE detp.col_tskst_dtevtptaskstate = TaskState
AND detp.col_tskst_dtevtpdateeventtype = DataEvent
;



    IF v_cntt = 0 THEN
      INSERT INTO TBL_DICT_TSKST_DTEVTP
      (col_tskst_dtevtptaskstate , col_tskst_dtevtpdateeventtype   )
      VALUES
      (TaskState, DataEvent);

    END IF;
    


END LOOP;
END;

   p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_DICT_TSKST_DTEVTP with '||v_count||' rows', IsError => 0);  
 

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/******************************************************************************/
--tbl_autoruleparamtmpl
/******************************************************************************/
begin
  v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/AutoRuleParamTmpl');
   MERGE INTO tbl_autoruleparamtmpl
   USING (
   SELECT Code, IsSystem, ParamValue, ParamCode, 
         (SELECT col_id FROM tbl_slaactiontmpl WHERE col_code = SLAAction) SLAAction,
         (SELECT col_id FROM tbl_casedependencytmpl WHERE col_code = CaseDep) CaseDep,
         (SELECT col_id FROM tbl_dict_casesystype WHERE col_code = CaseType )CaseType,
         (SELECT col_id FROM tbl_paramconfig WHERE col_code = ParamConf) ParamConf,
         (SELECT col_id FROM tbl_taskdependencytmpl WHERE col_code = TaskDep) TaskDep,
         (SELECT col_id FROM tbl_map_casestateinittmpl WHERE col_code = CaseStateIni) CaseStateIni,
         (SELECT col_id FROM tbl_map_taskstateinittmpl WHERE col_code = TaskStateIni) TaskStateIni,
         (SELECT col_id FROM tbl_taskeventtmpl WHERE col_code = TaskEvent) TaskEvent,
         (SELECT col_id FROM tbl_caseeventtmpl WHERE col_code = CaseEvent) CaseEvent,
         (SELECT col_id FROM tbl_dict_tasksystype WHERE col_code = TaskType) TaskType,
         (SELECT col_id FROM tbl_tasktemplate WHERE col_code = TaskTempl) TaskTempl,
         (SELECT col_id FROM tbl_dict_stateevent WHERE col_ucode = StateEventUcode) StateEventUcode,
 	       (SELECT col_id FROM tbl_DICT_StateSlaAction WHERE col_ucode = StateSlaAction) StateSlaAction	                          
            FROM XMLTABLE('AutoRuleParamTmpl'
              PASSING v_xmlresult
              COLUMNS
                       Code     NVARCHAR2(255) PATH './Code',
                       IsSystem NUMBER(10,2)   PATH './IsSystem',
                       ParamValue NVARCHAR2(255) PATH './ParamValue',
                       ParamCode  NVARCHAR2(255) PATH './ParamCode',
                       SLAAction  NVARCHAR2(255) PATH './SLAAction',
                       CaseDep    NVARCHAR2(255) PATH './CaseDep',
                       CaseType   NVARCHAR2(255) PATH './CaseType',
                       ParamConf  NVARCHAR2(255) PATH './ParamConf',
                       TaskDep    NVARCHAR2(255) PATH './TaskDep',
                       CaseStateIni NVARCHAR2(255) PATH './CaseStateIni',
                       TaskStateIni NVARCHAR2(255) PATH './TaskStateIni',
                       TaskEvent  NVARCHAR2(255) PATH './TaskEvent',
                       CaseEvent  NVARCHAR2(255) PATH './CaseEvent',                       
                       TaskType   NVARCHAR2(255) PATH './TaskType',
                       TaskTempl  NVARCHAR2(255) PATH './TaskTempl',
                       StateEventUcode   NVARCHAR2(255) PATH './StateEventUcode',
                       StateSlaAction  NVARCHAR2(255) PATH './StateSlaAction'											 
                       )
)
   ON (col_code = Code)
   WHEN MATCHED THEN
     UPDATE  SET  col_issystem = IsSystem, col_paramvalue = ParamValue, col_paramcode = ParamCode, 
     col_autorulepartpslaactiontp = SLAAction, col_autoruleparamtpcasedeptp = CaseDep, col_autoruleparamtpcasetype = CaseType, 
     col_autoruleparamtpparamconf = ParamConf, col_autoruleparamtptaskdeptp = TaskDep, 
     col_caseeventtpautorulepartp = CaseEvent, col_rulepartp_casestateinittp = CaseStateIni, col_rulepartp_taskstateinittp = TaskStateIni, 
     col_taskeventtpautoruleparmtp =  TaskEvent, col_tasksystypeautorulepartp = TaskType, col_tasktemplateautorulepartp  =  TaskTempl    ,
		 col_autorulepartmplstateevent = StateEventUcode,  col_dict_stateslaactionarp = StateSlaAction
         WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
     WHEN NOT MATCHED THEN
       INSERT (col_code,   col_issystem , col_paramvalue , col_paramcode, 
               col_autorulepartpslaactiontp, col_autoruleparamtpcasedeptp, col_autoruleparamtpcasetype , 
               col_autoruleparamtpparamconf , col_autoruleparamtptaskdeptp,  
               col_caseeventtpautorulepartp , col_rulepartp_casestateinittp, col_rulepartp_taskstateinittp , 
               col_taskeventtpautoruleparmtp , col_tasksystypeautorulepartp, col_tasktemplateautorulepartp,
               col_autorulepartmplstateevent,  col_dict_stateslaactionarp  )
       VALUES (Code, IsSystem, ParamValue, ParamCode,
               SLAAction, CaseDep, CaseType, 
               ParamConf, TaskDep, 
               CaseEvent, CaseStateIni, TaskStateIni,
               TaskEvent, TaskType, TaskTempl,
               StateEventUcode, StateSlaAction);  
 
   p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_AUTORULEPARAMTMPL with '||SQL%ROWCOUNT||' rows', IsError => 0);  
 
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/******************************************************************************/

--tbl_autoruleparameter
/******************************************************************************/
BEGIN
  v_xmlresult := v_input.extract('/CaseType/'||v_procType||'/CaseProcedure/ProcedureAddition['||idx||']/AutoRuleParam');
   MERGE INTO tbl_autoruleparameter
   USING (
   SELECT Code, IsSystem, ParamValue, ParamCode, 
         (SELECT col_id FROM tbl_slaaction WHERE col_code = SLAAction) SLAAction,
         (SELECT col_id FROM tbl_casedependency WHERE col_code = CaseDep) CaseDep,
         (SELECT col_id FROM tbl_dict_casesystype WHERE col_code = CaseType )CaseType,
         (SELECT col_id FROM tbl_paramconfig WHERE col_code = ParamConf) ParamConf,
         (SELECT col_id FROM tbl_taskdependency WHERE col_code = TaskDep) TaskDep,
         (SELECT col_id FROM tbl_map_casestateinitiation WHERE col_code = CaseStateIni) CaseStateIni,
         (SELECT col_id FROM tbl_map_taskstateinitiation WHERE col_code = TaskStateIni) TaskStateIni,
         (SELECT col_id FROM tbl_taskevent WHERE col_code = TaskEvent) TaskEvent,
         (SELECT col_id FROM tbl_caseevent WHERE col_code = CaseEvent) CaseEvent,
         (SELECT col_id FROM tbl_dict_tasksystype WHERE col_code = TaskType) TaskType,
         (SELECT col_id FROM tbl_tasktemplate WHERE col_code = TaskTempl) TaskTempl                           
            FROM XMLTABLE('AutoRuleParam'
              PASSING v_xmlresult
              COLUMNS
                       Code     NVARCHAR2(255) PATH './Code',
                       IsSystem NUMBER(10,2)   PATH './IsSystem',
                       ParamValue NVARCHAR2(255) PATH './ParamValue',
                       ParamCode  NVARCHAR2(255) PATH './ParamCode',
                       SLAAction  NVARCHAR2(255) PATH './SLAAction',
                       CaseDep    NVARCHAR2(255) PATH './CaseDep',
                       CaseType   NVARCHAR2(255) PATH './CaseType',
                       ParamConf  NVARCHAR2(255) PATH './ParamConf',
                       TaskDep    NVARCHAR2(255) PATH './TaskDep',
                       CaseStateIni NVARCHAR2(255) PATH './CaseStateIni',
                       TaskStateIni NVARCHAR2(255) PATH './TaskStateIni',
                       TaskEvent  NVARCHAR2(255) PATH './TaskEvent',
                       CaseEvent  NVARCHAR2(255) PATH './CaseEvent',                       
                       TaskType   NVARCHAR2(255) PATH './TaskType',
                       TaskTempl  NVARCHAR2(255) PATH './TaskTempl'
                       )
)
   ON (col_code = Code)
   WHEN MATCHED THEN
     UPDATE  SET  col_issystem = IsSystem, col_paramvalue = ParamValue, col_paramcode = ParamCode, 
     col_autoruleparamslaaction  = SLAAction, col_autoruleparamcasedep  = CaseDep, col_autoruleparamcasesystype  = CaseType, 
     col_autoruleparamparamconfig = ParamConf, col_autoruleparamtaskdep = TaskDep, 
     col_caseeventautoruleparam  = CaseEvent, col_ruleparam_casestateinit  = CaseStateIni, col_ruleparam_taskstateinit  = TaskStateIni, 
     col_taskeventautoruleparam  =  TaskEvent, col_tasksystypeautoruleparam   = TaskType, col_ttautoruleparameter   =  TaskTempl    
     WHEN NOT MATCHED THEN
       INSERT (col_code,   col_issystem , col_paramvalue , col_paramcode, 
               col_autoruleparamslaaction , col_autoruleparamcasedep , col_autoruleparamcasesystype   , 
               col_autoruleparamparamconfig   , col_autoruleparamtaskdep  ,  
               col_caseeventautoruleparam  , col_ruleparam_casestateinit , col_ruleparam_taskstateinit  , 
               col_taskeventautoruleparam  , col_tasksystypeautoruleparam , col_ttautoruleparameter   )
       VALUES (Code, IsSystem, ParamValue, ParamCode,
               SLAAction, CaseDep, CaseType, 
               ParamConf, TaskDep, 
               CaseEvent, CaseStateIni, TaskStateIni,
               TaskEvent, TaskType, TaskTempl);
 
   p_util_update_log ( XmlIdLog => XmlId, Message => 'ProcedureAddition       Merged TBL_AUTORULEPARAMETER with '||SQL%ROWCOUNT||' rows', IsError => 0);  
                

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);              
END;               

end loop;

 return 'OK';


EXCEPTION
  WHEN OTHERS THEN
 ROLLBACK;
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

 
 RETURN dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

END;
