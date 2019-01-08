DECLARE
v_clob           NCLOB := EMPTY_CLOB();
v_clob2          NCLOB := EMPTY_CLOB();
v_clob3          NCLOB := EMPTY_CLOB();
v_clobAdHoc      NCLOB := EMPTY_CLOB();
v_clobConfProc   NCLOB := EMPTY_CLOB();
v_xml_temp       XMLTYPE;
v_xml            XMLTYPE;
v_xml2           XMLTYPE;
v_case_type      NVARCHAR2(255);
v_sql            NVARCHAR2(7200);
v_list_procedure NVARCHAR2(7200);
v_result_fil     NVARCHAR2(4); 
Is_Dict_Load     PLS_INTEGER := 0;
v_adhoc          NUMBER;
v_configProc     NUMBER;
TYPE t_procAutorul	   IS TABLE OF NUMBER;
v_procAutorul    t_procAutorul;
v_DCMVersion     VARCHAR2(255);
v_CustomBOTags   VARCHAR2(32000);
BEGIN  

IF ExportCaseTypeId IS NOT NULL AND ExportCaseTypeId > 0 THEN 
    BEGIN  
     SELECT col_code 
       INTO v_case_type
       FROM tbl_dict_casesystype 
      WHERE col_id = ExportCaseTypeId;

    EXCEPTION WHEN NO_DATA_FOUND THEN 
      RETURN 'Error - can''t export case type for this ExportCaseTypeId'||ExportCaseTypeId;
    END;

END IF;

IF (ExportCaseTypeId IS NULL OR ExportCaseTypeId = 0) AND  
   (ExportDictionaries IS NOT NULL AND ExportDictionaries = 1) THEN 
   Is_Dict_Load := 2;
ELSIF (ExportCaseTypeId IS NOT NULL AND ExportCaseTypeId > 0) AND  
   (ExportDictionaries IS NOT NULL AND ExportDictionaries = 1) THEN  
   Is_Dict_Load := 1;   
END IF; 
v_CustomBOTags := :CustomBOTags;
-- Is_Dict_Load = 0 Loaded only CaseType
-- Is_Dict_Load = 1 Loaded both CaseType and Dictionary
-- Is_Dict_Load = 2 Loaded only Dictionary
v_result_fil := f_UTIL_fil_col_code();

dbms_lob.createtemporary(v_clob,true);
dbms_lob.createtemporary(v_clob2,true);
dbms_lob.createtemporary(v_clob3,true);
dbms_lob.createtemporary(v_clobAdHoc,true);
dbms_lob.createtemporary(v_clobConfProc,true);
      
DBMS_LOB.OPEN(v_clob, 1);
DBMS_LOB.OPEN(v_clob2, 1);
DBMS_LOB.OPEN(v_clob3, 1);
DBMS_LOB.OPEN(v_clobAdHoc, 1);
DBMS_LOB.OPEN(v_clobConfProc, 1);

--dbms_lob.append(v_clob, '<?xml version="1.0" encoding="UTF-16"?>');
dbms_lob.append(v_clob, '<CaseType>');
dbms_lob.append(v_clob, '<Scheme>'||user||'</Scheme>');

BEGIN
	v_DCMVersion := f_util_getdcmversion();

EXCEPTION WHEN OTHERS THEN 
	v_DCMVersion := 'NA';
END;

dbms_lob.append(v_clob, '<DcmVersion>'||v_DCMVersion||'</DcmVersion>');

   IF Is_Dict_Load = 1 THEN
     SELECT Xmlconcat(v_xml_temp,
            XMLFOREST(1 AS "OnlyDictionary"))
     INTO v_xml_temp
     FROM dual;
   END IF;
    
   IF Is_Dict_Load = 2 THEN 
     SELECT Xmlconcat(v_xml_temp,
            XMLFOREST(2 AS "OnlyDictionary"))
     INTO v_xml_temp
     FROM dual;
   END IF;

   IF Is_Dict_Load = 0 or Is_Dict_Load is null  THEN 
     SELECT Xmlconcat(v_xml_temp,
            XMLFOREST(0 AS "OnlyDictionary"))
     INTO v_xml_temp
     FROM dual;
   END IF;
   
dbms_lob.append(v_clob, v_xml_temp.getClobVal());  



IF Is_Dict_Load = 1 OR Is_Dict_Load = 0 THEN
SELECT  listagg(CAST( col_code  AS VARCHAR2(255)) ,';') WITHIN GROUP (ORDER BY col_code)
INTO 
v_list_procedure
FROM (
SELECT DISTINCT col_code
FROM tbl_procedure pr
WHERE pr.col_proceduredict_casesystype  
IN ( SELECT col_id FROM tbl_dict_casesystype WHERE col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type))))
UNION 
SELECT pr.col_code 
FROM 
tbl_dict_casesystype dct
JOIN tbl_procedure pr ON dct.col_casesystypeprocedure = pr.col_id
WHERE dct.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
;



SELECT Xmlagg(
      XMLELEMENT("CaseTypeConfig",
                  XMLElement("Code", t.col_code),
                  XMLElement("Name", t.col_name),
                  XMLElement("Description", t.col_description),
                  XMLElement("StateConfigCode", tt.col_code),
                  XMLElement("MSStateConfigCode", tt2.col_code),
                  XMLElement("StateConfigName", tt.col_name ),
                  XMLElement("ProcessorCode", t.col_processorcode),
                  XMLElement("CustomDataProcessor", t.col_customdataprocessor),
                  XMLElement("RetrieveCustomDataProcessor", t.col_retcustdataprocessor),
                  XMLElement("UpdateCustomDataProcessor", t.col_updatecustdataprocessor),
                  XMLElement("CustomValidator", t.col_customvalidator),
                  XMLElement("CustomValidatorResultProcessor", t.col_customvalresultprocessor),
                  XMLElement("ShowInPortal", t.col_showinportal),
                  XMLElement("IsDeleted", t.col_isdeleted ),
                  XMLElement("UseDataModel", t.col_usedatamodel ),
                  XMLElement("CaseTypeProcinCaseType", pric.col_code ),
                  XMLElement("IsDraftModeAvail", t.col_isdraftmodeavail),
                  XMLElement("CaseTypePriority", pri.col_code),
                  XMLElement("ColorCode", t.col_colorcode),
                  XMLElement("RouteCustomDataProcessor", t.col_routecustomdataprocessor),
                  XMLElement("CustomCountDataProcessor", t.col_customcountdataprocessor),
                  XMLElement("IconCode", t.col_iconcode ),
                  XMLElement("MdmModel", mdm.col_ucode ),
                  XMLElement("Procedure",
                      XMLElement("Code", COALESCE(pr.col_code,pr2.col_code)),
                      XMLElement("Name", COALESCE(pr.col_name, pr2.col_name)),
                      XMLElement("Description", COALESCE(pr.col_description,pr2.col_description)),
                      XMLElement("ConfigProc", COALESCE(pr.col_config,pr2.col_config)),
                      XMLElement("RootTaskTypeCode", COALESCE(pr.col_roottasktypecode, pr2.col_roottasktypecode)),
                      XMLElement("CustomDataProcessor", COALESCE(pr.col_customdataprocessor,pr2.col_customdataprocessor ) ),
                      XMLElement("CustomValResultProcessor", COALESCE(pr.col_customvalresultprocessor ,pr2.col_customvalresultprocessor)),
                      XMLElement("CaseState", COALESCE(cst.col_ucode,cst2.col_ucode )),
                      XMLElement("RetrieveCustomDataProcessor", COALESCE(pr.col_retcustdataprocessor,pr2.col_retcustdataprocessor)),
                      XMLElement("UpdateCustomDataProcessor", COALESCE(pr.col_updatecustdataprocessor,pr2.col_updatecustdataprocessor ) ),
                      XMLElement("IsDefault", to_char(COALESCE(pr.col_isdefault,pr2.col_isdefault,0),'FM9') ),
                      XMLElement("IsDeleted", to_char(COALESCE(pr.col_isdeleted,pr2.col_isdeleted,0),'FM9')),
                      XMLElement("ProcInCaseType", COALESCE(princt.col_code,princt.col_code)))
                    )
                    )
       INTO v_xml
FROM tbl_dict_casesystype t
LEFT JOIN tbl_procedure pr ON t.col_id = pr.col_proceduredict_casesystype
LEFT JOIN tbl_procedure pr2 ON t.col_casesystypeprocedure = pr2.col_id
LEFT JOIN tbl_dict_procedureincasetype princt ON pr.col_procprocincasetype = princt.col_id
LEFT JOIN tbl_dict_procedureincasetype princt2 ON pr2.col_procprocincasetype = princt2.col_id
LEFT JOIN tbl_dict_casestate cst ON pr.col_procedurecasestate = cst.col_id
LEFT JOIN tbl_dict_casestate cst2 ON pr2.col_procedurecasestate = cst2.col_id
LEFT JOIN tbl_dict_stateconfig tt ON t.col_stateconfigcasesystype = tt.col_id
LEFT JOIN tbl_dict_version tt2 ON t.col_dictvercasesystype= tt2.col_id
LEFT JOIN tbl_DICT_PROCEDUREINCASETYPE pric ON t.col_casetypeprocincasetype = pric.col_id
LEFT JOIN tbl_stp_priority pri ON t.col_casetypepriority = pri.col_id
LEFT JOIN tbl_MDM_Model mdm ON t.col_casesystypemodel = mdm.col_id
WHERE t.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
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
WHERE cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
OR
EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tst1, tbl_stp_availableadhoc ah, tbl_dict_casesystype cst1  
  WHERE t.col_id = tst1.col_stateconfigtasksystype
    AND ah.col_tasksystype = tst1.col_id
    AND ah.col_casesystype = cst1.col_id 
    AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
;


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
LEFT JOIN tbl_dict_casesystype cst ON sc.col_casesystypestateconfig = cst.col_id
LEFT JOIN tbl_dict_casestate cs ON t.col_statecasestate = cs.col_id
WHERE 
 cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
OR 
EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tst1, tbl_stp_availableadhoc ah, tbl_dict_casesystype cst1  
  WHERE sc.col_id = tst1.col_stateconfigtasksystype
    AND ah.col_tasksystype = tst1.col_id
    AND ah.col_casesystype = cst1.col_id 
    AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
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
WHERE rc.col_type = 'CASE';

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

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
LEFT JOIN tbl_dict_casesystype cst ON sc.col_casesystypestateconfig = cst.col_id
LEFT JOIN tbl_dict_taskeventmoment em ON t.col_stateeventeventmoment = em.col_id
LEFT JOIN tbl_dict_taskeventtype et ON t.col_stateeventeventtype = et.col_id
LEFT JOIN tbl_dict_transition tr ON t.col_stevt_trans = tr.col_id
WHERE  cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
OR 
EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tst1, tbl_stp_availableadhoc ah, tbl_dict_casesystype cst1  
  WHERE sc.col_id = tst1.col_stateconfigtasksystype
    AND ah.col_tasksystype = tst1.col_id
    AND ah.col_casesystype = cst1.col_id 
    AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

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
LEFT JOIN tbl_dict_casesystype cst ON sc.col_casesystypestateconfig = cst.col_id
LEFT JOIN tbl_dict_slaeventlevel el ON t.col_stateslaeventslaeventlvl = el.col_id
LEFT JOIN tbl_dict_transition tr ON t.col_stslaevt_trans = tr.col_id
LEFT JOIN tbl_dict_slaeventtype slet ON t.col_dict_sse_slaeventtype = slet.col_id
WHERE 
 cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
OR 
EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tst1, tbl_stp_availableadhoc ah, tbl_dict_casesystype cst1  
  WHERE sc.col_id = tst1.col_stateconfigtasksystype
    AND ah.col_tasksystype = tst1.col_id
    AND ah.col_casesystype = cst1.col_id 
    AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

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
LEFT JOIN tbl_dict_casesystype cst ON sc.col_casesystypestateconfig = cst.col_id
WHERE 
 cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
OR 
EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tst1, tbl_stp_availableadhoc ah, tbl_dict_casesystype cst1  
  WHERE sc.col_id = tst1.col_stateconfigtasksystype
    AND ah.col_tasksystype = tst1.col_id
    AND ah.col_casesystype = cst1.col_id 
    AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;
SELECT 
Xmlagg(Xmlelement("Documents",
               XMLFOREST(t.col_ucode            AS "Ucode",
                         t.col_isfolder         AS "IsFolder",
                         dd.col_ucode           AS "Parentid",
						 t.col_url              AS "DocumentURL",
                         t.col_name             AS "Name",
                         t.col_isdeleted        AS "IsDeleted",
                         t.col_folderorder      AS "FolderOrder",
                         dt.col_code            AS "DocumentType",
                         t.col_description      AS "Description",
                         t.col_isglobalresource AS "IsGlobalResource",
                         t.col_customdata       AS "CustomData",
                         t.col_versionindex     AS "VersionIndex",
                         st.col_ucode           AS "SystemType",
                         t.col_isprimary        AS "IsPrimary",
                         t.col_pdfurl           AS "PDFurl"
                         )
               )
       )
INTO v_xml   
FROM tbl_doc_document t
LEFT JOIN tbl_doc_document dd ON t.col_parentid = dd.col_id
LEFT JOIN tbl_dict_documenttype dt ON t.col_doctype = dt.col_id
LEFT JOIN tbl_dict_systemtype st ON t.col_doc_documentsystemtype = st.col_id
WHERE EXISTS 
(SELECT 1 FROM Tbl_Doc_Doccasetype t1
JOIN tbl_dict_casesystype cst ON t1.col_doccsetypetype = cst.col_id 
     AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
WHERE  t1.col_doccsetypedoc = t.col_id)
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
Xmlagg(Xmlelement("DocCaseType",
               XMLFOREST(t.col_ucode AS "Ucode",
                         cst.col_code AS "CaseType",
                         dd.col_ucode AS "Document"
                         )
               )
       )
INTO v_xml                 
FROM Tbl_Doc_Doccasetype t
JOIN tbl_dict_casesystype cst ON t.col_doccsetypetype = cst.col_id 
     AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
JOIN tbl_doc_document dd ON t.col_doccsetypedoc = dd.col_id;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT
--Xmlconcat(v_xml,
Xmlagg(
XMLELEMENT("CaseState",
           XMLELEMENT("Activity", cst.col_activity),
           XMLELEMENT("Code", cst.col_code),
           XMLELEMENT("Name", cst.col_name),
           XMLELEMENT("Description", cst.col_description),
           XMLELEMENT("IsAssign", cst.col_isassign),
           XMLELEMENT("IsDefaultonCreate", cst.col_isdefaultoncreate),
           XMLELEMENT("IsDefaultonCreate2", cst.col_isdefaultoncreate2),           
           XMLELEMENT("DefaultOrder", cst.col_defaultorder),
           XMLELEMENT("IsDeleted", cst.col_isdeleted),
           XMLELEMENT("IsFinish", cst.col_isfinish),
           XMLELEMENT("IsFix", cst.col_isfix),
           XMLELEMENT("IsHidden", cst.col_ishidden),
           XMLELEMENT("IsResolve", cst.col_isresolve),
           XMLELEMENT("IsStart", cst.col_isstart),
           XMLELEMENT("Config", conf.col_code),
           XMLELEMENT("Ucode", cst.col_ucode),
           XMLELEMENT("IconCode", cst.col_iconcode),
           XMLELEMENT("Theme", cst.col_theme )	
                  ))
--                  )
INTO v_xml
FROM tbl_dict_casestate cst
JOIN tbl_dict_stateconfig conf ON cst.col_stateconfigcasestate = conf.col_id
JOIN tbl_dict_casesystype ct ON ct.col_stateconfigcasesystype = conf.col_id AND ct.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT  Xmlagg(
  XMLELEMENT("CaseSysTypePriority",
            XMLFOREST(p.col_code  "CodePriority", 
                      cst.col_code AS "CaseType")
             )
         )  
INTO  v_xml        
FROM tbl_CaseSysTypePriority t
LEFT JOIN tbl_stp_priority p ON t.col_casetypeprioritypriority = p.col_id
LEFT JOIN tbl_dict_casesystype cst ON t.col_casetypeprioritycasetype = cst.col_id
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

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
,tbl_dict_casestate dcs1
,tbl_dict_stateconfig sc
,tbl_dict_casestate dcs2
,tbl_dict_casesystype cst
WHERE ct.col_sourcecasetranscasestate = dcs1.col_id
AND ct.col_targetcasetranscasestate = dcs2.col_id
AND dcs1.col_stateconfigcasestate = sc.col_id
AND dcs2.col_stateconfigcasestate = sc.col_id
AND cst.col_stateconfigcasesystype = sc.col_id
AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT   
Xmlagg(XMLELEMENT("CaseStateInitiation",
                          XMLELEMENT("Code", cinit.col_code),
                          XMLELEMENT("AssignProcessorCode", cinit.col_assignprocessorcode),
                          XMLELEMENT("ProcessorCode", cinit.col_processorcode),
                          XMLELEMENT("Initmetod", initm.col_code),
                          XMLELEMENT("CaseState", ct.col_ucode),
                          XMLELEMENT("CaseTypeCode", t.col_code)
                          )
                          )

INTO v_xml
FROM tbl_map_casestateinitiation cinit
,tbl_dict_initmethod initm
,tbl_dict_casesystype t
,tbl_dict_casestate ct
WHERE 
cinit.col_casestateinit_casesystype = t.col_id
AND cinit.col_casestateinit_initmethod =  initm.col_id
AND ct.col_id  = cinit.col_map_csstinit_csst
AND t.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))/* v_Case_Type*/
AND cinit.col_map_casestateinitcase IS NULL ; 

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT   
Xmlagg(XMLELEMENT("CaseStateInitiationTMPL",
                          XMLFOREST (cinit.col_code                AS "Code",
                                     cinit.col_assignprocessorcode AS "AssignProcessorCode", 
                                     cinit.col_processorcode       AS "ProcessorCode", 
                                     initm.col_code                AS "Initmetod",
                                     cinit.col_id2                 AS "ID2",
                                     ct.col_ucode                  AS "CaseState", 
                                     t.col_code                    AS "CaseTypeCode",
                                     tt.col_code                   AS "TaskTempl"
                                     )
                  )
      )
INTO v_xml
FROM TBL_MAP_CASESTATEINITTMPL cinit
 LEFT JOIN tbl_dict_initmethod initm ON cinit.col_casestateinittp_initmtd =  initm.col_id
 LEFT JOIN tbl_dict_casesystype t ON cinit.col_casestateinittp_casetype = t.col_id
 LEFT JOIN tbl_dict_casestate ct ON ct.col_id  = cinit.col_map_csstinittp_csst
 LEFT JOIN tbl_tasktemplate tt ON cinit.col_map_casestinittpltasktpl = tt.col_id
WHERE t.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
AND cinit.col_map_casestateinittpcasecc IS NULL ; 

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
Xmlagg(
XMLELEMENT("TaskType",
                 XMLFOREST(tst.col_code                  AS "Code",
                           tst.col_name                  AS "Name", 
                           to_char(tst.col_description)  AS "Description",
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
WHERE EXISTS 
( SELECT 1 FROM tbl_tasktemplate tt, tbl_procedure pr WHERE tt.col_tasktmpldict_tasksystype = tst.col_id 
    AND tt.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) 
    )
OR 
EXISTS 
(SELECT 1 FROM tbl_stp_availableadhoc ah, 
               tbl_dict_casesystype cst 
 WHERE ah.col_tasksystype = tst.col_id
   AND ah.col_casesystype = cst.col_id 
   AND cst.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
	 ) 
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT  Xmlagg(
        XMLELEMENT("TaskSysTypeResolutionCode",
                XMLFOREST(tstrc.col_code AS "Code",
                          rc.col_code AS "ResolutionCode",
                          tst.col_code AS "TaskType")
               )
        )      
INTO  v_xml               
FROM TBL_TASKSYSTYPERESOLUTIONCODE tstrc
JOIN Tbl_Dict_Tasksystype tst ON tstrc.col_tbl_dict_tasksystype = tst.col_id
JOIN tbl_stp_resolutioncode rc ON tstrc.col_tbl_stp_resolutioncode = rc.col_id
WHERE EXISTS 
(SELECT 1 FROM tbl_tasktemplate tt, tbl_procedure pr WHERE tt.col_tasktmpldict_tasksystype = tst.col_id 
    AND tt.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) )
OR 
EXISTS 
(SELECT 1 FROM tbl_stp_availableadhoc ah, 
               tbl_dict_casesystype cst 
 WHERE ah.col_tasksystype = tst.col_id
   AND ah.col_casesystype = cst.col_id 
   AND cst.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
	 ) 
;

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
LEFT JOIN tbl_dict_casesystype cst ON cst.col_stateconfigcasesystype = conf.col_id 
WHERE  cst.col_code IN (SELECT COLUMN_VALUE FROM TABLE(split_casetype_list(v_case_type)))
OR EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tst1, tbl_stp_availableadhoc ah, tbl_dict_casesystype cst1  
  WHERE conf.col_id = tst1.col_stateconfigtasksystype
    AND ah.col_tasksystype = tst1.col_id
    AND ah.col_casesystype = cst1.col_id 
    AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

FOR rec IN (SELECT COLUMN_VALUE  FROM TABLE(split_casetype_list(v_list_procedure))) LOOP
v_sql := '
SELECT LEVEL, XMLELEMENT("TaskTemplateTMPL", 
name||code||descr||TT||Icon||ExecutionMethod||TaskOrder||dead||goal||iconname||id2||inst||MaxA||Req||ST||TID||TP||Urg||Dpth||IconCls||Leaf||ProcCode||PageCode||IsHidden||TskSt||initi) 
FROM
(SELECT d.col_id,
        d.col_parentttid,
        XMLELEMENT("Name",  d.col_name ) name,
        XMLELEMENT("Code",  d.col_code )  code,
        XMLELEMENT("Description",  to_char(d.col_Description) ) descr,
        XMLELEMENT("TaskType", tst.col_code) TT,
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
        XMLELEMENT("IsHidden",  d.col_ishidden) IsHidden,
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
         d.col_ishidden,   tsst1.col_ucode)
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

v_clob2 := replace(replace(v_clob2, CHR(38)||'lt;','<'),CHR(38)||'gt;','>');

dbms_lob.append(v_clob, v_clob2);

END LOOP;


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

dbms_lob.append(v_clob3, v_xml_temp.getClobVal());

v_clob3 := replace(replace(v_clob3, CHR(38)||'lt;','<'),CHR(38)||'gt;','>');


dbms_lob.append(v_clob, v_clob3);

END LOOP;



SELECT
Xmlagg(
XMLELEMENT("Taskdependency",
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
)INTO
  v_xml
FROM
  tbl_taskdependency dep
  JOIN tbl_map_taskstateinitiation t ON t.col_id = dep.col_tskdpndprnttskstateinit
  JOIN tbl_tasktemplate tt ON t.col_map_taskstateinittasktmpl = tt.col_id
  JOIN tbl_dict_taskstate dt ON  dt.col_id = t.col_map_tskstinit_tskst
  INNER JOIN tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id
  INNER JOIN tbl_dict_casesystype c ON (p.col_proceduredict_casesystype = c.col_id OR c.col_casesystypeprocedure = p.col_id) AND c.col_code = v_case_type
  JOIN tbl_map_taskstateinitiation  t2 ON dep.col_tskdpndchldtskstateinit = t2.col_id
  JOIN tbl_tasktemplate tt2 ON t2.col_map_taskstateinittasktmpl = tt2.col_id AND tt2.col_proceduretasktemplate = tt2.col_proceduretasktemplate
  JOIN tbl_dict_taskstate dt2 ON  dt2.col_id = t2.col_map_tskstinit_tskst
  LEFT JOIN TBL_AUTORULEPARAMETER ar ON dep.col_id = ar.col_autoruleparamtaskdep
GROUP BY dep.col_code,  dep.col_processorcode, dep.col_type, tt.col_code, tt2.col_code,dt.col_ucode, dt2.col_ucode, dep.col_id2,  dep.col_isdefault,  dep.col_taskdependencyorder ;

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
  INNER JOIN tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id
  INNER JOIN tbl_dict_casesystype c ON (p.col_proceduredict_casesystype = c.col_id OR c.col_casesystypeprocedure = p.col_id) AND c.col_code = v_case_type
  JOIN TBL_MAP_TASKSTATEINITTMPL  t2 ON dep.col_taskdpchldtptaskstinittp  = t2.col_id
  JOIN tbl_tasktemplate tt2 ON t2.col_map_taskstinittpltasktpl = tt2.col_id AND tt2.col_proceduretasktemplate = tt2.col_proceduretasktemplate
  JOIN tbl_dict_taskstate dt2 ON  dt2.col_id = t2.col_map_tskstinittpl_tskst 
  LEFT JOIN TBL_AUTORULEPARAMTMPL ar ON dep.col_id = ar.col_autoruleparamtptaskdeptp 
GROUP BY dep.col_code,  dep.col_processorcode, dep.col_type, tt.col_code, tt2.col_code,dt.col_ucode, dt2.col_ucode, dep.col_id2, dep.col_isdefault, dep.col_taskdependencyorder;

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
Xmlagg(Xmlelement("CaseLinkTMPL",
               XMLFOREST(t.col_ucode AS "Ucode",
                         t.col_code  AS "Code",
                         t.col_name  AS "Name",
                         t.col_cancreatechildfromparent AS "Cancreatechildfromparent",
                         t.col_cancreateparentfromchild AS "Cancreateparentfromchild",
                         t.col_canlinkchildtoparent AS "Canlinkchildtoparent",
                         t.col_canlinkparenttochild AS "Canlinkparenttochild",
                         ld.col_ucode AS "LinkDirection",
                         lt.col_code AS "LinkType",
                         cst.col_code AS "ChildCaseType",
                         cst2.col_code AS "PrntCaseType"
                         )
               )
       )
INTO v_xml                 
FROM TBL_CASELINKTMPL t
LEFT JOIN tbl_dict_linkdirection ld ON t.col_caselinktmpllinkdirection = ld.col_id
LEFT JOIN tbl_dict_linktype lt ON t.col_caselinktmpllinktype = lt.col_id 
LEFT JOIN tbl_dict_casesystype cst ON t.col_caselinktmplchildcasetype  = cst.col_id 
LEFT JOIN tbl_dict_casesystype cst2 ON t.col_caselinktmplprntcasetype  = cst2.col_id 
WHERE 
/*cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
OR*/ 
cst2.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)));


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

                INSERT INTO tbl_impCaseType_TMP
                (col_caseid)
                VALUES
                (ExportCaseTypeId);
               
FOR rec IN (SELECT col_caselinktmplchildcasetype FROM TBL_CASELINKTMPL t
					LEFT JOIN tbl_dict_casesystype cst ON t.col_caselinktmplchildcasetype  = cst.col_id 
					LEFT JOIN tbl_dict_casesystype cst2 ON t.col_caselinktmplprntcasetype  = cst2.col_id 
					WHERE/* cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
					OR*/ cst2.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type))) 
                    AND NOT EXISTS (SELECT 1 FROM tbl_impCaseType_TMP tmp WHERE tmp.col_caseid = col_caselinktmplchildcasetype)
                    )LOOP

            IF 	rec.col_caselinktmplchildcasetype != ExportCaseTypeId THEN 
                dbms_lob.append(v_clob, '<CaseTypeChild>');
                dbms_lob.append(v_clob, f_UTIL_exportDCMDataXMLfn(ExportCaseTypeId => rec.col_caselinktmplchildcasetype, CustomBOTags => null));
                dbms_lob.append(v_clob, '</CaseTypeChild>');
            END IF;

                INSERT INTO tbl_impCaseType_TMP
                (col_caseid)
                VALUES
                (rec.col_caselinktmplchildcasetype);
END LOOP;

/***************************************************************************************************/
--Support adhoc pcocedure 
/***************************************************************************************************/
FOR rec IN (
SELECT pr.col_id, rownum rn
--      INTO v_adhoc  
FROM tbl_stp_availableadhoc ah
JOIN tbl_procedure pr ON ah.col_procedure = pr.col_id 
LEFT JOIN tbl_dict_casesystype ct ON ah.col_casesystype = ct.col_id
--LEFT JOIN tbl_dict_casesystype cst ON pr.col_proceduredict_casesystype = cst.col_id 
--LEFT JOIN tbl_dict_casesystype cst2 ON pr.col_id = cst2.col_casesystypeprocedure
where  ct.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
--or cst2.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)LOOP


IF rec.rn = 1 THEN 
        dbms_lob.append(v_clob, '<Availableadhoc><CaseProcedure>');
END IF;

  dbms_lob.append(v_clob, f_UTIL_exportProcXMLfn(ExportProcId => rec.col_id));


v_adhoc := rec.col_id;

END LOOP;

 if v_adhoc > 0 then
   dbms_lob.append(v_clob, '</CaseProcedure></Availableadhoc>');
   v_adhoc := 0;
 end if;

SELECT
Xmlagg(Xmlelement("Availableadhoc",
                  Xmlforest(col_code     AS "Code", 
                           TaskSysType   AS "TaskSysType", 
                           CaseSysType   AS "CaseSysType",
                           proc          AS "CaseProc",
                           isdeleted     AS "IsDeleted")
                  )
       )
INTO v_xml
from 
(SELECT ah.col_code, cst.col_code CaseSysType, tst.col_code TaskSysType, 
pr.col_code proc, ah.col_isdeleted isdeleted
FROM tbl_stp_availableadhoc ah
LEFT JOIN tbl_dict_tasksystype tst ON ah.col_tasksystype = tst.col_id
JOIN tbl_dict_casesystype cst ON ah.col_casesystype = cst.col_id AND cst.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
LEFT JOIN tbl_procedure pr ON ah.col_procedure = pr.col_id

)
;


/***************************************************************************************************/
--end support adhoc pcocedure 
/***************************************************************************************************/  

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
  Xmlagg(
  XMLELEMENT("FomObject",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_tablename  AS "Tablename", 
                      t.col_alias  AS "Alias", 
                      t.col_xmlalias  AS "XmlAlias",
                      t.col_isdeleted   AS "IsDeleted", 
                      t.col_isadded    AS "IsAdded",
                      t.col_apicode AS "ApiCode")
             )
         ) 
INTO v_xml       
FROM TBL_FOM_OBJECT t
WHERE EXISTS 
(SELECT 1 FROM  tbl_dom_object do,
                          tbl_dom_model dm,
                          tbl_mdm_model mm,
                          tbl_dict_casesystype cst
           WHERE do.col_dom_objectfom_object = t.col_id
           AND dm.col_id = do.col_dom_objectdom_model
           AND mm.col_id = dm.col_dom_modelmdm_model
           AND mm.col_id = cst.col_casesystypemodel
           AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR t.col_code = 'CASE'
;
                    
                    

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
  Xmlagg(
  XMLELEMENT("DictVersion",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name")
             )
         ) 

INTO v_xml 
FROM tbl_dict_version t
WHERE EXISTS (
SELECT 1 FROM 
tbl_dict_stateconfig sc 
LEFT JOIN tbl_dict_casesystype cst ON cst.col_stateconfigcasesystype = sc.col_id 
LEFT JOIN tbl_dict_casesystype cst1 ON sc.col_casesystypestateconfig = cst1.col_id
WHERE 
 sc.col_stateconfigversion = t.col_id
 AND (cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
OR cst1.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
      Xmlagg(Xmlelement
               ("SlaEvent",
                  XMLFOREST(se.col_code AS "Code", 
                            se.col_intervalds AS "Intervalds",
                            se.col_intervalym AS "Intervalym",
                            se.col_isrequired AS "Isrequired",
                            se.col_maxattempts AS "MaxAttempts",
                            se.col_slaeventorder AS "SlaEventOrder",
                            slat.col_code AS "SlaEventType",
                            tt.col_code AS "TaskTemplate",
                            det.col_code AS "DateEventType",
                            dsel.col_code AS "SlaEventLevel",
                            cst.col_code AS "CaseType",
                            se.col_isprimary AS "IsPrimary"
                            )
                   )
              )
   INTO  v_xml
FROM tbl_slaevent se
    LEFT JOIN tbl_tasktemplate tt ON se.col_slaeventtasktemplate = tt.col_id
    LEFT JOIN tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id
    LEFT JOIN tbl_dict_casesystype c ON (p.col_proceduredict_casesystype = c.col_id OR c.col_casesystypeprocedure = p.col_id)
    LEFT JOIN tbl_dict_slaeventtype slat ON se.col_slaeventdict_slaeventtype = slat.col_id
    LEFT JOIN TBL_DICT_DATEEVENTTYPE det ON se.col_slaevent_dateeventtype = det.col_id
    LEFT JOIN TBL_DICT_SLAEVENTLEVEL dsel ON se.col_slaevent_slaeventlevel = dsel.col_id
    LEFT JOIN tbl_dict_casesystype cst ON se.col_slaeventslacase = cst.col_id
WHERE c.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
OR cst.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)));


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
    LEFT JOIN tbl_procedure p	ON tt.col_proceduretasktemplate = p.col_id
	LEFT JOIN tbl_dict_casesystype c ON (p.col_proceduredict_casesystype = c.col_id OR c.col_casesystypeprocedure = p.col_id) 
    LEFT JOIN tbl_dict_slaeventtype slat ON se.col_slaeventtp_slaeventtype = slat.col_id
    LEFT JOIN TBL_DICT_DATEEVENTTYPE det ON se.col_slaeventtp_dateeventtype = det.col_id
    LEFT JOIN TBL_DICT_SLAEVENTLEVEL dsel ON se.col_slaeventtp_slaeventlevel = dsel.col_id
	LEFT JOIN tbl_dict_casesystype cst ON se.col_slaeventtmpldict_cst = cst.col_id
    LEFT JOIN tbl_dict_tasksystype tst ON se.col_slaeventtp_tasksystype = tst.col_id
WHERE (c.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type))) OR p.col_code IS NULL )
OR cst.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)));

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
    ,tbl_dict_casesystype c                              
WHERE  sa.col_slaaction_slaeventlevel = selvl.col_id
   AND sa.col_slaactionslaevent = se.col_id
   AND se.col_slaeventtasktemplate = tt.col_id
   AND tt.col_proceduretasktemplate = p.col_id
   AND (p.col_proceduredict_casesystype = c.col_id
   OR c.col_casesystypeprocedure = p.col_id
   ) AND c.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)));  

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
 LEFT JOIN tbl_dict_slaeventlevel selvl ON sa.col_slaactiontp_slaeventlevel = selvl.col_id
 LEFT JOIN TBL_SLAEVENTTMPL se ON sa.col_slaactiontpslaeventtp = se.col_id
 LEFT JOIN tbl_tasktemplate tt ON se.col_slaeventtptasktemplate = tt.col_id
 LEFT JOIN tbl_procedure p ON tt.col_proceduretasktemplate = p.col_id
 LEFT JOIN tbl_dict_casesystype c ON (p.col_proceduredict_casesystype = c.col_id OR c.col_casesystypeprocedure = p.col_id  )
WHERE  
c.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
OR c.col_code IS NULL ;  

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
LEFT JOIN tbl_dict_casesystype cst ON cst.col_stateconfigcasesystype = conf.col_id 
JOIN tbl_dict_taskstate tst2 ON trt.col_targettasktranstaskstate = tst2.col_id
LEFT JOIN tbl_dict_stateconfig conf2 ON tst2.col_stateconfigtaskstate = conf2.col_id
LEFT JOIN tbl_dict_casesystype cst2 ON cst2.col_stateconfigcasesystype = conf2.col_id 
WHERE cst.col_code IN (SELECT COLUMN_VALUE FROM TABLE(split_casetype_list(v_case_type)))
OR 
 cst2.col_code IN (SELECT COLUMN_VALUE FROM TABLE(split_casetype_list(v_case_type)))
OR 
EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tst1, tbl_stp_availableadhoc ah, tbl_dict_casesystype cst1  
  WHERE conf.col_id = tst1.col_stateconfigtasksystype
    AND ah.col_tasksystype = tst1.col_id
    AND ah.col_casesystype = cst1.col_id 
    AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR 
EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tst1, tbl_stp_availableadhoc ah, tbl_dict_casesystype cst1  
  WHERE conf2.col_id = tst1.col_stateconfigtasksystype
    AND ah.col_tasksystype = tst1.col_id
    AND ah.col_casesystype = cst1.col_id 
    AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)  ;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


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
LEFT JOIN tbl_fom_page fp                  ON fuel.col_uielementpage = fp.col_id
WHERE fuel.col_code != 'DEFAULT_PORTAL_DASHBOARD'
AND fp.col_id IN 
(SELECT assp.col_assocpagepage
FROM tbl_ASSOCPAGE assp
WHERE EXISTS 
(SELECT 1 FROM tbl_tasktemplate tt2, tbl_procedure pr WHERE assp.col_assocpagetasktemplate = tt2.col_id
    AND tt2.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) 
)
OR EXISTS 
( SELECT 1 FROM tbl_dict_casesystype dcst WHERE assp.col_assocpagedict_casesystype = dcst.col_id 
   AND dcst.col_code  IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR EXISTS 
( SELECT 1 FROM tbl_dict_tasksystype tstt, tbl_tasktemplate tt3, tbl_procedure pr2  WHERE assp.col_assocpagedict_tasksystype = tstt.col_id 
AND tstt.col_id = tt3.col_tasktmpldict_tasksystype AND tt3.col_proceduretasktemplate = pr2.col_id 
AND pr2.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) 
)
OR EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tst1, tbl_stp_availableadhoc ah, tbl_dict_casesystype cst1  
  WHERE assp.col_assocpagedict_tasksystype = tst1.col_id 
    AND ah.col_tasksystype = tst1.col_id
    AND ah.col_casesystype = cst1.col_id 
    AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR (
assp.col_partytypeassocpage IN  (SELECT col_id FROM tbl_dict_partytype)
)
)
OR 
fp.col_systemdefault = 1
or 
EXISTS 
(SELECT 1 FROM tbl_dom_object dm,
          TBL_DOM_MODEL m,
          TBL_MDM_MODEL mm,
          TBL_DICT_CASESYSTYPE ct
WHERE mdm.col_mdm_formdom_object = dm.col_id
AND dm.COL_DOM_OBJECTDOM_MODEL = m.COL_ID
AND m.COL_DOM_MODELMDM_MODEL = mm.COL_ID
AND mm.col_id = ct.col_casesystypemodel
AND ct.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type))) 
) 
OR
EXISTS 
(SELECT 1 FROM tbl_stp_availableadhoc ah, 
               tbl_dict_casesystype cst 
 WHERE ah.col_tasksystype = tt.col_id
   AND ah.col_casesystype = cst.col_id 
   AND cst.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
	 ) 
OR( fuel.col_uielementdashboard IS NOT NULL)
 AND dsh.col_dashboardcaseworker IS NULL
;

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
LEFT JOIN tbl_ac_accessobjecttype aot ON ao.col_accessobjaccessobjtype = aot.col_id
LEFT JOIN tbl_dict_accesstype acct ON ao.col_accessobjectaccesstype = acct.col_id
JOIN tbl_dict_casestate cst ON ao.col_accessobjectcasestate = cst.col_id AND 
(cst.col_stateconfigcasestate IN (SELECT conf.col_id FROM tbl_dict_stateconfig conf 
                                    JOIN tbl_dict_casesystype ct ON ct.col_stateconfigcasesystype = conf.col_id 
                                     AND ct.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
                                     )
)
LEFT JOIN tbl_dict_casesystype cstp ON ao.col_accessobjectcasesystype = cstp.col_id 
LEFT JOIN tbl_dict_tasksystype tst ON ao.col_accessobjecttasksystype = tst.col_id 
LEFT JOIN tbl_fom_uielement ue ON ao.col_accessobjectuielement = ue.col_id
LEFT JOIN tbl_dict_casetransition ctr ON ao.col_accessobjcasetransition = ctr.col_id
UNION 
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
LEFT JOIN tbl_ac_accessobjecttype aot ON ao.col_accessobjaccessobjtype = aot.col_id
LEFT JOIN tbl_dict_accesstype acct ON ao.col_accessobjectaccesstype = acct.col_id
LEFT JOIN tbl_dict_casestate cst ON ao.col_accessobjectcasestate = cst.col_id 
JOIN tbl_dict_casesystype cstp ON ao.col_accessobjectcasesystype = cstp.col_id 
 AND cstp.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
LEFT JOIN tbl_dict_tasksystype tst ON ao.col_accessobjecttasksystype = tst.col_id 
LEFT JOIN tbl_fom_uielement ue ON ao.col_accessobjectuielement = ue.col_id
LEFT JOIN tbl_dict_casetransition ctr ON ao.col_accessobjcasetransition = ctr.col_id
UNION 
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
LEFT JOIN tbl_ac_accessobjecttype aot ON ao.col_accessobjaccessobjtype = aot.col_id
LEFT JOIN tbl_dict_accesstype acct ON ao.col_accessobjectaccesstype = acct.col_id
LEFT JOIN tbl_dict_casestate cst ON ao.col_accessobjectcasestate = cst.col_id 
LEFT JOIN tbl_dict_casesystype cstp ON ao.col_accessobjectcasesystype = cstp.col_id 
JOIN tbl_dict_tasksystype tst ON ao.col_accessobjecttasksystype = tst.col_id 
LEFT JOIN tbl_fom_uielement ue ON ao.col_accessobjectuielement = ue.col_id
LEFT JOIN tbl_dict_casetransition ctr ON ao.col_accessobjcasetransition = ctr.col_id
WHERE EXISTS 
( SELECT 1 FROM tbl_tasktemplate tt, tbl_procedure pr WHERE tt.col_tasktmpldict_tasksystype = tst.col_id 
    AND tt.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR
EXISTS 
(SELECT 1 FROM tbl_stp_availableadhoc ah, 
               tbl_dict_casesystype cst 
 WHERE ah.col_tasksystype = tst.col_id
   AND ah.col_casesystype = cst.col_id 
   AND cst.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
	 ) 
UNION 
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
left JOIN tbl_ac_accessobjecttype aot ON ao.col_accessobjaccessobjtype = aot.col_id
LEFT JOIN tbl_dict_accesstype acct ON ao.col_accessobjectaccesstype = acct.col_id
LEFT JOIN tbl_dict_casestate cst ON ao.col_accessobjectcasestate = cst.col_id 
LEFT JOIN tbl_dict_casesystype cstp ON ao.col_accessobjectcasesystype = cstp.col_id 
LEFT JOIN tbl_dict_tasksystype tst ON ao.col_accessobjecttasksystype = tst.col_id 
LEFT JOIN tbl_dict_casetransition ctr ON ao.col_accessobjcasetransition = ctr.col_id
JOIN tbl_fom_uielement ue ON ao.col_accessobjectuielement = ue.col_id 
    LEFT JOIN tbl_fom_page fp ON ue.col_uielementpage = fp.col_id
WHERE ue.col_code != 'DEFAULT_PORTAL_DASHBOARD'
AND fp.col_id IN 
(SELECT assp.col_assocpagepage
FROM tbl_ASSOCPAGE assp
WHERE EXISTS 
(SELECT 1 FROM tbl_tasktemplate tt2, tbl_procedure pr WHERE assp.col_assocpagetasktemplate = tt2.col_id
    AND tt2.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) 
)
OR EXISTS 
( SELECT 1 FROM tbl_dict_casesystype dcst WHERE assp.col_assocpagedict_casesystype = dcst.col_id 
   AND dcst.col_code  IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR EXISTS 
( SELECT 1 FROM tbl_dict_tasksystype tstt, tbl_tasktemplate tt3, tbl_procedure pr2  WHERE assp.col_assocpagedict_tasksystype = tstt.col_id 
AND tstt.col_id = tt3.col_tasktmpldict_tasksystype AND tt3.col_proceduretasktemplate = pr2.col_id 
AND pr2.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) 
)
OR EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tst1, tbl_stp_availableadhoc ah, tbl_dict_casesystype cst1  
  WHERE assp.col_assocpagedict_tasksystype = tst1.col_id 
    AND ah.col_tasksystype = tst1.col_id
    AND ah.col_casesystype = cst1.col_id 
    AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR (
assp.col_partytypeassocpage IN  (SELECT col_id FROM tbl_dict_partytype)
)
)
OR 
fp.col_systemdefault = 1
or 
EXISTS 
(SELECT 1 FROM tbl_mdm_form mdm,
          tbl_dom_object dm,
          TBL_DOM_MODEL m,
          TBL_MDM_MODEL mm,
          TBL_DICT_CASESYSTYPE ct
WHERE ue.col_uielementform = mdm.col_id
AND mdm.col_mdm_formdom_object = dm.col_id
AND dm.COL_DOM_OBJECTDOM_MODEL = m.COL_ID
AND m.COL_DOM_MODELMDM_MODEL = mm.COL_ID
AND mm.col_id = ct.col_casesystypemodel
AND ct.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type))) 
) 
OR
EXISTS 
(SELECT 1 FROM tbl_dict_tasksystype tt,
               tbl_stp_availableadhoc ah, 
               tbl_dict_casesystype cst 
 WHERE ue.col_uielementtasksystype = tt.col_id
   AND ah.col_tasksystype = tt.col_id
   AND ah.col_casesystype = cst.col_id 
   AND cst.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
) 
OR ue.col_uielementdashboard IS NOT NULL
OR ue.col_uielementpage IS NOT NULL
UNION 
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
LEFT JOIN tbl_ac_accessobjecttype aot ON ao.col_accessobjaccessobjtype = aot.col_id
LEFT JOIN tbl_dict_accesstype acct ON ao.col_accessobjectaccesstype = acct.col_id
LEFT JOIN tbl_dict_casestate cst ON ao.col_accessobjectcasestate = cst.col_id 
LEFT JOIN tbl_dict_casesystype cstp ON ao.col_accessobjectcasesystype = cstp.col_id 
LEFT JOIN tbl_dict_tasksystype tst ON ao.col_accessobjecttasksystype = tst.col_id 
LEFT JOIN tbl_fom_uielement ue ON ao.col_accessobjectuielement = ue.col_id
JOIN tbl_dict_casetransition ctr ON ao.col_accessobjcasetransition = ctr.col_id
JOIN tbl_dict_casestate dcs1 ON ctr.col_sourcecasetranscasestate = dcs1.col_id 
JOIN tbl_dict_stateconfig sc ON dcs1.col_stateconfigcasestate = sc.col_id 
JOIN tbl_dict_casesystype cst1 ON cst1.col_stateconfigcasesystype = sc.col_id
AND cst1.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
UNION 
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
LEFT JOIN tbl_fom_uielement ue ON ao.col_accessobjectuielement = ue.col_id
LEFT JOIN tbl_dict_casetransition ctr ON ao.col_accessobjcasetransition = ctr.col_id
WHERE aot.col_code IN ('PAGE_ELEMENT','DASHBOARD_ELEMENT')
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
(SELECT 1 FROM tbl_stp_availableadhoc ah,tbl_dict_casesystype cst1  
WHERE ah.col_tasksystype = tstp.col_id
AND ah.col_casesystype = cst1.col_id 
AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR EXISTS 
( SELECT 1 FROM tbl_dict_casesystype dcst WHERE assp.col_assocpagedict_casesystype = dcst.col_id 
   AND dcst.col_code  IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
   
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
Xmlagg(Xmlelement("Team",
                         Xmlelement("Code", tm.col_code),
                         Xmlelement("Description", tm.col_description),
                         Xmlelement("GroupId", tm.col_groupid),
                         Xmlelement("Name", tm.col_name),
                         Xmlelement("ParentCode", (SELECT tm1.col_code FROM Tbl_Ppl_Team tm1 WHERE tm.col_parentteamid = tm1.col_id) ),
                         Xmlelement("AccessSubject", ascd.col_code)
                         
                         )
             )
INTO v_xml                          
FROM 
(SELECT * FROM  
Tbl_Ppl_Team 
ORDER BY 1 ASC ) tm
LEFT JOIN TBL_AC_ACCESSSUBJECT ascd ON tm.col_teamaccesssubject = ascd.col_id ;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
       Xmlagg(Xmlelement("BusinessRole",
                         Xmlelement("Code", br.col_code), 
                         Xmlelement("Description", br.col_description),
                         Xmlelement("Name", br.col_name),
                         Xmlelement("AccessSubject", ascd.col_code)
                         )
              )
INTO v_xml              
FROM Tbl_Ppl_Businessrole br
LEFT JOIN TBL_AC_ACCESSSUBJECT ascd ON br.col_businessroleaccesssubject = ascd.col_id;

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
                         Xmlelement("Team", team.col_code),
                         Xmlelement("BusinessRole", br.col_code),
                         Xmlelement("Ucode", t.col_ucode)
                         )
              )
INTO v_xml
FROM TBL_PPL_WORKBASKET t
JOIN tbl_dict_workbaskettype wbt 
ON t.col_workbasketworkbaskettype = wbt.col_id 
JOIN tbl_ppl_team team ON t.col_workbasketteam = team.col_id
LEFT JOIN tbl_ppl_businessrole br ON br.col_id = t.col_workbasketbusinessrole;

SELECT 
Xmlconcat(v_xml,
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
                         Xmlelement("Team", team.col_code),
                         Xmlelement("BusinessRole", br.col_code)
                         )
              )
)
INTO v_xml
FROM TBL_PPL_WORKBASKET t
JOIN tbl_dict_workbaskettype wbt 
ON t.col_workbasketworkbaskettype = wbt.col_id 
LEFT JOIN tbl_ppl_team team ON t.col_workbasketteam = team.col_id
JOIN tbl_ppl_businessrole br ON br.col_id = t.col_workbasketbusinessrole;


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
      Xmlagg(Xmlelement("MapWorkBasketTeam",
               Xmlelement("Team", tm.col_code),
               Xmlelement("WorkBasket", wb.col_code)
               )
              )
INTO v_xml
FROM tbl_map_workbasketteam wbtm
JOIN TBL_PPL_WORKBASKET wb ON wbtm.col_map_wb_tm_workbasket = wb.col_id AND (wb.col_workbasketbusinessrole IS NOT NULL OR wb.col_workbasketteam IS NOT NULL)
JOIN tbl_ppl_team tm ON wbtm.col_map_wb_tm_team = tm.col_id;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
Xmlagg(Xmlelement("MapWorkBasketBR",
               Xmlelement("BusinesRole", br.col_code),
               Xmlelement("WorkBasket", wb.col_code)
               )
              )
INTO v_xml
FROM tbl_map_workbasketbusnessrole wbbr
JOIN TBL_PPL_WORKBASKET wb ON wbbr.col_map_wb_br_workbasket = wb.col_id AND (wb.col_workbasketbusinessrole IS NOT NULL OR wb.col_workbasketteam IS NOT NULL)
JOIN tbl_ppl_businessrole br ON wbbr.col_map_wb_wr_businessrole = br.col_id;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


/*
SELECT 
       Xmlagg(Xmlelement("ExternalParty",
              Xmlelement("IsDeleted", ep.col_isdeleted),
              Xmlelement("LeverAgeratio", ep.col_leverageratio),
              Xmlelement("LogoUrl", ep.col_logourl),
              Xmlelement("Name", ep.col_name),
              Xmlelement("ExternalPartyRoot", (SELECT col_code FROM tbl_externalparty ep1 WHERE ep.col_extpartyextparty = ep1.col_id )),
              Xmlelement("PartyType", pt.col_code),
              Xmlelement("Workbasket", wb.col_code),
              Xmlelement("Address", ep.col_address),
              Xmlelement("Email", ep.col_email),
              Xmlelement("Phone", ep.col_phone),
              Xmlelement("Description", ep.col_description),
              Xmlelement("Team", tem.col_code),
              Xmlelement("Code", ep.col_code),
              Xmlelement("CustomData", DBMS_XMLGEN.CONVERT(xmlData => ep.col_customdata.getClobVal(),flag =>DBMS_XMLGEN.ENTITY_ENCODE)),
              Xmlelement("AccessSubject", ascd.col_code),
              Xmlelement("UserId", ep.col_userid)
              )
              )
--)
INTO v_xml
FROM (SELECT * FROM tbl_externalparty ORDER BY col_extpartyextparty NULLS FIRST ) 
ep
LEFT JOIN tbl_dict_partytype pt ON ep.col_externalpartypartytype = pt.col_id 
LEFT JOIN tbl_ppl_workbasket wb ON ep.col_externalpartyworkbasket = wb.col_id
LEFT JOIN tbl_ppl_team tem ON ep.col_defaultteam = tem.col_id
LEFT JOIN tbl_ac_accesssubject AScd ON ep.col_extpartyaccesssubject = ascd.col_id ;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;
*/

SELECT 
--Xmlconcat(v_xml,
        Xmlagg(Xmlelement("CustomCategory",
              Xmlelement("Code", r.col_code),
              Xmlelement("Name", r.col_name),
              Xmlelement("Description", r.col_description),
              Xmlelement("IsDeleted", r.col_isdeleted),
              Xmlelement("CustCategoryCode", (SELECT col_code FROM tbl_DICT_CUSTOMCATEGORY c WHERE c.col_id = r.col_categorycategory)),
              Xmlelement("IconCode", col_iconcode),
              Xmlelement("ColorCode", col_colorcode ),
              Xmlelement("Categoryorder", col_categoryorder ) 
              )
              )
--)
INTO v_xml
FROM 
tbl_DICT_CUSTOMCATEGORY r
ORDER BY col_categorycategory NULLS FIRST; 


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
--Xmlconcat(v_xml2,
       Xmlagg(Xmlelement("CustomWord",
              Xmlelement("Code", cwrd.col_code),
              Xmlelement("Name", cwrd.col_name),
              Xmlelement("Description", cwrd.col_description),
              Xmlelement("IsDeleted", cwrd.col_isdeleted),
              Xmlelement("Order", cwrd.col_order),
              Xmlelement("RowStyle", cwrd.col_rowstyle),
              Xmlelement("Status", cwrd.col_status),
              Xmlelement("Style", cwrd.col_style),
              Xmlelement("Value", cwrd.col_value),
              Xmlelement("WordCategory", cc.col_code),
              Xmlelement("Ucode", cwrd.col_ucode)  
                            )
) 
--)
INTO v_xml  
FROM 
tbl_DICT_CUSTOMWORD cwrd
LEFT JOIN tbl_DICT_CUSTOMCATEGORY cc ON cwrd.col_wordcategory = cc.col_id;

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
WHERE stscong.col_code IS NOT NULL;

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
WHERE stscong.col_code IS NOT NULL;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT  
        Xmlagg(Xmlelement("CaseStateDateEventType",
              Xmlelement("CaseState", cstat.col_ucode), 
              Xmlelement("DateEventType", det.col_code),
              Xmlelement("Config", stsc.col_code)
              )
              )
INTO v_xml                  
FROM TBL_DICT_CSEST_DTEVTP cset
JOIN tbl_dict_casestate cstat ON cset.col_csest_dtevtpcasestate = cstat.col_id
JOIN tbl_dict_stateconfig stsc ON cstat.col_stateconfigcasestate = stsc.col_id
JOIN tbl_dict_casesystype cst ON cst.col_stateconfigcasesystype = stsc.col_id AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type))) 
JOIN tbl_dict_dateeventtype det ON cset.col_csest_dtevtpdateeventtype = det.col_id
;

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
JOIN tbl_dict_stateconfig sc ON tst.col_stateconfigtaskstate = sc.col_id
JOIN tbl_dict_casesystype cst ON cst.col_stateconfigcasesystype = sc.col_id AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)));

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
      ar.col_issystem,           ar.col_paramvalue,     ar.col_paramcode,      ar.col_owner, 
      ar.col_code,               sa.col_code SLAAction, cd.col_code CaseDep,   cst.col_code AS CaseType, 
      pc.col_code ParamConf,     tad.col_code TaskDep,  ce.col_code CaseEvent, cit.col_code CaseStateIni, 
      tit.col_code TaskStateIni, te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl,
      ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction
FROM 
tbl_autoruleparamtmpl ar
JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamtpcasetype = cst.col_id AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
LEFT JOIN tbl_slaactiontmpl sa ON ar.col_autorulepartpslaactiontp = sa.col_id
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
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl  ,
      ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction
FROM tbl_autoruleparamtmpl ar
JOIN tbl_slaactiontmpl sa ON ar.col_autorulepartpslaactiontp = sa.col_id
JOIN tbl_slaeventtmpl se ON sa.col_slaactiontpslaeventtp = se.col_id
JOIN tbl_tasktemplate tt1 ON se.col_slaeventtptasktemplate = tt1.col_id
JOIN tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
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
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl,
      ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction   
FROM tbl_autoruleparamtmpl ar
JOIN tbl_caseeventtmpl ce ON ar.col_caseeventtpautorulepartp = ce.col_id  
JOIN tbl_map_casestateinittmpl ci ON ce.col_caseeventtpcasestinittp = ci.col_id
JOIN tbl_dict_casesystype cst1 ON ci.col_casestateinittp_casetype = cst1.col_id AND cst1.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
left JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamtpcasetype = cst.col_id 
LEFT JOIN tbl_slaactiontmpl sa ON ar.col_autorulepartpslaactiontp = sa.col_id
LEFT JOIN tbl_casedependencytmpl cd ON ar.col_autoruleparamtpcasedeptp = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamtpparamconf = pc.col_id
LEFT JOIN tbl_taskdependencytmpl tad ON ar.col_autoruleparamtptaskdeptp = tad.col_id
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
JOIN tbl_map_casestateinittmpl cit ON  ar.col_rulepartp_casestateinittp = cit.col_id
JOIN tbl_dict_casesystype cst1 ON cit.col_casestateinittp_casetype = cst1.col_id AND cst1.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamtpcasetype = cst.col_id
LEFT JOIN tbl_slaactiontmpl sa ON ar.col_autorulepartpslaactiontp = sa.col_id
LEFT JOIN tbl_casedependencytmpl cd ON ar.col_autoruleparamtpcasedeptp = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamtpparamconf = pc.col_id
LEFT JOIN tbl_taskdependencytmpl tad ON ar.col_autoruleparamtptaskdeptp = tad.col_id
LEFT JOIN tbl_caseeventtmpl ce ON ar.col_caseeventtpautorulepartp = ce.col_id 
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
tet.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl  ,
      ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction
FROM tbl_autoruleparamtmpl ar
JOIN tbl_taskeventtmpl tet ON ar.col_taskeventtpautoruleparmtp = tet.col_id
JOIN TBL_MAP_TASKSTATEINITTMPL tit1 ON tet.col_taskeventtptaskstinittp  = tit1.col_id
JOIN tbl_tasktemplate tt1 ON tit1.col_map_taskstinittpltasktpl = tt1.col_id
JOIN  tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
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
JOIN tbl_map_casestateinittmpl mci ON tmp.col_casedpCLDtplcasestinittpl = mci.col_id
JOIN tbl_dict_casesystype sc ON mci.col_casestateinittp_casetype = sc.col_id AND sc.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
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
JOIN tbl_map_casestateinittmpl mci ON tmp.col_casedpPRTtplcasestinittpl = mci.col_id
JOIN tbl_dict_casesystype sc ON mci.col_casestateinittp_casetype = sc.col_id AND sc.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
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
JOIN tbl_map_taskstateinittmpl mti ON tmp.col_casedpcldtpltaskstinittpl = mti.col_id
JOIN tbl_tasktemplate tt1 ON mti.col_map_taskstinittpltasktpl = tt1.col_id
JOIN  tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
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
JOIN tbl_tasktemplate tt1 ON mti.col_map_taskstinittpltasktpl = tt1.col_id
JOIN  tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
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
JOIN tbl_tasktemplate tt1 ON mti.col_map_taskstinittpltasktpl = tt1.col_id
JOIN  tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
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
JOIN tbl_tasktemplate tt1 ON mti.col_map_taskstinittpltasktpl = tt1.col_id
JOIN  tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
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
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl   ,
      ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction
FROM tbl_autoruleparamtmpl ar
JOIN tbl_map_taskstateinittmpl mti ON ar.col_rulepartp_taskstateinittp = mti.col_id
JOIN tbl_tasktemplate tt1 ON mti.col_map_taskstinittpltasktpl = tt1.col_id
JOIN  tbl_procedure p ON tt1.col_proceduretasktemplate = p.col_id AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
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
UNION 
SELECT 
ar.col_issystem, ar.col_paramvalue, ar.col_paramcode, ar.col_owner, ar.col_code, 
sa.col_code SLAAction, cd.col_code CaseDep, cst.col_code AS CaseType, 
pc.col_code ParamConf, tad.col_code TaskDep,
ce.col_code CaseEvent, cit.col_code CaseStateIni, mti.col_code TaskStateIni,
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl   ,
      ste.col_ucode StateEventUcode, dsa.col_ucode StateSlaAction
FROM tbl_autoruleparamtmpl ar
LEFT JOIN tbl_map_taskstateinittmpl mti ON ar.col_rulepartp_taskstateinittp = mti.col_id
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
WHERE EXISTS (
SELECT 1 
    FROM TBL_DICT_StateEvent ste1
    INNER JOIN TBL_DICT_STATE st1 ON ste1.COL_STATEEVENTSTATE=st1.col_ID
    INNER JOIN tbl_dict_stateconfig sc1 ON st1.col_statestateconfig = sc1.col_id
    INNER JOIN tbl_dict_casesystype cst1 ON sc1.col_casesystypestateconfig = cst1.col_id
    WHERE cst1.col_code in (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
    AND ste1.COL_ID = ar.COL_AUTORULEPARTMPLSTATEEVENT)
OR EXISTS (
SELECT 1 
    FROM TBL_DICT_StateEvent ste1
    INNER JOIN TBL_DICT_STATE st1 ON ste1.COL_STATEEVENTSTATE=st1.col_ID
    INNER JOIN tbl_dict_stateconfig sc1 ON st1.col_statestateconfig = sc1.col_id
    INNER JOIN tbl_dict_casesystype cst1 ON sc1.col_casesystypestateconfig = cst1.col_id
    WHERE cst1.col_code in (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
    AND ste1.COL_ID = dsa.COL_STATESLAACTNSTATESLAEVNT)
)
;


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

FOR rec IN (
SELECT pr.col_id, ROWNUM rn 
FROM 
tbl_autoruleparamtmpl t
JOIN tbl_procedure pr ON t.col_paramvalue = pr.col_code
WHERE col_paramCode  = 'ProcedureCode'
AND EXISTS 
( SELECT ParamValue
                FROM XMLTABLE('AutoRuleParamTmpl'
                    PASSING v_xml
                    COLUMNS
                             ParamValue         NVARCHAR2(255) PATH './ParamValue'
                             ) 
WHERE ParamValue = pr.col_code 
)
) LOOP

IF rec.rn = 1 THEN 
        dbms_lob.append(v_clob, '<AutoruleParamProc><CaseProcedure>');
END IF;

  dbms_lob.append(v_clob, f_UTIL_exportProcXMLfn(ExportProcId => rec.col_id));


v_adhoc := rec.col_id;

END LOOP;

 if v_adhoc > 0 then
   dbms_lob.append(v_clob, '</CaseProcedure></AutoruleParamProc>');
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
      ar.col_issystem,           ar.col_paramvalue,     ar.col_paramcode,      ar.col_owner, 
      ar.col_code,               sa.col_code SLAAction, cd.col_code CaseDep,   cst.col_code AS CaseType, 
      pc.col_code ParamConf,     tad.col_code TaskDep,  ce.col_code CaseEvent, cit.col_code CaseStateIni, 
      tit.col_code TaskStateIni, te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl
FROM 
tbl_autoruleparameter ar
JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamcasesystype = cst.col_id AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
LEFT JOIN tbl_slaaction sa ON ar.col_autoruleparamslaaction = sa.col_id
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
te.col_code TaskEvent, tst.col_code TaskType, tt.col_code TaskTempl   
FROM tbl_autoruleparameter ar
JOIN tbl_caseevent ce ON ar.col_caseeventautoruleparam = ce.col_id  
JOIN tbl_map_casestateinitiation ci ON ce.col_caseeventcasestateinit = ci.col_id
JOIN tbl_dict_casesystype cst1 ON ci.col_casestateinit_casesystype = cst1.col_id AND cst1.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamcasesystype = cst.col_id
LEFT JOIN tbl_slaaction sa ON ar.col_autoruleparamslaaction = sa.col_id
LEFT JOIN tbl_casedependency cd ON ar.col_autoruleparamcasedep = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamparamconfig = pc.col_id 
LEFT JOIN tbl_taskdependency tad ON ar.col_autoruleparamtaskdep = tad.col_id
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
    JOIN tbl_map_casestateinitiation cit ON  ar.col_ruleparam_casestateinit = cit.col_id
    JOIN tbl_dict_casesystype cst1 ON cit.col_casestateinit_casesystype = cst1.col_id AND cst1.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
LEFT JOIN tbl_dict_casesystype cst ON ar.col_autoruleparamcasesystype = cst.col_id
LEFT JOIN tbl_slaaction sa ON ar.col_autoruleparamslaaction = sa.col_id
LEFT JOIN tbl_casedependency cd ON ar.col_autoruleparamcasedep = cd.col_id
LEFT JOIN tbl_paramconfig pc ON ar.col_autoruleparamparamconfig = pc.col_id 
LEFT JOIN tbl_taskdependency tad ON ar.col_autoruleparamtaskdep = tad.col_id
LEFT JOIN tbl_caseevent ce ON ar.col_caseeventautoruleparam = ce.col_id 
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
    JOIN tbl_map_casestateinitiation mci ON tmp.col_casedpndchldcasestateinit = mci.col_id
    JOIN tbl_dict_casesystype sc ON mci.col_casestateinit_casesystype = sc.col_id AND sc.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
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
    JOIN tbl_map_casestateinitiation mci ON tmp.col_casedpndprntcasestateinit = mci.col_id
    JOIN tbl_dict_casesystype sc ON mci.col_casestateinit_casesystype = sc.col_id AND sc.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
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

BEGIN

SELECT pr1.col_id
BULK COLLECT INTO  v_procAutorul
FROM tbl_autoruleparamtmpl art
JOIN tbl_taskeventtmpl t ON art.col_taskeventtpautoruleparmtp = t.col_id AND t.col_processorcode = 'f_EVN_injectProcedure'
JOIN tbl_map_taskstateinittmpl p ON t.col_taskeventtptaskstinittp = p.col_id
JOIN tbl_tasktemplate tt ON p.col_map_taskstinittpltasktpl = tt.col_id
JOIN tbl_procedure pr ON tt.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
JOIN tbl_procedure pr1 ON art.col_paramvalue = pr1.col_code
WHERE art.col_paramcode = 'ProcedureCode'
;


IF v_procAutorul.count >0 THEN 
  FOR i IN v_procAutorul.FIRST .. v_procAutorul.LAST LOOP

      dbms_lob.append(v_clob, f_UTIL_exportProcXMLfn(ExportProcId => v_procAutorul(i))); 

  END LOOP;
END IF;

EXCEPTION WHEN NO_DATA_FOUND THEN 
   NULL;
  
END;


SELECT 
Xmlagg(
XMLELEMENT("CaseResolutionCode",
                 XMLELEMENT("CaseCode", cst.col_code),
                 XMLELEMENT("ResolutionCode", rc.col_code)
           )
           )      
INTO v_xml 
FROM 
tbl_dict_casesystype cst,
tbl_casesystyperesolutioncode cstrc,
tbl_stp_resolutioncode rc
WHERE cstrc.col_tbl_dict_casesystype = cst.col_id
AND cstrc.COL_CASETYPERESOLUTIONCODE = rc.col_id
AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)));

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
                      t.col_ucode             AS "Ucode")
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
WHERE (t.col_commoneventcasetype IS NOT NULL AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type))))
OR    (t.col_commoneventtasktmpl IS NOT NULL AND EXISTS (SELECT 1 FROM tbl_procedure proc WHERE proc.col_id = tt.col_proceduretasktemplate
             AND proc.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) ))
OR    (t.col_commoneventtasktype IS NOT NULL AND 
              EXISTS 
              (SELECT 1 FROM tbl_tasktemplate tats, tbl_procedure pr WHERE tats.col_tasktmpldict_tasksystype = tst.col_id 
                  AND tats.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))    )
          OR EXISTS 
              (SELECT 1 FROM tbl_stp_availableadhoc ah, tbl_dict_casesystype cst1 WHERE ah.col_casesystype = cst1.col_id 
                  AND  ah.col_tasksystype = tst.col_id
                  AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))  )      
       )
OR (t.col_commoneventprocedure IS NOT NULL AND p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))));


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
                      tst.col_code            AS "TaskType",
                      t.col_customconfig      AS "CustomConfig",
                      t.col_repeatingevent    AS "RepeatingEvent",
                      t.col_description       AS "Description")
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
WHERE (cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type))))
OR 
      (p.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))))
OR 
      (EXISTS 
              ( SELECT 1 FROM tbl_tasktemplate tats, tbl_procedure pr WHERE tats.col_tasktmpldict_tasksystype = tst.col_id 
                  AND tats.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) 
                  )
       OR EXISTS 
              (SELECT 1 FROM tbl_stp_availableadhoc ah, tbl_dict_casesystype cst1 WHERE ah.col_casesystype = cst1.col_id 
                  AND  ah.col_tasksystype = tst.col_id
                  AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))  )           
      )
OR 
      ( EXISTS (SELECT 1 FROM tbl_procedure proc WHERE proc.col_id = tt.col_proceduretasktemplate
                    AND proc.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))))
      );

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
Xmlagg(Xmlelement("AccessSubject",
              XMLFOREST( t.col_code AS "Code",
                         t.col_name AS "Name",
                         t.col_type AS "Type")
          )
) 

INTO v_xml 
FROM TBL_AC_ACCESSSUBJECT t
where col_type IN ('TEAM','BUSINESSROLE');

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
WHERE asb.col_type IN ('TEAM','BUSINESSROLE')
AND (ac.col_accessobjectcasesystype IS NULL OR 
ac.col_accessobjectcasesystype IN (SELECT col_id FROM tbl_dict_casesystype WHERE col_code IN 
(SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
); 

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT  
Xmlagg(Xmlelement("ACPermition",
               XMLFOREST( ap.col_code AS "Code",
                          ap.col_defaultacl AS "DefaultACL",
                          ap.col_description AS "Description",
                          ap.col_name AS "Name",
                          ap.col_orderacl AS "OrderACL", 
                          ap.col_position AS "Position", 
                          ac.col_code AS "AccessObjectType", 
                          ap.col_ucode AS "Ucode")
                 )
     )                 
INTO v_xml               
FROM tbl_AC_PERMISSION ap
LEFT JOIN tbl_ac_accessobjecttype ac ON ap.col_permissionaccessobjtype = ac.col_id
WHERE  EXISTS 
(SELECT 1 FROM tbl_ac_acl acl,
tbl_ac_accesssubject asbj 
WHERE acl.col_aclaccesssubject = asbj.col_id 
AND acl.col_aclpermission = ap.col_id
AND asbj.col_type IN ('BUSINESSROLE','TEAM'));

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
Xmlagg(
  XMLELEMENT("UiElementDomAttr",
            XMLFOREST(
            da.col_ucode AS "DOMAttrUcode",
            uae.col_code AS "FomUIElCode"
            )
                      
             )
         )
INTO 
v_xml          
FROM 
tbl_uielement_dom_attribute ua
JOIN tbl_DOM_Attribute da ON ua.col_dom_attribute_id = da.col_id 
JOIN tbl_fom_uielement uae ON ua.col_fom_uielement_id = uae.col_id 
   WHERE col_fom_uielement_id IN (SELECT uie.col_id
                                    FROM tbl_fom_uielement uie
                                   INNER JOIN tbl_mdm_form f
                                      ON uie.col_uielementform = f.col_id
                                   INNER JOIN tbl_dom_object o
                                      ON f.col_mdm_formdom_object = o.col_id
                                   INNER JOIN tbl_dom_model m
                                      ON o.col_dom_objectdom_model = m.col_id
                                   INNER JOIN tbl_mdm_model mm
                                      ON m.col_dom_modelmdm_model = mm.col_id
                                   INNER JOIN tbl_dict_casesystype cst ON  mm.col_id = cst.col_casesystypemodel
                                   AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
                                   )
; 

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


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
WHERE 
EXISTS 
(SELECT 1 FROM  
    tbl_dict_stateconfig g,
    tbl_dict_casesystype cst 
    WHERE dst.col_statestateconfig = g.col_id
      AND g.col_casesystypestateconfig = cst.col_id
      AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR EXISTS 
(SELECT 1 FROM  
    tbl_dict_stateconfig g1,
    tbl_dict_casesystype cst1 
    WHERE dst1.col_statestateconfig = g1.col_id
      AND g1.col_casesystypestateconfig = cst1.col_id
      AND cst1.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
); 

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

END IF; --Case Type 


SELECT 
  Xmlagg(
  XMLELEMENT("FomObject",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_tablename  AS "Tablename", 
                      t.col_alias  AS "Alias", 
                      t.col_xmlalias  AS "XmlAlias",
                      t.col_isdeleted   AS "IsDeleted", 
                      t.col_isadded    AS "IsAdded",
                      t.col_apicode AS "ApiCode")
             )
         ) 
INTO v_xml       
FROM TBL_FOM_OBJECT t
WHERE EXISTS 
(SELECT 1 FROM tbl_dom_renderobject ro
          WHERE t.col_id = ro.col_renderobjectfom_object
);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
Xmlagg(
  XMLELEMENT("DomReferenceAttr",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_name              AS "Name", 
                      t.col_useoncreate       AS "UseonCreate",
                      t.col_useonupdate       AS "UseonUpdate",
                      t.col_useonsearch       AS "UseonSearch",
                      t.col_useonlist         AS "UseOnList",
                      t.col_useondetail       AS "UseOnDetail",
                      dro.col_ucode            AS "DomReferenceObjectCode",
                      fa.col_ucode            AS "FomAttributeUcode",
                      t.col_ucode		      AS "Ucode"
											)
             )
         ) 
INTO v_xml 
FROM tbl_dom_referenceattr t
LEFT JOIN tbl_dom_referenceobject dro ON t.col_dom_refattrdom_refobject = dro.col_id
LEFT JOIN tbl_fom_attribute fa ON t.col_dom_refattrfom_attr = fa.col_id
;
 
if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT
--Xmlconcat(v_xml,
Xmlagg(Xmlelement("FomForm",
                         Xmlelement("Code",       frm.col_code),
                         Xmlelement("Formmarkup",frm.col_formmarkup),
                         Xmlelement("Description",frm.col_description),
                         Xmlelement("IsDeleted", frm.col_isdeleted),
                         Xmlelement("Name", frm.col_name),
                         Xmlelement("IsGeneralUse", frm.col_isgeneraluse )
                         )
                         )
--                         )
INTO v_xml
FROM tbl_fom_form frm
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT
--Xmlconcat(v_xml,
Xmlagg(Xmlelement("CodedPage",
                         Xmlelement("Code",       cp.col_code),
                         Xmlelement("Pagemarkup",cp.col_pagemarkup),
                         Xmlelement("Description",cp.col_description),
                         Xmlelement("IsDeleted", cp.col_isdeleted),
                         Xmlelement("Name", cp.col_name),
                         Xmlelement("IsGeneralUse", cp.col_isgeneraluse),
                         Xmlelement("IsNavMenuItem" ,cp.col_isnavmenuitem)
                         )
                         )
--                         )
INTO v_xml
FROM tbl_FOM_CodedPage cp
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
       Xmlagg(Xmlelement("Config",
                         XMLFOREST( t.col_configid AS "ConfigId",
                                    t.col_isdeletable AS "IsDeletable",
                                    t.col_isdeleted AS "IsDeleted",
                                    t.col_ismodifiable AS "IsModifiable", 
                                    t.col_name AS "Name",
                                    t.col_value AS "Value",
                                    t.col_bigvalue AS "BigValue")
                         )
              )
INTO v_xml                           
FROM TBL_CONFIG t;


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT  Xmlagg(
  XMLELEMENT("MessagePlaceholder",
            XMLFOREST(t.col_owner AS "Owner", 
                      t.col_placeholder  AS "Placeholder", 
                      t.col_processorcode  AS "ProcessorCode",
                      t.col_value AS "Value",
                      t.col_description AS "Description")
             )
         ) 
into  v_xml        
FROM tbl_MessagePlaceholder t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;




SELECT 
  Xmlagg(
  XMLELEMENT("FomObject",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_tablename  AS "Tablename", 
                      t.col_alias  AS "Alias", 
                      t.col_xmlalias  AS "XmlAlias",
                      t.col_isdeleted   AS "IsDeleted", 
                      t.col_isadded    AS "IsAdded",
                      t.col_apicode AS "ApiCode")
             )
         ) 
INTO v_xml       
FROM TBL_FOM_OBJECT t
WHERE t.col_id in
(select col_fom_attributefom_object from tbl_fom_attribute where col_id in
(select col_som_resultattrfom_attr from tbl_som_resultattr where col_som_resultattrsom_config IN  
(select col_id from tbl_som_config where col_code IN ('TASK_SEARCH','TASKCC_SEARCH')
)
union
select col_som_searchattrfom_attr from tbl_som_searchattr where col_som_searchattrsom_config IN 
(select col_id from tbl_som_config where col_code IN ('TASK_SEARCH','TASKCC_SEARCH')
)
)
)
OR EXISTS 
(SELECT 1 FROM tbl_dom_referenceobject do WHERE do.col_dom_refobjectfom_object = t.col_id )
or 
EXISTS 
(SELECT 1 FROM tbl_dom_renderobject ro
          WHERE t.col_id = ro.col_renderobjectfom_object
)
or 
t.col_code = 'CASE'
OR 
EXISTS (SELECT 1  from
                  tbl_dom_object do
                  LEFT JOIN tbl_dom_model dm
                    ON dm.col_id = do.col_dom_objectdom_model
                  LEFT JOIN tbl_mdm_model mm
                    ON mm.col_id = dm.col_dom_modelmdm_model
                  JOIN tbl_dict_casesystype cst ON mm.col_id = cst.col_casesystypemodel
WHERE  cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
AND do.col_dom_objectfom_object = t.col_id
)
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("FomAttribute",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      fo.col_code   AS "FomObject", 
                      t.col_columnname   AS "ColumnName", 
                      t.col_storagetype   AS "StorageType",
                      t.col_alias    AS "Alias", 
                      t.col_isdeleted     AS "IsDeleted",
                      dt.col_code AS "Datatype",
                      t.col_apicode AS "ApiCode",
                      t.col_ucode as "Ucode")
             )
         ) 
INTO v_xml       
FROM TBL_FOM_ATTRIBUTE t,
tbl_dict_datatype dt,
tbl_fom_object fo
WHERE t.col_fom_attributedatatype = dt.col_id
AND t.col_fom_attributefom_object = fo.col_id
and ((t.col_id in
(select col_som_resultattrfom_attr from tbl_som_resultattr where col_som_resultattrsom_config IN 
(select col_id from tbl_som_config where col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH')
)
union
select col_som_searchattrfom_attr from tbl_som_searchattr where col_som_searchattrsom_config IN 
(select col_id from tbl_som_config where col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH')
))
OR EXISTS 
(SELECT 1 FROM tbl_dom_referenceobject do WHERE do.col_dom_refobjectfom_object = fo.col_id)
OR fo.col_code  = 'CASE'
)
OR 
EXISTS (SELECT 1  from
                  tbl_dom_object do
                  LEFT JOIN tbl_dom_model dm
                    ON dm.col_id = do.col_dom_objectdom_model
                  LEFT JOIN tbl_mdm_model mm
                    ON mm.col_id = dm.col_dom_modelmdm_model
                  JOIN tbl_dict_casesystype cst ON mm.col_id = cst.col_casesystypemodel
WHERE  cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
AND do.col_dom_objectfom_object = fo.col_id
)
OR EXISTS (SELECT 1 FROM TBL_DOM_RENDERATTR dra
          WHERE dra.col_renderattrfom_attribute = t.col_id)
);



if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("FomRelationship",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_foreignkeyname AS "ForeignKeyName",
                      foc.col_code   AS "FomObjectChild",
                      fop.col_code  AS "FomObjectParent", 
                      t.col_isdeleted AS "IsDeleted",
                      t.col_apicode AS "ApiCode")
             )
         ) 
INTO v_xml       
FROM TBL_FOM_RELATIONSHIP t
JOIN tbl_fom_object foc ON t.col_childfom_relfom_object = foc.col_id
JOIN tbl_fom_object fop ON t.col_parentfom_relfom_object = fop.col_id
where t.col_id in
(select col_fom_pathfom_relationship from tbl_fom_path where col_id in
(select col_som_resultattrfom_path from tbl_som_resultattr where col_som_resultattrsom_config IN 
(select col_id from tbl_som_config where col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH'))
union
select col_som_searchattrfom_path from tbl_som_searchattr where col_som_searchattrsom_config IN 
(select col_id from tbl_som_config where col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH'))
))
OR EXISTS 
(SELECT 1 FROM  tbl_fom_object fo,
                          tbl_dom_object do,
                          tbl_dom_model dm,
                          tbl_mdm_model mm,
                          tbl_dict_casesystype cst
           WHERE t.col_childfom_relfom_object = fo.col_id
           AND do.col_dom_objectfom_object = fo.col_id
           AND dm.col_id = do.col_dom_objectdom_model
           AND mm.col_id = dm.col_dom_modelmdm_model
           AND mm.col_id = cst.col_casesystypemodel
           AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR foc.col_code = 'CASE'
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT Xmlagg(
  XMLELEMENT("FomPath",
            XMLFOREST(rsh.col_code  "FomRelationship", 
                      fp.col_code AS "Code", 
                      fp.col_name AS "Name",
                      fp.col_jointype   AS "JoinType",
                      fp2.col_ucode AS "FomPathFomPath",
                      fp.col_ucode as "Ucode")
             )
         ) 
INTO v_xml     
FROM TBL_FOM_PATH fp
left JOIN TBL_FOM_RELATIONSHIP rsh ON fp.col_fom_pathfom_relationship = rsh.col_id
LEFT JOIN TBL_FOM_PATH fp2 ON fp.col_fom_pathfom_path = fp2.col_id
WHERE 
EXISTS (SELECT 1 FROM tbl_som_resultattr sra, 
                      tbl_som_config sc 
                 WHERE fp.col_id = sra.col_som_resultattrfom_path 
                   AND sra.col_som_resultattrsom_config = sc.col_id 
                   AND sc.col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH'))
OR EXISTS (SELECT 1 FROM tbl_som_searchattr ssa, 
                      tbl_som_config sc 
                 WHERE fp.col_id = ssa.col_som_searchattrfom_path 
                   AND ssa.col_som_searchattrsom_config = sc.col_id 
                   AND sc.col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH')
           )
OR EXISTS (SELECT 1 FROM  tbl_fom_object fo,
                          tbl_dom_object do,
                          tbl_dom_model dm,
                          tbl_mdm_model mm,
                          tbl_dict_casesystype cst
           WHERE rsh.col_childfom_relfom_object = fo.col_id
           AND do.col_dom_objectfom_object = fo.col_id
           AND dm.col_id = do.col_dom_objectdom_model
           AND mm.col_id = dm.col_dom_modelmdm_model
           AND mm.col_id = cst.col_casesystypemodel
           AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR EXISTS 
(SELECT 1 FROM tbl_fom_object fo1
        WHERE rsh.col_childfom_relfom_object = fo1.col_id
        AND fo1.col_code = 'CASE'
);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT Xmlagg(
  XMLELEMENT("FomWidget",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name",
                      t.col_description   AS "Description",
                      t.col_config AS "Config",
                      t.col_image AS "Image",
                      t.col_type AS "Type",
                      t.col_owner AS "Owner",
                      t.col_category AS "Category",
                      t.col_isdeleted AS "Isdeleted")
             )
         ) 
INTO v_xml 
FROM Tbl_Fom_Widget t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT Xmlagg(
  XMLELEMENT("SomConfig",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name",
                      t.col_description   AS "Description",
                      t.col_isdeleted AS "Isdeleted",
                      t.col_defsortfield AS "Defsortfield",
                      t.col_sortdirection AS "SortDirection",
                      t.col_customconfig AS "CustomConfig",
                      t.col_xmlfromqry AS "XmlFromQry",
                      t.col_whereqry AS "WhereQry",
                      t.col_srchqry AS "Srchqry",
                      t.col_fromqry AS "Fromqry",
                      fo.col_code AS "FomObject",
                      t.col_searchconfig AS "SearchConfig",
                      t.col_gridconfig AS "GridConfig",
                      t.col_isshowinnavmenu AS "IsShowInNavMenu",
                      sm.col_ucode AS "SomModelUcode",
                      t.col_srchxml AS "SrchXml")
             )
         ) 
INTO v_xml 
FROM TBL_SOM_CONFIG t
LEFT JOIN tbl_fom_object fo ON t.col_som_configfom_object = fo.col_id
LEFT JOIN tbl_som_model sm ON t.col_som_configsom_model = sm.col_id
     LEFT JOIN tbl_mdm_model mdm ON sm.col_som_modelmdm_model = mdm.col_id 
     LEFT JOIN tbl_dict_casesystype cst ON mdm.col_id = cst.col_casesystypemodel
WHERE t.col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH')
OR cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
;


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT Xmlagg(
  XMLELEMENT("SomResultAttr",
            XMLFOREST(sr.col_code as "Code", 
                      sr.col_name AS "Name",
                      sr.col_sorder AS "Sorder",
                      sr.col_idproperty AS "IdProperty",
                      fp.col_ucode AS "FomPath",
                      sc.col_code AS "SomConfig",
                      fa.col_code AS "FomAttribute",
                      sr.col_jsondata AS "Jsondata",
                      sr.col_processorcode AS "ProcessorCode",
                      sr.col_metaproperty AS "MetaProperty",
                      sr.col_ucode AS "Ucode",
                      sr.col_isrender AS "IsRender",
                      sr.col_isdeleted AS "IsDeleted",
                      sra.col_ucode AS "ResultAttrGroup",
                      ro.col_ucode AS "RenderObject",
                      rc.col_ucode AS "RenderControl",
                      ra.col_ucode AS "RenderAttr",
                      rfo.col_ucode AS "DomRefObjUcode",
                      sa.col_ucode AS "SomAttribute"
                      )
             )
         ) 
INTO v_xml  
FROM tbl_som_resultattr  sr
LEFT JOIN tbl_fom_path fp ON sr.col_som_resultattrfom_path = fp.col_id
LEFT JOIN tbl_som_config sc ON sc.col_id = sr.col_som_resultattrsom_config
LEFT JOIN tbl_fom_attribute fa ON sr.col_som_resultattrfom_attr = fa.col_id
LEFT JOIN tbl_som_resultattr sra ON sr.col_resultattrresultattrgroup = sra.col_id
LEFT JOIN tbl_dom_renderobject ro ON sr.col_som_resattrrenderobject = ro.col_id
LEFT JOIN tbl_dom_rendercontrol rc ON sr.col_som_resultattrrenderctrl = rc.col_id
LEFT JOIN tbl_dom_renderattr ra ON sr.col_som_resultattrrenderattr = ra.col_id
LEFT JOIN tbl_dom_referenceobject rfo ON sr.col_som_resultattrrefobject = rfo.col_id
LEFT JOIN tbl_som_attribute sa ON sr.col_som_resultattrsom_attr = sa.col_id
WHERE  sc.col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH')
OR EXISTS 
((SELECT 1 FROM tbl_som_model smm,
                tbl_mdm_model mdm,
			    tbl_dict_casesystype cst 
                   WHERE smm.col_som_modelmdm_model = mdm.col_id 
					AND mdm.col_id = cst.col_casesystypemodel
					AND sc.col_som_configsom_model = smm.col_id
					AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
									 ))
;

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
                      fp.col_systemdefault AS "SystemDefault",
                      cst1.col_code AS "CaseType")
             )
         ) 
INTO v_xml 
FROM TBL_FOM_Page fp
LEFT JOIN tbl_dict_casesystype cst1 ON fp.col_pagecasesystype = cst1.col_id
WHERE 
(fp.col_id IN 
(SELECT assp.col_assocpagepage
FROM tbl_ASSOCPAGE assp
WHERE EXISTS 
(SELECT 1 FROM tbl_tasktemplate tt2, tbl_procedure pr WHERE assp.col_assocpagetasktemplate = tt2.col_id
    AND tt2.col_proceduretasktemplate = pr.col_id AND pr.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) 
)
OR EXISTS 
( SELECT 1 FROM tbl_dict_casesystype dcst WHERE assp.col_assocpagedict_casesystype = dcst.col_id 
   AND dcst.col_code  IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR EXISTS 
( SELECT 1 FROM tbl_dict_tasksystype tstt, tbl_tasktemplate tt3, tbl_procedure pr2  WHERE assp.col_assocpagedict_tasksystype = tstt.col_id 
AND tstt.col_id = tt3.col_tasktmpldict_tasksystype AND tt3.col_proceduretasktemplate = pr2.col_id 
AND pr2.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure))) 
)
OR EXISTS
( SELECT 1 FROM tbl_dict_tasksystype tst1, tbl_stp_availableadhoc ah, tbl_dict_casesystype cst1  
  WHERE assp.col_assocpagedict_tasksystype = tst1.col_id 
    AND ah.col_tasksystype = tst1.col_id
    AND ah.col_casesystype = cst1.col_id 
    AND cst1.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR 
(
assp.col_partytypeassocpage IN  (SELECT col_id FROM tbl_dict_partytype)
)
)
OR 
fp.col_systemdefault = 1
OR 
fp.col_id IN (SELECT col_sourceid FROM tbl_loc_keysources WHERE UPPER(col_sourcetype) = 'PAGE')
OR EXISTS 
(SELECT 1 
FROM tbl_fom_uielement uie WHERE uie.col_uielementpage = fp.col_id) 
)
AND
(cst1.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type))) OR cst1.col_code IS NULL);


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT Xmlagg(
  XMLELEMENT("SomSearchAttr",
            XMLFOREST(sss.col_code  "Code", 
                      sss.col_name AS "Name",
                      sss.col_sorder AS "Sorder",
                      sss.col_iscaseincensitive AS "IsCaseinCensitive",
                      sss.col_islike AS "IsLike",
                      sss.col_isadded AS "IsAdded",
                      sss.col_customconfig AS "CustomConfig",
                      sss.col_valuefield AS "ValueField",
                      sss.col_processorcode AS "ProcessorCode",
                      sss.col_displayfield AS "DisplayField",
                      uet.col_code AS "UiElementType",
                      sss.col_constant AS "Constant",
                      sss.col_defaultvalue AS "DefaultValue",
                      sss.col_ispredefined AS "IsPreDefined",
                      sss.col_iscolumncomp AS "IsColumnComp",
                      fp.col_ucode AS "FomPath",
                      sc.col_code AS "SomConfig",
                      fa.col_code AS "FomAttribute",
                      fal.col_code AS "LeftSearchFomAttribute",
                      far.col_code AS "RightSearchFomAttribute",
                      sss.col_jsondata AS "Jsondata",
                      sss.col_rightalias AS "RightAlias",
                      sss.col_leftalias AS "LeftAlias",
                      sss.col_ucode AS "Ucode",
                      sss.col_isrender AS "IsRender",
                      ra.col_ucode AS "RendErattrUcode",
                      rc.col_ucode AS "RenderControlUcode",
                      ro.col_ucode AS "RenderObjectUcode",
                      ssa.col_ucode AS "SearchAttrGroup",
                      sss.col_isdeleted AS "IsDeleted",
                      dro.col_ucode AS "DomReferenceObjectUcode",
                      sa.col_ucode AS "SomAttribute")
             )
         ) 
INTO v_xml   
FROM  tbl_som_searchattr sss
LEFT JOIN tbl_som_config sc ON sss.col_som_searchattrsom_config = sc.col_id
LEFT JOIN tbl_fom_path fp ON sss.col_som_searchattrfom_path = fp.col_id
LEFT JOIN tbl_fom_attribute fa ON sss.col_som_searchattrfom_attr = fa.col_id
LEFT JOIN tbl_fom_attribute fal ON sss.col_left_searchattrfom_attr = fal.col_id
LEFT JOIN tbl_fom_attribute far ON sss.col_right_searchattrfom_attr = far.col_id
LEFT JOIN tbl_fom_uielementtype uet ON sss.col_searchattr_uielementtype = uet.col_id
LEFT JOIN tbl_dom_renderattr ra ON sss.col_som_searchattrrenderattr = ra.col_id
LEFT JOIN tbl_dom_rendercontrol rc ON sss.col_som_searchattrrenderctrl = rc.col_id
LEFT JOIN tbl_dom_renderobject ro ON sss.col_som_srchattrrenderobject = ro.col_id
LEFT JOIN tbl_som_searchattr ssa ON sss.col_searchattrsearchattrgroup = ssa.col_id
LEFT JOIN tbl_dom_referenceobject dro ON sss.col_som_searchattrrefobject = dro.col_id
LEFT JOIN tbl_som_attribute sa ON sss.col_som_searchattrsom_attr = sa.col_id
WHERE  sc.col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH')
OR EXISTS 
(SELECT 1 FROM tbl_som_model sommo,
               tbl_mdm_model mdm,
			   tbl_dict_casesystype cst    
           WHERE sc.col_som_configsom_model = sommo.col_id
              AND sommo.col_som_modelmdm_model = mdm.col_id 
			  AND mdm.col_id = cst.col_casesystypemodel
			  AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type))) 
)
;


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

 SELECT  Xmlagg(
  XMLELEMENT("DomModel",
            XMLFOREST(t.col_ucode             AS "Ucode", 
                      t.col_code              AS "Code",
                      t.col_description       AS "Description",
                      t.col_name              AS "Name",
                      fo.col_code             AS "FomObject",
                      t.col_config            AS "Config",
                      t.col_isdeleted         AS "IsDeleted",
                      t.col_usedfor           AS "UsedFor",
                      mdm.col_ucode           AS "MdmModelUcode")
                      
             )
         )  
INTO  v_xml        
FROM 
tbl_DOM_Model t
LEFT JOIN tbl_fom_object fo ON t.col_dom_modelfom_object = fo.col_id
LEFT JOIN tbl_mdm_model mdm ON t.col_dom_modelmdm_model = mdm.col_id
WHERE mdm.col_id IN 
 (SELECT col_casesystypemodel FROM tbl_dict_casesystype WHERE col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))) 
OR t.col_usedfor = 'CASE_TYPE';

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT Xmlagg(
  XMLELEMENT("DomObject",
            XMLFOREST(t.col_ucode             AS "Ucode", 
                      t.col_code              AS "Code",
                      t.col_name              AS "Name",
                      fo.col_code             AS "FomObject",
                      pt.col_code             AS "PartyType",
                      pathtoprntext.col_ucode  AS "PathToprntext",
                      pathtosrvparty.col_ucode AS "PathTosrvparty",
                      t.col_isroot            AS "IsRoot",
                      t.col_issharable        AS "IsSharable",
                      dm.col_ucode            AS "DomModel",
                      t.col_type              AS "Type",
                      t.col_description       AS "Description")
                      
             )
         )  
INTO  v_xml
FROM tbl_dom_object t
LEFT JOIN tbl_dict_partytype pt ON t.col_dom_objectdict_partytype = pt.col_id
LEFT JOIN tbl_fom_object fo ON t.col_dom_objectfom_object = fo.col_id
LEFT JOIN tbl_fom_path pathtoprntext ON t.col_dom_object_pathtoprntext = pathtoprntext.col_id
LEFT JOIN tbl_fom_path pathtosrvparty ON t.col_dom_object_pathtosrvparty = pathtosrvparty.col_id
left JOIN tbl_dom_model dm ON t.col_dom_objectdom_model = dm.col_id
LEFT JOIN tbl_mdm_model mdm ON dm.col_dom_modelmdm_model = mdm.col_id
WHERE 
(mdm.col_id IN 
 (SELECT col_casesystypemodel FROM tbl_dict_casesystype WHERE col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))) 
OR dm.col_usedfor = 'CASE_TYPE')
OR(
fo.col_id in
(select col_fom_attributefom_object from tbl_fom_attribute where col_id in
(select col_som_resultattrfom_attr from tbl_som_resultattr where col_som_resultattrsom_config IN  
(select col_id from tbl_som_config where col_code IN ('TASK_SEARCH','TASKCC_SEARCH')
)
union
select col_som_searchattrfom_attr from tbl_som_searchattr where col_som_searchattrsom_config IN 
(select col_id from tbl_som_config where col_code IN ('TASK_SEARCH','TASKCC_SEARCH')
)
)
)
)
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT Xmlagg(
  XMLELEMENT("DomRelationship",
            XMLFOREST(t.col_ucode             AS "Ucode", 
                      t.col_code              AS "Code",
                      t.col_name              AS "Name",
                      fr.col_code             AS "FomRelationship",
                      doc.col_ucode           AS "DomObjectChild",
                      dop.col_ucode           AS "DomObjectParent")
                      
             )
         )  
INTO  v_xml   
FROM tbl_dom_relationship t
LEFT JOIN tbl_fom_relationship fr ON t.col_dom_relfom_rel = fr.col_id
LEFT JOIN tbl_dom_object doc ON t.col_childdom_reldom_object = doc.col_id
     JOIN tbl_dom_model obj ON doc.col_dom_objectdom_model = obj.col_id
     JOIN tbl_mdm_model mdm ON obj.col_dom_modelmdm_model = mdm.col_id
AND  (mdm.col_id IN 
 (SELECT col_casesystypemodel FROM tbl_dict_casesystype WHERE col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))) 
OR obj.col_usedfor = 'CASE_TYPE')
LEFT JOIN tbl_dom_object dop ON t.col_parentdom_reldom_object = dop.col_id
     JOIN tbl_dom_model obj1 ON dop.col_dom_objectdom_model = obj1.col_id
     JOIN tbl_mdm_model mdm1 ON obj1.col_dom_modelmdm_model = mdm1.col_id
AND  (mdm1.col_id IN 
 (SELECT col_casesystypemodel FROM tbl_dict_casesystype WHERE col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))) 
OR obj1.col_usedfor = 'CASE_TYPE');

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;



SELECT Xmlagg(
  XMLELEMENT("DomAttribute",
            XMLFOREST(t.col_ucode             AS "Ucode", 
                      t.col_code              AS "Code",
                      t.col_name              AS "Name",
                      fa.col_code             AS "FomAttribute",
                      do.col_ucode            AS "DomObject",
                      t.col_dorder            AS "DOrder",
                      t.col_isupdatable       AS "IsUpdatable",
                      t.col_issearchable      AS "IsSearchable",
                      t.col_isretrievableinlist AS "IsRetrievableInList",
                      t.col_isretrievableindetail AS "IsRetrievableInDetail",
                      t.col_isinsertable      AS "IsInsertable",
                      t.col_isrequired        AS "IsRequired",
                      t.col_config            AS "Config",
                      t.col_description       AS "Description",
                      t.col_issystem          AS "IsSystem",
                      ao.col_code             AS "AccesObject")
                      
             )
         ) 
INTO  v_xml            
FROM tbl_DOM_Attribute t
LEFT JOIN tbl_fom_attribute fa ON t.col_dom_attrfom_attr = fa.col_id
LEFT JOIN tbl_dom_object do ON t.col_dom_attributedom_object = do.col_id
      JOIN tbl_dom_model dm ON do.col_dom_objectdom_model = dm.col_id
      JOIN tbl_mdm_model mdm ON dm.col_dom_modelmdm_model = mdm.col_id
LEFT JOIN tbl_ac_accessobject ao ON t.col_dom_attributeaccessobject = ao.col_id
WHERE  (mdm.col_ID IN 
 (SELECT col_casesystypemodel FROM tbl_dict_casesystype WHERE col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))) 
OR DM.col_usedfor = 'CASE_TYPE')
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;



SELECT Xmlagg(
  XMLELEMENT("DomConfig",
            XMLFOREST(t.col_ucode             AS "Ucode", 
                      t.col_isdeleted         AS "IsDeleted",
                      t.col_description       AS "Description",
                      t.col_name              AS "Name",
                      t.col_code              AS "Code",
                      fo.col_code             AS "FomObject",
                      t.col_purpose           AS "Purpose",
                      dm.col_ucode            AS "DomModelUcode"
                      )
             )
         )  
INTO  v_xml 
FROM 
tbl_dom_config t
LEFT JOIN tbl_fom_object fo ON t.col_dom_configfom_object = fo.col_id
LEFT JOIN tbl_dom_model dm ON t.col_dom_configdom_model = dm.col_id
JOIN tbl_mdm_model mdm ON dm.col_dom_modelmdm_model = mdm.col_id
AND  (mdm.col_id IN 
 (SELECT col_casesystypemodel FROM tbl_dict_casesystype WHERE col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))) 
OR dm.col_usedfor = 'CASE_TYPE')
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;



SELECT Xmlagg(
  XMLELEMENT("DomUpdateAttr",
            XMLFOREST(t.col_ucode             AS "Ucode", 
                      t.col_code              AS "Code",
                      t.col_name              AS "Name",
                      t.col_dorder            AS "DOrder",
                      t.col_mappingname       AS "MappingName",
                      dc.col_ucode            AS "DomConfig",
                      fa.col_code             AS "FomAttribute",
                      fp.col_ucode            AS "FomPath",
                      da.col_ucode            AS "DomAttributeUcode"
                      )
                      
             )
         )  
INTO  v_xml  
FROM tbl_DOM_UpdateAttr t
LEFT JOIN tbl_dom_config dc ON t.col_dom_updateattrdom_config = dc.col_id
LEFT JOIN tbl_fom_attribute fa ON t.col_dom_updateattrfom_attr = fa.col_id
LEFT JOIN tbl_fom_path fp ON t.col_dom_updateattrfom_path = fp.col_id
LEFT JOIN tbl_dom_attribute da ON t.col_dom_updateattrdom_attr = da.col_id
where
EXISTS 
(SELECT 1 FROM tbl_dom_model dm 
JOIN tbl_mdm_model mdm ON dm.col_dom_modelmdm_model = mdm.col_id
WHERE dc.col_dom_configdom_model = dm.col_id
AND  (mdm.col_id IN 
 (SELECT col_casesystypemodel FROM tbl_dict_casesystype WHERE col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))) 
OR dm.col_usedfor = 'CASE_TYPE')
)
OR
(fa.col_id in
(select col_som_resultattrfom_attr from tbl_som_resultattr where col_som_resultattrsom_config IN 
(select col_id from tbl_som_config where col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH')
)
union
select col_som_searchattrfom_attr from tbl_som_searchattr where col_som_searchattrsom_config IN 
(select col_id from tbl_som_config where col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH')
))
OR EXISTS 
(SELECT 1 FROM tbl_dom_referenceobject do WHERE do.col_dom_refobjectfom_object = fa.col_fom_attributefom_object AND t.col_dom_updateattrdom_attr IS NULL)
OR EXISTS 
(SELECT 1 FROM tbl_fom_object fo WHERE col_code  = 'CASE' and fo.col_id= fa.col_fom_attributefom_object AND t.col_dom_updateattrdom_attr IS NULL)
);


if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT Xmlagg(
  XMLELEMENT("DomInsertAttr",
            XMLFOREST(t.col_ucode             AS "Ucode",
                      t.col_dorder            AS "DOrder", 
                      t.col_code              AS "Code",
                      t.col_name              AS "Name",
                      t.col_mappingname       AS "MappingName",
                      dc.col_ucode            AS "DomConfig",
                      fa.col_code             AS "FomAttribute",
                      fp.col_ucode            AS "FomPath",
                      da.col_ucode            AS "DomAttributeUcode"
                      )
                      
             )
         )  
INTO  v_xml 
FROM tbl_DOM_InsertAttr t
LEFT JOIN tbl_dom_config dc ON t.col_dom_insertattrdom_config = dc.col_id
LEFT JOIN tbl_fom_attribute fa ON t.col_dom_insertattrfom_attr = fa.col_id
LEFT JOIN tbl_fom_path fp ON t.col_dom_insertattrfom_path = fp.col_id
LEFT JOIN tbl_dom_attribute da ON t.col_dom_insertattrdom_attr = da.col_id
where 
EXISTS 
(SELECT 1 FROM tbl_dom_model dm 
JOIN tbl_mdm_model mdm ON dm.col_dom_modelmdm_model = mdm.col_id
WHERE dc.col_dom_configdom_model = dm.col_id
AND  (mdm.col_id IN 
 (SELECT col_casesystypemodel FROM tbl_dict_casesystype WHERE col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))) 
OR dm.col_usedfor = 'CASE_TYPE')
)
OR(fa.col_id in
(select col_som_resultattrfom_attr from tbl_som_resultattr where col_som_resultattrsom_config IN 
(select col_id from tbl_som_config where col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH')
)
union
select col_som_searchattrfom_attr from tbl_som_searchattr where col_som_searchattrsom_config IN 
(select col_id from tbl_som_config where col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH')
))
OR EXISTS 
(SELECT 1 FROM tbl_dom_referenceobject do WHERE do.col_dom_refobjectfom_object = fa.col_fom_attributefom_object AND t.col_dom_insertattrdom_attr IS NULL)
OR EXISTS 
(SELECT 1 FROM tbl_fom_object fo WHERE col_code  = 'CASE' and fo.col_id= fa.col_fom_attributefom_object AND t.col_dom_insertattrdom_attr IS NULL)
);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

/*
SELECT Xmlagg(
        XMLELEMENT("DomCache",
                  XMLFOREST(t.col_ucode             AS "Ucode", 
                            t.col_sqltype           AS "SqlType",
                            t.col_session           AS "Session",
                            t.col_parentseqnumber   AS "ParentSeqnuMber",
                            t.col_parentobjecttablename AS "ParentObjectTableName",
                            t.col_parentobjectname  AS "ParentObjectName",
                            t.col_parentobject      AS "ParentObject",
                            t.col_objecttablename   AS "ObjectTableName",
                            t.col_objectname        AS "ObjectName",
                            t.col_childobjecttablename AS "ChildObjectTableName",
                            t.col_childobjectname   AS "ChildObjectName",
                            t.col_childobject       AS "ChildObject",
                            t.col_sorder            AS "Sorder",
                            t.col_parentrecordid    AS "ParentreCordId",
                            t.col_query             AS "Query",
                            t.col_recordid          AS "RecordId",
                            dc.col_code            AS "DomConfig",
                            t.col_isdeleted         AS "IsDeleted",
                            t.col_isadded           AS "IsAdded",
                            t.col_isextension       AS "IsExtension",
                            t.col_rootparentseqnumber AS "RootParentSeqNumber",
                            t.col_parentitemid      AS "ParentItemId",
                            t.col_itemid            AS "ItemId")
                            
                   )
               )  
INTO  v_xml      
FROM tbl_dom_cache t
LEFT JOIN tbl_dom_config dc ON t.col_dom_cachedom_config = dc.col_id
LEFT JOIN tbl_dom_model dm ON dc.col_dom_configdom_model = dm.col_id
JOIN tbl_mdm_model mdm ON dm.col_dom_modelmdm_model = mdm.col_id
AND  (mdm.col_id IN 
 (SELECT col_casesystypemodel FROM tbl_dict_casesystype WHERE col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))) 
OR dm.col_usedfor = 'CASE_TYPE');

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;
*/

SELECT  Xmlagg(
  XMLELEMENT("SomAttribute",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_dorder            AS "DOrder",
                      t.col_isinsertable      AS "IsInsertable",
                      t.col_isretrievableindetail AS "IsRetrievableInDetail",
                      t.col_isretrievableinlist AS "IsretRievableInList",
                      t.col_issearchable      AS "IsSearchable", 
                      t.col_isupdatable       AS "IsUpdatable",
                      t.col_name              AS "Name",
                      t.col_ucode             AS "Ucode",
                      t.col_config            AS "Config",
                      t.col_description       AS "Description",
                      t.col_issystem          AS "IsSystem",
                      fa.col_ucode            AS "FomAttributeUcode",
                      so.col_ucode            AS "SomObjectUcode",
                      ro.col_ucode            AS "DomRenderObjectUcode",
                      refo.col_ucode          AS "DomReferenceObjectUcode",
                      ao.col_code             AS "AccessObjectCode"
                      )
             )
         ) 
INTO v_xml  
FROM TBL_SOM_ATTRIBUTE t
LEFT JOIN tbl_fom_attribute fa ON t.col_som_attrfom_attr = fa.col_id
LEFT JOIN tbl_som_object so on t.col_som_attributesom_object = so.col_id
LEFT JOIN tbl_dom_renderobject ro ON t.col_som_attributerenderobject = ro.col_id
LEFT JOIN tbl_dom_referenceobject refo ON t.col_som_attributerefobject = refo.col_id
LEFT JOIN tbl_ac_accessobject ao ON t.col_som_attributeaccessobject = ao.col_id
WHERE EXISTS 
(SELECT 1 FROM tbl_som_model sm,
               tbl_mdm_model mdm,
			   tbl_dict_casesystype cst 
WHERE so.col_som_objectsom_model = sm.col_id
AND sm.col_som_modelmdm_model = mdm.col_id 
AND mdm.col_id = cst.col_casesystypemodel
AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT Xmlagg(
  XMLELEMENT("MdmModel",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_description       AS "Description",
                      t.col_config            AS "Config",											
                      t.col_isdeleted         AS "IsDeleted",
                      t.col_name              AS "Name", 
                      t.col_ucode             AS "Ucode",
                      t.col_usedfor           AS "UsedFor",
                      cst.col_code            AS "CaseType",
                      fo.col_code             AS "FomObjectCode")
             )
         ) 
INTO v_xml
FROM
tbl_mdm_model t
JOIN tbl_dict_casesystype cst ON t.col_id = cst.col_casesystypemodel and cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
LEFT JOIN tbl_fom_object fo ON t.col_mdm_modelfom_object = fo.col_id
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
 Xmlagg(
  XMLELEMENT("SomModel",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_description       AS "Description",
                      t.col_config            AS "Config",											
                      t.col_isdeleted         AS "IsDeleted",
                      t.col_name              AS "Name", 
                      t.col_ucode             AS "Ucode",
                      t.col_usedfor           AS "UsedFor",
                      fo.col_code             AS "FomObjectCode",
                      mdm.col_ucode           AS "MdmModel")
             )
         ) 
INTO v_xml 
FROM tbl_som_model t 
LEFT JOIN tbl_fom_object fo ON t.col_som_modelfom_object = fo.col_id
JOIN tbl_mdm_model mdm ON t.col_som_modelmdm_model = mdm.col_id
JOIN tbl_dict_casesystype cst ON mdm.col_id = cst.col_casesystypemodel 
AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;



SELECT 
 Xmlagg(
  XMLELEMENT("SomObject",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_description       AS "Description",
                      t.col_isroot            AS "IsRoot",											
                      t.col_issharable        AS "IsSharable",
                      t.col_name              AS "Name", 
                      t.col_ucode             AS "Ucode",
                      t.col_type              AS "SomObjectType",
                      fo.col_code             AS "FomObjectCode",
                      sm.col_ucode            AS "SomModelUcode"
											)
             )
         ) 
INTO v_xml 
FROM tbl_som_object t 
LEFT JOIN tbl_som_model sm ON t.col_som_objectsom_model = sm.col_id 
LEFT JOIN tbl_fom_object fo ON t.col_som_objectfom_object = fo.col_id
where EXISTS 
(SELECT 1 FROM tbl_mdm_model mdm,
               tbl_dict_casesystype cst 
WHERE sm.col_som_modelmdm_model = mdm.col_id 
AND mdm.col_id = cst.col_casesystypemodel
AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;



SELECT 
 Xmlagg(
  XMLELEMENT("SomRelationship",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_name              AS "Name", 
                      t.col_ucode             AS "Ucode",
                      soc.col_ucode           AS "SomObjectCodeCh",
                      sop.col_ucode           AS "SomObjectCodePr",
                      fr.col_code             AS "FomRelationship" 
                      )
             )
         ) 
INTO v_xml 
FROM  tbl_som_relationship t 
LEFT JOIN tbl_som_object soc ON t.col_childsom_relsom_object = soc.col_id
LEFT JOIN tbl_som_object sop ON t.col_parentsom_relsom_object = sop.col_id
LEFT JOIN tbl_fom_relationship fr ON t.col_som_relfom_rel = fr.col_id
where EXISTS 
(SELECT 1 FROM tbl_som_model sm, 
               tbl_mdm_model mdm,
               tbl_dict_casesystype cst 
WHERE soc.col_som_objectsom_model = sm.col_id 
AND sm.col_som_modelmdm_model = mdm.col_id 
AND mdm.col_id = cst.col_casesystypemodel
AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
OR 
EXISTS 
(SELECT 1 FROM tbl_som_model sm, 
               tbl_mdm_model mdm,
               tbl_dict_casesystype cst 
WHERE sop.col_som_objectsom_model = sm.col_id 
AND sm.col_som_modelmdm_model = mdm.col_id 
AND mdm.col_id = cst.col_casesystypemodel
AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


 SELECT 
  Xmlagg(
  XMLELEMENT("MdmModelVersion",
            XMLFOREST("ErrorMessage",
                      "Description", 
                      "Config",
                      "UsedFor",
                      "Ucode",
                      "Name",
                      "Code",
                      "IsDeleted",
                      "MdmModelUcode",
                      "Order"
                     )
             )
       ) 
INTO v_xml 
from
(SELECT 
                      t.col_errormessage      AS "ErrorMessage",
                      t.col_description       AS "Description", 
                      t.col_config            AS "Config",
                      t.col_usedfor           AS "UsedFor",
                      t.col_ucode             AS "Ucode",
                      t.col_name              AS "Name",
                      t.col_code              AS "Code",
                      t.col_isdeleted         AS "IsDeleted",
                      mm.col_ucode            AS "MdmModelUcode",
                      row_number() OVER(PARTITION BY 1 ORDER BY t.col_id) AS "Order" 
 FROM
 tbl_mdm_modelversion t
 JOIN tbl_mdm_model mm ON t.col_mdm_modelversionmdm_model = mm.col_id
 JOIN tbl_dict_casesystype cst ON mm.col_id = cst.col_casesystypemodel 
 AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
 )
  WHERE "Order" = 1;
 
if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
Xmlagg(
  XMLELEMENT("DomReferenceObject",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_name              AS "Name", 
                      t.col_isdeleted         AS "IsDeleted",
                      fo.col_code             AS "FomObjectCode",
                      t.col_ucode             AS "Ucode"
                      )
             )
         ) 
INTO v_xml 
FROM
tbl_dom_referenceobject t
LEFT JOIN tbl_fom_object fo ON t.col_dom_refobjectfom_object = fo.col_id;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
Xmlagg(
  XMLELEMENT("DomRefObjFilter",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_name              AS "Name", 
                      t.col_description       AS "Description",
                      t.col_query             AS "Query",
                      dro.col_code            AS "DomReferenceObjectCode"
											)
             )
         ) 
INTO v_xml 
FROM  
tbl_dom_refobjfilter t 
LEFT JOIN tbl_dom_referenceobject dro ON t.col_dom_refobjfiltdom_refobj = dro.col_id;
 
if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

/*
SELECT 
Xmlagg(
 XMLELEMENT("DomModelJournal",
            XMLFOREST("ParentElementId",
                      "ElementId", 
                      "ResultMessage",
                      "ParamXml",
                      "Ucode",
                      "Type",
                      "SubType",
                      "AppBaseCode",
                      "MdmModelversion",
                      "DBName",
                      "ErrorMessage",
                      "ErrorCode",
                       "Order")
             )
       ) 
INTO v_xml 
FROM
(SELECT 
                      t.col_parentelementid   AS "ParentElementId",
                      t.col_elementid         AS "ElementId", 
                      t.col_resultmessage     AS "ResultMessage",
                      t.col_paramxml          AS "ParamXml",
                      t.col_ucode             AS "Ucode",
                      t.col_type              AS "Type",
                      t.col_subtype           AS "SubType",
                      t.col_appbasecode       AS "AppBaseCode",
                      mdv.col_ucode            AS "MdmModelversion",
                      t.col_dbname            AS "DBName",
                      t.col_errormessage      AS "ErrorMessage",
                      t.col_errorcode         AS "ErrorCode",
                      row_number() OVER(PARTITION BY 1 ORDER BY t.col_id) AS "Order" 
FROM  tbl_dom_modeljournal t
LEFT JOIN tbl_mdm_modelversion mdv ON t.col_mdm_modverdom_modjrnl = mdv.col_id
WHERE 	t.col_mdm_modverdom_modjrnl IS NOT NULL 
    OR mdv.col_mdm_modelversionmdm_model IN 
(SELECT mdm.col_id FROM tbl_mdm_model mdm
JOIN tbl_dict_casesystype cst ON mdm.col_id = cst.col_casesystypemodel 
AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
)
);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;
*/

SELECT 
Xmlagg(
  XMLELEMENT("MdmForm",
            XMLFOREST(t.col_code              AS "Code",
                      t.col_name              AS "Name", 
                      t.col_description       AS "Description",
                      t.col_isdeleted         AS "IsDeleted",
                      t.col_businessobject    AS "BusinessObject",
                      t.col_autogenerated     AS "AutoGenerated",
                      o.col_ucode             AS "DomObjectUcode",
                      t.col_formrule          AS "FormRule"
                      )
             )
         ) 
INTO v_xml
FROM tbl_mdm_form t 
LEFT JOIN TBL_DOM_OBJECT o
          ON t.COL_MDM_FORMDOM_OBJECT = o.COL_ID
       LEFT JOIN TBL_DOM_MODEL m
          ON o.COL_DOM_OBJECTDOM_MODEL = m.COL_ID
       LEFT JOIN TBL_MDM_MODEL mm
          ON m.COL_DOM_MODELMDM_MODEL = mm.COL_ID
       LEFT JOIN TBL_DICT_CASESYSTYPE ct
          ON mm.col_id = ct.col_casesystypemodel
WHERE ct.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
OR t.COL_MDM_FORMDOM_OBJECT IS NULL;
 
if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;



SELECT 
Xmlagg(
  XMLELEMENT("MdmSearchPage",
            XMLFOREST(t.col_ucode             AS "Ucode",
                      mf.col_code             AS "MdmFormCode", 
                      sc.col_code             AS "SomConfigCode",
                      t.col_formmode          AS "FormMode"
                      )
             )
         ) 
INTO v_xml
FROM tbl_mdm_searchpage t
LEFT JOIN tbl_mdm_form mf ON t.col_searchpagemdm_form = mf.col_id
LEFT JOIN tbl_som_config sc ON t.col_searchpagesom_config = sc.col_id
LEFT JOIN tbl_som_model sm ON sc.col_som_configsom_model = sm.col_id
     LEFT JOIN tbl_mdm_model mdm ON sm.col_som_modelmdm_model = mdm.col_id 
     LEFT JOIN tbl_dict_casesystype cst ON mdm.col_id = cst.col_casesystypemodel
      AND cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
WHERE sc.col_code IN( 'TASK_SEARCH', 'TASKCC_SEARCH')
--OR cst.col_id IS NOT NULL 
;
 
if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT Xmlagg(
  XMLELEMENT("Participant",
            XMLFOREST(pp.col_code AS "Code", 
                      pp.col_description AS "Description",
                      pp.col_isowner AS "IsOwner",
                      pp.col_name AS "Name",
                      pp.col_owner AS "Owner",
                      pp.col_required AS "Required",
                      cst.col_code AS "CaseCode",
                      tst.col_code AS "TaskSysType",
                      br.col_code AS "BusinessRole",
                      pp.col_isdeleted AS "IsDeleted",
                      pt.col_code AS "PartyType",
                      pp.col_allowmultiple AS "Allowmultiple",
                      tm.col_code AS "TeamCode",
                      prc.col_code AS "Procedure",
                      pp.col_getprocessorcode AS "GetProcessorCode",
                      pp.col_getprocessorcode2 AS "GetProcessorCode2",
                      pp.col_customconfig AS "CustomConfig",
                      pp.col_issupervisor AS "IsSupervisor",
                      pp.col_iscreator AS "IsCreator",
                      put.col_code AS "PartiUnitType")
             )
         ) 
INTO v_xml    
FROM tbl_participant pp
left JOIN tbl_dict_casesystype cst ON pp.col_participantcasesystype = cst.col_id 
LEFT JOIN tbl_dict_tasksystype tst ON pp.col_participanttasksystype = tst.col_id
LEFT JOIN tbl_ppl_businessrole br ON pp.col_participantbusinessrole = br.col_id
LEFT JOIN tbl_dict_partytype pt ON pp.col_participantdict_partytype = pt.col_id
LEFT JOIN tbl_ppl_team tm ON pp.col_participantteam = tm.col_id
LEFT JOIN tbl_procedure prc ON pp.col_participantprocedure = prc.col_id
LEFT JOIN tbl_dict_participantunittype put ON pp.col_participantdict_unittype = put.col_id
WHERE nvl(pp.col_participantppl_caseworker,0) = 0 
AND nvl(pp.col_participantexternalparty,0) = 0
and 
(cst.col_code IN  (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
OR prc.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_list_procedure)))
);

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
  Xmlagg(
  XMLELEMENT("Orgchart",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name", 
                      t.col_owner AS "Owner",
                      cst.col_code AS "CaseType",
                      tm.col_code AS "Team",
                      t.col_isprimary AS "IsPrimary" )
             )
        ) 

INTO v_xml       
FROM Tbl_Ppl_Orgchart t
JOIN tbl_dict_casesystype cst ON t.col_casesystypeorgchart = cst.col_id and cst.col_code IN (SELECT * FROM TABLE(split_casetype_list(v_case_type)))
LEFT JOIN tbl_ppl_team tm ON t.col_teamorgchart = tm.col_id
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("DomRenderType",
            XMLFOREST(t.col_ucode  "Ucode", 
                      t.col_code  "Code", 
                      t.col_name AS "Name"
											)
             )
         ) 

INTO v_xml 
FROM tbl_DOM_RenderType t;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
  Xmlagg(
  XMLELEMENT("DomRenderObject",
            XMLFOREST(t.col_ucode  "Ucode", 
                      t.col_code  "Code", 
                      t.col_name AS "Name",
                      fo.col_code AS "FomObject",
                      t.col_useincase AS "UseInCase",
                      t.col_useincustomobject AS "UseInCustOmobject",
                      dt.col_code AS "DataType",
                      rt.col_ucode AS "RenderType")
             )
         ) 

INTO v_xml 
FROM tbl_dom_renderobject t
LEFT JOIN tbl_fom_object fo ON t.col_renderobjectfom_object = fo.col_id
LEFT JOIN tbl_dict_datatype dt ON t.col_dom_renderobjectdatatype = dt.col_id
LEFT JOIN tbl_dom_rendertype rt ON t.col_renderobjectrendertype = rt.col_id;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;

SELECT 
Xmlagg(
XMLELEMENT("DomRenderattr",
  XMLFOREST(t.col_code   "Code",
            t.col_name AS "Name",
            fa.col_ucode AS "FomAttrUcode",
            ro.col_ucode AS "DomRenderObjectCode",
            t.col_processorcode AS "ProcessorCode",
            t.col_useinsearch AS "UseInSearch",
            t.col_Ucode AS "Ucode",
            t.col_issearchable AS "IsSearchable",
            t.col_issortable AS "IsSortable")
          )
)
INTO v_xml 
FROM 
TBL_DOM_RENDERATTR t
LEFT JOIN tbl_fom_attribute fa ON t.col_renderattrfom_attribute = fa.col_id
LEFT JOIN tbl_dom_renderobject ro ON t.col_renderattrrenderobject = ro.col_id 
;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


SELECT 
  Xmlagg(
  XMLELEMENT("DomRenderControl",
            XMLFOREST(t.col_code  "Code", 
                      t.col_name AS "Name",
                      ro.col_ucode AS "DomRenderObjec",
                      t.col_config AS "Config",
                      t.col_isdefault AS "IsDefault",
                      t.col_Ucode AS "Ucode")
             )
         ) 

INTO v_xml 
FROM tbl_dom_rendercontrol t
LEFT JOIN tbl_dom_renderobject ro ON t.col_rendercontrolrenderobject  = ro.col_id;

if v_xml is not null then
dbms_lob.append(v_clob, v_xml.getClobVal());
end if;


 dbms_lob.append(v_clob, f_util_create_xml_dict); 
 
 if v_CustomBOTags is not null then 
      dbms_lob.append(v_clob, f_UTIL_export_tagXMLfn(tags_name => v_CustomBOTags)); 
 end if;
 
   
 dbms_lob.append(v_clob, '</CaseType>');

RETURN v_clob;





EXCEPTION
  WHEN OTHERS THEN
 ROLLBACK;
 RETURN dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
END;