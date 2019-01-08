DECLARE
v_xml        XMLTYPE;
v_clob       NCLOB := EMPTY_CLOB();
BEGIN

dbms_lob.createtemporary(v_clob,true);
DBMS_LOB.OPEN(v_clob, 1);
dbms_lob.append(v_clob,'<Dictionary>');

SELECT
Xmlagg(
XMLELEMENT("DictAccessType",
                 XMLELEMENT("Code", rc.col_code),
                 XMLELEMENT("Name", rc.col_name),
                 XMLELEMENT("Owner", rc.col_owner)
                 )
)
 INTO v_xml
FROM
TBL_DICT_ACCESSTYPE rc;



if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT
Xmlagg(
XMLELEMENT("DictActionType",
                 XMLFOREST(rc.col_code          AS "Code",
                           rc.col_name          AS "Name", 
                           rc.col_owner         AS "Owner", 
                           rc.col_description   AS "Description",
                           rc.col_processorcode AS "ProcessorCode", 
                           rc.col_SlaProcessorCode AS "SlaProcessorCode",
                           rc.col_msprocessorcode AS "MSProcessorCode",
                           rc.col_iscasetype    AS "IsCaseType",
                           rc.col_isdoctype     AS "IsDocType",
                           rc.col_isparty       AS "IsParty",
                           rc.col_isprocedure   AS "IsProcedure",
                           rc.col_istasktype    AS "IsTaskType",
                           et.col_code          AS "TaskEventType") 
                 )
       )
 INTO v_xml
FROM
TBL_DICT_ACTIONTYPE rc
LEFT JOIN tbl_dict_taskeventtype et ON rc.col_actiontype_taskeventtype = et.col_id;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT

Xmlagg(
XMLELEMENT("DictBusinessObject",
                 XMLELEMENT("Code", rc.col_code),
                 XMLELEMENT("Name", rc.col_name),
                 XMLELEMENT("Owner", rc.col_owner),
                 XMLELEMENT("IsDeleted", rc.col_isdeleted)
                 )
                 )
 INTO v_xml
FROM
TBL_DICT_BUSINESSOBJECT rc;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
Xmlagg(
XMLELEMENT("DictDataType",
                 XMLELEMENT("Code", rc.col_code),
                 XMLELEMENT("Name", rc.col_name),
                 XMLELEMENT("Owner", rc.col_owner),
                 XMLELEMENT("IsDeleted", rc.col_isdeleted),
                 XMLELEMENT("Description", rc.col_description),
                 XMLELEMENT("IconCode", rc.col_iconcode ),
                 XMLELEMENT("SearchType", rc.col_searchtype ),
                 XMLELEMENT("DOrder", rc.col_dorder  ),
                 XMLELEMENT("TypeCode", rc.col_typecode),
                 XMLELEMENT("Processorcode", rc.col_processorcode),
                 XMLELEMENT("Parentdatatype", rc1.col_code)
                 
                 )
)
INTO v_xml
FROM
TBL_DICT_DATATYPE rc
LEFT JOIN TBL_DICT_DATATYPE rc1 ON rc.col_datatypeparentdatatype = rc1.col_id;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;



/*
SELECT
Xmlconcat(v_xml,
  Xmlagg(
  XMLELEMENT("DictDocExtension",
                   XMLELEMENT("Extension", ext.col_extension),
                   XMLELEMENT("Name", ext.col_name),
                   XMLELEMENT("Owner", ext.col_owner),
                   XMLELEMENT("Icon", ext.col_icon)
                   )
                   ))
  INTO v_xml
FROM
TBL_DICT_DOCEXTENSION ext;*/


SELECT 
  Xmlagg(
  XMLELEMENT("DictDocumentType",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner", 
                      t.col_description AS "Description",                       
                      t.col_isdeleted AS "IsDeleted"  )
             )
         ) 

INTO v_xml       
FROM tbl_dict_documenttype t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;



SELECT 
  Xmlagg(
  XMLELEMENT("DictExportContentType",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner")
             )
         ) 
INTO v_xml       
FROM tbl_dict_exportcontenttype t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("DictItemType",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner")
             )
         ) 
INTO v_xml       
FROM TBL_DICT_ITEMTYPE t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("DictNotificationObject",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner")
             )
         ) 
INTO v_xml       
FROM TBL_DICT_NOTIFICATIONOBJECT t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
 Xmlagg(
  XMLELEMENT("Message",
            XMLFOREST(t.col_code  "Code", 
                      t.col_template  AS "Template", 
                      t.col_description  AS "Description",
                      mt.col_code AS "MessageType")
             )
         )
into v_xml         
FROM 
TBL_MESSAGE t
LEFT JOIN tbl_dict_messagetype mt ON t.col_messagetypemessage = mt.col_id;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("DictNotificationType",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner",
                      no.col_code AS "NotificationObject",
                      ms.col_code AS "Message")
             )
         ) 
INTO v_xml       
FROM  tbl_dict_notificationtype t 
LEFT JOIN TBL_DICT_NOTIFICATIONOBJECT no ON t.col_notifictypenotifobject = no.col_id
LEFT JOIN tbl_message ms ON t.col_notificationtypemessage = ms.col_id ;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
  Xmlagg(
  XMLELEMENT("DictOperation",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner")
             )
         ) 
INTO v_xml       
FROM TBL_DICT_OPERATION t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;



SELECT 
  Xmlagg(
  XMLELEMENT("DictProcessingStatus",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner")
             )
         ) 

INTO v_xml       
FROM TBL_DICT_PROCESSINGSTATUS t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
  Xmlagg(
  XMLELEMENT("DictWorkActivityType",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner",
                      t.col_description AS "Description",
                      t.col_iconcode AS "IconCode",
                      t.col_isdeleted AS "IsDeleted")
             )
         ) 
INTO v_xml       
FROM TBL_DICT_WORKACTIVITYTYPE t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("DictTaskEventSyncType",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner")
             )
         ) 
INTO v_xml       
FROM TBL_DICT_TASKEVENTSYNCTYPE t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("DictTagType",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner")
             )
         ) 
INTO v_xml       
FROM tbl_dict_tagtype t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("DictTag",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner",
                      tt.col_code AS "TagType" )
             )
         ) 
INTO v_xml       
FROM tbl_dict_tag t
LEFT JOIN tbl_dict_tagtype tt ON t.col_dict_tagdict_tagtype = tt.col_id ;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
Xmlagg(
XMLELEMENT("CaseState",
           XMLFOREST(cst.col_activity AS "Activity",
                     cst.col_code AS "Code",
                     cst.col_name AS "Name",
                     cst.col_description AS "Description",
                     cst.col_isassign AS "IsAssign",
                     cst.col_isdefaultoncreate AS "IsDefaultonCreate", 
                     cst.col_isdefaultoncreate2 AS "IsDefaultonCreate2",
                     cst.col_defaultorder AS "DefaultOrder",
                     cst.col_isdeleted AS "IsDeleted",
                     cst.col_isfinish AS "IsFinish",
                     cst.col_isfix AS "IsFix",
                     cst.col_ishidden AS "IsHidden",
                     cst.col_isresolve AS "IsResolve",
                     cst.col_isstart AS "IsStart",
                     sc.col_code AS "Config",
                     cst.col_ucode AS "Ucode",
                     cst.col_iconcode AS "IconCode",
                     cst.col_theme AS "Theme")
                  )
)
INTO v_xml
FROM tbl_dict_casestate cst
LEFT JOIN tbl_dict_stateconfig sc ON cst.col_stateconfigcasestate = sc.col_id
LEFT JOIN tbl_DICT_StateConfigType dsct ON sc.col_stateconfstateconftype =  dsct.col_id
WHERE cst.col_stateconfigcasestate IS NULL
OR sc.col_code = 'DEFAULT_CASE'
OR dsct.col_code = 'DOCUMENT'
;


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


/*not move yet*/
SELECT
Xmlagg(
XMLELEMENT("CaseTransition",
                  XMLELEMENT("Ucode", ct.col_ucode), 
                  XMLELEMENT("Code", ct.col_code),
                  XMLELEMENT("Name", ct.col_Name),
                  XMLELEMENT("Description", ct.col_description),
                  XMLELEMENT("Transition", ct.col_transition),
                  XMLELEMENT("Manualonly", ct.col_manualonly),
                  XMLELEMENT("IconCode", ct.col_iconcode),
                  XMLELEMENT("IsNextDefault", ct.col_isnextdefault),
                  XMLELEMENT("IsPrevDefault", ct.col_isprevdefault),
                  XMLELEMENT("CodeSource", dcs1.col_ucode),
                  XMLELEMENT("CodeTarget", dcs2.col_ucode)
                                     )
                  )

INTO v_xml
FROM tbl_dict_casetransition ct
  JOIN tbl_dict_casestate dcs1 ON ct.col_sourcecasetranscasestate = dcs1.col_id
  LEFT JOIN tbl_dict_stateconfig conf ON dcs1.col_stateconfigcasestate = conf.col_id
  JOIN tbl_dict_casestate dcs2 ON ct.col_targetcasetranscasestate = dcs2.col_id 
  LEFT JOIN tbl_dict_stateconfig conf2 ON dcs2.col_stateconfigcasestate = conf2.col_id
WHERE 
(dcs1.col_stateconfigcasestate IS NULL 
OR 
conf.col_code = 'DEFAULT_CASE'
)
AND 
(dcs2.col_stateconfigcasestate IS NULL
OR
conf2.col_code = 'DEFAULT_CASE'
)
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
Xmlagg(
XMLELEMENT("ResolutionCode",
                 XMLELEMENT("Code", rc.col_code),
                 XMLELEMENT("Description", rc.col_description),
                 XMLELEMENT("IsDeleted", rc.col_isdeleted),
                 XMLELEMENT("Name", rc.col_name),
                 XMLELEMENT("Type", rc.col_type),
                 XMLELEMENT("CellStyle", rc.col_cellstyle),
                 XMLELEMENT("RowStyle", rc.col_rowstyle),
                 XMLELEMENT("TextStyle", rc.col_textstyle),
                 XMLELEMENT("Ucode", rc.col_ucode),
                 XMLELEMENT("IconCode", rc.col_iconcode),
                 XMLELEMENT("Theme", rc.col_theme)
                 )
                 )
 INTO v_xml
FROM
TBL_STP_RESOLUTIONCODE rc
WHERE rc.col_type IS NULL 
   OR rc.col_type = 'TASK';

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT
Xmlagg(
XMLELEMENT("TaskType",
                 XMLFOREST(tst.col_code                  AS "Code",
                           tst.col_name                  AS "Name", 
                           tst.col_description           AS "Description",
                           tst.col_customdataprocessor   AS "CustomDataProcessor", 
                           tst.col_dateeventcustdataproc AS "DateEventCustDataProc",
                           tst.col_isdeleted             AS "IsDeleted",
                           tst.col_processorcode         AS "ProcessorCode",
                           tst.col_retcustdataprocessor  AS "RetCustDataProcessor",
                           tst.col_updatecustdataprocessor AS "UpdateCustDataProcessor",
                           em.col_code                   AS "TaskSysTypeExecMethod",
                           sc.col_code                   AS "StateConfig",
                           tst.col_routecustomdataprocessor AS "RouteCustomDataProcessor", 
                           tst.col_iconcode              AS "IconCode",
                           tst.col_pagecode              AS "PageCode",
                           tst.col_uimode                AS "UiMode" )
                 )
)
 INTO v_xml
FROM
Tbl_Dict_Tasksystype tst
LEFT JOIN tbl_dict_executionmethod em ON tst.col_tasksystypeexecmethod = em.col_id
LEFT JOIN tbl_dict_stateconfig  sc ON tst.col_stateconfigtasksystype = sc.col_id
WHERE tst.col_stateconfigtasksystype IS NULL
OR sc.col_code ='DEFAULT_TASK'
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT Xmlagg(
        XMLELEMENT("TaskSysTypeResolutionCode",
               xmlforesT (tstrc.col_code AS "Code",
                          rc.col_code    AS "ResolutionCode",
                          tst.col_code   AS "TaskType")
               )
        )      
INTO  v_xml                 
FROM TBL_TASKSYSTYPERESOLUTIONCODE tstrc
JOIN Tbl_Dict_Tasksystype tst ON tstrc.col_tbl_dict_tasksystype = tst.col_id 
AND (tst.col_stateconfigtasksystype IS NULL 
OR tst.col_stateconfigtasksystype IN (SELECT col_id FROM tbl_dict_stateconfig WHERE col_code = 'DEFAULT_TASK'))
JOIN tbl_stp_resolutioncode rc ON tstrc.col_tbl_stp_resolutioncode = rc.col_id;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
Xmlagg(
XMLELEMENT("TaskState",
           XMLELEMENT("Activity", col_activity ),
           XMLELEMENT("CanAssign", col_canassign),
           XMLELEMENT("Code", ts.col_code),
           XMLELEMENT("Name", ts.col_name),
           XMLELEMENT("DefaultOrder", col_defaultorder),
           XMLELEMENT("Description", col_description),
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
LEFT JOIN tbl_dict_stateconfig conf ON ts.col_stateconfigtaskstate = conf.col_id 
WHERE ts.col_stateconfigtaskstate IS NULL
or conf.col_code = 'DEFAULT_TASK';

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
      Xmlagg(Xmlelement("SlaEventType",
              Xmlelement("Code", setp.col_code),
              Xmlelement("IntervalDS", setp.col_intervalds),
              Xmlelement("IntervalYM", setp.col_intervalym),
              Xmlelement("Name", setp.col_name),
              Xmlelement("IsDeleted", setp.col_isdeleted),
              Xmlelement("Description", setp.col_description)
              )
              )
   INTO
  v_xml              
FROM tbl_dict_slaeventtype setp;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
        Xmlagg(Xmlelement("SlaEventLevel", 
               Xmlelement("Code", sel.col_code),
               Xmlelement("Name", sel.col_name),
               Xmlelement("Description", sel.col_description),
               Xmlelement("IsDeleted", sel.col_isdeleted)
               )
               )
   INTO
  v_xml                 
FROM tbl_dict_slaeventlevel sel; 

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
Xmlagg(Xmlelement("TaskTransition",
                         Xmlforest(trt.col_code        AS "Code",
                                   trt.col_description AS "Description",
                                   trt.col_manualonly  AS "ManualOnly",
                                   trt.col_name        AS "Name",
                                   trt.col_transition  AS "Transition",
                                   tst.col_ucode       AS "Source",
                                   tst2.col_ucode      AS "Target",
                                   trt.col_ucode       AS "Ucode",
                                   trt.col_iconcode    AS "IconCode")
                         )
)
 INTO v_xml                          
FROM tbl_dict_tasktransition trt
JOIN tbl_dict_taskstate tst ON trt.col_sourcetasktranstaskstate = tst.col_id   
LEFT JOIN tbl_dict_stateconfig conf ON tst.col_stateconfigtaskstate = conf.col_id
JOIN tbl_dict_taskstate tst2 ON trt.col_targettasktranstaskstate = tst2.col_id 
LEFT JOIN tbl_dict_stateconfig conf2 ON tst2.col_stateconfigtaskstate = conf2.col_id
WHERE 
( tst.col_stateconfigtaskstate IS NULL 
OR conf.col_code ='DEFAULT_TASK'
)
AND 
( tst2.col_stateconfigtaskstate IS NULL
OR conf2.col_code ='DEFAULT_TASK'
);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
Xmlagg(Xmlelement("FomUielementType",
                         Xmlelement("Code",       fue.col_code),
                         Xmlelement("Name",fue.col_name)

                         )
                         )
 INTO v_xml
FROM TBL_FOM_UIELEMENTTYPE fue;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
Xmlagg(Xmlelement("STPPriority",
               Xmlelement("Code", sp.col_code),
               Xmlelement("Icon", sp.col_icon),
               Xmlelement("IconCode", sp.col_iconcode),
               Xmlelement("IconName", sp.col_iconname),
               Xmlelement("IsDefault", sp.col_isdefault),
               Xmlelement("Name", sp.col_name),
               Xmlelement("Value", sp.col_value),
               Xmlelement("Description", sp.col_description),
               Xmlelement("IsDeleted", sp.col_isdeleted)
               )
      ) 
INTO v_xml                
FROM 
tbl_STP_PRIORITY sp;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
Xmlagg(Xmlelement("ParticipantType",
               Xmlelement("Code", ptpt.col_code),
               Xmlelement("Description", ptpt.col_description),
               Xmlelement("Name", ptpt.col_name),
               Xmlelement("Owner", ptpt.col_owner)
               )
       )
INTO v_xml                 
FROM tbl_dict_participanttype ptpt;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;



SELECT 
Xmlagg(Xmlelement("AssocpageType",
               Xmlelement("Code", dasp.col_code),
               Xmlelement("Description", dasp.col_description),
               Xmlelement("Name", dasp.col_name),
               Xmlelement("Owner", dasp.col_owner),
               Xmlelement("AllowMultiple", col_allowmultiple)
               )
       )
INTO v_xml                
FROM 
tbl_DICT_ASSOCPAGETYPE  dasp;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
Xmlagg(Xmlelement("PartyType",
               XMLFOREST(dpt.col_code        AS "Code",
                         dpt.col_description AS "Description",
                         dpt.col_isdeleted   AS "IsDeleted", 
                         dpt.col_issystem    AS "IsSystem",
                         dpt.col_name        AS "Name", 
                         dpt.col_owner       AS "Owner",
                         dpt.col_pagecode    AS "PageCode",
                         ptpt.col_code       AS "ParticipantType",
                         dpt.col_customdataprocessor AS "CustomDataProcessor",
                         dpt.col_delcustdataprocessor AS "DelCustomDataProcessor",
                         dpt.col_retcustdataprocessor AS "RetCustDataProcessor", 
                         dpt.col_updatecustdataprocessor AS "UpdateCustDataProcessor",
                         dpt.col_disablemanagement AS "DisableManagement",
                         mdm.col_ucode             AS "MdmModel") 
               )
      )
INTO v_xml       
FROM tbl_dict_partytype dpt
LEFT JOIN tbl_dict_participanttype ptpt ON dpt.col_partytypeparticiptype = ptpt.col_id
LEFT JOIN tbl_mdm_model mdm ON dpt.col_partytypemodel = mdm.col_id;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
Xmlagg(Xmlelement("WorkbasketType",
                  Xmlelement("Code", wbt.col_code),
                  Xmlelement("Name", wbt.col_name),
                  Xmlelement("Owner", wbt.col_owner)
                  )
      ) 
INTO v_xml                          
FROM tbl_dict_workbaskettype wbt;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
           Xmlagg(Xmlelement("WorkBasket",
                         Xmlelement("Code", t.col_code),
                         Xmlelement("Description", t.col_description),
                         Xmlelement("IsDefault", t.col_isdefault),
                         Xmlelement("IsPrivate", t.col_isprivate),
                         Xmlelement("Name", t.col_name),
                         Xmlelement("ProcessorCode", t.col_processorcode),
                         Xmlelement("ProcessorCode2", t.col_processorcode2),
                         Xmlelement("ProcessorCode3", t.col_processorcode3),
                         Xmlelement("WorkbasketType", wbt.col_code),
                         Xmlelement("Team", null),
                         Xmlelement("BusinessRole", null),
                         Xmlelement("Ucode", t.col_ucode)
                         )
              )
INTO v_xml
FROM TBL_PPL_WORKBASKET t
JOIN tbl_dict_workbaskettype wbt 
ON t.col_workbasketworkbaskettype = wbt.col_id 
WHERE t.col_code = 'DOCUMENT_INDEXING_EMAIL';

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
           Xmlagg(Xmlelement("DateEventType",
              XMLFOREST( det.col_canoverwrite AS "CanOverWrite",
                         det.col_code         AS "Code",
                         det.col_isslaend     AS "IsSlaEnd",
                         det.col_isslastart   AS "IsSlaStart",
                         det.col_isstate      AS "IsSlaState",
                         det.col_multipleallowed AS "Multipleallowed",
                         det.col_name            AS "Name",
                         det.col_description     AS "Description",
                         det.col_isdeleted       AS "IsDeleted", 
                         det.col_type            AS "Type",
                         det.col_iscasemainflag  AS "IsCaseMainFlag" )
)
)
INTO v_xml  
FROM tbl_DICT_DATEEVENTTYPE det;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
       Xmlagg(Xmlelement("InitMetod",
              Xmlelement("Code", im.col_code),
              Xmlelement("Description", im.col_description),
              Xmlelement("Name", im.col_name)
              )
              )
INTO v_xml               
FROM TBL_DICT_INITMETHOD im;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
       Xmlagg(Xmlelement("TaskEventMoment",
              Xmlelement("Code", dtem.col_code),
              Xmlelement("Name", dtem.col_name)
              )
              )
INTO v_xml                
FROM 
TBL_DICT_TASKEVENTMOMENT dtem;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

/* it is need remove */
SELECT 
        Xmlagg(Xmlelement("CaseStateDateEventType",
              Xmlelement("CaseState", cstat.col_ucode), 
              Xmlelement("DateEventType", det.col_code),
              Xmlelement("Config", conf.col_code)
              )
              )

INTO v_xml                  
FROM TBL_DICT_CSEST_DTEVTP cset
JOIN tbl_dict_casestate cstat ON cset.col_csest_dtevtpcasestate = cstat.col_id 
LEFT JOIN tbl_dict_stateconfig conf ON cstat.col_stateconfigcasestate = conf.col_id
JOIN tbl_dict_dateeventtype det ON cset.col_csest_dtevtpdateeventtype = det.col_id
WHERE cstat.col_stateconfigcasestate IS NULL
OR conf.col_code = 'DEFAULT_CASE'
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
       Xmlagg(Xmlelement("TaskStateDateEventType",
              Xmlelement("TaskState", tst.col_ucode), 
              Xmlelement("DateEventType", ddt.col_code)
              )
              )
INTO v_xml                
FROM TBL_DICT_TSKST_DTEVTP tsdet
JOIN tbl_dict_dateeventtype ddt ON tsdet.col_tskst_dtevtpdateeventtype = ddt.col_id
JOIN tbl_dict_taskstate tst ON  tsdet.col_tskst_dtevtptaskstate = tst.col_id
LEFT JOIN tbl_dict_stateconfig conf ON tst.col_stateconfigtaskstate = conf.col_id
WHERE tst.col_stateconfigtaskstate IS NULL
OR conf.col_code = 'DEFAULT_TASK'
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

/* end it is need remove */

SELECT 
       Xmlagg(Xmlelement("TaskEventType",
              Xmlelement("Code", tet.col_code),
              Xmlelement("Name", tet.col_name)
              )
              ) 
INTO v_xml               
FROM 
TBL_DICT_TASKEVENTTYPE tet;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
       Xmlagg(Xmlelement("ValidationStatus",
              Xmlelement("Code", vs.col_code),
              Xmlelement("Description", vs.col_description)
              )
              ) 
INTO v_xml               
FROM 
tbl_DICT_VALIDATIONSTATUS vs;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
       Xmlagg(Xmlelement("DependencyType",
              Xmlelement("Code",dtp.col_code),
              Xmlelement("Description", dtp.col_description),
              Xmlelement("Name", dtp.col_name)
                     )
              ) 

INTO v_xml
FROM  TBL_DICT_DEPENDENCYTYPE dtp;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
       Xmlagg(Xmlelement("PatamType",
              Xmlelement("Code",dtp.col_code),
              Xmlelement("ProcessorCode", dtp.col_processorcode),
              Xmlelement("Name", dtp.col_name)
                     )
              ) 

INTO v_xml
FROM 
TBL_DICT_PARAMTYPE dtp; 

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("DictExecutionMethod",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner", 
                      t.col_description AS "Description", 
                      t.col_isdeleted AS "IsDeleted"  )
             )
         ) 
INTO v_xml       
FROM TBL_DICT_EXECUTIONMETHOD t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
       Xmlagg(Xmlelement("CaseStateSetup",
             Xmlelement("Code", cset.col_code),
             Xmlelement("FofsedNull", cset.col_forcednull),
             Xmlelement("ForcedOverWrite", cset.col_forcedoverwrite),
             Xmlelement("Name", cset.col_name),
             Xmlelement("NotNullOverWrite", cset.col_notnulloverwrite),
             Xmlelement("CaseState", cstat.col_ucode),
             Xmlelement("CaseConfig", stscong.col_code),
             Xmlelement("NullOverWrite", cset.col_nulloverwrite),
             Xmlelement("Ucode", cset.col_ucode)
             )
             )

INTO v_xml
FROM tbl_dict_CASESTATESETUP cset
LEFT JOIN tbl_dict_casestate cstat ON cset.col_casestatesetupcasestate = cstat.col_id 
LEFT JOIN tbl_dict_stateconfig stscong ON cstat.col_stateconfigcasestate = stscong.col_id
WHERE 
(
/*stscong.col_code IS NULL OR */
stscong.col_code = 'DEFAULT_CASE' 
);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
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

INTO v_xml
FROM tbl_DICT_TASKSTATESETUP tstp
LEFT JOIN tbl_dict_taskstate tstk ON  tstp.col_taskstatesetuptaskstate = tstk.col_id
LEFT JOIN tbl_dict_stateconfig stscong ON tstk.col_stateconfigtaskstate = stscong.col_id
WHERE
/* stscong.col_code IS NULL
 OR */
 stscong.col_code = 'DEFAULT_TASK';

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT
  Xmlagg(
  XMLELEMENT("ParticipantUnitType",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner", 
                      t.col_description AS "Description", 
                      t.col_getprocessorcode  AS "GetProcessorCode"  )
             )
         ) 

INTO v_xml       
FROM tbl_DICT_ParticipantUnitType t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
     Xmlagg(Xmlelement("AccessObjectType",
                         Xmlelement("Code",         aot.col_code),  
                         Xmlelement("Name",         aot.col_name), 
                         Xmlelement("Description",  aot.col_description),
                         Xmlelement("IsDelete",     aot.col_isdeleted)
                       )
           ) 

INTO v_xml                         
FROM tbl_ac_accessobjecttype aot;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT  
Xmlagg(Xmlelement("ACPermition",
               Xmlelement("Code", ap.col_code),
               Xmlelement("DefaultACL", ap.col_defaultacl),
               Xmlelement("Description", ap.col_description),
               Xmlelement("Name", ap.col_name),
               Xmlelement("OrderACL", ap.col_orderacl),
               Xmlelement("Position", ap.col_position),
               Xmlelement("AccessObjectType", ac.col_code),
               Xmlelement("Ucode", ap.col_ucode)
               ))
INTO v_xml               
FROM tbl_AC_PERMISSION ap
 JOIN tbl_ac_accessobjecttype ac ON ap.col_permissionaccessobjtype = ac.col_id
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
--Xmlconcat(v_xml,
Xmlagg(Xmlelement("AccessSubject",
              Xmlelement("Code", t.col_code),
              Xmlelement("Name", t.col_name),
              Xmlelement("Type", t.col_type)
          )
) 
--)
INTO v_xml 
FROM TBL_AC_ACCESSSUBJECT t
where col_type is null  OR t.col_type = 'CUSTOM';

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if; 


SELECT Xmlagg(
XMLELEMENT("AcAcl",
         XMLFOREST( acl.col_code AS "Code",
                    acl.col_type AS "AclType",         
                    acl.col_processorcode AS "ProcessorCode",
                    ac.col_code AS "AccessObject",
                    asb.col_code AS "AccessSubject",
                    acp.col_ucode AS "Permission"
                    )
           )
)     
INTO v_xml
FROM 
tbl_ac_acl acl
JOIN tbl_ac_accessobject ac ON acl.col_aclaccessobject = ac.col_id 
JOIN tbl_ac_accesssubject asb ON acl.col_aclaccesssubject = asb.col_id 
JOIN tbl_ac_permission acp ON acl.col_aclpermission = acp.col_id
where asb.col_type is null OR asb.col_type = 'CUSTOM'; 

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
ctr.col_ucode casetransition,
acct.col_code accesstype
FROM  
tbl_AC_ACCESSOBJECT  ao
LEFT JOIN tbl_ac_accessobjecttype aot ON ao.col_accessobjaccessobjtype = aot.col_id 
LEFT JOIN tbl_dict_accesstype acct ON ao.col_accessobjectaccesstype = acct.col_id
LEFT JOIN tbl_dict_casestate cst ON ao.col_accessobjectcasestate = cst.col_id 
LEFT JOIN tbl_dict_stateconfig conf ON cst.col_stateconfigcasestate = conf.col_id
LEFT JOIN tbl_dict_casesystype cstp ON ao.col_accessobjectcasesystype = cstp.col_id 
LEFT JOIN tbl_dict_tasksystype tst ON ao.col_accessobjecttasksystype = tst.col_id 
 LEFT JOIN tbl_dict_stateconfig cf ON cf.col_id =  tst.col_stateconfigtasksystype
LEFT JOIN tbl_fom_uielement ue ON ao.col_accessobjectuielement = ue.col_id
LEFT JOIN tbl_fom_page fp ON ue.col_uielementpage = fp.col_id
LEFT JOIN tbl_dict_casetransition ctr ON ao.col_accessobjcasetransition = ctr.col_id
LEFT JOIN tbl_dict_casestate dcs1 ON ctr.col_sourcecasetranscasestate = dcs1.col_id 
WHERE 
( conf.col_code ='DEFAULT_CASE'
AND 
aot.col_code!='CASE_TYPE_CASE_STATE')
OR 
(ue.col_code = 'DEFAULT_PORTAL_DASHBOARD' OR fp.col_systemdefault = 1 OR 
ue.col_uielementdashboard IS NOT NULL)
OR 
(aot.col_code IN ('WORKITEM','TASK_BUSINESS_OBJECT', 'CASE_BUSINESS_OBJECT' ))
OR
( ctr.col_id IS NOT NULL  OR dcs1.col_id IS NOT NULL )
OR  conf.col_isdefault = 1
OR 
(ao.col_accessobjectcasesystype IS NULL
AND ao.col_accessobjecttasksystype IS NULL
AND ao.col_accessobjectuielement IS NULL 
AND ao.col_accessobjectcasestate IS NULL
AND ao.col_accessobjcasetransition IS NULL 
)
OR cf.col_isdefault = 1 
)
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

/*Next Select uses xml from previous select*/

SELECT 
Xmlagg(Xmlelement("FomUiElement",
                         Xmlforest(fuel.col_code           AS "Code",
                                  fuel.col_description    AS "Description",
                                  fuel.col_isdeleted      AS "IsDelete",
                                  fuel.col_ishidden       AS "IsHidden",
                                  fuel.col_name           AS "Name",
                                  (SELECT fuel2.col_code  FROM tbl_fom_uielement fuel2 WHERE fuel2.col_id = fuel.col_parentid) AS "ParentCode",
                                  fuel.col_processorcode  AS "ProcessorCode",
                                  fuel.col_title          AS "Title",
                                  fuel.col_uielementorder AS "UiElementOrder", 
                                  cst.col_code            AS "CaseType",
                                  ctr.col_ucode           AS "CaseTtansition",
                                  tt.col_code             AS "TaskType",
                                  ttr.col_ucode           AS "TaskTtansition",
                                  uet.col_code            AS "UserElementType",
                                  cstat.col_ucode         AS "CaseState",
                                  dts.col_ucode           AS "TaskState",
                                  fuel.col_config         AS "Config",
                                  fuel.col_iseditable     AS "IsEditable",
                                  fuel.col_regionid       AS "RegionId",
                                  fuel.col_positionindex  AS "PositionIndex", 
                                  fuel.col_jsondata       AS "JsonData", 
                                  fuel.col_rulevisibility AS "RuleVisibility",
                                  fuel.col_elementcode    AS "ElementCode",
                                  fp.col_code             AS "UIElementPage",
                                  wg.col_code             AS "FomWidget",
                                  dsh.col_code            AS "FomDashboard",
                                  fuel.col_usereditable   AS "UserEditable",
                                  (SELECT listagg(to_char(fom.col_code),',') WITHIN GROUP(ORDER BY fom.col_code) FROM tbl_fom_form fom WHERE 
                                                        fom.col_id IN (SELECT * FROM TABLE(split_casetype_list(fuel.col_formidlist)))) AS "FomFormList",
                                  (SELECT listagg(to_char(fom.col_code),',') WITHIN GROUP(ORDER BY fom.col_code) FROM tbl_fom_codedpage fom WHERE 
                                                        fom.col_id IN (SELECT * FROM TABLE(split_casetype_list(fuel.col_codedpageidlist)))) AS "CodedPageList",    
                                   do.col_ucode           AS "DomObject", 
                                   mdm.col_code           AS "MdmForm",
                                   sc.col_code            AS "SomConfig")           
                                    
                         )
)
INTO v_xml  
FROM tbl_fom_uielement fuel
LEFT JOIN tbl_dict_casesystype cst ON fuel.col_uielementcasesystype = cst.col_id 
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
WHERE fuel.col_code = 'DEFAULT_PORTAL_DASHBOARD'
OR fuel.col_code IN 
(SELECT UserElement 
FROM XMLTABLE ('AccessObject'
PASSING v_xml
COLUMNS        UserElement  NVARCHAR2(255) PATH './UserElement'
  )
)
OR 
(fuel.col_uielementpage IN (SELECT col_id FROM tbl_fom_page r /*WHERE r.col_systemdefault = 1 */ ) )
or 
(dsh.col_id IS NOT NULL)
 AND dsh.col_dashboardcaseworker IS NULL
;


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT
  Xmlagg(
  XMLELEMENT("CommonEventType",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner",
                      t.col_ucode AS "Ucode",
                      t.col_purpose AS "Purpose",
                      t.col_repeatingevent AS "RepeatingEvent")
             )
         ) 

INTO v_xml       
FROM tbl_DICT_CommonEventType t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("DictProcedureInCaseType",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner")
             )
         ) 

INTO v_xml       
FROM TBL_DICT_PROCEDUREINCASETYPE t
;


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT
Xmlagg(
XMLELEMENT("StateConfigs",
         XMLFOREST( t.col_name AS "Name",
                    t.col_code AS "Code",
                    t.col_isdeleted AS "IsDeleted",         
                    t.col_config AS "Config", 
                    t.col_type AS "Type",
                    t.col_isdefault AS "IsDefault",
                    t.col_iconcode AS "IconCode",
                    t.col_iscurrent AS "IsCurent",
                    t.col_revision AS "Revision",
                    v.col_code AS "Version",
                    sct.col_ucode AS "StateconfigTypeUcode",
                    cst.col_code AS "CaseType"
                    )
         
         )
)     

       INTO v_xml    
from tbl_dict_stateconfig t
LEFT JOIN tbl_dict_stateconfigtype sct ON t.col_stateconfstateconftype = sct.col_id
LEFT JOIN tbl_dict_version v ON t.col_stateconfigversion = v.col_id
LEFT JOIN tbl_dict_casesystype cst ON t.col_casesystypestateconfig = cst.col_id
where col_isdefault = 1
OR sct.col_Code = 'DOCUMENT';

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
Xmlagg(Xmlelement("LinkType",
               XMLFOREST(ptpt.col_code AS "Code",
                         ptpt.col_description AS "Description",
                         ptpt.col_name AS "Name",
                         ptpt.col_owner AS "Owner", 
                         ptpt.col_isdeleted AS "IsDeleted"
                         )
               )
       )
INTO v_xml                 
FROM tbl_dict_LinkType ptpt;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("Orgchart",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner",
                      t.col_isprimary AS "IsPrimary",
                      t.col_config    AS "Config",
                      t.col_description AS "Description",
                      tm.col_code     AS "Team" )
             )
         ) 
INTO v_xml       
FROM Tbl_Ppl_Orgchart t
LEFT JOIN tbl_ppl_team tm ON t.col_teamorgchart = tm.col_id
WHERE t.col_casesystypeorgchart IS NULL
AND t.col_isprimary = 1
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("FOMWidget",
            XMLFOREST(t.col_code      AS "Code", 
                      t.col_name      AS "Name", 
                      t.col_owner     AS "Owner",
                      t.col_description  AS "Description",
                      t.col_config    AS "Config",
                      t.col_image     AS "Image",
                      t.col_type      AS "Type",
                      t.col_category  AS "Category",
                      t.col_isdeleted AS "IsDeleted" )
             )
         ) 
INTO v_xml  
FROM tbl_FOM_Widget t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("FOMDashboard",
            XMLFOREST(t.col_code      AS "Code", 
                      t.col_name      AS "Name", 
                      t.col_owner     AS "Owner",
                      t.col_description  AS "Description",
                      t.col_config    AS "Config",
                      t.col_issystem  AS "IsSystem",
                      t.col_isdefault AS "IsDefault",
                      t.col_isdeleted AS "IsDeleted" )
             )
         ) 
INTO v_xml  
FROM tbl_FOM_Dashboard t
WHERE COL_DASHBOARDCASEWORKER IS NULL;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT
  Xmlagg(
  XMLELEMENT("MessageType",
            XMLFOREST(t.col_code      AS "Code", 
                      t.col_name      AS "Name", 
                      t.col_owner     AS "Owner",
                      t.col_description  AS "Description",
                      t.col_colortheme   AS "ColorTheme"/*,
                      t.col_historycreatedby   AS "HistoryCreatedBy",
                      t.col_historycreateddate  AS "HistoryCreatedDate"*/)
             )
         ) 
INTO v_xml      
FROM
 Tbl_Dict_Messagetype t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("LocNamespace",
            XMLFOREST(t.col_ucode             AS "Ucode", 
                      t.col_owner             AS "Owner",
                      t.col_name              AS "Name",
                      t.col_description       AS "Description")
             )
         ) 
INTO v_xml   
FROM  tbl_LOC_Namespace t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
Xmlagg(
  XMLELEMENT("LocPluralForm",
            XMLFOREST(lpf.col_ucode  "Ucode", 
                      lpf.col_language AS "Language",
                      lpf.col_pluralforms   AS "Pluralforms")
             )
         ) 
INTO v_xml 
FROM tbl_loc_pluralform lpf;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("LocKey",
            XMLFOREST(ns.col_ucode            AS "NameSpase", 
                      t.col_isplural          AS "IsPlural", 
--                      t.col_isnew             AS "IsNew",
                      t.col_isdeleted         AS "IsDeleted",
                      t.col_description       AS "Description",
                      t.col_owner             AS "Owner",
                      t.col_name              AS "Name",
                      t.col_context           AS "Context",
                      t.col_ucode             AS "Ucode")
             )
         ) 
INTO v_xml  
FROM tbl_LOC_Key t
LEFT JOIN tbl_LOC_Namespace ns ON t.col_namespaceid = ns.col_id
WHERE t.col_namespaceid IS NULL 
OR EXISTS 
(SELECT 1 FROM tbl_LOC_Namespace r WHERE t.col_namespaceid = r.col_id
);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("LocLanguages",
            XMLFOREST(t.col_isdefault        AS "IsDefault", 
                      t.col_appbaselangid    AS "AppbaseLangId", 
                      t.col_languagename     AS "LanguageName",
                      t.col_languagecode     AS "LanguageCode",
                      t.col_momentcode       AS "MomentCode",
                      t.col_owner            AS "Owner",
                      t.col_extcode          AS "ExtCode",
                      pf.col_ucode           AS "PluralForm",
                      t.col_isdeleted        AS "IsDeleted",
                      t.col_ucode            AS "Ucode")
             )
         ) 
INTO v_xml   
FROM tbl_LOC_Languages t
LEFT JOIN tbl_loc_pluralform pf ON t.col_pluralformid = pf.col_id
WHERE t.col_pluralformid IS NULL 
OR EXISTS 
(SELECT 1 FROM tbl_loc_pluralform pf1 WHERE t.col_pluralformid = pf1.col_id);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("LocTranslation",
            XMLFOREST(t.col_ucode             AS "Ucode", 
                      t.col_owner             AS "Owner",
--                      pf.col_ucode            AS "PluralForm",
                      t.col_pluralform        AS "PluralForm", 
                      lg.col_ucode            AS "Language",
                      k.col_ucode             AS "LocKey",
                      t.col_isdraft           AS "IsDraft",
                      t.col_description       AS "Description",
                      t.col_value             AS "Value"
                      )
             )
         ) 
INTO v_xml   
FROM tbl_LOC_Translation t
--LEFT JOIN tbl_loc_pluralform pf ON t.col_pluralform = pf.col_id
LEFT JOIN tbl_loc_languages lg ON t.col_langid = lg.col_id
JOIN tbl_loc_key k ON t.col_keyid = k.col_id
WHERE t.col_langid IS NULL 
OR EXISTS  
( SELECT 1 FROM tbl_loc_languages lg1 WHERE t.col_langid = lg1.col_id
);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("LocKeySources",
            XMLFOREST(t.col_ucode             AS "Ucode", 
                      d.col_code              AS "SourceCode",
                      k.col_ucode             AS "LocKey",
                      t.col_sourcetype        AS "SourceType"
                      )
             )
         ) 

INTO v_xml
FROM tbl_LOC_KeySources t
JOIN tbl_loc_key k ON t.col_keyid = k.col_id
JOIN tbl_fom_dashboard d ON t.col_sourceid = d.col_id AND UPPER(t.col_sourcetype) = 'DASHBOARD' 
and d.COL_DASHBOARDCASEWORKER IS NULL
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("LocKeySources",
            XMLFOREST(t.col_ucode             AS "Ucode", 
                      p.col_code              AS "SourceCode",
                      k.col_ucode             AS "LocKey",
                      t.col_sourcetype        AS "SourceType"
                      )
             )
         ) 

INTO v_xml
FROM tbl_LOC_KeySources t
JOIN tbl_loc_key k ON t.col_keyid = k.col_id
JOIN tbl_fom_page p ON t.col_sourceid = p.col_id AND UPPER(t.col_sourcetype) = 'PAGE'
and p.col_pagecasesystype is null;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

/* Statr Added 30-10-2017 */

SELECT   Xmlagg(
  XMLELEMENT("IntIntegtarget",
            XMLFOREST(t.col_code              AS "Code", 
                      t.col_isdeleted         AS "IsDeleted",
                      t.col_description       AS "Description",
                      t.col_config            AS "Config",
                      t.col_name              AS "Name"
                      )
             )
         ) 

INTO v_xml
FROM Tbl_Int_Integtarget t; 

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT  Xmlagg(
  XMLELEMENT("CaseRole",
            XMLFOREST(t.col_code              AS "Code", 
                      t.col_isdeleted         AS "IsDeleted",
                      t.col_description       AS "Description",
                      t.col_name              AS "Name"
                      )
             )
         ) 

INTO v_xml 
FROM tbl_dict_caserole t; 

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT  Xmlagg(
  XMLELEMENT("DcmType",
            XMLFOREST(t.col_code              AS "Code", 
                      t.col_description       AS "Description",
                      t.col_name              AS "Name",
                      t.col_ucode             AS "Ucode"
                      )
             )
         ) 
INTO v_xml 
FROM TBL_DICT_DCMTYPE t; 

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT  Xmlagg(
  XMLELEMENT("DictState",
            XMLFOREST(t.col_code              AS "Code", 
                      t.col_activity          AS "Activity",                        
                      t.col_description       AS "Description",
                      t.col_defaultorder      AS "DefaultOrder",
                      t.col_name              AS "Name",
                      t.col_iconcode          AS "IconCode",
                      t.col_isdeleted         AS "IsDeleted",
                      t.col_ishidden          AS "IsHidden",
                      t.col_ucode             AS "Ucode",
                      sc.col_code             AS "StateConfig", 
                      cs.col_ucode            AS "CaseStateUcode",
                      t.col_id2               AS "ID2",
                      t.col_commoncode        AS "CommonCode" 
                      )
             )
         ) 
INTO v_xml 
FROM tbl_dict_state t
LEFT JOIN tbl_dict_stateconfig sc ON t.col_statestateconfig = sc.col_id
LEFT JOIN tbl_dict_stateconfigtype sct ON sc.col_stateconfstateconftype = sct.col_id
LEFT JOIN tbl_dict_casestate cs ON t.col_statecasestate = cs.col_id
WHERE sc.col_isdefault = 1
OR sct.col_Code = 'DOCUMENT'; 

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT  Xmlagg(
  XMLELEMENT("DictStateConfigType",
            XMLFOREST(t.col_ucode         AS "Ucode",
                      t.col_code          AS "Code",
                      t.col_description   AS "Description",
                      t.col_name          AS "Name"
                      )
             )
         ) 
INTO v_xml 
FROM tbl_dict_stateconfigtype t
; 

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT  Xmlagg(
  XMLELEMENT("DictTagObject",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_name              AS "Name"
                      )
             )
         ) 
INTO v_xml 
FROM tbl_dict_tagobject t
; 

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT  Xmlagg(
  XMLELEMENT("DictTagToTagObject",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_name              AS "Name",
                      tg.col_code             AS "Tag",
                      tob.col_code            AS "TagObject")
             )
         ) 
INTO v_xml 
FROM tbl_dict_tagtotagobject t
LEFT JOIN tbl_dict_tag tg ON t.col_tagtotagobjectdict_tag = tg.col_id 
LEFT JOIN tbl_dict_tagobject tob ON t.col_tagtotagobjectdict_tagobj = tob.col_id
; 

IF v_xml IS NOT NULL THEN
dbms_lob.append(v_clob, v_xml.getClobVal());
END IF;

SELECT  Xmlagg(
  XMLELEMENT("DictTransition",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_description       AS "Description",
                      t.col_iconcode          AS "IconCode",
                      t.col_isnextdefault     AS "IsNextDefault",
                      t.col_isprevdefault     AS "IsPrevDefault",
                      t.col_manualonly        AS "ManualOnly",
                      t.col_name              AS "Name",
                      t.col_transition        AS "Transition",
                      t.col_ucode             AS "Ucode",
                      dst.col_ucode           AS "SourceTransitions",
                      dst1.col_ucode          AS "TargetTransitions",
                      t.col_colorcode         AS "ColorCode",
                      t.col_sorder            AS "Sorder",
                      t.col_commoncode        AS "CommonCode",
                      t.col_notshowinui       AS "NotShowInUI")
             )
         ) 
INTO v_xml 
FROM TBL_DICT_TRANSITION t
LEFT JOIN tbl_dict_state dst ON t.col_sourcetransitionstate = dst.col_id
LEFT JOIN tbl_dict_state dst1 ON t.col_targettransitionstate = dst1.col_id
where 
t.col_sourcetransitionstate IN 
(SELECT col_id FROM tbl_dict_state t1
WHERE t1.col_statestateconfig IN (SELECT col_id FROM tbl_dict_stateconfig WHERE col_isdefault = 1 OR col_code ='DOCUMENT') )
OR 
t.col_targettransitionstate IN 
(SELECT col_id FROM tbl_dict_state t2
WHERE t2.col_statestateconfig IN (SELECT col_id FROM tbl_dict_stateconfig WHERE col_isdefault = 1 OR col_code ='DOCUMENT') )
; 

IF v_xml IS NOT NULL THEN
dbms_lob.append(v_clob, v_xml.getClobVal());
END IF;

SELECT 
Xmlagg(
XMLELEMENT("StateEvent",
  XMLFOREST(t.col_ucode AS "Ucode",
            t.col_eventorder AS "EventOrder",
            t.col_eventsubtype  AS "EventSubType",
            t.col_eventtype  AS "EventType",
            t.col_processorcode AS "ProcessorCode",
            ds.col_ucode AS "StateUcode",
            em.col_code AS "TaskEventMomentCode",
            et.col_code AS "TaskEventTypeCode",
            t.col_eventcode AS "EventCode",
            t.col_eventname AS "EventName",
            tr.col_ucode AS "Transition")
          )
)
INTO v_xml 
FROM tbl_DICT_StateEvent t
LEFT JOIN tbl_dict_state ds ON t.col_stateeventstate = ds.col_id
LEFT JOIN tbl_dict_stateconfig sc ON ds.col_statestateconfig = sc.col_id
LEFT JOIN tbl_dict_stateconfigtype sct ON sc.col_stateconfstateconftype = sct.col_id
LEFT JOIN tbl_dict_taskeventmoment em ON t.col_stateeventeventmoment = em.col_id
LEFT JOIN tbl_dict_taskeventtype et ON t.col_stateeventeventtype = et.col_id
LEFT JOIN tbl_dict_transition tr ON t.col_stevt_trans = tr.col_id
WHERE sc.col_isdefault = 1
OR sct.col_Code = 'DOCUMENT';


IF v_xml IS NOT NULL THEN
dbms_lob.append(v_clob, v_xml.getClobVal());
END IF;

SELECT 
Xmlagg(
XMLELEMENT("StateSlaEvent",
  XMLFOREST(t.col_ucode AS "Ucode",
            t.col_attemptcount AS "AttemptCount",
            t.col_intervalds AS "Intervalds",
            t.col_intervalym AS "Intervalym",						
            t.col_maxattempts AS "MaxAttempts",
            t.col_slaeventorder AS "SlaEventOrder",
            ds.col_ucode AS "StateUcode",
            el.col_code AS "SlaEventLevelCode",
            t.col_servicesubtype AS "ServiceSubType",
            t.col_servicetype AS "ServiceType",
            t.col_eventcode AS "EventCode",
            t.col_eventname AS "EventName",
            tr.col_ucode AS "Transition",
            slet.col_code AS "SlaEventType"
           )
         )
)
INTO v_xml 
FROM
tbl_dict_stateslaevent t
LEFT JOIN tbl_dict_state ds ON t.col_stateslaeventdict_state = ds.col_id
LEFT JOIN tbl_dict_stateconfig sc ON ds.col_statestateconfig = sc.col_id
LEFT JOIN tbl_dict_stateconfigtype sct ON sc.col_stateconfstateconftype = sct.col_id
LEFT JOIN tbl_dict_slaeventlevel el ON t.col_stateslaeventslaeventlvl = el.col_id
LEFT JOIN tbl_dict_transition tr ON t.col_stslaevt_trans = tr.col_id
LEFT JOIN tbl_dict_slaeventtype slet ON t.col_dict_sse_slaeventtype = slet.col_id
WHERE sc.col_isdefault = 1
OR sct.col_Code = 'DOCUMENT';

IF v_xml IS NOT NULL THEN
dbms_lob.append(v_clob, v_xml.getClobVal());
END IF;

SELECT 
Xmlagg(
XMLELEMENT("StateSlaAction",
  XMLFOREST(t.col_ucode AS "Ucode",
            t.col_processorcode AS "ProcessorCode",						
            t.col_slaactionorder AS "SlaActionOrder",
            se.col_ucode AS "StateSlaEvent",
            t.col_eventcode AS "EventCode",
            t.col_eventname AS "EventName"
           )
         )
)
INTO v_xml 
FROM
tbl_DICT_StateSlaAction t
LEFT JOIN tbl_dict_stateslaevent se ON t.col_stateslaactnstateslaevnt = se.col_id
LEFT JOIN tbl_dict_state ds ON se.col_stateslaeventdict_state = ds.col_id
LEFT JOIN tbl_dict_stateconfig sc ON ds.col_statestateconfig = sc.col_id
LEFT JOIN tbl_dict_stateconfigtype sct ON sc.col_stateconfstateconftype = sct.col_id
WHERE sc.col_isdefault = 1
OR sct.col_Code = 'DOCUMENT';

IF v_xml IS NOT NULL THEN
dbms_lob.append(v_clob, v_xml.getClobVal());
END IF;

SELECT  Xmlagg(
  XMLELEMENT("DictLinkDirection",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_name              AS "Name",
                      t.col_description       AS "Description",
                      t.col_ucode             AS "Ucode")
             )
         ) 
INTO v_xml 
FROM tbl_DICT_LinkDirection t
; 

IF v_xml IS NOT NULL THEN
dbms_lob.append(v_clob, v_xml.getClobVal());
END IF;



/* End Added 30-10-2017 */


SELECT   Xmlagg(
  XMLELEMENT("DictContainerType",
            XMLFOREST(t.col_id                AS "ID",
                      t.col_code              AS "Code", 
                      t.col_name              AS "Name",
                      t.col_ucode             AS "Ucode"
                      )
             )
         ) 

INTO v_xml
FROM tbl_DICT_ContainerType t; 

IF v_xml IS NOT NULL THEN
dbms_lob.append(v_clob, v_xml.getClobVal());
END IF;

SELECT   Xmlagg(
  XMLELEMENT("DictSystemType",
            XMLFOREST(t.col_id                AS "ID",
                      t.col_code              AS "Code", 
                      t.col_name              AS "Name",
                      t.col_ucode             AS "Ucode"
                      )
             )
         ) 

INTO v_xml
FROM Tbl_Dict_Systemtype t; 

IF v_xml IS NOT NULL THEN
dbms_lob.append(v_clob, v_xml.getClobVal());
END IF;

SELECT   Xmlagg(
  XMLELEMENT("DictBlackList",
            XMLFOREST(t.col_code              AS "Code", 
                      t.col_type              AS "BlackListType",
                      t.col_ucode             AS "Ucode"
                      )
             )
         ) 

INTO v_xml
FROM Tbl_DICT_BlackList t;

IF v_xml IS NOT NULL THEN
dbms_lob.append(v_clob, v_xml.getClobVal());
END IF;


SELECT
  Xmlagg(
  XMLELEMENT("ThreadSetting",
            XMLFOREST(t.col_ucode                  "Ucode",
                      t.col_owner                  "Owner",
                      t.col_allowaddpeople         "AllowAddPeople",
                      t.col_allowcommentdiscussion "AllowCommentDiscussion",
                      t.col_allowcreatediscussion  "AllowCreateDiscussion",
                      t.col_allowdeletecomment     "AllowDeleteComment",
                      t.col_allowdeletediscussion  "AllowDeleteDiscussion",
                      t.col_alloweditcomment       "AllowEditComment",
                      t.col_allowjoindiscussion    "AllowJoinDiscussion",
                      t.col_allowleavediscussion   "AllowLeaveDiscussion",
                      t.col_allowremovepeople      "AllowRemovePeople")
             )
         ) 

INTO v_xml       
FROM TBL_THREADSETTING t;

IF v_xml IS NOT NULL THEN
dbms_lob.append(v_clob, v_xml.getClobVal());
END IF;

SELECT
  Xmlagg(
  XMLELEMENT("PartyorgType",
            XMLFOREST(t.col_code                  "Code",
                      t.col_owner                 "Owner",
                      t.col_name                  "Name")
             )
         ) 
INTO v_xml       
FROM TBL_DICT_PARTYORGTYPE t;

IF v_xml IS NOT NULL THEN
dbms_lob.append(v_clob, v_xml.getClobVal());
END IF;

dbms_lob.append(v_clob,'</Dictionary>');




RETURN v_clob;
END;