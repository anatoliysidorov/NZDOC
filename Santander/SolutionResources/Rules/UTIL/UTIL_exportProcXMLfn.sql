DECLARE
v_clob           NCLOB := EMPTY_CLOB();
v_clob2          NCLOB := EMPTY_CLOB();
v_xml_temp       XMLTYPE;
v_xml            XMLTYPE;
v_sql            NVARCHAR2(7200);
v_list_procedure NVARCHAR2(7200);
v_ExportProcId	 number;
BEGIN

v_ExportProcId := ExportProcId;

IF v_ExportProcId IS NOT NULL AND v_ExportProcId > 0 THEN
    BEGIN
     SELECT col_code
       INTO v_list_procedure
       FROM tbl_procedure
      WHERE col_id = v_ExportProcId;

    EXCEPTION WHEN NO_DATA_FOUND THEN
      RETURN 'Error - can''t export procedure for this ExportProcId'||v_ExportProcId;
    END;

END IF;

dbms_lob.createtemporary(v_clob,true);
dbms_lob.createtemporary(v_clob2,true);

DBMS_LOB.OPEN(v_clob, 1);
DBMS_LOB.OPEN(v_clob2, 1);

dbms_lob.append(v_clob, '<ProcedureAddition>');



SELECT Xmlagg(
      XMLELEMENT("Procedure",
                      XMLElement("Code", pr.col_code),
                      XMLElement("Name", pr.col_name),
                      XMLElement("Description", pr.col_description),
                      XMLElement("ConfigProc", pr.col_config),
                      XMLElement("RootTaskTypeCode", pr.col_roottasktypecode),
                      XMLElement("CustomDataProcessor", pr.col_customdataprocessor ),
                      XMLElement("CaseState", cst.col_ucode),
                      XMLElement("RetrieveCustomDataProcessor", pr.col_retcustdataprocessor),
                      XMLElement("UpdateCustomDataProcessor", pr.col_updatecustdataprocessor),
                      XMLElement("IsDefault", to_char(pr.col_isdefault,'FM9') ),
                      XMLElement("IsDeleted", to_char(pr.col_isdeleted,'FM9') ),
                      XMLElement("ProcInCaseType", princt.col_code)

                      )

                    )
       INTO v_xml
FROM tbl_procedure pr
LEFT JOIN tbl_dict_casestate cst ON pr.col_procedurecasestate = cst.col_id
LEFT JOIN tbl_dict_procedureincasetype princt ON pr.col_procprocincasetype = princt.col_id
WHERE pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
Xmlagg(
XMLELEMENT("TaskType",
                 XMLELEMENT("Code", tst.col_code),
                 XMLELEMENT("Name", tst.col_name),
                 XMLELEMENT("Description", to_char(tst.col_description)),
                 XMLELEMENT("CustomDataProcessor", tst.col_customdataprocessor),
                 XMLELEMENT("DateEventCustDataProc", tst.col_dateeventcustdataproc),
                 XMLELEMENT("IsDeleted", tst.col_isdeleted),
                 XMLELEMENT("ProcessorCode", tst.col_processorcode),
                 XMLELEMENT("RetCustDataProcessor", tst.col_retcustdataprocessor),
                 XMLELEMENT("UpdateCustDataProcessor", tst.col_updatecustdataprocessor),
                 XMLELEMENT("TaskSysTypeExecMethod", em.col_code),
                 XMLELEMENT("StateConfig", sc.col_code),
                 XMLELEMENT("RouteCustomDataProcessor", tst.col_routecustomdataprocessor),
                 XMLELEMENT("IconCode", tst.col_iconcode )
                 )
                 )
INTO v_xml
FROM
Tbl_Dict_Tasksystype tst
LEFT JOIN tbl_dict_executionmethod em ON tst.col_tasksystypeexecmethod = em.col_id
LEFT JOIN tbl_dict_stateconfig  sc ON tst.col_stateconfigtasksystype = sc.col_id
WHERE EXISTS
( SELECT 1 FROM tbl_tasktemplate tt, tbl_procedure pr WHERE tt.col_tasktmpldict_tasksystype = tst.col_id
    AND tt.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
    )
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT  Xmlagg(
        XMLELEMENT("TaskSysTypeResolutionCode",
                XMLELEMENT("ResolutionCode", rc.col_code),
                XMLELEMENT("TaskType", tst.col_code)
               )
        )
INTO  v_xml
FROM TBL_TASKSYSTYPERESOLUTIONCODE tstrc
JOIN Tbl_Dict_Tasksystype tst ON tstrc.col_tbl_dict_tasksystype = tst.col_id
JOIN tbl_stp_resolutioncode rc ON tstrc.col_tbl_stp_resolutioncode = rc.col_id
WHERE EXISTS
(SELECT 1 FROM tbl_tasktemplate tt, tbl_procedure pr WHERE tt.col_tasktmpldict_tasksystype = tst.col_id
    AND tt.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) );

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT
Xmlagg(
XMLELEMENT("TaskState",
           XMLELEMENT("Activity", ts.col_activity ),
           XMLELEMENT("CanAssign", col_canassign),
           XMLELEMENT("Code", ts.col_code),
           XMLELEMENT("Name", ts.col_name),
           XMLELEMENT("DefaultOrder", col_defaultorder),
           XMLELEMENT("Description", ts.col_description),
           XMLELEMENT("IsAssign", col_isassign),
           XMLELEMENT("IsDefaultonCreate", col_isdefaultoncreate),
           XMLELEMENT("IsDefaultonCreate2", col_isdefaultoncreate2),
           XMLELEMENT("IsDeleted", ts.col_isdeleted),
           XMLELEMENT("IsFinish", col_isfinish),
           XMLELEMENT("IsHidden", col_ishidden),
           XMLELEMENT("IsResolve", col_isresolve),
           XMLELEMENT("IsStart", col_isstart),
           XMLELEMENT("StyleInfo",dbms_xmlgen.convert(xmlData => ts.col_styleinfo.getClobVal(),flag => dbms_xmlgen.ENTITY_ENCODE)),
           XMLELEMENT("Ucode", ts.col_ucode),
           XMLELEMENT("StateConfig", conf.col_code),
           XMLELEMENT("Iconcode", ts.col_iconcode)
            )
 )
INTO  v_xml
FROM tbl_dict_taskstate ts
JOIN tbl_dict_stateconfig conf ON ts.col_stateconfigtaskstate = conf.col_id
where exists 
(SELECT 1 FROM tbl_tasktemplate tt, tbl_procedure pr WHERE tt.col_tasktmpldict_taskstate= ts.col_id
    AND tt.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))));

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

FOR rec IN (SELECT COLUMN_VALUE  FROM TABLE(split_casetype_list(v_list_procedure))) LOOP
v_sql := '
SELECT LEVEL, XMLELEMENT("TaskTemplateTMPL",
name||code||descr||TT||Icon||ExecutionMethod||TaskOrder||dead||goal||iconname||id2||inst||MaxA||Req||ST||TID||TP||Urg||Dpth||IconCls||Leaf||ProcCode||PageCode||TskSt||initi)
FROM
(SELECT d.col_id,
        d.col_parentttid,
        XMLELEMENT("Name",  d.col_name ) name ,
        XMLELEMENT("Code",  d.col_code )  code,
        XMLELEMENT("Description",  to_char(d.col_Description) ) descr,
        XMLELEMENT("TaskType", tst.col_code) TT ,
        XMLELEMENT("Icon",     d.col_icon ) Icon,
        XMLELEMENT("ExecutionMethod",  emm.col_code) ExecutionMethod,
        XMLELEMENT("TaskOrder", d.col_taskorder) TaskOrder,
        XMLELEMENT("DeadLine",  d.col_deadline) dead,
        XMLELEMENT("Goal",      d.col_goal) goal,
        XMLELEMENT("IconName",  d.col_iconname) iconname,
        XMLELEMENT("ID2",  d.col_id2) id2,
        XMLELEMENT("Instatiation",  d.col_instatiation) inst,
        XMLELEMENT("MaxAllowed",  d.col_maxallowed) MaxA,
        XMLELEMENT("Required",  d.col_required) Req,
        XMLELEMENT("SystemType",  d.col_systemtype) ST,
        XMLELEMENT("TaskId",  d.col_taskid) TID,
        XMLELEMENT("Type",  d.col_type) TP,
        XMLELEMENT("Urgency",  d.col_urgency) Urg,
        XMLELEMENT("Depth",  d.col_depth) Dpth,
        XMLELEMENT("IconCls",  d.col_iconcls) IconCls,
        XMLELEMENT("Leaf",  d.col_leaf) Leaf,
        XMLELEMENT("ProcCode",  d.col_processorcode) ProcCode,
        XMLELEMENT("PageCode",  d.col_pagecode) PageCode,
        XMLELEMENT("TaskState",  tsst1.col_ucode) TskSt,
        XMLAGG(XMLELEMENT("TaskStateInitiationTMPL",
                               XMLELEMENT("Code", mi.col_code),
                               XMLELEMENT("AssignProcessorCode", mi.col_assignprocessorcode),
                               XMLELEMENT("MapTskstinitInitmtd", imd.col_code),
                               XMLELEMENT("ProcessorCode", mi.col_processorcode),
                               XMLELEMENT("MapTskstinitTsks", tsst.col_ucode),
                               (SELECT XMLAGG(XMLELEMENT("TaskEventTMPL",
                                          XMLELEMENT("Code", r.col_code),
                                          XMLELEMENT("ProcessorCode", r.col_processorcode),
                                          XMLELEMENT("TaskEventOrder", r.col_taskeventorder),
                                          XMLELEMENT("TaskEventMoment", e.col_code),
                                          XMLELEMENT("TaskEventType", tet.col_code)
                                          )) FROM TBL_TASKEVENTTMPL r,
                                  tbl_dict_taskeventmoment e,
                                  tbl_dict_taskeventtype tet
                                   WHERE r.col_taskeventmomnttaskeventtp = e.col_id
                                   AND r.col_taskeventtypetaskeventtp  = tet.col_id
                                   AND r.col_taskeventtptaskstinittp  = mi.col_id
                                  GROUP BY col_taskeventtptaskstinittp ))) initi
FROM
tbl_tasktemplate d
INNER JOIN tbl_procedure p ON d.col_proceduretasktemplate = p.col_id and p.col_code = '''||rec.COLUMN_VALUE||'''
LEFT JOIN tbl_dict_tasksystype tst ON d.col_tasktmpldict_tasksystype = tst.col_id
LEFT JOIN TBL_MAP_TASKSTATEINITTMPL mi ON mi.col_map_taskstinittpltasktpl = d.col_id
LEFT JOIN TBL_DICT_EXECUTIONMETHOD emm on  d.col_execmethodtasktemplate = emm.col_id
LEFT JOIN tbl_dict_initmethod imd ON mi.col_map_tskstinittpl_initmtd = imd.col_id
LEFT JOIN tbl_dict_taskstate tsst ON mi.col_map_tskstinittpl_tskst = tsst.col_id
LEFT JOIN tbl_dict_taskstate tsst1 ON d.col_tasktmpldict_taskstate = tsst1.col_id
GROUP BY d.col_id,         d.col_parentttid,             d.col_name,
         d.col_code,       to_char(d.col_Description),   tst.col_code,
         d.col_icon,       emm.col_code,d.col_taskorder, d.col_deadline,
         d.col_goal,       d.col_iconname,               d.col_id2,
         d.col_instatiation, d.col_maxallowed,           d.col_required,
         d.col_systemtype, d.col_taskid,                 d.col_type,
         d.col_urgency,    d.col_depth,                  d.col_iconcls,
         d.col_leaf,       d.col_processorcode,          d.col_pagecode,
         tsst1.col_ucode)
where col_parentttid != 0
START WITH col_parentttid = 0
CONNECT BY PRIOR col_id  = col_parentttid
';


v_xml_temp := dbms_xmlgen.getxmltype(dbms_xmlgen.newcontextFromHierarchy(v_sql));


SELECT
XMLELEMENT
("TaskTemplatesTMPL",
  v_xml_temp
  ) xmldoc
 INTO v_xml_temp
from dual;



dbms_lob.append(v_clob2, v_xml_temp.getClobVal());
--v_clob := v_xml_temp.getClobVal();

v_clob2 := replace(replace(v_clob2, CHR(38)||'lt;','<'),CHR(38)||'gt;','>');

dbms_lob.append(v_clob, v_clob2);

END LOOP;


if v_xml_temp is null then

FOR rec IN (SELECT COLUMN_VALUE  FROM TABLE(split_casetype_list(v_list_procedure))) LOOP
v_sql := '
SELECT LEVEL, XMLELEMENT("TaskTemplate",
name||code||descr||TT||Icon||ExecutionMethod||TaskOrder||dead||goal||iconname||id2||inst||MaxA||Req||ST||TID||TP||Urg||Dpth||IconCls||Leaf||ProcCode||PageCode||TskSt||initi)
FROM
(SELECT d.col_id,
        d.col_parentttid,
        XMLELEMENT("Name",  d.col_name ) name ,
        XMLELEMENT("Code",  d.col_code )  code,
        XMLELEMENT("Description",  to_char(d.col_Description) ) descr,
        XMLELEMENT("TaskType", tst.col_code) TT ,
        XMLELEMENT("Icon",     d.col_icon ) Icon,
        XMLELEMENT("ExecutionMethod",  emm.col_code) ExecutionMethod,
        XMLELEMENT("TaskOrder", d.col_taskorder) TaskOrder,
        XMLELEMENT("DeadLine",  d.col_deadline) dead,
        XMLELEMENT("Goal",      d.col_goal) goal,
        XMLELEMENT("IconName",  d.col_iconname) iconname,
        XMLELEMENT("ID2",  d.col_id2) id2,
        XMLELEMENT("Instatiation",  d.col_instatiation) inst,
        XMLELEMENT("MaxAllowed",  d.col_maxallowed) MaxA,
        XMLELEMENT("Required",  d.col_required) Req,
        XMLELEMENT("SystemType",  d.col_systemtype) ST,
        XMLELEMENT("TaskId",  d.col_taskid) TID,
        XMLELEMENT("Type",  d.col_type) TP,
        XMLELEMENT("Urgency",  d.col_urgency) Urg,
        XMLELEMENT("Depth",  d.col_depth) Dpth,
        XMLELEMENT("IconCls",  d.col_iconcls) IconCls,
        XMLELEMENT("Leaf",  d.col_leaf) Leaf,
        XMLELEMENT("ProcCode",  d.col_processorcode) ProcCode,
        XMLELEMENT("PageCode",  d.col_pagecode) PageCode,
        XMLELEMENT("TaskState",  tsst1.col_ucode) TskSt,
        XMLAGG(XMLELEMENT("TaskStateInitiation",
                               XMLELEMENT("Code", mi.col_code),
                               XMLELEMENT("AssignProcessorCode", mi.col_assignprocessorcode),
                               XMLELEMENT("MapTskstinitInitmtd", imd.col_code),
                               XMLELEMENT("ProcessorCode", mi.col_processorcode),
                               XMLELEMENT("MapTskstinitTsks", tsst.col_ucode),
                               (SELECT XMLAGG(XMLELEMENT("TaskEvent",
                                          XMLELEMENT("Code", r.col_code),
                                          XMLELEMENT("ProcessorCode", r.col_processorcode),
                                          XMLELEMENT("TaskEventOrder", r.col_taskeventorder),
                                          XMLELEMENT("TaskEventMoment", e.col_code),
                                          XMLELEMENT("TaskEventType", tet.col_code)
                                          )) FROM tbl_taskevent r,
                                  tbl_dict_taskeventmoment e,
                                  tbl_dict_taskeventtype tet
                                   WHERE r.col_taskeventmomenttaskevent = e.col_id
                                   AND r.col_taskeventtypetaskevent = tet.col_id
                                   AND r.col_taskeventtaskstateinit = mi.col_id
                                  GROUP BY col_taskeventtaskstateinit ))) initi
FROM
tbl_tasktemplate d
INNER JOIN tbl_procedure p ON d.col_proceduretasktemplate = p.col_id and p.col_code = '''||rec.COLUMN_VALUE||'''
LEFT JOIN tbl_dict_tasksystype tst ON d.col_tasktmpldict_tasksystype = tst.col_id
LEFT JOIN tbl_map_taskstateinitiation mi ON mi.col_map_taskstateinittasktmpl = d.col_id
LEFT JOIN TBL_DICT_EXECUTIONMETHOD emm on  d.col_execmethodtasktemplate = emm.col_id
LEFT JOIN tbl_dict_initmethod imd ON mi.col_map_tskstinit_initmtd = imd.col_id
LEFT JOIN tbl_dict_taskstate tsst ON mi.col_map_tskstinit_tskst = tsst.col_id
LEFT JOIN tbl_dict_taskstate tsst1 ON d.col_tasktmpldict_taskstate = tsst1.col_id
GROUP BY d.col_id,         d.col_parentttid,             d.col_name,
         d.col_code,       to_char(d.col_Description),   tst.col_code,
         d.col_icon,       emm.col_code,d.col_taskorder, d.col_deadline,
         d.col_goal,       d.col_iconname,               d.col_id2,
         d.col_instatiation, d.col_maxallowed,           d.col_required,
         d.col_systemtype, d.col_taskid,                 d.col_type,
         d.col_urgency,    d.col_depth,                  d.col_iconcls,
         d.col_leaf,       d.col_processorcode,          d.col_pagecode,
         tsst1.col_ucode )
where col_parentttid != 0
START WITH col_parentttid = 0
CONNECT BY PRIOR col_id  = col_parentttid
';


v_xml_temp := dbms_xmlgen.getxmltype(dbms_xmlgen.newcontextFromHierarchy(v_sql));


SELECT
XMLELEMENT
("TaskTemplates",
  v_xml_temp
  ) xmldoc
 INTO v_xml_temp
from dual;

/*SELECT
XMLELEMENT
("TaskTemplates",
  (select dbms_xmlgen.getxmltype(dbms_xmlgen.newcontextFromHierarchy(v_sql))
  from dual)
  ) xmldoc
 INTO v_xml_temp
from dual;*/

dbms_lob.append(v_clob2, v_xml_temp.getClobVal());
--v_clob := v_xml_temp.getClobVal();

v_clob2 := replace(replace(v_clob2, CHR(38)||'lt;','<'),CHR(38)||'gt;','>');

/*SELECT
Xmlconcat(v_xml, XMLType(v_clob))
INTO v_xml
FROM dual;
*/
dbms_lob.append(v_clob, v_clob2);

END LOOP;

end if;

SELECT
Xmlagg(
    XMLELEMENT("Taskdependency",
    XMLELEMENT("Code",dep.col_code ),
    XMLELEMENT("ProcessorCode", dep.col_processorcode),
    XMLELEMENT("Type", dep.col_type),
    XMLELEMENT("TaskTemplateCodePr", tt.col_code),
    XMLELEMENT("TaskTemplateCodeChld",tt2.col_code),
    XMLELEMENT("MapTskstinitTsksPr",dt.col_ucode ),
    XMLELEMENT("MapTskstinitTsksChld",dt2.col_ucode ),
    XMLAGG (
           XMLELEMENT("AutoruleParams",
           XMLELEMENT("Code",ar.col_code),
           XMLELEMENT("ParamCode",ar.col_paramcode),
           XMLELEMENT("ParamValue",ar.col_paramvalue)
           )
           )
         )
)
INTO
  v_xml
FROM
  tbl_taskdependency dep
  JOIN tbl_map_taskstateinitiation t ON t.col_id = dep.col_tskdpndprnttskstateinit
  JOIN tbl_tasktemplate tt ON t.col_map_taskstateinittasktmpl = tt.col_id
  JOIN tbl_dict_taskstate dt ON  dt.col_id = t.col_map_tskstinit_tskst
  INNER JOIN tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT COLUMN_VALUE  FROM TABLE(split_casetype_list(v_list_procedure)))
  JOIN tbl_map_taskstateinitiation  t2 ON dep.col_tskdpndchldtskstateinit = t2.col_id
  JOIN tbl_tasktemplate tt2 ON t2.col_map_taskstateinittasktmpl = tt2.col_id AND tt2.col_proceduretasktemplate = tt2.col_proceduretasktemplate
  JOIN tbl_dict_taskstate dt2 ON  dt2.col_id = t2.col_map_tskstinit_tskst
  LEFT JOIN TBL_AUTORULEPARAMETER ar ON dep.col_id = ar.col_autoruleparamtaskdep
GROUP BY dep.col_code,  dep.col_processorcode, dep.col_type, tt.col_code, tt2.col_code,dt.col_ucode, dt2.col_ucode ;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
Xmlagg(
XMLELEMENT("TaskdependencyTMPL",
XMLFOREST(dep.col_code          AS "Code",
          dep.col_processorcode AS "ProcessorCode",
          dep.col_type          AS "Type", 
          tt.col_code           AS "TaskTemplateCodePr",
          tt2.col_code          AS "TaskTemplateCodeChld",
          dt.col_ucode          AS "MapTskstinitTsksPr",
          dt2.col_ucode         AS "MapTskstinitTsksChld",
          dep.col_id2           AS "ID2",
          dep.col_isdefault     AS "IsDefault",
          dep.col_taskdependencyorder AS "TaskDependencyOrder" ),
 XMLAGG (
       XMLELEMENT("AutoruleParams",
       XMLforest(ar.col_code       AS "Code",
                 ar.col_paramcode  AS "ParamCode",
                 ar.col_paramvalue AS "ParamValue" )
                  )
        )
         )
)
INTO
  v_xml
FROM
  TBL_TASKDEPENDENCYTMPL dep
  JOIN TBL_MAP_TASKSTATEINITTMPL t ON t.col_id = dep.col_taskdpprnttptaskstinittp
  JOIN tbl_tasktemplate tt ON t.col_map_taskstinittpltasktpl = tt.col_id
  JOIN tbl_dict_taskstate dt ON  dt.col_id = t.col_map_tskstinittpl_tskst
  INNER JOIN tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT COLUMN_VALUE  FROM TABLE(split_casetype_list(v_list_procedure)))
  JOIN TBL_MAP_TASKSTATEINITTMPL  t2 ON dep.col_taskdpchldtptaskstinittp  = t2.col_id
  JOIN tbl_tasktemplate tt2 ON t2.col_map_taskstinittpltasktpl  = tt2.col_id AND tt2.col_proceduretasktemplate = tt2.col_proceduretasktemplate
  JOIN tbl_dict_taskstate dt2 ON  dt2.col_id = t2.col_map_tskstinittpl_tskst
  LEFT JOIN TBL_AUTORULEPARAMTMPL ar ON dep.col_id = ar.col_autoruleparamtptaskdeptp
GROUP BY dep.col_code,  dep.col_processorcode, dep.col_type, tt.col_code, tt2.col_code,dt.col_ucode, dt2.col_ucode,
dep.col_id2, dep.col_isdefault, dep.col_taskdependencyorder ;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

/***************************************************************************************************/
--tbl_casedependencytmpl
/***************************************************************************************************/

SELECT  Xmlagg(
  XMLELEMENT("CaseDependencyTMPL",
            XMLFOREST(t.col_code AS "Code",
                      t.col_type  AS "Type",
                      t.col_processorcode  AS "ProcessorCode",
                      mti.col_code AS "PrntTaskstateInitTMPL",
                      ini.col_code AS "CldTaskstateInitTMPL",
                      cini.col_code AS "CLDCaseStateInitTMPL",
                      cini1.col_code AS "PrntCaseStateInitTMPL" )
             )
         )
INTO v_xml
FROM tbl_casedependencytmpl t
JOIN tbl_map_taskstateinittmpl mti ON t.col_casedpPRTtpltaskstinittpl = mti.col_id
JOIN tbl_tasktemplate tt ON mti.col_map_taskstinittpltasktpl = tt.col_id
JOIN  tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_map_taskstateinittmpl ini ON t.col_casedpCLDtpltaskstinittpl = ini.col_id
LEFT JOIN tbl_map_casestateinittmpl cini ON t.col_casedpCLDtplcasestinittpl = cini.col_id
LEFT JOIN tbl_map_casestateinittmpl cini1 ON t.col_casedpPRTtplcasestinittpl = cini1.col_id
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;
/***************************************************************************************************/
--tbl_casedependency
/***************************************************************************************************/


SELECT  Xmlagg(
  XMLELEMENT("CaseDependency",
            XMLFOREST(t.col_code AS "Code",
                      t.col_type AS "Type",
                      t.col_processorcode  AS "ProcessorCode",
                      mti.col_code AS "PrntTaskstateInit",
                      ini.col_code AS "CldTaskstateInit",
                      cini.col_code AS "CLDCaseStateInit",
                      cini1.col_code AS "PrntCaseStateInit" )
             )
         )
INTO v_xml
FROM
tbl_casedependency t
JOIN tbl_map_taskstateinitiation mti ON t.col_casedpndPRNttaskstateinit = mti.col_id
JOIN tbl_tasktemplate tt ON mti.col_map_taskstateinittasktmpl = tt.col_id
JOIN  tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id AND p.col_code in (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_map_taskstateinitiation ini ON t.col_casedpndCHLdtaskstateinit = ini.col_id
LEFT JOIN tbl_map_casestateinitiation cini ON t.col_casedpndCHLdcasestateinit = cini.col_id
LEFT JOIN  tbl_map_casestateinitiation cini1 ON t.col_casedpndpRNTcasestateinit = cini1.col_id
;


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
      Xmlagg(Xmlelement
               ("SlaEvent",
                  XMLFOREST(se.col_code          AS "Code", 
                            se.col_intervalds    AS "Intervalds",
                            se.col_intervalym    AS "Intervalym",
                            se.col_isrequired    AS "Isrequired",
                            se.col_maxattempts   AS "MaxAttempts",
                            se.col_slaeventorder AS "SlaEventOrder",
                            slat.col_code        AS "SlaEventType",
                            tt.col_code          AS "TaskTemplate",
                            det.col_code         AS "DateEventType",
                            dsel.col_code        AS "SlaEventLevel",
                            cst.col_code         AS "CaseType"
                            )
                   )
              )
   INTO  v_xml
FROM tbl_slaevent se
    LEFT JOIN tbl_tasktemplate tt ON se.col_slaeventtasktemplate = tt.col_id
         JOIN tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id
    LEFT JOIN tbl_dict_slaeventtype slat ON se.col_slaeventdict_slaeventtype = slat.col_id
    LEFT JOIN TBL_DICT_DATEEVENTTYPE det ON se.col_slaevent_dateeventtype = det.col_id
    LEFT JOIN TBL_DICT_SLAEVENTLEVEL dsel ON se.col_slaevent_slaeventlevel = dsel.col_id
    LEFT JOIN tbl_dict_casesystype cst ON se.col_slaeventslacase = cst.col_id

WHERE p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)));

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
      Xmlagg(Xmlelement
                ("SlaEventTMPL",
                    XMLFOREST(se.col_code          AS "Code", 
                              se.col_intervalds    AS  "Intervalds",
                              se.col_intervalym    AS "Intervalym",
                              se.col_isrequired    AS "Isrequired",
                              se.col_maxattempts   AS "MaxAttempts",
                              se.col_slaeventorder AS "SlaEventOrder",
                              slat.col_code        AS "SlaEventType",
                              tt.col_code          AS "TaskTemplate",
                              det.col_code         AS "DateEventType",
                              dsel.col_code        AS "SlaEventLevel",
                              cst.col_code         AS "CaseType",
                              se.col_attemptcount  AS "AttemptCount",
                              se.col_id2           AS "ID2",
                              tst.col_code         AS "TaskType")
                         )
              )
   INTO  v_xml
FROM TBL_SLAEVENTTMPL se
    LEFT JOIN tbl_tasktemplate tt ON se.col_slaeventtptasktemplate = tt.col_id
         JOIN tbl_procedure p	ON tt.col_proceduretasktemplate = p.col_id
    LEFT JOIN tbl_dict_slaeventtype slat ON se.col_slaeventtp_slaeventtype = slat.col_id
    LEFT JOIN TBL_DICT_DATEEVENTTYPE det ON se.col_slaeventtp_dateeventtype = det.col_id
    LEFT JOIN TBL_DICT_SLAEVENTLEVEL dsel ON se.col_slaeventtp_slaeventlevel = dsel.col_id
	LEFT JOIN tbl_dict_casesystype cst ON se.col_slaeventtmpldict_cst = cst.col_id
    LEFT JOIN tbl_dict_tasksystype tst ON se.col_slaeventtp_tasksystype = tst.col_id    
WHERE p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)));

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT Xmlagg(Xmlelement("SlaAction",
             Xmlelement("Code", sa.col_code),
             Xmlelement("ActionOrder", sa.col_actionorder),
             Xmlelement("Name", sa.col_name),
             Xmlelement("ProcessorCode", sa.col_processorcode),
             Xmlelement("SlaEventLevel", selvl.col_code),
             Xmlelement("SlaEventCode", se.col_code)
             )
 )
 INTO v_xml
FROM  tbl_slaaction sa
    ,tbl_dict_slaeventlevel selvl
    ,tbl_slaevent se
    ,tbl_tasktemplate tt
    ,tbl_procedure p
WHERE  sa.col_slaaction_slaeventlevel = selvl.col_id
   AND sa.col_slaactionslaevent = se.col_id
   AND se.col_slaeventtasktemplate = tt.col_id
   AND tt.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) ;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT Xmlagg(Xmlelement("SlaActionTMPL",
             Xmlelement("Code", sa.col_code),
             Xmlelement("ActionOrder", sa.col_actionorder),
             Xmlelement("Name", sa.col_name),
             Xmlelement("ProcessorCode", sa.col_processorcode),
             Xmlelement("SlaEventLevel", selvl.col_code),
             Xmlelement("SlaEventCode", se.col_code)
             )
 )
 INTO v_xml
FROM  TBL_SLAACTIONTMPL sa
    ,tbl_dict_slaeventlevel selvl
    ,TBL_SLAEVENTTMPL se
    ,tbl_tasktemplate tt
    ,tbl_procedure p
WHERE  sa.col_slaactiontp_slaeventlevel = selvl.col_id
   AND sa.col_slaactiontpslaeventtp = se.col_id
   AND se.col_slaeventtptasktemplate = tt.col_id
   AND tt.col_proceduretasktemplate = p.col_id  AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)));

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;



SELECT
Xmlagg(Xmlelement("TaskTransition",
                         Xmlelement("Code",         trt.col_code),
                         Xmlelement("Description",  trt.col_description),
                         Xmlelement("ManualOnly",   trt.col_manualonly),
                         Xmlelement("Name",         trt.col_name),
                         Xmlelement("Transition",   trt.col_transition),
                         Xmlelement("Source",       tst.col_ucode),
                         Xmlelement("Target",       tst2.col_ucode),
                         Xmlelement("Ucode",        trt.col_ucode)
                         )
                         )
INTO v_xml
FROM tbl_dict_tasktransition trt
JOIN tbl_dict_taskstate tst ON trt.col_sourcetasktranstaskstate = tst.col_id AND
EXISTS
(SELECT 1 FROM tbl_tasktemplate tt, tbl_procedure pr WHERE tt.col_tasktmpldict_taskstate= tst.col_id
    AND tt.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))))
JOIN tbl_dict_taskstate tst2 ON trt.col_targettasktranstaskstate = tst2.col_id
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
Xmlagg(Xmlelement("FomUiElement",
                         Xmlelement("Code",         fuel.col_code),
                         Xmlelement("Description",  fuel.col_description),
                         Xmlelement("IsDelete",     fuel.col_isdeleted),
                         Xmlelement("IsHidden",     fuel.col_ishidden),
                         Xmlelement("Name",         fuel.col_name),
                         Xmlelement("ParentCode",   (SELECT fuel2.col_code  FROM tbl_fom_uielement fuel2 WHERE fuel2.col_id = fuel.col_parentid)),
                         Xmlelement("ProcessorCode",fuel.col_processorcode),
                         Xmlelement("Title",        fuel.col_title),
                         Xmlelement("UiElementOrder", fuel.col_uielementorder),
                         Xmlelement("CaseType",     cst.col_code),
                         Xmlelement("CaseTtansition",   ctr.col_ucode),
                         Xmlelement("TaskType",         tt.col_code),
                         Xmlelement("TaskTtansition",   ttr.col_ucode),
                         Xmlelement("UserElementType",  uet.col_code),
                         Xmlelement("CaseState",        cstat.col_ucode),
                         Xmlelement("TaskState",        dts.col_ucode),
                         Xmlelement("Config",           fuel.col_config),
                         Xmlelement("IsEditable",       fuel.col_iseditable),
                         Xmlelement("RegionId",         fuel.col_regionid),
                         Xmlelement("PositionIndex",    fuel.col_positionindex),
                         Xmlelement("JsonData",         fuel.col_jsondata),
                         Xmlelement("RuleVisibility",   fuel.col_rulevisibility),
                         Xmlelement("ElementCode",      fuel.col_elementcode ),
                         Xmlelement("UIElementPage",    fp.col_code),
                         Xmlelement("FomWidget",        wg.col_code),
                         Xmlelement("FomDashboard",     dsh.col_code),
                         Xmlelement("UserEditable",     fuel.col_usereditable),
                         Xmlelement("FomFormList",      (SELECT listagg(to_char(fom.col_code),',') WITHIN GROUP(ORDER BY fom.col_code) FROM tbl_fom_form fom WHERE
                                                        fom.col_id IN (SELECT * FROM TABLE(split_casetype_list(fuel.col_formidlist))))
                                    ),
                         Xmlelement("CodedPageList",    (SELECT listagg(to_char(fom.col_code),',') WITHIN GROUP(ORDER BY fom.col_code) FROM tbl_fom_codedpage fom WHERE
                                                        fom.col_id IN (SELECT * FROM TABLE(split_casetype_list(fuel.col_codedpageidlist))))
                                                                        ),
                         Xmlelement("DomObject" , do.col_ucode),
                         Xmlelement("MdmForm" , mdm.col_code),
                         Xmlelement("SomConfig" , sc.col_code)           
                                    
                         )
                         )
INTO v_xml
FROM tbl_fom_uielement fuel
LEFT JOIN tbl_dict_casesystype cst    ON fuel.col_uielementcasesystype = cst.col_id
LEFT JOIN tbl_dict_casetransition ctr ON fuel.col_uielementcasetransition = ctr.col_id
LEFT JOIN tbl_dict_tasksystype tt     ON fuel.col_uielementtasksystype = tt.col_id
LEFT JOIN tbl_dict_tasktransition ttr ON fuel.col_uielementtasktransition = ttr.col_id
LEFT JOIN tbl_fom_uielementtype uet   ON fuel.col_uielementuielementtype =  uet.col_id
LEFT JOIN tbl_dict_casestate cstat    ON fuel.col_uielementcasestate = cstat.col_id
LEFT JOIN tbl_fom_widget wg           ON fuel.col_uielementwidget = wg.col_id
LEFT JOIN tbl_fom_dashboard dsh       ON fuel.col_uielementdashboard = dsh.col_id
LEFT JOIN tbl_dict_taskstate    dts   ON fuel.col_uielementtaskstate = dts.col_id
LEFT JOIN tbl_dom_object do           ON fuel.col_uielementobject = do.col_id
LEFT JOIN tbl_mdm_form mdm            ON fuel.col_uielementform = mdm.col_id
LEFT JOIN tbl_som_config sc           ON fuel.col_fom_uielementsom_config = sc.col_id
LEFT JOIN tbl_fom_page fp             ON fuel.col_uielementpage = fp.col_id
WHERE fuel.col_code != 'DEFAULT_PORTAL_DASHBOARD'
AND fp.col_id IN
(SELECT assp.col_assocpagepage
FROM tbl_ASSOCPAGE assp
WHERE EXISTS
(SELECT 1 FROM tbl_tasktemplate tt2, tbl_procedure pr WHERE assp.col_assocpagetasktemplate = tt2.col_id
    AND tt2.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
)
OR EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tstt, tbl_tasktemplate tt3, tbl_procedure pr2  WHERE assp.col_assocpagedict_tasksystype = tstt.col_id
AND tstt.col_id = tt3.col_tasktmpldict_tasksystype AND tt3.col_proceduretasktemplate = pr2.col_id
AND pr2.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
)
OR (
assp.col_partytypeassocpage IN  (SELECT col_id FROM tbl_dict_partytype)
)
)
OR
fp.col_systemdefault = 1
ORDER BY fuel.col_id;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
Xmlagg(Xmlelement("AccessObject",
                         Xmlelement("Code",         col_code),
                         Xmlelement("Name",         col_name),
                         Xmlelement("AccessObjectTypeCode", accessobjecttype),
                         Xmlelement("CaseStateCode", casestate),
                         Xmlelement("CaseTypeCode", casesystype),
                         Xmlelement("TaskTypeCode", tasksystype),
                         Xmlelement("UserElement", uielement),
                         Xmlelement("CaseTransition", casetransition),
                         Xmlelement("AccessTypeCode", accesstype)
                         ))
INTO v_xml
FROM
(
SELECT
ao.col_code,
ao.col_name,
aot.col_code accessobjecttype,
cst.col_ucode casestate,
cstp.col_code casesystype,
tst.col_code tasksystype,
ue.col_code uielement,
ctr.col_code casetransition,
acct.col_code accesstype
FROM
tbl_AC_ACCESSOBJECT  ao
JOIN tbl_ac_accessobjecttype aot ON ao.col_accessobjaccessobjtype = aot.col_id
LEFT JOIN tbl_dict_accesstype acct ON ao.col_accessobjectaccesstype = acct.col_id
LEFT JOIN tbl_dict_casestate cst ON ao.col_accessobjectcasestate = cst.col_id
LEFT JOIN tbl_dict_casesystype cstp ON ao.col_accessobjectcasesystype = cstp.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ao.col_accessobjecttasksystype = tst.col_id
LEFT JOIN tbl_dict_casetransition ctr ON ao.col_accessobjcasetransition = ctr.col_id
JOIN tbl_fom_uielement ue ON ao.col_accessobjectuielement = ue.col_id
JOIN tbl_fom_page fp             ON ue.col_uielementpage = fp.col_id
WHERE fp.col_id IN
(SELECT assp.col_assocpagepage
FROM tbl_ASSOCPAGE assp
WHERE EXISTS
(SELECT 1 FROM tbl_tasktemplate tt2, tbl_procedure pr WHERE assp.col_assocpagetasktemplate = tt2.col_id
    AND tt2.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
)
OR EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tstt, tbl_tasktemplate tt3, tbl_procedure pr2  WHERE assp.col_assocpagedict_tasksystype = tstt.col_id
AND tstt.col_id = tt3.col_tasktmpldict_tasksystype AND tt3.col_proceduretasktemplate = pr2.col_id
AND pr2.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
)
OR (
assp.col_partytypeassocpage IN  (SELECT col_id FROM tbl_dict_partytype)
)
)
)
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
Xmlagg(Xmlelement("Assocpage",
               Xmlelement("Code", assp.col_code),
               Xmlelement("Description", assp.col_description),
               Xmlelement("IsDeleted", assp.col_isdeleted),
               Xmlelement("Order", assp.col_order),
               Xmlelement("Owner", assp.col_owner),
               Xmlelement("Pagecode", assp.col_pagecode),
               Xmlelement("Pageparam", assp.col_pageparams),
               Xmlelement("Required", assp.col_required),
               Xmlelement("Title", assp.col_title),
               Xmlelement("AssocpageType", dasp.col_code),
               Xmlelement("CodedPage", cp.col_code),
               Xmlelement("CaseType", cst.col_code),
               Xmlelement("TaskType", tstp.col_code),
               Xmlelement("Form", ff.col_code),
               Xmlelement("TaskTemplate", tt.col_code),
               Xmlelement("PartyType", pt.col_code),
               Xmlelement("AllowAspx", assp.col_allowaspx),
               Xmlelement("AllowCodedPage", assp.col_allowcodedpage),
               Xmlelement("AllowForm", assp.col_allowform ),
               Xmlelement("AllowFormInTab", assp.col_allowformintab ),
               Xmlelement("FomPage", fp.col_code),
               Xmlelement("WorkActivityType", wat.col_code),
               Xmlelement("DocTypeCode", dt.col_code),
               Xmlelement("MDMFormCode", mdm.col_code)

               )
      )
INTO v_xml
FROM tbl_ASSOCPAGE assp
LEFT JOIN tbl_DICT_ASSOCPAGETYPE  dasp ON assp.col_assocpageassocpagetype = dasp.col_id
LEFT JOIN tbl_fom_codedpage cp ON assp.col_assocpagecodedpage = cp.col_id
LEFT JOIN tbl_dict_casesystype cst ON assp.col_assocpagedict_casesystype = cst.col_id
LEFT JOIN tbl_dict_tasksystype tstp ON assp.col_assocpagedict_tasksystype = tstp.col_id
LEFT JOIN tbl_fom_form ff ON assp.col_assocpageform = ff.col_id
LEFT JOIN tbl_tasktemplate tt ON assp.col_assocpagetasktemplate = tt.col_id
LEFT JOIN tbl_dict_partytype pt ON assp.col_partytypeassocpage  = pt.col_id
LEFT JOIN tbl_fom_page fp ON assp.col_assocpagepage = fp.col_id
LEFT JOIN tbl_dict_documenttype dt ON assp.col_assocpagedict_doctype = dt.col_id
LEFT JOIN tbl_mdm_form mdm ON assp.col_assocpagemdm_form = mdm.col_id
LEFT JOIN tbl_dict_workactivitytype wat ON assp.col_dict_watypeassocpage = wat.col_id
WHERE EXISTS
(SELECT 1 FROM tbl_tasktemplate tt2, tbl_procedure pr WHERE assp.col_assocpagetasktemplate = tt2.col_id
    AND tt2.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
)
OR EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tstt, tbl_tasktemplate tt3, tbl_procedure pr2  WHERE assp.col_assocpagedict_tasksystype = tstt.col_id
AND tstt.col_id = tt3.col_tasktmpldict_tasksystype AND tt3.col_proceduretasktemplate = pr2.col_id
AND pr2.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
)
OR (
assp.col_partytypeassocpage IN  (SELECT col_id FROM tbl_dict_partytype)
)
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
--Xmlconcat(v_xml2,
        Xmlagg(Xmlelement("TaskStateSetup",
              Xmlelement("Code", tstp.col_code),
              Xmlelement("FofsedNull", tstp.col_forcednull),
             Xmlelement("ForcedOverWrite", tstp.col_forcedoverwrite),
             Xmlelement("Name", tstp.col_name),
             Xmlelement("NotNullOverWrite", tstp.col_notnulloverwrite),
             Xmlelement("TaskState", tstk.col_ucode),
             Xmlelement("NullOverWrite", tstp.col_nulloverwrite),
             Xmlelement("CaseConfig", stscong.col_code),
             Xmlelement("Ucode", tstp.col_ucode)
             )
             )
--)
INTO v_xml
FROM tbl_DICT_TASKSTATESETUP tstp
LEFT JOIN tbl_dict_taskstate tstk ON  tstp.col_taskstatesetuptaskstate = tstk.col_id
LEFT JOIN tbl_dict_stateconfig stscong ON tstk.col_stateconfigtaskstate = stscong.col_id
WHERE stscong.col_code IS NOT NULL;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
       Xmlagg(Xmlelement("TaskStateDateEventType",
              Xmlelement("TaskState", tst.col_ucode),
              Xmlelement("DateEventType", ddt.col_code),
              Xmlelement("StateConfig", sc.col_code)
              )
              )
INTO v_xml
FROM TBL_DICT_TSKST_DTEVTP tsdet
JOIN tbl_dict_dateeventtype ddt ON tsdet.col_tskst_dtevtpdateeventtype = ddt.col_id
JOIN tbl_dict_taskstate tst ON  tsdet.col_tskst_dtevtptaskstate = tst.col_id
AND
EXISTS
(SELECT 1 FROM tbl_tasktemplate tt, tbl_procedure pr WHERE tt.col_tasktmpldict_taskstate= tst.col_id
    AND tt.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))))
JOIN tbl_dict_stateconfig sc ON tst.col_stateconfigtaskstate = sc.col_id
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT
Xmlagg(
  XMLELEMENT("AutoRuleParamTmpl",
            XMLFOREST(col_code       AS "Code",
                      col_issystem   AS "IsSystem",
                      col_paramvalue AS "ParamValue",
                      col_paramcode  AS "ParamCode",
                      SLAAction      AS "SLAAction",
                      CaseDep        AS "CaseDep",
                      CaseType       AS "CaseType",
                      ParamConf      AS "ParamConf",
                      TaskDep        AS "TaskDep",
                      CaseEvent      AS "CaseEvent",
                      CaseStateIni   AS "CaseStateIni",
                      TaskStateIni   AS "TaskStateIni",
                      TaskEvent      AS "TaskEvent",
                      TaskType       AS "TaskType",
                      TaskTempl      AS "TaskTempl",
                      StateEventUcode AS "StateEventUcode",
                      StateSlaAction AS "StateSlaAction")
                      )
)
INTO v_xml
FROM
(
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, cd.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tad.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl,
ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction
FROM
tbl_autoruleparamtmpl ar
JOIN tbl_paramconfig pc ON ar.col_autoruleparamtpparamconf = pc.col_id
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamtpcasetype = cst.col_id
LEFT JOIN tbl_slaactiontmpl sa ON ar.col_autorulepartpslaactiontp = sa.col_id
LEFT JOIN tbl_casedependencytmpl cd ON ar.col_autoruleparamtpcasedeptp = cd.col_id
LEFT JOIN tbl_taskdependencytmpl tad ON ar.col_autoruleparamtptaskdeptp = tad.col_id
LEFT JOIN tbl_caseeventtmpl ce ON ar.col_caseeventtpautorulepartp = ce.col_id
LEFT JOIN tbl_map_casestateinittmpl cit ON ar.col_rulepartp_casestateinittp = cit.col_id
LEFT JOIN tbl_map_taskstateinittmpl tit ON ar.col_rulepartp_taskstateinittp = tit.col_id
LEFT JOIN tbl_taskeventtmpl te ON ar.col_taskeventtpautoruleparmtp = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautorulepartp = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_tasktemplateautorulepartp = tt.col_id
LEFT JOIN tbl_dict_stateevent ste ON ar.col_autorulepartmplstateevent = ste.col_id
LEFT JOIN tbl_DICT_StateSlaAction dsa ON ar.col_DICT_StateSlaActionARP = dsa.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, cd.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tad.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl,
ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction
FROM tbl_autoruleparamtmpl ar
JOIN tbl_slaactiontmpl sa ON ar.col_autorulepartpslaactiontp = sa.col_id
JOIN tbl_slaeventtmpl se ON sa.col_slaactiontpslaeventtp = se.col_id
JOIN tbl_tasktemplate tt ON se.col_slaeventtptasktemplate = tt.col_id
JOIN tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamtpcasetype = cst.col_id
LEFT JOIN tbl_casedependencytmpl cd ON ar.col_autoruleparamtpcasedeptp = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamtpparamconf = pc.col_id
LEFT JOIN tbl_taskdependencytmpl tad ON ar.col_autoruleparamtptaskdeptp = tad.col_id
LEFT JOIN tbl_caseeventtmpl ce ON ar.col_caseeventtpautorulepartp = ce.col_id
LEFT JOIN tbl_map_casestateinittmpl cit ON ar.col_rulepartp_casestateinittp = cit.col_id
LEFT JOIN tbl_map_taskstateinittmpl tit ON ar.col_rulepartp_taskstateinittp = tit.col_id
LEFT JOIN tbl_taskeventtmpl te ON ar.col_taskeventtpautoruleparmtp = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautorulepartp = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_tasktemplateautorulepartp = tt.col_id
LEFT JOIN tbl_dict_stateevent ste ON ar.col_autorulepartmplstateevent = ste.col_id
LEFT JOIN tbl_DICT_StateSlaAction dsa ON ar.col_DICT_StateSlaActionARP = dsa.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, cd.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tad.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
tet.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl,
ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction
FROM tbl_autoruleparamtmpl ar
JOIN tbl_taskeventtmpl tet ON ar.col_taskeventtpautoruleparmtp = tet.col_id
JOIN TBL_MAP_TASKSTATEINITTMPL tit ON tet.col_taskeventtptaskstinittp  = tit.col_id
JOIN tbl_tasktemplate tt ON tit.col_map_taskstinittpltasktpl = tt.col_id
JOIN  tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamtpcasetype = cst.col_id
LEFT JOIN tbl_slaactiontmpl sa ON ar.col_autorulepartpslaactiontp = sa.col_id
LEFT JOIN tbl_casedependencytmpl cd ON ar.col_autoruleparamtpcasedeptp = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamtpparamconf = pc.col_id
LEFT JOIN tbl_taskdependencytmpl tad ON ar.col_autoruleparamtptaskdeptp = tad.col_id
LEFT JOIN tbl_caseeventtmpl ce ON ar.col_caseeventtpautorulepartp = ce.col_id
LEFT JOIN tbl_map_casestateinittmpl cit ON ar.col_rulepartp_casestateinittp = cit.col_id
LEFT JOIN tbl_map_taskstateinittmpl tit ON ar.col_rulepartp_taskstateinittp = tit.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautorulepartp = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_tasktemplateautorulepartp = tt.col_id
LEFT JOIN tbl_dict_stateevent ste ON ar.col_autorulepartmplstateevent = ste.col_id
LEFT JOIN tbl_DICT_StateSlaAction dsa ON ar.col_DICT_StateSlaActionARP = dsa.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, tmp.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tad.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl,
ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction
FROM tbl_autoruleparamtmpl ar
JOIN tbl_casedependencytmpl tmp ON ar.col_autoruleparamtpcasedeptp = tmp.col_id
JOIN tbl_map_taskstateinittmpl mti ON tmp.col_casedpcldtpltaskstinittpl = mti.col_id
JOIN tbl_tasktemplate tt ON mti.col_map_taskstinittpltasktpl = tt.col_id
JOIN  tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamtpcasetype = cst.col_id
LEFT JOIN tbl_slaactiontmpl sa ON ar.col_autorulepartpslaactiontp = sa.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamtpparamconf = pc.col_id
LEFT JOIN tbl_taskdependencytmpl tad ON ar.col_autoruleparamtptaskdeptp = tad.col_id
LEFT JOIN tbl_caseeventtmpl ce ON ar.col_caseeventtpautorulepartp = ce.col_id
LEFT JOIN tbl_map_casestateinittmpl cit ON ar.col_rulepartp_casestateinittp = cit.col_id
LEFT JOIN tbl_map_taskstateinittmpl tit ON ar.col_rulepartp_taskstateinittp = tit.col_id
LEFT JOIN tbl_taskeventtmpl te ON ar.col_taskeventtpautoruleparmtp = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautorulepartp = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_tasktemplateautorulepartp = tt.col_id
LEFT JOIN tbl_dict_stateevent ste ON ar.col_autorulepartmplstateevent = ste.col_id
LEFT JOIN tbl_DICT_StateSlaAction dsa ON ar.col_DICT_StateSlaActionARP = dsa.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, tmp.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tad.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl,
ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction
FROM tbl_autoruleparamtmpl ar
JOIN tbl_casedependencytmpl tmp ON ar.col_autoruleparamtpcasedeptp = tmp.col_id
JOIN tbl_map_taskstateinittmpl mti ON tmp.col_casedpprttpltaskstinittpl = mti.col_id
JOIN tbl_tasktemplate tt ON mti.col_map_taskstinittpltasktpl = tt.col_id
JOIN  tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamtpcasetype = cst.col_id
LEFT JOIN tbl_slaactiontmpl sa ON ar.col_autorulepartpslaactiontp = sa.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamtpparamconf = pc.col_id
LEFT JOIN tbl_taskdependencytmpl tad ON ar.col_autoruleparamtptaskdeptp = tad.col_id
LEFT JOIN tbl_caseeventtmpl ce ON ar.col_caseeventtpautorulepartp = ce.col_id
LEFT JOIN tbl_map_casestateinittmpl cit ON ar.col_rulepartp_casestateinittp = cit.col_id
LEFT JOIN tbl_map_taskstateinittmpl tit ON ar.col_rulepartp_taskstateinittp = tit.col_id
LEFT JOIN tbl_taskeventtmpl te ON ar.col_taskeventtpautoruleparmtp = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautorulepartp = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_tasktemplateautorulepartp = tt.col_id
LEFT JOIN tbl_dict_stateevent ste ON ar.col_autorulepartmplstateevent = ste.col_id
LEFT JOIN tbl_DICT_StateSlaAction dsa ON ar.col_DICT_StateSlaActionARP = dsa.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, cd.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tdt.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl,
ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction
FROM tbl_autoruleparamtmpl ar
JOIN tbl_taskdependencytmpl tdt ON ar.col_autoruleparamtptaskdeptp = tdt.col_id
JOIN tbl_map_taskstateinittmpl mti ON tdt.col_taskdpchldtptaskstinittp = mti.col_id
JOIN tbl_tasktemplate tt ON mti.col_map_taskstinittpltasktpl = tt.col_id
JOIN  tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamtpcasetype = cst.col_id
LEFT JOIN tbl_slaactiontmpl sa ON ar.col_autorulepartpslaactiontp = sa.col_id
LEFT JOIN tbl_casedependencytmpl cd ON ar.col_autoruleparamtpcasedeptp = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamtpparamconf = pc.col_id
LEFT JOIN tbl_caseeventtmpl ce ON ar.col_caseeventtpautorulepartp = ce.col_id
LEFT JOIN tbl_map_casestateinittmpl cit ON ar.col_rulepartp_casestateinittp = cit.col_id
LEFT JOIN tbl_map_taskstateinittmpl tit ON ar.col_rulepartp_taskstateinittp = tit.col_id
LEFT JOIN tbl_taskeventtmpl te ON ar.col_taskeventtpautoruleparmtp = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautorulepartp = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_tasktemplateautorulepartp = tt.col_id
LEFT JOIN tbl_dict_stateevent ste ON ar.col_autorulepartmplstateevent = ste.col_id
LEFT JOIN tbl_DICT_StateSlaAction dsa ON ar.col_DICT_StateSlaActionARP = dsa.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, cd.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tdt.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl,
ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction
FROM tbl_autoruleparamtmpl ar
JOIN tbl_taskdependencytmpl tdt ON ar.col_autoruleparamtptaskdeptp = tdt.col_id
JOIN tbl_map_taskstateinittmpl mti ON tdt.col_taskdpprnttptaskstinittp = mti.col_id
JOIN tbl_tasktemplate tt ON mti.col_map_taskstinittpltasktpl = tt.col_id
JOIN  tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamtpcasetype = cst.col_id
LEFT JOIN tbl_slaactiontmpl sa ON ar.col_autorulepartpslaactiontp = sa.col_id
LEFT JOIN tbl_casedependencytmpl cd ON ar.col_autoruleparamtpcasedeptp = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamtpparamconf = pc.col_id
LEFT JOIN tbl_caseeventtmpl ce ON ar.col_caseeventtpautorulepartp = ce.col_id
LEFT JOIN tbl_map_casestateinittmpl cit ON ar.col_rulepartp_casestateinittp = cit.col_id
LEFT JOIN tbl_map_taskstateinittmpl tit ON ar.col_rulepartp_taskstateinittp = tit.col_id
LEFT JOIN tbl_taskeventtmpl te ON ar.col_taskeventtpautoruleparmtp = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautorulepartp = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_tasktemplateautorulepartp = tt.col_id
LEFT JOIN tbl_dict_stateevent ste ON ar.col_autorulepartmplstateevent = ste.col_id
LEFT JOIN tbl_DICT_StateSlaAction dsa ON ar.col_DICT_StateSlaActionARP = dsa.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, cd.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tad.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, mti.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl,
ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction
FROM tbl_autoruleparamtmpl ar
JOIN tbl_map_taskstateinittmpl mti ON ar.col_rulepartp_taskstateinittp = mti.col_id
JOIN tbl_tasktemplate tt ON mti.col_map_taskstinittpltasktpl = tt.col_id
JOIN  tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
left JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamtpcasetype = cst.col_id
LEFT JOIN tbl_slaactiontmpl sa ON ar.col_autorulepartpslaactiontp = sa.col_id
LEFT JOIN tbl_casedependencytmpl cd ON ar.col_autoruleparamtpcasedeptp = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamtpparamconf = pc.col_id
LEFT JOIN tbl_taskdependencytmpl tad ON ar.col_autoruleparamtptaskdeptp = tad.col_id
LEFT JOIN tbl_caseeventtmpl ce ON ar.col_caseeventtpautorulepartp = ce.col_id
LEFT JOIN tbl_map_casestateinittmpl cit ON ar.col_rulepartp_casestateinittp = cit.col_id
LEFT JOIN tbl_taskeventtmpl te ON ar.col_taskeventtpautoruleparmtp = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautorulepartp = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_tasktemplateautorulepartp = tt.col_id
LEFT JOIN tbl_dict_stateevent ste ON ar.col_autorulepartmplstateevent = ste.col_id
LEFT JOIN tbl_DICT_StateSlaAction dsa ON ar.col_DICT_StateSlaActionARP = dsa.col_id
);


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT
Xmlagg(
  XMLELEMENT("AutoRuleParam",
            XMLFOREST(col_code       AS "Code",
                      col_issystem   AS "IsSystem",
                      col_paramvalue AS "ParamValue",
                      col_paramcode  AS "ParamCode",
                      SLAAction      AS "SLAAction",
                      CaseDep        AS "CaseDep",
                      CaseType       AS "CaseType",
                      ParamConf      AS "ParamConf",
                      TaskDep        AS "TaskDep",
                      CaseEvent      AS "CaseEvent",
                      CaseStateIni   AS "CaseStateIni",
                      TaskStateIni   AS "TaskStateIni",
                      TaskEvent      AS "TaskEvent",
                      TaskType       AS "TaskType",
                      TaskTempl      AS "TaskTempl")
                      )
)
INTO v_xml
FROM
(
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, cd.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tad.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl
FROM
tbl_autoruleparameter ar
JOIN tbl_paramconfig pc ON ar.col_autoruleparamparamconfig = pc.col_id
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamcasesystype = cst.col_id
LEFT JOIN tbl_slaaction sa ON ar.col_autoruleparamslaaction = sa.col_id
LEFT JOIN tbl_casedependency cd ON ar.col_autoruleparamcasedep = cd.col_id
LEFT JOIN tbl_taskdependency tad ON ar.col_autoruleparamtaskdep = tad.col_id
LEFT JOIN tbl_caseevent ce ON ar.col_caseeventautoruleparam = ce.col_id
LEFT JOIN tbl_map_casestateinitiation cit ON ar.col_ruleparam_casestateinit = cit.col_id
LEFT JOIN tbl_map_taskstateinitiation tit ON ar.col_ruleparam_taskstateinit = tit.col_id
LEFT JOIN tbl_taskevent te ON ar.col_taskeventautoruleparam = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautoruleparam = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_ttautoruleparameter= tt.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, cd.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tad.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl
FROM tbl_autoruleparameter ar
JOIN tbl_slaaction sa ON ar.col_autoruleparamslaaction = sa.col_id
JOIN tbl_slaevent se ON sa.col_slaactionslaevent = se.col_id
JOIN tbl_tasktemplate tt1 ON se.col_slaeventtasktemplate = tt1.col_id
JOIN tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamcasesystype = cst.col_id
LEFT JOIN tbl_casedependency cd ON ar.col_autoruleparamcasedep = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamparamconfig = pc.col_id
LEFT JOIN tbl_taskdependency tad ON ar.col_autoruleparamtaskdep = tad.col_id
LEFT JOIN tbl_caseevent ce ON ar.col_caseeventautoruleparam = ce.col_id
LEFT JOIN tbl_map_casestateinitiation cit ON ar.col_ruleparam_casestateinit = cit.col_id
LEFT JOIN tbl_map_taskstateinitiation tit ON ar.col_ruleparam_taskstateinit = tit.col_id
LEFT JOIN tbl_taskevent te ON ar.col_taskeventautoruleparam = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautoruleparam = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_ttautoruleparameter= tt.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, cd.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tad.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
tet.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl
FROM tbl_autoruleparameter ar
    JOIN tbl_taskevent tet ON ar.col_taskeventautoruleparam = tet.col_id
    JOIN TBL_MAP_TASKSTATEINITIATION tit1 ON tet.col_taskeventtaskstateinit  = tit1.col_id
    JOIN tbl_tasktemplate tt1 ON tit1.col_map_taskstateinittasktmpl = tt1.col_id
    JOIN tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamcasesystype = cst.col_id
LEFT JOIN tbl_slaaction sa ON ar.col_autoruleparamslaaction = sa.col_id
LEFT JOIN tbl_casedependency cd ON ar.col_autoruleparamcasedep = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamparamconfig = pc.col_id
LEFT JOIN tbl_taskdependency tad ON ar.col_autoruleparamtaskdep = tad.col_id
LEFT JOIN tbl_caseevent ce ON ar.col_caseeventautoruleparam = ce.col_id
LEFT JOIN tbl_map_casestateinitiation cit ON ar.col_ruleparam_casestateinit = cit.col_id
LEFT JOIN tbl_map_taskstateinitiation tit ON ar.col_ruleparam_taskstateinit = tit.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautoruleparam = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_ttautoruleparameter= tt.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, tmp.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tad.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl
FROM tbl_autoruleparameter ar
    JOIN tbl_casedependency tmp ON ar.col_autoruleparamcasedep = tmp.col_id
    JOIN tbl_map_taskstateinitiation mti ON tmp.col_casedpndchldtaskstateinit = mti.col_id
    JOIN tbl_tasktemplate tt1 ON mti.col_map_taskstateinittasktmpl = tt1.col_id
    JOIN tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamcasesystype = cst.col_id
LEFT JOIN tbl_slaaction sa ON ar.col_autoruleparamslaaction = sa.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamparamconfig = pc.col_id
LEFT JOIN tbl_taskdependency tad ON ar.col_autoruleparamtaskdep = tad.col_id
LEFT JOIN tbl_caseevent ce ON ar.col_caseeventautoruleparam = ce.col_id
LEFT JOIN tbl_map_casestateinitiation cit ON ar.col_ruleparam_casestateinit = cit.col_id
LEFT JOIN tbl_map_taskstateinitiation tit ON ar.col_ruleparam_taskstateinit = tit.col_id
LEFT JOIN tbl_taskevent te ON ar.col_taskeventautoruleparam = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautoruleparam = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_ttautoruleparameter= tt.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, tmp.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tad.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl
FROM tbl_autoruleparameter ar
    JOIN tbl_casedependency tmp ON ar.col_autoruleparamcasedep = tmp.col_id
    JOIN tbl_map_taskstateinitiation mti ON tmp.col_casedpndprnttaskstateinit = mti.col_id
    JOIN tbl_tasktemplate tt1 ON mti.col_map_taskstateinittasktmpl = tt1.col_id
    JOIN  tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamcasesystype = cst.col_id
LEFT JOIN tbl_slaaction sa ON ar.col_autoruleparamslaaction = sa.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamparamconfig = pc.col_id
LEFT JOIN tbl_taskdependency tad ON ar.col_autoruleparamtaskdep = tad.col_id
LEFT JOIN tbl_caseevent ce ON ar.col_caseeventautoruleparam = ce.col_id
LEFT JOIN tbl_map_casestateinitiation cit ON ar.col_ruleparam_casestateinit = cit.col_id
LEFT JOIN tbl_map_taskstateinitiation tit ON ar.col_ruleparam_taskstateinit = tit.col_id
LEFT JOIN tbl_taskevent te ON ar.col_taskeventautoruleparam = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautoruleparam = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_ttautoruleparameter= tt.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, cd.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tdt.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl
FROM tbl_autoruleparameter ar
    JOIN tbl_taskdependency tdt ON ar.col_autoruleparamtaskdep = tdt.col_id
    JOIN tbl_map_taskstateinitiation mti ON tdt.col_tskdpndchldtskstateinit = mti.col_id
    JOIN tbl_tasktemplate tt1 ON mti.col_map_taskstateinittasktmpl = tt1.col_id
    JOIN  tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamcasesystype = cst.col_id
LEFT JOIN tbl_slaaction sa ON ar.col_autoruleparamslaaction = sa.col_id
LEFT JOIN tbl_casedependency cd ON ar.col_autoruleparamcasedep = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamparamconfig = pc.col_id
LEFT JOIN tbl_caseevent ce ON ar.col_caseeventautoruleparam = ce.col_id
LEFT JOIN tbl_map_casestateinitiation cit ON ar.col_ruleparam_casestateinit = cit.col_id
LEFT JOIN tbl_map_taskstateinitiation tit ON ar.col_ruleparam_taskstateinit = tit.col_id
LEFT JOIN tbl_taskevent te ON ar.col_taskeventautoruleparam = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautoruleparam = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_ttautoruleparameter= tt.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, cd.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tdt.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, tit.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl
FROM tbl_autoruleparameter ar
    JOIN tbl_taskdependency tdt ON ar.col_autoruleparamtaskdep = tdt.col_id
    JOIN tbl_map_taskstateinitiation mti ON tdt.col_tskdpndprnttskstateinit = mti.col_id
    JOIN tbl_tasktemplate tt1 ON mti.col_map_taskstateinittasktmpl = tt1.col_id
    JOIN  tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamcasesystype = cst.col_id
LEFT JOIN tbl_slaaction sa ON ar.col_autoruleparamslaaction = sa.col_id
LEFT JOIN tbl_casedependency cd ON ar.col_autoruleparamcasedep = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamparamconfig = pc.col_id
LEFT JOIN tbl_caseevent ce ON ar.col_caseeventautoruleparam = ce.col_id
LEFT JOIN tbl_map_casestateinitiation cit ON ar.col_ruleparam_casestateinit = cit.col_id
LEFT JOIN tbl_map_taskstateinitiation tit ON ar.col_ruleparam_taskstateinit = tit.col_id
LEFT JOIN tbl_taskevent te ON ar.col_taskeventautoruleparam = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautoruleparam = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_ttautoruleparameter= tt.col_id
UNION
SELECT
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code,
sa.col_code SLAAction, cd.col_code CaseDep, cst.col_code AS CaseType,
pc.col_code ParamConf, tad.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, mti.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl
FROM tbl_autoruleparameter ar
    JOIN tbl_map_taskstateinitiation mti ON ar.col_ruleparam_taskstateinit = mti.col_id
    JOIN tbl_tasktemplate tt1 ON mti.col_map_taskstateinittasktmpl = tt1.col_id
    JOIN  tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamcasesystype = cst.col_id
LEFT JOIN tbl_slaaction sa ON ar.col_autoruleparamslaaction = sa.col_id
LEFT JOIN tbl_casedependency cd ON ar.col_autoruleparamcasedep = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamparamconfig = pc.col_id
LEFT JOIN tbl_taskdependency tad ON ar.col_autoruleparamtaskdep = tad.col_id
LEFT JOIN tbl_caseevent ce ON ar.col_caseeventautoruleparam = ce.col_id
LEFT JOIN tbl_map_casestateinitiation cit ON ar.col_ruleparam_casestateinit = cit.col_id
LEFT JOIN tbl_taskevent te ON ar.col_taskeventautoruleparam = te.col_id
LEFT JOIN tbl_dict_tasksystype tst ON ar.col_tasksystypeautoruleparam = tst.col_id
LEFT JOIN tbl_tasktemplate tt ON ar.col_ttautoruleparameter= tt.col_id
);


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT Xmlagg(
  XMLELEMENT("FomPage",
            XMLFOREST(fp.col_code  "Code",
                      fp.col_name AS "Name",
                      fp.col_description   AS "Description",
                      fp.col_isdeleted AS "Isdeleted",
                      fp.col_fieldvalues AS "FieldValues",
                      fp.col_usedfor AS "UsedFor",
                      fp.col_config AS "Config",
                      fp.col_systemdefault AS "SystemDefault")
             )
         )
INTO v_xml
FROM TBL_FOM_Page fp
WHERE col_id IN
(SELECT assp.col_assocpagepage
FROM tbl_ASSOCPAGE assp
WHERE EXISTS
(SELECT 1 FROM tbl_tasktemplate tt2, tbl_procedure pr WHERE assp.col_assocpagetasktemplate = tt2.col_id
    AND tt2.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
)
OR EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tstt, tbl_tasktemplate tt3, tbl_procedure pr2  WHERE assp.col_assocpagedict_tasksystype = tstt.col_id
AND tstt.col_id = tt3.col_tasktmpldict_tasksystype AND tt3.col_proceduretasktemplate = pr2.col_id
AND pr2.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
)
OR (
assp.col_partytypeassocpage IN  (SELECT col_id FROM tbl_dict_partytype)
)
)
OR
fp.col_systemdefault = 1;


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
Xmlagg(
  XMLELEMENT("CommonEventTmpl",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_eventorder        AS "EventOrder",
                      t.col_processorcode     AS "ProcessorCode",
                      t.col_name              AS "Name",
                      t.col_ucode             AS "Ucode",
                      cet.col_code            AS "CommonEventType",
                      tem.col_code            AS "TaskEventMoment",
                      tes.col_code            AS "TaskEventSyncType",
                      tet.col_code            AS "TaskEventType",
                      cst.col_code            AS "CaseType",
                      p.col_code              AS "Procedure",
                      tt.col_code             AS "TaskTemplate",
                      tst.col_code            AS "TaskType"											
											)
             )
         ) 
INTO v_xml    
FROM 
tbl_commoneventtmpl t
LEFT JOIN tbl_dict_commoneventtype cet ON t.col_comeventtmplcomeventtype = cet.col_id
LEFT JOIN tbl_dict_taskeventmoment tem ON t.col_comevttmplevtmmnt = tem.col_id
LEFT JOIN tbl_dict_taskeventsynctype tes ON t.col_comevttmplevtsynct = tes.col_id
LEFT JOIN tbl_dict_taskeventtype tet ON t.col_comevttmpltaskevtt   = tet.col_id
LEFT JOIN tbl_dict_casesystype cst ON t.col_commoneventtmplcasetype   = cst.col_id
LEFT JOIN tbl_procedure p ON t.col_commoneventtmplprocedure  = p.col_id
LEFT JOIN tbl_tasktemplate tt ON t.col_commoneventtmpltasktmpl  = tt.col_id
LEFT JOIN tbl_dict_tasksystype tst ON t.col_commoneventtmpltasktype  = tst.col_id
WHERE (p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))))
OR 
      (EXISTS 
              ( SELECT 1 FROM tbl_tasktemplate tats, tbl_procedure pr WHERE tats.col_tasktmpldict_tasksystype = tst.col_id 
                  AND tats.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) 
                  )
      )
OR 
      ( EXISTS (SELECT 1 FROM tbl_procedure proc WHERE proc.col_id = tt.col_proceduretasktemplate
                    AND proc.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))))
      );

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
Xmlagg(
  XMLELEMENT("CommonEvent",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_eventorder        AS "EventOrder",
                      t.col_processorcode     AS "ProcessorCode",
                      t.col_name              AS "Name",
                      cet.col_code            AS "CommonEventType",
                      cst.col_code            AS "CaseType",
                      tt.col_code             AS "TaskTemplate",
                      tst.col_code            AS "TaskType",
                      tem.col_code            AS "TaskEventMoment",
                      tes.col_code            AS "TaskEventSyncType",
                      tet.col_code            AS "TaskEventType",
					  p.col_code              AS "Procedure",
					  t.col_isprocessed       AS "IsProcessed",
					  t.col_linkcode          AS "LinkCode",
				      t.col_ucode             AS "Ucode"
			)
            )
         ) 
INTO v_xml   
FROM tbl_commonevent t
LEFT JOIN tbl_dict_commoneventtype cet ON t.col_comeventcomeventtype = cet.col_id
LEFT JOIN tbl_dict_casesystype cst ON t.col_commoneventcasetype = cst.col_id
LEFT JOIN tbl_tasktemplate tt ON t.col_commoneventtasktmpl = tt.col_id
LEFT JOIN tbl_dict_tasksystype tst ON t.col_commoneventtasktype = tst.col_id
LEFT JOIN tbl_dict_taskeventmoment tem ON t.col_commoneventeventmoment = tem.col_id
LEFT JOIN tbl_dict_taskeventsynctype tes ON t.col_commoneventeventsynctype = tes.col_id
LEFT JOIN tbl_procedure p ON t.col_commoneventprocedure = p.col_id
LEFT JOIN tbl_dict_taskeventtype tet ON t.col_commoneventtaskeventtype = tet.col_id
WHERE (t.col_commoneventtasktmpl IS NOT NULL AND EXISTS (SELECT 1 FROM tbl_procedure proc WHERE proc.col_id = tt.col_proceduretasktemplate
             AND proc.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) ))
OR    (t.col_commoneventtasktype IS NOT NULL AND EXISTS 
              ( SELECT 1 FROM tbl_tasktemplate tats, tbl_procedure pr WHERE tats.col_tasktmpldict_tasksystype = tst.col_id 
                  AND tats.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) 
                  ))
OR (t.col_commoneventprocedure IS NOT NULL AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))));


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

dbms_lob.append(v_clob, '</ProcedureAddition>');

RETURN v_clob;





EXCEPTION
  WHEN OTHERS THEN
 ROLLBACK;
 RETURN dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
END;
