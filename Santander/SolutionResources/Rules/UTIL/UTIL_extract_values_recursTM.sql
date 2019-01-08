declare
  v_input           xmltype;

  v_param           NVARCHAR2(255);
  v_result          NVARCHAR2(255);
  v_code            NVARCHAR2(255);
  v_name            NVARCHAR2(255);
  v_description     NVARCHAR2(255);
  v_executiontype   NVARCHAR2(255);
  v_tasktype        NVARCHAR2(255);
  v_icon            NVARCHAR2(255);
  v_iconcls         NVARCHAR2(255);
  v_xmlresult       xmltype;
  v_count           Integer;
  v_maxcount        Integer;
  v_path            VARCHAR2(255);
  v_path2           NVARCHAR2(255);
  v_level           Integer;
  v_parentid        Integer;
  v_nextparentid    Integer;
  v_taskorder       Integer;
  v_casetypeid      Integer;
  v_procedureid     Integer;
  v_tasktypeid      INTEGER;
  v_taskcode        NVARCHAR2(255);
  
  v_assignprocessorcode NVARCHAR2(255);
  v_MapTskstinitInitmtd NVARCHAR2(255);
  v_MapTskstinitTsks    NVARCHAR2(255);
  v_processorcode       NVARCHAR2(255);
  v_executionmethodtasktemplate NUMBER;
  v_MapTskstinitInitmtdID NUMBER;
  v_MapTskstinitTsksID    NUMBER;
  v_cnt                   PLS_INTEGER;
  v_col_id                NUMBER ;
  v_cnt_2                 PLS_INTEGER;
  v_cnt_cnt               PLS_INTEGER; 
      v_DeadLine     NUMBER(10,2);
      v_Goal         NUMBER(10,2);
      v_IconName     NVARCHAR2(255);
      v_ID2          NUMBER;
      v_Instatiation NVARCHAR2(255) ;
      v_MaxAllowed   NUMBER;
      v_Required     NUMBER;
      v_SystemType   NVARCHAR2(255);
      v_TaskId       NVARCHAR2(255);
      v_type         NVARCHAR2(255);
      v_Urgency      NVARCHAR2(255);
      v_Depth        NUMBER;
      v_Leaf         NUMBER;
      v_ProcCode     NVARCHAR2(255);
      v_PageCode     NVARCHAR2(255);
      v_taskState    NUMBER;
      v_isHidden     NUMBER;
begin
  v_casetypeid := CaseTypeId;
  v_procedureid := ProcedureId;
  if Input is not null then
    v_input :=/* XMLType(*/Input/*)*/;
 --   v_xml_current := Input.getStringVal();
  else
    v_input := null;
  end if;
  v_path := Path;
  v_level := TaskTemplateLevel;
  if v_level is null then
    v_level := 1;
  end if;
  v_parentid := ParentId;
  if v_parentid is null then
    v_parentid := 0;
       SELECT COUNT(*) INTO v_cnt FROM tbl_tasktemplate WHERE col_proceduretasktemplate = v_procedureid AND col_name = 'root';
    IF v_cnt = 0 THEN
        insert into tbl_tasktemplate(col_name,col_parentttid,col_taskorder,col_depth,col_leaf,col_proceduretasktemplate) 
        values('root',v_parentid,1,0,0, v_procedureid);
        select gen_tbl_tasktemplate.currval into v_parentid from dual;
    END IF;
  end if;
  --EXTRACTING PROCEDURE
  if v_path is null then
    v_path := '//TaskTemplatesTMPL';
  end if;
  v_count := 1;
  v_xmlresult := Input;


  --v_taskorder := 1;
  v_maxcount := 900;
  while (true)
  loop
    if v_xmlresult is not null then
      v_xmlresult := v_input.extract(v_path || '/TaskTemplateTMPL[' || to_char(v_count) || ']');

      if v_xmlresult is null then
        exit;
      end if;
      v_name        := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/Name/text()');
      v_description := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/Description/text()');
      v_tasktype    := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskType/text()');
      v_taskcode    := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/Code/text()');
      v_taskorder   := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskOrder/text()');
      v_DeadLine    := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/DeadLine/text()');
      v_Goal        := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/Goal/text()');
      v_IconName    := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/IconName/text()');
      v_ID2         := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/ID2/text()');
      v_Instatiation:= f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/Instatiation/text()');
      v_MaxAllowed  := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/MaxAllowed/text()');
      v_Required    := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/Required/text()');
      v_SystemType  := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/SystemType/text()');
      v_TaskId      := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskId/text()');
      v_Type        := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/Type/text()');
      v_Urgency     := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/Urgency/text()');
      v_Depth       := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/Depth/text()');
      v_Leaf        := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/Leaf/text()');
      v_ProcCode    := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/ProcCode/text()');
      v_PageCode    := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/PageCode/text()');
      v_isHidden    := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/IsHidden/text()');
BEGIN
      SELECT col_id
             INTO
             v_executionmethodtasktemplate
      FROM tbl_dict_executionmethod
      WHERE col_code = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/ExecutionMethod/text()');
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_executionmethodtasktemplate := NULL;
       p_util_update_log ( XmlIdLog => XmlId, Message => 'TaskTemplate executionmethodtasktemplate is null', IsError => 1);              
      END;
      BEGIN
        SELECT col_id
          INTO v_tasktypeid
          FROM tbl_dict_tasksystype
         WHERE col_code = v_tasktype;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_tasktypeid := NULL;
        p_util_update_log ( XmlIdLog => XmlId, Message => 'TaskTemplate tasktypeid is null', IsError => 1);          
      END;
      v_icon := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/Icon/text()');
      v_iconcls := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/IconCls/text()');
      --CREATE TASKTEMPLATES
      BEGIN
      begin
      SELECT col_id 
      INTO v_taskState 
      FROM tbl_dict_taskstate 
      WHERE col_ucode = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskState/text()');
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_taskState := NULL;
        p_util_update_log ( XmlIdLog => XmlId, Message => 'TaskTemplate taskState is null', IsError => 1);         
      END;
      MERGE INTO  tbl_tasktemplate
      USING
      (SELECT v_name Name_         ,v_taskcode taskcode,        dbms_xmlgen.convert(v_description,1) description,
              v_parentid  parentid ,v_taskorder taskorder,      v_Depth Depth,
              v_Leaf leaf          ,ProcedureId Procedure_,     v_tasktypeid tasktypeid,
              v_executionmethodtasktemplate executionmethodtasktemplate, 
              v_DeadLine DeadLine  ,v_Goal Goal,                v_IconName IconName,
              v_ID2  ID2           ,v_Instatiation Instatiation, v_MaxAllowed MaxAllowed,
              v_Required Required  ,v_SystemType SystemType,    v_TaskId TaskId,
              v_Type Type_         ,v_Urgency Urgency,          v_icon Icon,
              v_ProcCode ProcCode  ,v_PageCode PageCode,        v_iconcls IconCls,
              v_taskState TskSts   ,v_IsHidden IsHidden 
      FROM dual)
      ON (col_code = taskcode)
      WHEN MATCHED THEN
        UPDATE SET col_name = dbms_xmlgen.convert(name_,1),  col_description = description, col_parentttid  =parentid,
                   col_taskorder = taskorder, col_depth = Depth, col_leaf = leaf,
                   col_proceduretasktemplate = Procedure_,col_tasktmpldict_tasksystype = tasktypeid,
                   col_execmethodtasktemplate = executionmethodtasktemplate, 
                   col_deadline = DeadLine, col_goal = Goal, col_iconname = IconName,
                   col_id2 = ID2, col_instatiation = Instatiation, col_maxallowed = MaxAllowed,
                   col_required = Required, col_systemtype =  SystemType, col_taskid = TaskId, 
                   col_type = Type_, col_urgency = Urgency, col_icon = Icon, col_iconcls = IconCls,
                   col_processorcode = ProcCode, col_pagecode  = PageCode , col_tasktmpldict_taskstate =  TskSts,
                   col_ishidden = IsHidden
      WHEN NOT MATCHED THEN
      INSERT  (col_name, col_code, col_description, col_parentttid, col_taskorder,col_depth,
               col_leaf, col_proceduretasktemplate,col_tasktmpldict_tasksystype, col_execmethodtasktemplate,
               col_deadline, col_goal, col_iconname, col_id2, col_instatiation, col_maxallowed,
               col_required, col_systemtype, col_taskid, col_type, col_urgency, col_icon , col_iconcls ,
               col_processorcode, col_pagecode, col_tasktmpldict_taskstate,
               col_ishidden)
      VALUES  (dbms_xmlgen.convert(name_,1), taskcode, description ,parentid, taskorder, Depth,
               leaf, Procedure_, tasktypeid, executionmethodtasktemplate,
               DeadLine, Goal, IconName, ID2, Instatiation, MaxAllowed,
               Required, SystemType, TaskId, Type_, Urgency, Icon, IconCls, 
               ProcCode, PageCode, TskSts,
               IsHidden);
               
   p_util_update_log ( XmlIdLog => XmlId, Message => 'TaskTemplate       Merged TBL_TASKTEMPLATE with name'||v_name, IsError => 0);          
        
      SELECT col_id INTO v_nextparentid FROM tbl_tasktemplate WHERE col_code = v_taskcode;
      if v_parentid > 0 then
        update tbl_tasktemplate set col_leaf = 0 where col_id = v_parentid;
      end if;
      EXCEPTION
        WHEN OTHERS THEN NULL;
     
      END;

      /*************************************************************/
      --TBL_MAP_TASKSTATEINITIATION   TBL_TASKEVENT
      /*************************************************************/
       SELECT y.column_value.getstringval()
          INTO v_cnt
       FROM xmltable('count(/TaskTemplateTMPL[1]/TaskStateInitiationTMPL)' passing v_xmlresult) y ;
       FOR i IN 1..v_cnt LOOP
            v_assignprocessorcode := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskStateInitiationTMPL['||i||']/AssignProcessorCode/text()');
            v_processorcode := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskStateInitiationTMPL['||i||']/ProcessorCode/text()');
            v_MapTskstinitInitmtd := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskStateInitiationTMPL['||i||']/MapTskstinitInitmtd/text()');
            v_MapTskstinitTsks := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskStateInitiationTMPL['||i||']/MapTskstinitTsks/text()');

            IF v_MapTskstinitTsks IS NOT NULL THEN
            BEGIN
              SELECT col_id
              INTO v_MapTskstinitInitmtdID
               FROM TBL_DICT_INITMETHOD
               WHERE col_code = v_MapTskstinitInitmtd;
            EXCEPTION WHEN NO_DATA_FOUND THEN
              p_util_update_log ( XmlIdLog => XmlId, Message => 'TaskTemplate      Incorrect XML, cant find code '||v_MapTskstinitInitmtd||' in table  TBL_DICT_INITMETHOD', IsError => 1);                        
              RETURN 'Incorrect XML, cant find code '||v_MapTskstinitInitmtd||' in table  TBL_DICT_INITMETHOD';
            END;
            BEGIN

              SELECT COUNT(*)
              INTO v_cnt_cnt
              FROM  TBL_DICT_TASKSTATE
              WHERE  col_ucode = v_MapTskstinitTsks;
                 IF v_cnt_cnt = 0 THEN
                         SELECT col_ucode INTO
                           v_MapTskstinitTsks
                           FROM (
                           SELECT "Code", "Ucode", "StateConfig"
                            FROM XMLTABLE('/CaseType/TaskState'
                              PASSING v_input
                              COLUMNS
                                       "Code" nvarchar2(255) PATH './Code',
                                       "Ucode" nvarchar2(255) PATH './Ucode',
                                       "StateConfig" NVARCHAR2(255) PATH './StateConfig'
                                       )
                               ) state_,
                             tbl_dict_taskstate tst
                            WHERE  "Ucode" =  v_MapTskstinitTsks
                            AND tst.col_code = "Code"
                            AND tst.col_stateconfigtaskstate IS NULL;

             END IF;

              SELECT col_id
              INTO v_MapTskstinitTsksID
               FROM TBL_DICT_TASKSTATE
               WHERE col_ucode = v_MapTskstinitTsks;
            EXCEPTION WHEN NO_DATA_FOUND THEN
              p_util_update_log ( XmlIdLog => XmlId, Message => 'TaskTemplate      Incorrect XML, cant find code '||v_MapTskstinitTsks||' in table  TBL_DICT_TASKSTATE', IsError => 1);               
              RETURN 'Incorrect XML, cant find code '||v_MapTskstinitTsks||' in table  TBL_DICT_TASKSTATE';
            END;

            v_code := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskStateInitiationTMPL['||i||']/Code/text()');
            MERGE INTO tbl_map_taskstateinittmpl
            USING (SELECT v_assignprocessorcode assignprocessorcode, v_processorcode processorcode,
                        v_nextparentid nextparentid, v_MapTskstinitInitmtdID MapTskstinitInitmtdID, v_MapTskstinitTsksID MapTskstinitTsksID,
                        v_code code
            FROM dual)
            ON (col_code = code)
            WHEN MATCHED THEN
              UPDATE SET col_assignprocessorcode = assignprocessorcode, col_processorcode = processorcode,
                         col_map_taskstinittpltasktpl  = nextparentid, col_map_tskstinittpl_initmtd  = MapTskstinitInitmtdID,
                         col_map_tskstinittpl_tskst  = MapTskstinitTsksID
            WHEN NOT MATCHED THEN
            INSERT
            (col_assignprocessorcode, col_processorcode , col_map_taskstinittpltasktpl , col_map_tskstinittpl_initmtd ,
             col_map_tskstinittpl_tskst , col_code)
            VALUES
            (assignprocessorcode, processorcode, nextparentid, MapTskstinitInitmtdID, MapTskstinitTsksID, code);
            
            p_util_update_log ( XmlIdLog => XmlId, Message => 'TaskTemplate       Merged TBL_MAP_TASKSTATEINITIATION with code'||v_code, IsError => 0);              
            
            SELECT col_id INTO v_col_id FROM tbl_map_taskstateinittmpl WHERE col_code = v_code;

            DECLARE
              v_TEProcessorCode       NVARCHAR2(255);
              v_TaskEventOrder        PLS_INTEGER;
              v_TaskEventMoment       NVARCHAR2(255);
              v_TaskEventMomentID     NUMBER;
              v_TaskEventType         NVARCHAR2(255);
              v_TaskEventTypeID       NUMBER;
              v_path_2                NVARCHAR2(255);
              v_code_event            nvarchar2(255);
            BEGIN

         v_path_2 := 'count(/TaskTemplateTMPL[1]/TaskStateInitiationTMPL['||i||']/TaskEventTMPL)';
         SELECT y.column_value.getstringval()
          INTO v_cnt_2
       FROM xmltable(v_path_2 passing v_xmlresult) y;

       FOR j IN 1..v_cnt_2  LOOP
              v_TEProcessorCode := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskStateInitiationTMPL['||i||']/TaskEventTMPL['||j||']/ProcessorCode/text()');
              v_TaskEventOrder  := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskStateInitiationTMPL['||i||']/TaskEventTMPL['||j||']/TaskEventOrder/text()');
              v_TaskEventMoment := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskStateInitiationTMPL['||i||']/TaskEventTMPL['||j||']/TaskEventMoment/text()');
              v_TaskEventType   := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskStateInitiationTMPL['||i||']/TaskEventTMPL['||j||']/TaskEventType/text()');
              v_code_event      := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskTemplateTMPL[1]/TaskStateInitiationTMPL['||i||']/TaskEventTMPL['||j||']/Code/text()');

                    IF v_TEProcessorCode IS NOT NULL THEN

                    SELECT col_id
                      INTO v_TaskEventMomentID
                    FROM tbl_dict_taskeventmoment
                    WHERE col_code = v_TaskEventMoment;
                    --Exception !!!
                    SELECT col_id
                      INTO v_TaskEventTypeID
                      FROM tbl_dict_taskeventtype
                   WHERE col_code =  v_TaskEventType;
                     --Exception !!!!
                      MERGE INTO tbl_taskeventtmpl
                     USING (SELECT v_TEProcessorCode TEProcessorCode, v_TaskEventOrder TaskEventOrder,
                                   v_TaskEventMomentID TaskEventMomentID, v_col_id cl_id,
                                   v_TaskEventTypeID TaskEventTypeID, v_code_event code
                            FROM  dual)
                     ON (col_code = code )
                     WHEN MATCHED THEN
                       UPDATE  SET col_processorcode =TEProcessorCode , col_taskeventorder =TaskEventOrder,
                                   col_taskeventmomnttaskeventtp  =TaskEventMomentID , col_taskeventtptaskstinittp  =cl_id ,
                                   col_taskeventtypetaskeventtp  = TaskEventTypeID
                     WHEN NOT MATCHED THEN
                       INSERT (col_processorcode , col_taskeventorder, col_taskeventmomnttaskeventtp  , col_taskeventtptaskstinittp  , col_taskeventtypetaskeventtp , col_code )
                       VALUES (TEProcessorCode, TaskEventOrder, TaskEventMomentID, cl_id, TaskEventTypeID , code);
                      
                      p_util_update_log ( XmlIdLog => XmlId, Message => 'TaskTemplate       Merged TBL_TASKEVENT with code'||v_code_event, IsError => 0);  

                    END IF;
       END LOOP;
            END;
           END IF;
       END LOOP;
      /*************************************************************/
      -- END  TBL_MAP_TASKSTATEINITIATION
      /*************************************************************/
  --    v_taskorder := v_taskorder + 1;
      begin
        v_result := f_UTIL_extract_values_recursTM(Input => v_input/*.getClobVal()*/,
                                               Path => v_path || '/TaskTemplateTMPL[' || to_char(v_count) || ']',
                                                 TaskTemplateLevel => v_level + 1,
                                                 ParentId => v_nextparentid,
                                                 CaseTypeId => v_casetypeid,
                                                 ProcedureId => v_procedureid,
                                                 XmlId => XmlId);
        exception
        when OTHERS then
        exit;
      end;
      v_count := v_count + 1;
      if v_count > v_maxcount then
        return 'Failure';
      end if;
    else
      return 'Ok';
    end if;
  end loop;
  return 'Ok';

end;
