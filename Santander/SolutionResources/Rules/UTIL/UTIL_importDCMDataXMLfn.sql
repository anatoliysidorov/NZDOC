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
  v_username                    NVARCHAR2(255);
  v_CaseTypeChild               NVARCHAR2(255);
  v_casetypeCode                NVARCHAR2(255);
  v_mdmModelId                  NUMBER;
  v_ErrorCode                   NUMBER;
  v_ErrorMessage                NVARCHAR2(255);
  --v_session_longoops
        rindex    BINARY_INTEGER;
        slno      BINARY_INTEGER;
        totalwork number;
        sofar     number;
        obj       BINARY_INTEGER;  
BEGIN

	IF USER = 'USER_DCM_CATS_V3_PRODUCTIONTEN' THEN 
		RAISE_APPLICATION_ERROR(-20001,'YOU ARE TRYING MAKE IMPORT ON USER_DCM_CATS_V3_PRODUCTIONTEN!!!!'); 
	END IF;	
    
--v_session_longoops  
        rindex := dbms_application_info.set_session_longops_nohint;
        sofar := 0;
        totalwork := 52;
        
  if Input is not null then
    v_input := XMLType(Input);
    v_input_clob := v_input.getClobVal();
  else
  begin
    SELECT COL_XMLDATA into v_input_clob 
    from tbl_importXML where col_id = XmlId; 
    v_input := XMLType(v_input_clob);
  EXCEPTION  
  WHEN No_DATA_FOUND THEN
     RETURN 'Nothing import';
  end;  
  end if;

  SELECT SYS_CONTEXT ('CLIENTCONTEXT', 'AccessSubject')
    INTO v_username 
  FROM dual;

DBMS_SESSION.SET_CONTEXT('CLIENTCONTEXT', 'AccessSubject', 'IMPORT');

  v_path := Path;
  v_level := TaskTemplateLevel;
  if v_level is null then
    v_level := 1;
  end if;
  v_parentid := nvl(ParentId,0);
  

   p_util_update_log ( XmlIdLog => XmlId, Message => 'Start load' , IsError => 0);
	 
  IF v_input IS NULL THEN
   p_util_update_log ( XmlIdLog => XmlId, Message => 'XML is empty' , IsError => 1, import_status => 'FAILURE');

    RETURN 'Empty';
  END IF;
-- v_dict = 0 Loaded only CaseType
-- v_dict = 1 Loaded both CaseType and Dictionary
-- v_dict = 2 Loaded only Dictionary

SELECT sum(cnt)
INTO v_cnt
FROM(
SELECT COUNT(*) cnt FROM tbl_dict_taskstate
UNION 
SELECT COUNT(*) FROM tbl_dict_casestate
);
 
v_dict := f_UTIL_extract_value_xml(Input => v_input, Path => '/CaseType/OnlyDictionary/text()');

IF v_cnt = 0 AND v_dict = 0 THEN 
  v_dict := 1;
  --Load with CaseType dictionary, if dictionarys are empty
p_util_update_log ( XmlIdLog => XmlId, Message => 'Dictionary are empty', IsError => 0);  
END IF; 

	 p_util_update_log ( XmlIdLog => XmlId, Message => 'Start load dictionary', IsError => 0);
/***************************************************************************************************/
--tbl_fom_page
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_input.extract('/CaseType/FomPage');
 
/*DELETE FROM tbl_fom_page 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('FomPage'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_FOM_PAGE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/ 
 
MERGE INTO TBL_FOM_PAGE
USING(
SELECT Code, Name,  Description, Isdeleted,FieldValues, UsedFor, Config, 
CASE WHEN  t2.col_systemdefault = 1 
  THEN 0
     ELSE SystemDefault
END SystemDefault,
(SELECT COL_ID FROM tbl_dict_casesystype where lower(col_code) = lower(CaseType)) CaseType
            FROM XMLTABLE('FomPage'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Description NCLOB PATH './Description',
                       Isdeleted NUMBER PATH './Isdeleted',
                       FieldValues NCLOB PATH './FieldValues',                       
                       UsedFor NVARCHAR2(255) PATH './UsedFor',
                       Config NCLOB PATH './Config',
                       SystemDefault NUMBER PATH './SystemDefault',
                       CaseType NVARCHAR2(255) PATH './CaseType'
                       )t1
LEFT JOIN                        
(SELECT  col_code, col_usedfor, col_systemdefault
FROM tbl_fom_page
WHERE ((col_createdby = 'IMPORT' AND col_modifiedby != 'IMPORT')
OR col_createdby != 'IMPORT' 
OR col_createdby IS NULL
)
AND col_systemdefault = 1 
) t2 ON t1.UsedFor = t2.col_usedfor                        
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name,  col_description = Description ,
  col_isdeleted  = Isdeleted, col_fieldvalues = FieldValues, col_usedfor  = UsedFor,
  col_config = Config, col_systemdefault =  SystemDefault,
  col_pagecasesystype = CaseType
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name,  col_description, col_isdeleted, col_fieldvalues, col_usedfor, col_config, 
  col_systemdefault, col_pagecasesystype )
  VALUES (Code, Name,  Description, Isdeleted, FieldValues, UsedFor, Config,
  SystemDefault,  CaseType);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_FOM_PAGE with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 


/**********************************************************************************/
--Extracting TBL_DICT_VERSION
/**********************************************************************************/
BEGIN
 v_xmlresult := v_input.extract('/CaseType/DictVersion'); 

MERGE INTO TBL_DICT_VERSION
USING(
SELECT Code, Name_
            FROM XMLTABLE('DictVersion'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name'
                       )
               )
ON (col_code = Code) --index without lower()
WHEN MATCHED THEN
  UPDATE SET col_name = Name_
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name )
  VALUES (Code, Name_);
  
     p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_VERSION with '||SQL%ROWCOUNT||' rows', IsError => 0);
     
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/*************************************************************/
--EXTRACTING Resolution codes
/*************************************************************/
BEGIN
   v_xmlresult := v_input.extract('/CaseType/ResolutionCode'); 

  
    MERGE INTO TBL_STP_RESOLUTIONCODE
    USING (
    SELECT Code, Name,  Description, Type, IsDeleted, CellStyle, RowStyle,
           TextStyle, Ucode, IconCode, Theme
            FROM XMLTABLE('ResolutionCode'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Description NCLOB PATH './Description',
                       Type NVARCHAR2(255) PATH './Type',
                       IsDeleted NUMBER  PATH './IsDeleted',
                       CellStyle NVARCHAR2(255) PATH './CellStyle',
                       RowStyle NVARCHAR2(255) PATH './RowStyle',
                       TextStyle NVARCHAR2(255) PATH './TextStyle',
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       IconCode NVARCHAR2(255) PATH './IconCode',
                       Theme NVARCHAR2(255) PATH './Theme' 
                       )
)
    ON (lower(col_code) = lower(code))
    WHEN MATCHED THEN UPDATE  SET
        col_name = Name, col_description = Description, col_type = Type, col_isdeleted = IsDeleted, 
        col_cellstyle = CellStyle,col_rowstyle = RowStyle,col_textstyle = TextStyle,
        col_ucode = ucode,col_iconcode = IconCode ,col_theme = Theme 
        WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
    WHEN NOT MATCHED THEN
    INSERT
    (col_code      , col_name      , col_description, col_type, col_isdeleted ,
    col_cellstyle, col_rowstyle, col_textstyle, col_ucode, col_iconcode, col_theme)
    VALUES
    (Code, Name, Description, Type, IsDeleted ,
     CellStyle, RowStyle ,TextStyle, Ucode, IconCode, Theme)
     LOG ERRORS INTO er$STP_RESOLUTIONCODE ('IMPOTR') REJECT LIMIT 5;
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_STP_RESOLUTIONCODE with '||SQL%ROWCOUNT||' rows', IsError => 0);  

  	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$STP_RESOLUTIONCODE d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_STP_RESOLUTIONCODE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
	END LOOP;
      
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
/* DICT */
/***************************************************************************************************/
If  v_dict IN (1, 2) THEN 
    v_xmlresult := v_input.extract('/CaseType/Dictionary');

    v_result := f_UTIL_extract_dict_xml(XML_DICT => v_xmlresult, Xml_Id =>  XmlId);
    
    
   
end if;   


/***************************************************************************************************/
--TBL_DOM_RENDERTYPE
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_input.extract('/CaseType/DomRenderType');
 
MERGE INTO TBL_DOM_RENDERTYPE
USING(
SELECT Ucode, Code, Name
            FROM XMLTABLE('DomRenderType'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code = Code, col_name = NAME
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code, col_name )
  VALUES (Ucode, code, NAME);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DOM_RENDERTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
    
  /***************************************************************************************************/
 -- TBL_CONFIG
 /***************************************************************************************************/
 BEGIN
   v_xmlresult := v_input.extract('/CaseType/Config');


                  
MERGE INTO TBL_CONFIG
USING
(SELECT ConfigId, Name2, IsDeletable, IsDeleted, IsModifiable,
CASE WHEN Name2 IN ('ENV_ID' , 'TOKEN_DOMAIN') THEN 
       (SELECT VALUE FROM CONFIG WHERE NAME = 'ENV_ID') 
     WHEN Name2 = 'ENV_SCHEMA' THEN
       (SELECT VALUE FROM CONFIG WHERE NAME = 'ENV_SCHEMA')
     WHEN name2 = 'TENANT_SCHEMA' THEN   
       (SELECT VALUE FROM CONFIG WHERE NAME = 'TENANT_SCHEMA')
     ELSE Value_
END Value2,
BigValue
FROM XMLTABLE ('Config'
PASSING v_xmlresult 
COLUMNS
                       ConfigId nvarchar2(255) PATH './ConfigId',
                       Name2 nvarchar2(255) PATH './Name',
                       IsDeletable nvarchar2(255) PATH './IsDeletable',
                       IsDeleted nvarchar2(255) PATH './IsDeleted',
                       IsModifiable nvarchar2(255) PATH './IsModifiable',
                       Value_ nvarchar2(255) PATH './Value',
                       BigValue NCLOB PATH './BigValue'  
                       )
)
ON (col_name = name2)
WHEN MATCHED THEN UPDATE
  SET col_isdeletable  = IsDeletable, col_ismodifiable =  IsModifiable, col_isdeleted = IsDeleted, col_value = dbms_xmlgen.convert(value2,1),
  col_configid = ConfigId, col_bigvalue = BigValue
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT
 (col_configid, col_isdeletable, col_isdeleted, col_ismodifiable, col_name, col_value, col_bigvalue   )
VALUES
 (ConfigId, IsDeletable, IsDeleted, IsModifiable, name2,  dbms_xmlgen.convert(value2,1), BigValue);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_CONFIG with '||SQL%ROWCOUNT||' rows', IsError => 0);
 


EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 

/******************************************************************************/

--TBL_MESSAGEPLACEHOLDER
/******************************************************************************/

BEGIN
 v_xmlresult := v_input.extract('/CaseType/MessagePlaceholder');
   MERGE INTO TBL_MESSAGEPLACEHOLDER
   USING (
   SELECT Owner, Placeholder, ProcessorCode, Value, Description 
            FROM XMLTABLE('MessagePlaceholder'
              PASSING v_xmlresult
              COLUMNS
                       Owner NVARCHAR2(255) PATH './Owner',
                       Placeholder NVARCHAR2(255) PATH './Placeholder',
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',
                       Value NVARCHAR2(255) PATH './Value',
                       Description NCLOB PATH './Description'
                       )
)
   ON (col_placeholder  = Placeholder)
   WHEN MATCHED THEN
     UPDATE  SET  col_owner  = Owner, col_processorcode   = ProcessorCode, col_value = Value, col_description = Description
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
     WHEN NOT MATCHED THEN
       INSERT (col_placeholder, col_owner, col_processorcode, col_value, col_description )
       VALUES (Placeholder, Owner, ProcessorCode,  Value, Description);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_MESSAGEPLACEHOLDER with '||SQL%ROWCOUNT||' rows', IsError => 0);


EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/******************************************************************************/

--TBL_FOM_OBJECT
/******************************************************************************/

 BEGIN
 v_xmlresult := v_input.extract('/CaseType/FomObject');
 
  MERGE INTO TBL_FOM_OBJECT
   USING (
   SELECT distinct Code, Name, Tablename, Alias, XmlAlias, IsDeleted , IsAdded, ApiCode
            FROM XMLTABLE('FomObject'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Tablename  NVARCHAR2(255) PATH './Tablename',
                       Alias NVARCHAR2(255) PATH './Alias',
                       XmlAlias NVARCHAR2(255) PATH './XmlAlias',
                       IsDeleted NUMBER PATH './IsDeleted',
                       IsAdded NUMBER PATH './IsAdded',
                       ApiCode NVARCHAR2(255) PATH './ApiCode'
                       )
)
   ON (lower(col_code)  = lower(Code))
   WHEN MATCHED THEN
     UPDATE  SET  col_name  = Name, col_tablename   = Tablename, col_alias   = Alias, 
                  col_xmlalias  = XmlAlias, col_isdeleted  = IsDeleted, 
                  col_isadded = IsAdded, col_apicode = ApiCode
WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')                  
     WHEN NOT MATCHED THEN
       INSERT (col_code  , col_name , col_tablename , col_alias , col_xmlalias , col_isdeleted, col_isadded, col_apicode )
       VALUES (Code, Name, Tablename,  Alias, XmlAlias, IsDeleted,IsAdded, ApiCode );			 
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_FOM_OBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0);
       

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/***************************************************************************************************/
--TBL_DOM_RENDEROBJECT
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_input.extract('/CaseType/DomRenderObject');
 
MERGE INTO TBL_DOM_RENDEROBJECT
USING(
SELECT Ucode, Code, Name, UseInCase, UseInCustOmobject, 
(SELECT col_id FROM tbl_fom_object WHERE lower(col_code) = lower(FomObject)) FomObject,
(SELECT col_id FROM tbl_dict_datatype WHERE lower(col_code) = lower(DataType)) DataType,
(SELECT col_id FROM tbl_dom_rendertype WHERE col_ucode = RenderType) RenderType
            FROM XMLTABLE('DomRenderObject'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       FomObject NVARCHAR2(255) PATH './FomObject',
                       UseInCase NUMBER PATH './UseInCase',
                       UseInCustOmobject NUMBER PATH './UseInCustOmobject',
                       DataType NVARCHAR2(255) PATH './DataType',
                       RenderType NVARCHAR2(255) PATH './RenderType'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code = Code, col_name = NAME, col_useincase  = UseInCase, 
	col_useincustomobject  = UseInCustOmobject, col_renderobjectrendertype  = RenderType,
	col_dom_renderobjectdatatype = DataType, col_renderobjectfom_object = FomObject
    WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code, col_name , col_useincase, 
          col_useincustomobject , col_renderobjectrendertype,
          col_dom_renderobjectdatatype, col_renderobjectfom_object)
  VALUES (Ucode, code, Name, UseInCase,
          UseInCustOmobject, RenderType,
          DataType, FomObject);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DOM_RENDEROBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
/******************************************************************************/

--TBL_DOM_REFERENCEOBJECT
/******************************************************************************/

 BEGIN
 v_xmlresult := v_input.extract('/CaseType/DomReferenceObject');
 
  MERGE INTO TBL_DOM_REFERENCEOBJECT
   USING (
   SELECT Code, Name,  IsDeleted , Ucode,
   (SELECT col_id FROM tbl_FOM_OBJECT WHERE lower(col_code) = lower(FomObjectCode)) FomObjectCode
            FROM XMLTABLE('DomReferenceObject'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       IsDeleted NUMBER PATH './IsDeleted',
                       FomObjectCode NVARCHAR2(255) PATH './FomObjectCode',
                       Ucode NVARCHAR2(255) PATH './Ucode'
                       )
)
   ON (col_ucode  = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_name  = Name,  col_isdeleted  = IsDeleted, 
                  col_dom_refobjectfom_object = FomObjectCode, col_code  = Code
               WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')   
     WHEN NOT MATCHED THEN
       INSERT (col_code  , col_name , col_isdeleted, col_dom_refobjectfom_object, col_ucode )
       VALUES (Code, Name, IsDeleted, FomObjectCode, ucode); 
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DOM_REFERENCEOBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0);
       

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/******************************************************************************/

--TBL_SOM_CONFIG
/******************************************************************************/

 BEGIN
 v_xmlresult := v_input.extract('/CaseType/SomConfig');
MERGE INTO TBL_SOM_CONFIG
   USING (
   SELECT Code, Name, Isdeleted, Defsortfield, SortDirection, Description, 
          dbms_xmlgen.convert(CustomConfig,1) CustomConfig, XmlFromQry, WhereQry, Srchqry, Fromqry, 
          (SELECT col_id FROM tbl_fom_object WHERE lower(col_code) = lower(FomObject)) FomObject,
          (SELECT col_id FROM tbl_som_model WHERE col_ucode = SomModelUcode) SomModelUcode,
          SearchConfig, GridConfig, IsShowInNavMenu, SrchXml
            FROM XMLTABLE('SomConfig'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Isdeleted NUMBER PATH './Isdeleted',
                       Defsortfield NVARCHAR2(255) PATH './Defsortfield',
                       SortDirection NVARCHAR2(255) PATH './SortDirection',
                       Description NCLOB PATH './Description',
                       CustomConfig NCLOB PATH './CustomConfig',
                       XmlFromQry NCLOB PATH './XmlFromQry',
                       WhereQry NCLOB PATH './WhereQry',
                       Srchqry NCLOB PATH './Srchqry',
                       Fromqry NCLOB PATH './Fromqry',
                       FomObject NVARCHAR2(255) PATH './FomObject',
                       SearchConfig NCLOB PATH './SearchConfig',
                       GridConfig NCLOB PATH './GridConfig',
                       IsShowInNavMenu NUMBER PATH './IsShowInNavMenu',
                       SomModelUcode NVARCHAR2(255) PATH './SomModelUcode',
                       SrchXml NCLOB PATH './SrchXml'
                       )
          )
   ON (lower(col_code) = lower(Code))
   WHEN MATCHED THEN
     UPDATE  SET  col_name  = Name, col_isdeleted  = Isdeleted, col_defsortfield  = Defsortfield, 
                  col_description = Description, col_sortdirection = SortDirection, col_som_configfom_object =  FomObject,
                  COL_CUSTOMCONFIG = CustomConfig, COL_XMLFROMQRY = XmlFromQry, COL_WHEREQRY = WhereQry,
                  col_srchqry = Srchqry, col_fromqry = Fromqry,  col_som_configsom_model = SomModelUcode,
                  col_searchconfig = SearchConfig, col_gridconfig = GridConfig, col_isshowinnavmenu=IsShowInNavMenu,
                  col_srchxml = SrchXml
            WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')                  
     WHEN NOT MATCHED THEN
       INSERT (col_code  , col_name , col_description , col_isdeleted , col_defsortfield , col_sortdirection, col_som_configfom_object,
               col_customconfig, col_xmlfromqry, col_whereqry, col_srchqry, col_fromqry , 
               col_searchconfig, col_gridconfig, col_isshowinnavmenu, col_som_configsom_model, col_srchxml)
       VALUES (Code, Name, Description,  Isdeleted, Defsortfield, SortDirection, FomObject,
               CustomConfig, XmlFromQry, WhereQry, Srchqry, Fromqry ,
               SearchConfig, GridConfig,IsShowInNavMenu, SomModelUcode, SrchXml);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_SOM_CONFIG with '||SQL%ROWCOUNT||' rows', IsError => 0);

 
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/******************************************************************************/

--TBL_FOM_ATTRIBUTE
/******************************************************************************/

 BEGIN
 v_xmlresult := v_input.extract('/CaseType/FomAttribute');
 /*
DELETE FROM TBL_FOM_ATTRIBUTE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('FomAttribute'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE lower(col_ucode) = lower(ucode))
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT'); 
*/
   MERGE INTO TBL_FOM_ATTRIBUTE
   USING (
   SELECT Code, Name, Ucode,
   (SELECT col_id FROM tbl_fom_object WHERE lower(col_code) = lower(FomObject)) FomObject,
    ColumnName, StorageType, Alias ,IsDeleted,ApiCode,
    (SELECT col_id FROM tbl_dict_datatype WHERE lower(col_code) = lower(Datatype)) Datatype
            FROM XMLTABLE('FomAttribute'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       FomObject  NVARCHAR2(255) PATH './FomObject',
                       ColumnName NVARCHAR2(255) PATH './ColumnName',
                       StorageType NVARCHAR2(255) PATH './StorageType',
                       Alias  NVARCHAR2(255) PATH './Alias',
                       IsDeleted NUMBER PATH './IsDeleted', 
                       Datatype NVARCHAR2(255) PATH './Datatype',
                       Ucode	NVARCHAR2(255) PATH './Ucode',
                       ApiCode NVARCHAR2(255) PATH './ApiCode'
                       )
)
   ON (col_ucode  = ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_name  = Name, col_fom_attributefom_object   = FomObject, col_columnname   = ColumnName, 
                  col_storagetype  = StorageType, col_alias  = Alias, col_isdeleted = IsDeleted, 
                  col_fom_attributedatatype = Datatype, col_code  = code, col_apicode = ApiCode
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')                  
     WHEN NOT MATCHED THEN
       INSERT (col_code  , col_name , col_fom_attributefom_object , col_columnname , col_storagetype , 
       col_alias,  col_isdeleted, col_fom_attributedatatype, col_ucode, col_apicode )
       VALUES (Code, Name, FomObject,  ColumnName, StorageType, 
       Alias, IsDeleted, Datatype, ucode, ApiCode);

 p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_FOM_ATTRIBUTE with '||SQL%ROWCOUNT||' rows', IsError => 0);
       

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/***************************************************************************************************/
--TBL_DOM_RENDERATTR
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_input.extract('/CaseType/DomRenderattr');
 
MERGE INTO TBL_DOM_RENDERATTR
USING(
SELECT Code, Name,  ProcessorCode, UseInSearch, 
(SELECT col_id FROM tbl_fom_attribute WHERE col_ucode = FomAttrUcode) FomAttrUcode, 
(SELECT col_id FROM tbl_dom_renderobject WHERE col_ucode = DomRenderObjectCode) DomRenderObjectCode,
Ucode, IsSearchable, IsSortable
            FROM XMLTABLE('DomRenderattr'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',
                       UseInSearch NUMBER PATH './UseInSearch',
                       FomAttrUcode NVARCHAR2(255) PATH './FomAttrUcode',                       
                       DomRenderObjectCode NVARCHAR2(255) PATH './DomRenderObjectCode',
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       IsSearchable NUMBER PATH './IsSearchable',
                       IsSortable NUMBER PATH './IsSortable'

                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_code  = Code ,
    col_processorcode = ProcessorCode, col_useinsearch = UseInSearch, 
	col_renderattrfom_attribute = FomAttrUcode, col_renderattrrenderobject = DomRenderObjectCode,
    col_issearchable = IsSearchable,  col_issortable = IsSortable 
    WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')  
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_renderattrfom_attribute, col_renderattrrenderobject, col_processorcode, 
  col_useinsearch, col_ucode, col_issearchable, col_issortable)
  VALUES (Code, Name,  FomAttrUcode, DomRenderObjectCode, ProcessorCode, 
  UseInSearch, Ucode, IsSearchable, IsSortable);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DOM_RENDERATTR with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
/***************************************************************************************************/
--TBL_DOM_RENDERCONTROL
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_input.extract('/CaseType/DomRenderControl');
 
MERGE INTO TBL_DOM_RENDERCONTROL
USING(
SELECT Ucode, Code, Name, Config, IsDefault,
(SELECT col_id FROM tbl_dom_renderobject WHERE col_ucode = DomRenderObjec) DomRenderObjec
            FROM XMLTABLE('DomRenderControl'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Config NCLOB PATH './Config',
                       IsDefault NUMBER PATH './IsDefault',
                       DomRenderObjec NVARCHAR2(255) PATH './DomRenderObjec'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code = Code, col_name = NAME, col_config = Config, 
	col_isdefault = IsDefault, col_rendercontrolrenderobject = DomRenderObjec
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')  
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code, col_name , col_config, 
	        col_isdefault, col_rendercontrolrenderobject)
  VALUES (Ucode, code, Name, Config,
          IsDefault, DomRenderObjec);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DOM_RENDERCONTROL with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
/******************************************************************************/

--TBL_DOM_REFERENCEATTR
/******************************************************************************/

 BEGIN
 v_xmlresult := v_input.extract('/CaseType/DomReferenceAttr');

  MERGE INTO TBL_DOM_REFERENCEATTR
   USING (
   SELECT Code, Name,  UseonCreate , UseonUpdate, UseonSearch, UseOnList, UseOnDetail, Ucode,
   (SELECT col_id FROM tbl_dom_referenceobject WHERE col_ucode = DomReferenceObjectCode) DomReferenceObjectCode,
   (SELECT col_id FROM tbl_fom_attribute WHERE col_ucode = FomAttributeUcode )FomAttributeUcode
            FROM XMLTABLE('DomReferenceAttr'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       UseonCreate NUMBER PATH './UseonCreate',
                       UseonUpdate NUMBER PATH './UseonUpdate',
                       UseonSearch NUMBER PATH './UseonSearch',
                       UseOnList NUMBER PATH './UseOnList',
                       UseOnDetail NUMBER PATH './UseOnDetail',
                       DomReferenceObjectCode NVARCHAR2(255) PATH './DomReferenceObjectCode',
                       FomAttributeUcode NVARCHAR2(255) PATH './FomAttributeUcode',
                       Ucode NVARCHAR2(255) PATH './Ucode'
                       )
)
   ON (col_ucode  = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_name  = Name,  col_useoncreate = UseonCreate, 
                  col_useonupdate  = UseonUpdate, col_useonsearch = UseonSearch,
                  col_useonlist = UseOnList,  col_useondetail = UseOnDetail, 
                  col_dom_refattrdom_refobject = DomReferenceObjectCode, 
                  col_dom_refattrfom_attr = FomAttributeUcode, col_code = Code 
             WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')     
     WHEN NOT MATCHED THEN
       INSERT (col_code  , col_name , col_useoncreate, col_useonupdate, col_useonsearch, 
        col_useonlist, col_useondetail, col_dom_refattrdom_refobject, col_dom_refattrfom_attr, col_ucode)
       VALUES (Code, Name, UseonCreate, UseonUpdate, UseonSearch, 
       UseOnList, UseOnDetail, DomReferenceObjectCode, FomAttributeUcode, Ucode); 
       
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DOM_REFERENCEATTR with '||SQL%ROWCOUNT||' rows', IsError => 0);
       

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 

/******************************************************************************/

--TBL_FOM_RELATIONSHIP
/******************************************************************************/

BEGIN
   v_xmlresult := v_input.extract('/CaseType/FomRelationship');


   MERGE INTO TBL_FOM_RELATIONSHIP
   USING (
   SELECT Code, Name, ForeignKeyName, 
   (SELECT col_id FROM tbl_fom_object WHERE lower(col_code) = lower(FomObjectChild)) FomObjectChild,
   (SELECT col_id FROM tbl_fom_object WHERE lower(col_code) = lower(FomObjectParent)) FomObjectParent,
   IsDeleted, ApiCode
            FROM XMLTABLE('FomRelationship'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       ForeignKeyName  NVARCHAR2(255) PATH './ForeignKeyName',
                       FomObjectChild NVARCHAR2(255) PATH './FomObjectChild',
                       FomObjectParent NVARCHAR2(255) PATH './FomObjectParent',
                       IsDeleted NUMBER PATH './IsDeleted',
                       ApiCode NVARCHAR2(255) PATH './ApiCode'                     
                       )
)
   ON (lower(col_code)  = lower(Code))
   WHEN MATCHED THEN
     UPDATE  SET  col_name  = Name, col_childfom_relfom_object   = FomObjectChild, 
                  col_parentfom_relfom_object   = FomObjectParent,  col_isdeleted = IsDeleted, col_foreignkeyname = ForeignKeyName,
                  col_apicode = ApiCode
             WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')     
     WHEN NOT MATCHED THEN
       INSERT ( col_code  , col_name , col_childfom_relfom_object , col_parentfom_relfom_object , col_isdeleted, col_foreignkeyname, col_apicode)
       VALUES (    Code,      Name,     FomObjectChild,  FomObjectParent, IsDeleted, ForeignKeyName, ApiCode);

 p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_FOM_RELATIONSHIP with '||SQL%ROWCOUNT||' rows', IsError => 0);
 

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/******************************************************************************/

--TBL_FOM_PATH
/******************************************************************************/

 BEGIN
  v_xmlresult := v_input.extract('/CaseType/FomPath');
   MERGE INTO TBL_FOM_PATH
   USING (
   SELECT Code, Name, JoinType, Ucode,
   (SELECT col_id FROM TBL_FOM_RELATIONSHIP WHERE lower(col_code) = lower(FomRelationship)) FomRelationship,
   (SELECT col_id FROM TBL_FOM_PATH WHERE col_ucode = FomPathFomPath) FomPathFomPath
            FROM XMLTABLE('FomPath'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       JoinType  NVARCHAR2(255) PATH './JoinType',
                       FomRelationship NVARCHAR2(255) PATH './FomRelationship',
                       FomPathFomPath NVARCHAR2(255) PATH './FomPathFomPath',
                       Ucode NVARCHAR2(255) PATH './Ucode'
                       )
)
   ON (col_ucode  = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_name  = Name, col_fom_pathfom_relationship   = FomRelationship, 
                  col_fom_pathfom_path   = FomPathFomPath, col_jointype = JoinType,
                  col_code  = code
            WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')      
     WHEN NOT MATCHED THEN
       INSERT (  col_code  , col_name , col_fom_pathfom_relationship , col_fom_pathfom_path, col_jointype, col_ucode  )
       VALUES (   Code,      Name,     FomRelationship,  FomPathFomPath, JoinType, Ucode); 

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_FOM_PATH with '||SQL%ROWCOUNT||' rows', IsError => 0);

 MERGE INTO TBL_FOM_PATH
   USING (
   SELECT Ucode,  (SELECT col_id FROM TBL_FOM_PATH WHERE col_ucode = FomPathFomPath) FomPathFomPath
            FROM XMLTABLE('FomPath'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       FomPathFomPath NVARCHAR2(255) PATH './FomPathFomPath'   
                       )
)
   ON (col_ucode  = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_fom_pathfom_path   = FomPathFomPath
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');
     
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/******************************************************************************/

--TBL_SOM_RESULTATTR
/******************************************************************************/

 BEGIN
  v_xmlresult := v_input.extract('/CaseType/SomResultAttr');
/*
DELETE FROM TBL_SOM_RESULTATTR 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('SomResultAttr'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE lower(col_ucode) = lower(ucode))
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');
*/
      MERGE INTO TBL_SOM_RESULTATTR
   USING (
   SELECT Code, Name, Sorder, IdProperty,IsRender,
   Jsondata, ProcessorCode, MetaProperty, Ucode, IsDeleted,
   (SELECT col_id FROM tbl_fom_path WHERE  col_ucode = FomPath) FomPath,
   (SELECT col_id FROM tbl_som_config WHERE lower(col_code) = lower(SomConfig)) SomConfig, 
   (SELECT col_id FROM tbl_fom_attribute WHERE lower(col_code) = lower(FomAttribute)) FomAttribute,
   (SELECT col_id FROM tbl_som_resultattr WHERE col_ucode = ResultAttrGroup) ResultAttrGroup,
   (SELECT col_id FROM tbl_dom_renderobject WHERE col_ucode = RenderObject) RenderObject,
   (SELECT col_id FROM tbl_dom_rendercontrol WHERE col_ucode = RenderControl) RenderControl,
   (SELECT col_id FROM tbl_dom_renderattr WHERE col_ucode = RenderAttr) RenderAttr,
   (SELECT col_id FROM tbl_dom_referenceobject WHERE col_ucode = DomRefObjUcode) DomRefObjUcode,
   (SELECT col_id FROM tbl_som_attribute WHERE col_ucode = SomAttribute) SomAttribute
            FROM XMLTABLE('SomResultAttr'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Sorder  NUMBER PATH './Sorder',
                       IdProperty NUMBER PATH './IdProperty',
                       IsDeleted NUMBER PATH 'IsDeleted',
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       FomPath NVARCHAR2(255) PATH './FomPath',
                       SomConfig NVARCHAR2(255) PATH './SomConfig',
                       FomAttribute NVARCHAR2(255) PATH './FomAttribute',
                       Jsondata NCLOB PATH './Jsondata',
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',
                       MetaProperty NUMBER PATH './MetaProperty',
                       IsRender NUMBER PATH './IsRender',
                       ResultAttrGroup NVARCHAR2(255) PATH './ResultAttrGroup',
                       RenderObject NVARCHAR2(255) PATH './RenderObject',
                       RenderControl NVARCHAR2(255) PATH './RenderControl',
                       RenderAttr NVARCHAR2(255) PATH './RenderAttr',
                       DomRefObjUcode NVARCHAR2(255) PATH './DomRefObjUcode',
                       SomAttribute NVARCHAR2(255) PATH './SomAttribute'
                       )
)
   ON (col_ucode  = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_name  = Name, col_sorder    = Sorder,  col_idproperty  = IdProperty,
                  col_isdeleted = IsDeleted,
                  col_som_resultattrfom_path = FomPath , col_som_resultattrsom_config = SomConfig,
                  col_som_resultattrfom_attr = FomAttribute, col_code  = code,
                  col_jsondata = Jsondata, col_processorcode = ProcessorCode,
                  col_metaproperty = MetaProperty, col_isrender = IsRender,
                  col_resultattrresultattrgroup = ResultAttrGroup, col_som_resattrrenderobject = RenderObject,
                  col_som_resultattrrenderattr = RenderAttr, col_som_resultattrrenderctrl = RenderControl,
                  col_som_resultattrrefobject = DomRefObjUcode, 
                  col_som_resultattrsom_attr = SomAttribute
            WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')      
     WHEN NOT MATCHED THEN
       INSERT (  col_code  , col_name , col_sorder , col_idproperty, col_isdeleted,
               col_som_resultattrfom_path,  col_som_resultattrsom_config, col_som_resultattrfom_attr,
               col_ucode , col_jsondata , col_processorcode, col_metaproperty, col_isrender,
               col_resultattrresultattrgroup , col_som_resattrrenderobject,
               col_som_resultattrrenderattr, col_som_resultattrrenderctrl,
               col_som_resultattrrefobject, col_som_resultattrsom_attr)
       VALUES (   Code,      Name,     Sorder,  IdProperty, IsDeleted,
               FomPath,  SomConfig, FomAttribute, 
               ucode , Jsondata, ProcessorCode, MetaProperty, IsRender,
               ResultAttrGroup, RenderObject,
               RenderAttr, RenderControl,
               DomRefObjUcode,SomAttribute);
               
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_SOM_RESULTATTR with '||SQL%ROWCOUNT||' rows', IsError => 0);

      MERGE INTO TBL_SOM_RESULTATTR
   USING (
   SELECT Ucode, 
   (SELECT col_id FROM tbl_som_resultattr WHERE col_ucode = ResultAttrGroup) ResultAttrGroup
            FROM XMLTABLE('SomResultAttr'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       ResultAttrGroup NVARCHAR2(255) PATH './ResultAttrGroup'
                       )
)
   ON (col_ucode  = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET   col_resultattrresultattrgroup = ResultAttrGroup
            WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');
            
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/******************************************************************************/

--TBL_SOM_SEARCHATTR
/******************************************************************************/

 BEGIN
  v_xmlresult := v_input.extract('/CaseType/SomSearchAttr');
/*
	DELETE FROM 
TBL_SOM_SEARCHATTR
WHERE NOT EXISTS 
(SELECT 1 FROM XMLTABLE('/SomSearchAttr'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode')
 WHERE  Ucode = col_ucode                      
)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');
*/
     MERGE INTO TBL_SOM_SEARCHATTR
   USING (
   SELECT Code, Name, Sorder, IsCaseinCensitive, 
          IsLike, IsAdded, CustomConfig,ValueField,
          ProcessorCode, DisplayField , IsColumnComp,IsRender, 
   (SELECT col_id FROM tbl_fom_uielementtype WHERE  col_code = UiElementType) UiElementType, -- index without lower()
          Constant, DefaultValue, IsPreDefined, IsDeleted,
   (SELECT col_id FROM tbl_fom_path WHERE col_ucode = FomPath) FomPath, 
   (SELECT col_id FROM tbl_som_config WHERE lower(col_code) = lower(SomConfig)) SomConfig,
   (SELECT col_id FROM tbl_fom_attribute WHERE lower(col_code) = lower(FomAttribute)) FomAttribute,
   (SELECT col_id FROM tbl_fom_attribute WHERE lower(col_code) = lower(LeftSearchFomAttribute)) LeftSearchFomAttribute,
   (SELECT col_id FROM tbl_fom_attribute WHERE lower(col_code) = lower(RightSearchFomAttribute)) RightSearchFomAttribute,
   Jsondata, RightAlias, LeftAlias, Ucode,
   (SELECT col_id FROM tbl_dom_renderattr WHERE col_ucode = RendErattrUcode) RendErattrUcode,
   (SELECT col_id FROM tbl_dom_rendercontrol WHERE col_ucode = RenderControlUcode) RenderControlUcode,
   (SELECT col_id FROM tbl_dom_renderobject WHERE col_ucode = RenderObjectUcode) RenderObjectUcode,
   (SELECT col_id FROM tbl_som_searchattr WHERE col_ucode = SearchAttrGroup) SearchAttrGroup,
   (SELECT col_id FROM tbl_dom_referenceobject WHERE col_ucode =  DomReferenceObjectUcode) DomReferenceObject,
   (SELECT col_id FROM tbl_som_attribute WHERE col_ucode = SomAttribute) SomAttribute
            FROM XMLTABLE('SomSearchAttr'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Sorder  NUMBER PATH './Sorder',
                       IsCaseinCensitive NUMBER PATH './IsCaseinCensitive',
                       IsLike NUMBER PATH './IsLike',
                       IsAdded NUMBER PATH './IsAdded',
                       CustomConfig NCLOB PATH './CustomConfig',
                       ValueField NVARCHAR2(255) PATH './ValueField',
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',
                       DisplayField NVARCHAR2(255) PATH './DisplayField',
                       UiElementType NVARCHAR2(255) PATH './UiElementType',
                       Constant NUMBER PATH './Constant',
                       DefaultValue NVARCHAR2(255) PATH './DefaultValue',
                       IsPreDefined NUMBER PATH './IsPreDefined',
                       IsColumnComp NUMBER PATH './IsColumnComp',
                       FomPath NVARCHAR2(255) PATH './FomPath',
                       SomConfig NVARCHAR2(255) PATH './SomConfig',
                       FomAttribute NVARCHAR2(255) PATH './FomAttribute',
                       LeftSearchFomAttribute NVARCHAR2(255) PATH './LeftSearchFomAttribute',
                       RightSearchFomAttribute NVARCHAR2(255) PATH './RightSearchFomAttribute',
                       Jsondata NCLOB PATH './Jsondata',
                       RightAlias NVARCHAR2(255) PATH './RightAlias',
                       LeftAlias NVARCHAR2(255) PATH './LeftAlias',
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       IsRender NUMBER PATH './IsRender',
                       RendErattrUcode NVARCHAR2(255) PATH './RendErattrUcode',
                       RenderControlUcode NVARCHAR2(255) PATH './RenderControlUcode',
                       RenderObjectUcode NVARCHAR2(255) PATH './RenderObjectUcode',
                       SearchAttrGroup NVARCHAR2(255) PATH './SearchAttrGroup',
                       IsDeleted NUMBER PATH './IsDeleted',
                       DomReferenceObjectUcode NVARCHAR2(255) PATH './DomReferenceObjectUcode',
                       SomAttribute NVARCHAR2(255) PATH './SomAttribute'
                       )
)
   ON (col_ucode  = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_name  = Name, col_sorder = Sorder,  col_iscaseincensitive   = IsCaseinCensitive,
                  col_islike  = IsLike, col_isadded   =  IsAdded, col_customconfig = CustomConfig, 
                  col_valuefield = ValueField, col_processorcode =  ProcessorCode, col_displayfield = DisplayField,
                  col_searchattr_uielementtype = UiElementType, col_constant = Constant, col_defaultvalue = DefaultValue,
                  col_ispredefined = IsPreDefined, col_iscolumncomp = IsColumnComp , 
                  col_som_searchattrfom_path = FomPath, col_som_searchattrsom_config = SomConfig, col_som_searchattrfom_attr = FomAttribute , 
                  col_left_searchattrfom_attr = LeftSearchFomAttribute, col_right_searchattrfom_attr = RightSearchFomAttribute,
                  col_jsondata = Jsondata, col_rightalias = RightAlias, col_code  = code, 
                  col_leftalias = LeftAlias, col_isrender = IsRender,
                  col_som_searchattrrenderattr = RendErattrUcode, col_som_searchattrrenderctrl = RenderControlUcode, 
                  col_som_srchattrrenderobject = RenderObjectUcode, col_searchattrsearchattrgroup = SearchAttrGroup,
                  col_isdeleted = IsDeleted, col_som_searchattrrefobject = DomReferenceObject,
                  col_som_searchattrsom_attr = SomAttribute
           WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')       
     WHEN NOT MATCHED THEN
       INSERT (col_som_searchattrfom_path, col_som_searchattrsom_config, col_som_searchattrfom_attr,
               col_code, col_name, col_sorder, col_iscaseincensitive, 
               col_islike, col_isadded, col_customconfig, col_valuefield,
               col_processorcode, col_displayfield, col_searchattr_uielementtype, col_constant, 
               col_defaultvalue, col_ispredefined, col_iscolumncomp, 
               col_left_searchattrfom_attr, col_right_searchattrfom_attr, 
               col_jsondata, col_rightalias, col_leftalias, col_ucode,
               col_isrender, 
               col_som_searchattrrenderattr  , col_som_searchattrrenderctrl , 
               col_som_srchattrrenderobject , col_searchattrsearchattrgroup,
               col_isdeleted , col_som_searchattrrefobject, col_som_searchattrsom_attr)
       VALUES (FomPath, SomConfig,  FomAttribute,
               Code, Name, Sorder, IsCaseinCensitive,
               IsLike, IsAdded, CustomConfig,ValueField,
               ProcessorCode, DisplayField, UiElementType, Constant,
               DefaultValue, IsPreDefined, IsColumnComp,
               LeftSearchFomAttribute , RightSearchFomAttribute,
               Jsondata, RightAlias, LeftAlias, Ucode,
               IsRender, 
               RendErattrUcode, RenderControlUcode,
               RenderObjectUcode, SearchAttrGroup,
               IsDeleted, DomReferenceObject, SomAttribute);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_SOM_SEARCHATTR with '||SQL%ROWCOUNT||' rows', IsError => 0);

MERGE INTO TBL_SOM_SEARCHATTR
   USING (
   SELECT Ucode,
   (SELECT col_id FROM tbl_som_searchattr WHERE col_ucode = SearchAttrGroup) SearchAttrGroup
            FROM XMLTABLE('SomSearchAttr'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       SearchAttrGroup NVARCHAR2(255) PATH './SearchAttrGroup'
                       )
)
   ON (col_ucode  = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_searchattrsearchattrgroup = SearchAttrGroup
           WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');
           
 EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;     


 /***************************************************************************************************/

 -- TBL_fom_form
 /***************************************************************************************************/

BEGIN
    v_xmlresult := v_input.extract('/CaseType/FomForm');
 MERGE INTO tbl_fom_form
 USING(
SELECT Code, Name,  IsDeleted, Description, Formmarkup, IsGeneralUse
            FROM XMLTABLE('/FomForm'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name nvarchar2(255) PATH './Name',
                       Formmarkup NCLOB PATH './Formmarkup',
                       IsDeleted NUMBER PATH './IsDeleted',
                       Description NCLOB PATH './Description',
                       IsGeneralUse NUMBER PATH './IsGeneralUse'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_formmarkup = Formmarkup, col_isdeleted = IsDeleted, col_description = Description,
  col_isgeneraluse = IsGeneralUse
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_formmarkup, col_isdeleted, col_description, col_isgeneraluse)
  VALUES (Code, Name, Formmarkup, IsDeleted, Description, IsGeneralUse);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_fom_form with '||SQL%ROWCOUNT||' rows', IsError => 0);


EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 

/***************************************************************************************************/

 -- tbl_DOM_Model
 /***************************************************************************************************/
BEGIN
v_xmlresult := v_input.extract('/CaseType/DomModel');
/*
DELETE FROM
tbl_DOM_Model
WHERE NOT EXISTS
(SELECT 1 FROM XMLTABLE('/DomModel'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode')
 WHERE  Ucode = col_ucode
)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');
*/
MERGE INTO tbl_DOM_Model
 USING(
SELECT Ucode, Code,  Description, Name_, 
(SELECT col_id FROM tbl_fom_object WHERE lower(col_code) = lower(FomObject)) FomObject,
Config, IsDeleted, UsedFor, 
(SELECT col_id FROM tbl_mdm_model WHERE col_ucode = MdmModelUcode) MdmModelUcode 
            FROM XMLTABLE('/DomModel'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code  NVARCHAR2(255) PATH './Code',
                       Description NCLOB PATH './Description',
                       Name_ NVARCHAR2(255) PATH './Name',
                       CaseType NVARCHAR2(255) PATH './CaseType',
                       FomObject NVARCHAR2(255) PATH './FomObject',
                       Config NCLOB PATH './Config',
                       IsDeleted NUMBER PATH './IsDeleted',
                       UsedFor NVARCHAR2(255) PATH './UsedFor',
                       MdmModelUcode NVARCHAR2(255) PATH './MdmModelUcode'  
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code  = code, col_description = Description,
  col_name  = Name_, 
  col_dom_modelfom_object = FomObject, col_config = dbms_xmlgen.convert(Config,1),
  col_isdeleted = IsDeleted, col_usedfor = UsedFor, col_dom_modelmdm_model = MdmModelUcode 
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')  
WHEN NOT MATCHED THEN
  INSERT (col_code, col_description , col_name ,  col_dom_modelfom_object, col_config, col_isdeleted, col_usedfor, col_ucode, col_dom_modelmdm_model   )
  VALUES (code, Description, Name_, FomObject, dbms_xmlgen.convert(Config,1), IsDeleted, UsedFor, Ucode, MdmModelUcode);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_DOM_Model with '||SQL%ROWCOUNT||' rows', IsError => 0);


EXCEPTION 
	WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 

/***************************************************************************************************/

 -- tbl_dom_object
 /***************************************************************************************************/

BEGIN
v_xmlresult := v_input.extract('/CaseType/DomObject');
/*
DELETE FROM
tbl_dom_object
WHERE NOT EXISTS
(SELECT 1 FROM XMLTABLE('/DomObject'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode')
 WHERE  Ucode = col_ucode
)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');
*/
MERGE INTO tbl_dom_object
 USING(
SELECT Ucode, Code,   Name_, 
(SELECT col_id FROM tbl_fom_object WHERE lower(col_code) = lower(FomObject)) FomObject,
(SELECT col_id FROM tbl_dict_partytype WHERE lower(col_code) = lower(PartyType)) PartyType,
(SELECT col_id FROM tbl_fom_path WHERE col_ucode = PathToprntext) PathToprntext,
(SELECT col_id FROM tbl_fom_path WHERE col_ucode = PathTosrvparty) PathTosrvparty,
IsRoot, IsSharable, Type_, Descr, 
(SELECT col_id FROM tbl_dom_model WHERE col_ucode = DomModel) DomModel
            FROM XMLTABLE('/DomObject'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code NVARCHAR2(255) PATH './Code',
                       Name_ NVARCHAR2(255) PATH './Name',
                       FomObject NVARCHAR2(255) PATH './FomObject',
                       PartyType NVARCHAR2(255) PATH './PartyType',
                       PathToprntext NVARCHAR2(255) PATH './PathToprntext',
                       PathTosrvparty NVARCHAR2(255) PATH './PathTosrvparty',
                       IsRoot NUMBER PATH './IsRoot',
                       IsSharable NUMBER PATH './IsSharable',
                       DomModel NVARCHAR2(255) PATH './DomModel',
                       Type_ NVARCHAR2(255) PATH './Type',
                       Descr NCLOB PATH './Description' 
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code  = Code, col_name  = Name_,
  col_dom_objectfom_object =  FomObject, col_dom_objectdict_partytype  = PartyType, 
  col_dom_object_pathtoprntext  = PathToprntext, col_dom_object_pathtosrvparty  = PathTosrvparty,
  col_isroot = IsRoot, col_issharable = IsSharable, col_dom_objectdom_model = DomModel,
  col_type = Type_, col_description = Descr
 WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT') 
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code,  col_name, col_dom_objectdict_partytype , 
          col_dom_objectfom_object , col_dom_object_pathtoprntext , col_dom_object_pathtosrvparty , 
          col_isroot, col_issharable, col_dom_objectdom_model,
          col_type, col_description  )
  VALUES (Ucode, Code, Name_, PartyType,  
          FomObject, PathToprntext, PathTosrvparty,
          IsRoot, IsSharable, DomModel,
          Type_, Descr);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_dom_object with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 

 /***************************************************************************************************/

 -- tbl_dom_relationship
 /***************************************************************************************************/

BEGIN
v_xmlresult := v_input.extract('/CaseType/DomRelationship');
/*
DELETE FROM tbl_dom_relationship 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DomRelationship'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE lower(col_ucode) = lower(ucode))
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT'); 
*/
MERGE INTO tbl_dom_relationship
 USING(
SELECT Ucode, Code,   Name_, 
(SELECT col_id FROM tbl_fom_relationship WHERE lower(col_code) = lower(FomRelationship)) FomRelationship,
(SELECT col_id FROM tbl_dom_object WHERE col_ucode = DomObjectChild) DomObjectChild,
(SELECT col_id FROM tbl_dom_object WHERE col_ucode = DomObjectParent) DomObjectParent
            FROM XMLTABLE('/DomRelationship'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code NVARCHAR2(255) PATH './Code',
                       Name_ NVARCHAR2(255) PATH './Name',
                       FomRelationship NVARCHAR2(255) PATH './FomRelationship',
                       DomObjectChild NVARCHAR2(255) PATH './DomObjectChild',
                       DomObjectParent NVARCHAR2(255) PATH './DomObjectParent'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code  = Code, col_name  = Name_,
  col_dom_relfom_rel  =  FomRelationship, col_childdom_reldom_object   = DomObjectChild, 
  col_parentdom_reldom_object   = DomObjectParent
 WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT') 
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code,  col_name, col_dom_relfom_rel  , 
          col_childdom_reldom_object  , col_parentdom_reldom_object  )
  VALUES (Ucode, Code, Name_, FomRelationship,  
          DomObjectChild, DomObjectParent);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_dom_relationship with '||SQL%ROWCOUNT||' rows', IsError => 0);


EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
 /***************************************************************************************************/

 -- tbl_DOM_Attribute
 /***************************************************************************************************/

BEGIN
v_xmlresult := v_input.extract('/CaseType/DomAttribute');
/*
DELETE FROM tbl_DOM_Attribute 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DomAttribute'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE lower(col_ucode) = lower(ucode))
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT'); 
*/
MERGE INTO tbl_DOM_Attribute
 USING(
SELECT Ucode, Code,   Name_, 
(SELECT col_id FROM tbl_fom_attribute WHERE lower(col_code) = lower(FomAttribute)) FomAttribute,
(SELECT col_id FROM tbl_dom_object WHERE col_ucode = DomObject) DomObject,
(SELECT col_id FROM tbl_ac_accessobject WHERE lower(col_code) = lower(AccesObject)) AccesObject,
DOrder, IsUpdatable,IsSearchable, IsRetrievableInList,IsRetrievableInDetail, IsInsertable,
IsRequired, Config, Description, IsSystem  
            FROM XMLTABLE('/DomAttribute'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code NVARCHAR2(255) PATH './Code',
                       Name_ NVARCHAR2(255) PATH './Name',
                       FomAttribute NVARCHAR2(255) PATH './FomAttribute',
                       DomObject NVARCHAR2(255) PATH './DomObject',
                       DOrder NUMBER PATH './DOrder',
                       IsUpdatable NUMBER PATH './IsUpdatable',
                       IsSearchable NUMBER PATH './IsSearchable',
                       IsRetrievableInList NUMBER PATH './IsRetrievableInList',
                       IsRetrievableInDetail NUMBER PATH './IsRetrievableInDetail',
                       IsInsertable NUMBER PATH './IsInsertable',
                       IsRequired NUMBER path './IsRequired',
                       Config NCLOB PATH './Config', 
                       Description NCLOB PATH './Description',
                       IsSystem NUMBER PATH'./IsSystem',
                       AccesObject NVARCHAR2(255) PATH './AccesObject')
                       )
               
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code  = Code, col_name  = Name_,
  col_dom_attrfom_attr   =  FomAttribute, col_dom_attributedom_object    = DomObject, 
  col_dorder = DOrder, col_isupdatable = IsUpdatable, 
  col_issearchable = IsSearchable, col_isretrievableinlist = IsRetrievableInList,
  col_isretrievableindetail = IsRetrievableInDetail, col_isinsertable = IsInsertable,
  col_isrequired = IsRequired, col_config = Config, col_description = Description,
  col_issystem = IsSystem, col_dom_attributeaccessobject = AccesObject
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code,  col_name, col_dom_attrfom_attr   , 
          col_dom_attributedom_object   , col_dorder ,
          col_isupdatable , col_issearchable , col_isretrievableinlist, 
          col_isretrievableindetail  , col_isinsertable ,
          col_isrequired , col_config ,col_description, col_issystem,
          col_dom_attributeaccessobject)
  VALUES (Ucode, Code, Name_, FomAttribute,  
          DomObject, DOrder,
          IsUpdatable, IsSearchable, IsRetrievableInList,
          IsRetrievableInDetail, IsInsertable,
          IsRequired, Config, Description, IsSystem,
          AccesObject);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_DOM_Attribute with '||SQL%ROWCOUNT||' rows', IsError => 0);


EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
	END;
 /***************************************************************************************************/

 -- tbl_dom_config
 /***************************************************************************************************/

BEGIN
v_xmlresult := v_input.extract('/CaseType/DomConfig');

/*
DELETE FROM tbl_dom_config 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DomConfig'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE lower(col_ucode) = lower(ucode))
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT'); 
*/
MERGE INTO tbl_dom_config
 USING(
SELECT Ucode, Code,   Name_, Descr, IsDeleted, 
(SELECT col_id FROM tbl_fom_object WHERE lower(col_code) = lower(FomObject)) FomObject,
(SELECT col_id FROM tbl_dict_casesystype WHERE lower(col_code) = lower(CaseType) ) CaseType, 
(SELECT col_id FROM tbl_dom_model WHERE col_ucode = DomModelUcode) DomModelUcode,
Purpose
            FROM XMLTABLE('/DomConfig'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code NVARCHAR2(255) PATH './Code',
                       Name_ NVARCHAR2(255) PATH './Name',
                       Descr NCLOB PATH './Description',
                       CaseType NVARCHAR2(255) PATH './CaseType',
                       FomObject NVARCHAR2(255) PATH './FomObject',
                       IsDeleted NUMBER PATH './IsDeleted',
                       Purpose NVARCHAR2(255) PATH './Purpose',
                       DomModelUcode NVARCHAR2(255) PATH './DomModelUcode'  
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code  = Code, col_name  = Name_,
  col_description = Descr,
  col_dom_configfom_object  = FomObject, col_isdeleted  = IsDeleted, 
  col_purpose = Purpose, col_dom_configdom_model = DomModelUcode
 WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT') 
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code, col_name, col_description, 
           col_dom_configfom_object,
          col_isdeleted, col_purpose, col_dom_configdom_model )
  VALUES (Ucode, Code, Name_, Descr,  
          FomObject,
          IsDeleted, Purpose, DomModelUcode);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_dom_config with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
 /***************************************************************************************************/

 -- tbl_DOM_UpdateAttr
 /***************************************************************************************************/

BEGIN
v_xmlresult := v_input.extract('/CaseType/DomUpdateAttr');
/*
DELETE FROM tbl_DOM_UpdateAttr 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DomUpdateAttr'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE lower(col_ucode) = lower(ucode))
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT'); 
*/
MERGE INTO tbl_DOM_UpdateAttr
 USING(
SELECT Ucode, Code,   Name_, DOrder, MappingName, 
(SELECT col_id FROM tbl_dom_config WHERE col_ucode = DomConfig) DomConfig,
(SELECT col_id FROM tbl_fom_attribute WHERE lower(col_code) = lower(FomAttribute) ) FomAttribute, 
(SELECT col_id FROM tbl_fom_path WHERE col_ucode = FomPath ) FomPath,
(SELECT col_id FROM tbl_dom_attribute WHERE col_ucode = DomAttributeUcode ) DomAttribute
            FROM XMLTABLE('/DomUpdateAttr'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code NVARCHAR2(255) PATH './Code',
                       Name_ NVARCHAR2(255) PATH './Name',
                       DOrder NUMBER PATH './DOrder',
                       MappingName NVARCHAR2(255) PATH './MappingName',
                       DomConfig NVARCHAR2(255) PATH './DomConfig',
                       FomAttribute NVARCHAR2(255) PATH './FomAttribute',
                       FomPath NVARCHAR2(255) PATH './FomPath',
                       DomAttributeUcode NVARCHAR2(255) PATH './DomAttributeUcode'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code  = Code, col_name  = Name_,
  col_dorder  = DOrder, col_mappingname  = MappingName, 
  col_dom_updateattrdom_config   = DomConfig, col_dom_updateattrfom_attr   = FomAttribute, 
  col_dom_updateattrfom_path  = FomPath, col_dom_updateattrdom_attr = DomAttribute
WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')  
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code, col_name, col_dorder , 
          col_mappingname , col_dom_updateattrdom_config ,
          col_dom_updateattrfom_attr , col_dom_updateattrfom_path,  col_dom_updateattrdom_attr )
  VALUES (Ucode, Code, Name_, DOrder,  
          MappingName, DomConfig,
          FomAttribute, FomPath, DomAttribute);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_DOM_UpdateAttr with '||SQL%ROWCOUNT||' rows', IsError => 0);


EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
 /***************************************************************************************************/

 -- tbl_DOM_InsertAttr
 /***************************************************************************************************/

BEGIN
v_xmlresult := v_input.extract('/CaseType/DomInsertAttr');
/*
DELETE FROM tbl_DOM_InsertAttr 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DomInsertAttr'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE lower(col_ucode) = lower(ucode))
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT'); 
*/
MERGE INTO tbl_DOM_InsertAttr
 USING(
SELECT Ucode, Code,   Name_, DOrder, MappingName, 
(SELECT col_id FROM tbl_dom_config WHERE col_ucode = DomConfig) DomConfig,
(SELECT col_id FROM tbl_fom_attribute WHERE lower(col_code) = lower(FomAttribute) ) FomAttribute, 
(SELECT col_id FROM tbl_fom_path WHERE col_ucode = FomPath ) FomPath,
(SELECT col_id FROM tbl_dom_attribute WHERE col_ucode = DomAttributeUcode) DomAttributeUcode
            FROM XMLTABLE('/DomInsertAttr'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code NVARCHAR2(255) PATH './Code',
                       Name_ NVARCHAR2(255) PATH './Name',
                       DOrder NUMBER PATH './DOrder',
                       MappingName NVARCHAR2(255) PATH './MappingName',
                       DomConfig NVARCHAR2(255) PATH './DomConfig',
                       FomAttribute NVARCHAR2(255) PATH './FomAttribute',
                       FomPath NVARCHAR2(255) PATH './FomPath',
                       DomAttributeUcode NVARCHAR2(255) PATH './DomAttributeUcode'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code = Code, col_name = Name_,
  col_dorder = DOrder, col_mappingname = MappingName, 
  col_dom_insertattrdom_config = DomConfig, col_dom_insertattrfom_attr = FomAttribute, 
  col_dom_insertattrfom_path = FomPath, col_dom_insertattrdom_attr = DomAttributeUcode
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code, col_name, col_dorder , 
          col_mappingname  , col_dom_insertattrdom_config  ,
          col_dom_insertattrfom_attr  , col_dom_insertattrfom_path,
          col_dom_insertattrdom_attr   )
  VALUES (Ucode, Code, Name_, DOrder,  
          MappingName, DomConfig,
          FomAttribute, FomPath,
          DomAttributeUcode);
          
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_DOM_InsertAttr with '||SQL%ROWCOUNT||' rows', IsError => 0);
 
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
 /***************************************************************************************************/

 -- tbl_dom_cache
 /***************************************************************************************************/

BEGIN
v_xmlresult := v_input.extract('/CaseType/DomCache');
/*
DELETE FROM tbl_dom_cache 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DomCache'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = Ucode)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from tbl_dom_cache '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
MERGE INTO tbl_dom_cache
 USING(
SELECT Ucode, SqlType,   Session_, ParentSeqnuMber, ParentObjectTableName, 
ParentObjectName,ObjectTableName, ChildObjectTableName, ChildObjectName, Sorder, 
ParentreCordId, Query_, IsDeleted, IsAdded, IsExtension, RootParentSeqNumber, 
(SELECT col_id FROM tbl_dom_config WHERE lower(col_code) = lower(DomConfig) ) DomConfig,
ObjectName, ChildObject, RecordId, ParentObject, ParentItemId, ItemId
            FROM XMLTABLE('/DomCache'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       SqlType NVARCHAR2(255) PATH './SqlType',
                       Session_ NVARCHAR2(255) PATH './Session',
                       ParentSeqnuMber NUMBER PATH './ParentSeqnuMber',
                       ParentObjectTableName NVARCHAR2(255) PATH './ParentObjectTableName',
                       ParentObjectName NVARCHAR2(255) PATH './ParentObjectName',
                       ParentObject NVARCHAR2(255) PATH './ParentObject',
                       ObjectTableName NVARCHAR2(255) PATH './ObjectTableName',
                       ObjectName NVARCHAR2(255) PATH './ObjectName',
                       ChildObjectTableName NVARCHAR2(255) PATH './ChildObjectTableName',
                       ChildObjectName NVARCHAR2(255) PATH './ChildObjectName',
                       ChildObject NVARCHAR2(255) PATH './ChildObject',
                       Sorder NUMBER PATH './Sorder',
                       ParentreCordId NUMBER PATH './ParentreCordId',
                       Query_ NCLOB PATH './Query',
                       RecordId NVARCHAR2(255) PATH './RecordId',
                       DomConfig NVARCHAR2(255) PATH './DomConfig',
                       IsDeleted NUMBER PATH './IsDeleted',
                       IsAdded NUMBER PATH './IsAdded',
                       IsExtension NUMBER PATH './IsExtension',
                       RootParentSeqNumber NUMBER PATH './RootParentSeqNumber',
                       ParentItemId NUMBER PATH './ParentItemId',
                       ItemId NUMBER PATH './ItemId'
 )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_sqltype  = SqlType,
  col_session  = Session_, col_parentseqnumber  = ParentSeqnuMber, 
  col_parentobjecttablename = ParentObjectTableName, col_parentobjectname = ParentObjectName,
  col_parentobject  = ParentObject, col_objecttablename  = ObjectTableName, 
  col_objectname  = ObjectName, col_childobjecttablename = ChildObjectTableName,
  col_childobjectname = ChildObjectName, col_childobject = ChildObject, 
  col_sorder = Sorder, col_parentrecordid =ParentreCordId , col_query = Query_, 
  col_recordid = RecordId, col_dom_cachedom_config =  DomConfig, col_isdeleted = IsDeleted, 
  col_isadded = IsAdded, col_isextension = IsExtension, col_rootparentseqnumber = RootParentSeqNumber,
  col_parentitemid = ParentItemId, col_itemid = ItemId
 WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT') 
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_sqltype , col_session , 
          col_parentseqnumber, col_parentobjecttablename, col_parentobjectname, col_parentobject, 
          col_objecttablename, col_objectname,   
          col_childobjecttablename, col_childobjectname , col_childobject,      
          col_sorder, col_parentrecordid , col_query, col_recordid, 
          col_dom_cachedom_config, col_isdeleted , col_isadded, 
          col_isextension , col_rootparentseqnumber, col_parentitemid, col_itemid )
  VALUES (Ucode, SqlType, Session_,   
          ParentSeqnuMber, ParentObjectTableName, ParentObjectName, ParentObject,
          ObjectTableName, ObjectName,
          ChildObjectTableName, ChildObjectName, ChildObject,
          Sorder, ParentreCordId,  Query_, RecordId,
          DomConfig, IsDeleted, IsAdded,
          IsExtension, RootParentSeqNumber, ParentItemId, ItemId);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_dom_cache with '||SQL%ROWCOUNT||' rows', IsError => 0);



EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
  /***************************************************************************************************/

 -- tbl_FOM_CodedPage
 /***************************************************************************************************/

BEGIN
     v_xmlresult := v_input.extract('/CaseType/CodedPage');
     
v_cnt := f_util_softDelete(InputTableName =>'TBL_FOM_CODEDPAGE',
                  partOfXml =>  v_xmlresult,
                  fieldMerge => 'code',
                  xmlID => XmlId,
                  tagName => 'CodedPage');   
                  
MERGE INTO tbl_FOM_CodedPage
USING(
SELECT Code, Name, Description, IsDeleted, dbms_xmlgen.convert(Pagemarkup,1) Pagemarkup,
IsGeneralUse, IsNavMenuItem
            FROM XMLTABLE('CodedPage'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Pagemarkup NCLOB PATH './Pagemarkup',
                       Description NCLOB PATH './Description',
                       IsDeleted NUMBER PATH './IsDeleted',
                       IsGeneralUse NUMBER PATH './IsGeneralUse',
                       IsNavMenuItem NUMBER PATH './IsNavMenuItem' 
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_description = Description, col_isdeleted = IsDeleted ,col_pagemarkup  = Pagemarkup,
  col_isgeneraluse = IsGeneralUse, col_isnavmenuitem = IsNavMenuItem
WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')  
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_description, col_isdeleted, col_pagemarkup, col_isgeneraluse, col_isnavmenuitem   )
  VALUES (Code, Name, Description, IsDeleted, Pagemarkup, IsGeneralUse, IsNavMenuItem);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_FOM_CodedPage with '||SQL%ROWCOUNT||' rows', IsError => 0);


EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/***************************************************************************************************/

 -- TBL_MDM_FORM 
/***************************************************************************************************/
BEGIN
     v_xmlresult := v_input.extract('/CaseType/MdmForm');
--col_insertdomobjectid - col_updatedomobjectid don't used     
MERGE INTO TBL_MDM_FORM
USING(
SELECT Code, Name, Description, IsDeleted, 
BusinessObject, AutoGenerated, FormRule,
(SELECT col_id FROM tbl_dom_object WHERE  col_ucode = DomObjectUcode) DomObjectUcode  

            FROM XMLTABLE('MdmForm'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Description NCLOB PATH './Description',
                       IsDeleted NUMBER PATH './IsDeleted',
                       BusinessObject NVARCHAR2(255) PATH './BusinessObject',
                       AutoGenerated NUMBER PATH './AutoGenerated',
                       DomObjectUcode NVARCHAR2(255) PATH './DomObjectUcode',
                       FormRule NCLOB PATH './FormRule')
               )
ON (upper(col_code) = upper(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_description = Description, col_isdeleted = IsDeleted ,
  col_businessobject = BusinessObject, col_autogenerated = AutoGenerated,
  col_mdm_formdom_object = DomObjectUcode, col_formrule = FormRule
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_description, col_isdeleted, col_businessobject,
    col_autogenerated , col_mdm_formdom_object, col_formrule  )
  VALUES (Code, Name, Description, IsDeleted, BusinessObject,
    AutoGenerated, DomObjectUcode, FormRule );

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_MDM_FORM with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/***************************************************************************************************/

 -- TBL_MDM_SEARCHPAGE 
/***************************************************************************************************/
BEGIN
     v_xmlresult := v_input.extract('/CaseType/MdmSearchPage');
MERGE INTO tbl_mdm_searchpage
USING(
SELECT Ucode, FormMode,
(SELECT col_id FROM tbl_mdm_form WHERE  upper(col_code) = upper(MdmFormCode)) MdmFormCode,
(SELECT col_id FROM tbl_som_config WHERE  lower(col_code) = lower(SomConfigCode)) SomConfigCode
            FROM XMLTABLE('MdmSearchPage'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       MdmFormCode NVARCHAR2(255) PATH './MdmFormCode',
                       SomConfigCode NVARCHAR2(255) PATH './SomConfigCode',
                       FormMode NVARCHAR2(255) PATH './FormMode'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_searchpagemdm_form = MdmFormCode, col_searchpagesom_config = SomConfigCode,
  col_formmode = FormMode
WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')  
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_searchpagemdm_form, col_searchpagesom_config, col_formmode)
  VALUES (Ucode, MdmFormCode, SomConfigCode, FormMode);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_MDM_SEARCHPAGE with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

 p_util_update_log ( XmlIdLog => XmlId, Message => 'End Load Dictionary', IsError => 0);  

 
IF  v_dict != 2 THEN 
 /* if v_parentid is null or v_cnt = 0 then
    v_parentid := 0;
    insert into tbl_tasktemplate(col_name,col_parentttid,col_taskorder,col_depth,col_leaf) values('root',v_parentid,1,0,0);
    select gen_tbl_tasktemplate.currval into v_parentid from dual;
  end if;    */

  /***************************************************************************************************/

 -- tbl_dict_stateconfig
 /***************************************************************************************************/



BEGIN
       
  v_xmlresult := v_input.extract('/CaseType/StateConfigs');
  
  MERGE INTO tbl_dict_stateconfig t
    USING (
    SELECT t1.*,
    f_util_extract_clob_from_xml(Input => v_input_clob ,Path => '/CaseType/StateConfigs['||t1.rn||']/Config/text()') Config ,
    (SELECT col_id FROM tbl_dict_version WHERE col_code = Version) VersionID,
    (SELECT col_id FROM tbl_dict_stateconfigtype WHERE col_ucode = StateconfigTypeUcode) StateconfigTypeId,
    (SELECT col_id FROM tbl_dict_casesystype WHERE lower(col_code) = lower(CaseType)) CaseTypeId
     FROM 
    (
    SELECT Code, Name, IsDeleted,  Type, IsDefault,   row_number() OVER (ORDER BY NULL) AS RN, 
    Version, Revision, IsCurent, IconCode, StateconfigTypeUcode, CaseType
            FROM XMLTABLE('StateConfigs'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       IsDeleted NUMBER PATH './IsDeleted',
                  --     Config xmltype PATH './Config/text()',
                       Type NVARCHAR2(255) PATH './Type',
                       IsDefault NUMBER PATH './IsDefault',
                       IconCode NVARCHAR2(255) PATH './IconCode',
                       IsCurent NUMBER PATH './IsCurent',
                       Revision NUMBER(10,2) PATH './Revision',
                       Version NVARCHAR2(255) PATH './Version', 
                       StateconfigTypeUcode NVARCHAR2(255) PATH './StateconfigTypeUcode', 
                       CaseType NVARCHAR2(255) PATH './CaseType'
                   
                       )

    ) t1
    ) t2
    ON (lower(t2.Code) = lower(t.col_code))
    WHEN MATCHED THEN
      UPDATE SET col_name = Name,  col_isdeleted = IsDeleted , col_config = dbms_xmlgen.convert(Config,1)  , col_type = Type, col_isdefault = IsDefault,
      col_iconcode = IconCode, col_iscurrent = IsCurent, col_revision = Revision, 
      col_stateconfstateconftype = StateconfigTypeId, 
      col_stateconfigversion = VersionID, col_casesystypestateconfig = CaseTypeId
      WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
    WHEN NOT MATCHED THEN
      INSERT
       (col_code , col_name,  col_isdeleted, col_config, col_type, col_isdefault,
       col_iconcode, col_iscurrent, col_revision, col_stateconfstateconftype, 
       col_stateconfigversion, col_casesystypestateconfig)
      VALUES
       (Code, Name, IsDeleted, dbms_xmlgen.convert(Config,1) , Type, IsDefault,
       IconCode, IsCurent, Revision, StateconfigTypeId,
       VersionID, CaseTypeId);
       
p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_dict_stateconfig with '||SQL%ROWCOUNT||' rows', IsError => 0);
       

EXCEPTION 
		WHEN OTHERS THEN 
   p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
  /***************************************************************************************************/

 -- tbl_dict_casesystype
 /***************************************************************************************************/

BEGIN
  v_xmlresult := v_input.extract('/CaseType/CaseTypeConfig');
  
  IF v_xmlresult.existsnode('/CaseTypeConfig/Code/text()') = 1 THEN
            v_casetypeCode := f_UTIL_extract_value_xml(v_xmlresult, Path => '/CaseTypeConfig/Code/text()');
  END IF;
  
  MERGE INTO tbl_dict_casesystype
  USING
  (SELECT Code, Name, Description, 
    ProcessorCode, CustomDataProcessor, RetrieveCustomDataProcessor,
    UpdateCustomDataProcessor, CustomValidator, CustomValidatorResultProcessor, 
    ShowInPortal,  IsDeleted, UseDataModel, IsDraftModeAvail, CustomCountDataProcessor,
    (SELECT col_id FROM tbl_dict_stateconfig WHERE lower(col_code) = lower(StateConfigCode)) StateConfigCode,
    (SELECT col_id FROM tbl_MDM_Model WHERE col_ucode = MdmModel) MdmModel,
    (SELECT col_id FROM tbl_dict_version WHERE col_code = MSStateConfigCode) MSStateConfigCode,
    (SELECT col_id FROM tbl_DICT_PROCEDUREINCASETYPE WHERE col_code = CaseTypeProcinCaseType) CaseTypeProcinCaseType,
    (SELECT col_id FROM tbl_stp_priority WHERE lower(col_code) = lower(CaseTypePriority)) CaseTypePriority,
     ColorCode , RouteCustomDataProcessor, IconCode
    FROM  XMLTABLE('CaseTypeConfig'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Description NCLOB PATH './Description',
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',
                       CustomDataProcessor NVARCHAR2(255) PATH './CustomDataProcessor',
                       RetrieveCustomDataProcessor NVARCHAR2(255) PATH './RetrieveCustomDataProcessor',
                       UpdateCustomDataProcessor NVARCHAR2(255) PATH './UpdateCustomDataProcessor',
                       CustomValidator NVARCHAR2(255) PATH './CustomValidator',
                       StateConfigCode NVARCHAR2(255) PATH './StateConfigCode',
                       MSStateConfigCode NVARCHAR2(255) PATH './MSStateConfigCode',
                       CustomValidatorResultProcessor NVARCHAR2(255) PATH './CustomValidatorResultProcessor',
                       ShowInPortal NUMBER PATH './ShowInPortal',
                       IsDeleted NUMBER PATH './IsDeleted',
                       UseDataModel NUMBER PATH './UseDataModel',
                       CaseTypeProcinCaseType NVARCHAR2(255) PATH './CaseTypeProcinCaseType',
                       IsDraftModeAvail NUMBER PATH './IsDraftModeAvail',
                       CaseTypePriority NVARCHAR2(255) PATH './CaseTypePriority',
                       ColorCode NVARCHAR2(255) PATH './ColorCode',   
                       RouteCustomDataProcessor NVARCHAR2(255) PATH './RouteCustomDataProcessor',
                       CustomCountDataProcessor NVARCHAR2(255) PATH './CustomCountDataProcessor',
                       IconCode NVARCHAR2(255) PATH './IconCode',
                       MdmModel NVARCHAR2(255) PATH './MdmModel'                                                                                            
                       )
 )
  ON ( lower(col_code)  = lower(Code))
  WHEN MATCHED THEN
   UPDATE  SET  col_name = Name, col_description = Description, col_stateconfigcasesystype = StateConfigCode,
    col_processorcode = ProcessorCode, col_customdataprocessor = CustomDataProcessor,
    col_retcustdataprocessor = RetrieveCustomDataProcessor, col_updatecustdataprocessor = UpdateCustomDataProcessor,
    col_customvalidator = CustomValidator, col_customvalresultprocessor = CustomValidatorResultProcessor, 
    col_showinportal = ShowInPortal, col_isdeleted = IsDeleted, 
    col_customcountdataprocessor = CustomCountDataProcessor,
    col_usedatamodel = UseDataModel, col_dictvercasesystype = MSStateConfigCode,
    --col_casesystypeprocedure, 
    col_casetypeprocincasetype = CaseTypeProcinCaseType,
    col_isdraftmodeavail = IsDraftModeAvail, 
    col_casetypepriority = CaseTypePriority, col_colorcode = ColorCode, 
    col_routecustomdataprocessor =  RouteCustomDataProcessor, col_iconcode = IconCode,
    col_casesystypemodel = MdmModel, COL_DEFAULTPORTALDOCFOLDER = nvl(COL_DEFAULTPORTALDOCFOLDER,0),
    COL_DEFAULTMAILFOLDER = nvl(COL_DEFAULTMAILFOLDER,0), COL_DEFAULTDOCFOLDER = nvl(COL_DEFAULTDOCFOLDER,0)
   WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT') 
  WHEN NOT MATCHED THEN
  INSERT  (col_code, col_name, col_description, col_stateconfigcasesystype,
           col_processorcode, col_customdataprocessor, col_retcustdataprocessor, col_updatecustdataprocessor,
           col_customvalidator, col_customvalresultprocessor, col_showinportal,
           col_isdeleted, col_casetypeprocincasetype, col_isdraftmodeavail,
           col_casetypepriority,col_usedatamodel, col_dictvercasesystype,
           col_colorcode, col_routecustomdataprocessor, col_iconcode,  
           col_casesystypemodel, col_customcountdataprocessor,
           COL_DEFAULTPORTALDOCFOLDER, COL_DEFAULTMAILFOLDER, COL_DEFAULTDOCFOLDER )
  VALUES (Code, Name, Description, StateConfigCode,
           ProcessorCode , CustomDataProcessor, RetrieveCustomDataProcessor,  UpdateCustomDataProcessor,
           CustomValidator, CustomValidatorResultProcessor, ShowInPortal,
           IsDeleted, CaseTypeProcinCaseType, IsDraftModeAvail,
           CaseTypePriority, UseDataModel, MSStateConfigCode,
           ColorCode, RouteCustomDataProcessor, IconCode,
           MdmModel, CustomCountDataProcessor,
           0,0,0);

p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_dict_casesystype with '||SQL%ROWCOUNT||' rows', IsError => 0);


EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
BEGIN 
  SELECT col_id
    INTO v_casetypeid
    FROM tbl_dict_casesystype
   WHERE lower(col_code) = lower(v_casetypeCode);

   
  p_util_update_log ( XmlIdLog => XmlId, Message => 'Loading CASE TYPE '||v_casetypeCode, IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 

BEGIN
  v_xmlresult := v_input.extract('/CaseType/StateConfigs');
	
 MERGE INTO tbl_dict_stateconfig t
    USING (
    SELECT Code,
		(SELECT col_id FROM tbl_dict_casesystype WHERE lower(col_code) = lower(CaseType)) CaseTypeId
            FROM XMLTABLE('StateConfigs'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       CaseType NVARCHAR2(255) PATH './CaseType'
                   
                       )


    ) 
    ON (lower(Code) = lower(col_code))
    WHEN MATCHED THEN
      UPDATE SET col_casesystypestateconfig = CaseTypeId
      WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 

BEGIN

 v_xmlresult := v_input.extract('/CaseType/FomPage');      
 
MERGE INTO TBL_FOM_PAGE
USING(
SELECT Code, (SELECT COL_ID FROM tbl_dict_casesystype where lower(col_code) = lower(CaseType)) CaseType
            FROM XMLTABLE('FomPage'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       CaseType NVARCHAR2(255) PATH './CaseType'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN 
 UPDATE SET col_pagecasesystype = CaseType
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT'); 

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 

/***************************************************************************************************/
--TBL_CASELINKTMPL
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_input.extract('/CaseType/CaseLinkTMPL');

 IF v_xmlresult IS NOT NULL THEN
	 

SELECT y.column_value.getstringval()
    INTO v_count
    FROM xmltable('count(/CaseType/CaseTypeChild)' passing v_input) y ;

FOR i IN 1..v_count LOOP 
-- v_CaseTypeChild := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'CaseLinkTMPL/ChildCaseType/text()');
 --IF v_CaseTypeChild IS NOT NULL AND v_CaseTypeChild != v_casetypeCode THEN 
     v_xmlresult2 := v_input.extract('/CaseType/CaseTypeChild['||i||']/CaseType');
     v_result := f_util_importdcmdataxmlfn(Input =>  (v_xmlresult2.getClobVal()),
                               ParentId => 0,
                               Path => NULL,
                               TaskTemplateLevel =>0,
                               XmlId => XmlId);
 --END IF;	
END LOOP;
 
MERGE INTO TBL_CASELINKTMPL
USING(
SELECT Ucode, Code_, Name_, 
Cancreatechildfromparent, Cancreateparentfromchild,
Canlinkchildtoparent, Canlinkparenttochild,
(SELECT col_id FROM tbl_dict_linkdirection WHERE col_ucode = LinkDirection) LinkDirection,
(SELECT col_id FROM tbl_dict_linktype WHERE upper(col_code) = upper(LinkType)) LinkType,
(SELECT col_id FROM tbl_dict_casesystype WHERE lower(col_code) = lower(ChildCaseType)) ChildCaseType,
(SELECT col_id FROM tbl_dict_casesystype WHERE lower(col_code) = lower(PrntCaseType)) PrntCaseType
             FROM XMLTABLE('CaseLinkTMPL'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code_ NVARCHAR2(255) PATH './Code',
                       Name_ NVARCHAR2(255) PATH './Name',
                       Cancreatechildfromparent NUMBER PATH './Cancreatechildfromparent',
                       Cancreateparentfromchild NUMBER PATH './Cancreateparentfromchild',
                       Canlinkchildtoparent NUMBER PATH './Canlinkchildtoparent',
                       Canlinkparenttochild NUMBER PATH './Canlinkparenttochild',											 
                       LinkDirection NVARCHAR2(255) PATH './LinkDirection',
                       LinkType NVARCHAR2(255) PATH './LinkType',
                       ChildCaseType NVARCHAR2(255) PATH './ChildCaseType',
                       PrntCaseType NVARCHAR2(255) PATH './PrntCaseType'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code = code_ , col_name = name_, 
	col_cancreatechildfromparent =  Cancreatechildfromparent, col_cancreateparentfromchild = Cancreateparentfromchild ,
	col_canlinkchildtoparent = Canlinkchildtoparent, col_canlinkparenttochild = Canlinkparenttochild, 
	col_caselinktmplchildcasetype = ChildCaseType , col_caselinktmpllinktype = LinkType, 
	col_caselinktmplprntcasetype =  PrntCaseType, col_caselinktmpllinkdirection = LinkDirection
    WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code , col_name , 
	      col_cancreatechildfromparent , col_cancreateparentfromchild ,
		  col_canlinkchildtoparent, col_canlinkparenttochild, 
		  col_caselinktmplchildcasetype , col_caselinktmpllinktype , 
		  col_caselinktmplprntcasetype , col_caselinktmpllinkdirection)
  VALUES (Ucode, Code_, Name_, 
	      Cancreatechildfromparent, Cancreateparentfromchild,
		  Canlinkchildtoparent, Canlinkparenttochild,
		  ChildCaseType, LinkType,
		  PrntCaseType, LinkDirection);

p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_CASELINKTMPL with '||SQL%ROWCOUNT||' rows', IsError => 0);

END IF;	

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;

/***************************************************************************************************/
--TBL_DOC_DOCUMENT
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_input.extract('/CaseType/Documents');
 
MERGE INTO TBL_DOC_DOCUMENT
USING(
SELECT Ucode, IsFolder, DocumentURL, Name_, IsDeleted, Descr, IsGlobalResource, 
(SELECT col_id FROM TBL_DOC_DOCUMENT WHERE col_ucode = Parentid) Parentid,
(SELECT col_id FROM tbl_dict_documenttype WHERE lower(col_code) = lower(DocumentType)) DocumentType,
(SELECT col_id FROM tbl_dict_systemtype WHERE col_ucode = SystemType) SystemType,
 length(dbms_xmlgen.convert(CustomData,1)) xmlleng, 
CustomData,
 IsPrimary, VersionIndex, PDFurl, FolderOrder
             FROM XMLTABLE('Documents'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       IsFolder NUMBER PATH './IsFolder',
                       Parentid NVARCHAR2(255) PATH './Parentid',
                       DocumentURL NVARCHAR2(255) PATH './DocumentURL',
                       Name_ NVARCHAR2(255) PATH './Name',
                       IsDeleted NUMBER PATH './IsDeleted',
                       FolderOrder NUMBER PATH './FolderOrder',
                       DocumentType NVARCHAR2(255) PATH './DocumentType',
                       Descr NCLOB PATH './Description',
                       IsGlobalResource NUMBER PATH './IsGlobalResource',
                       CustomData NCLOB PATH './CustomData',
                       VersionIndex NUMBER PATH './VersionIndex',
                       IsPrimary NUMBER PATH './IsPrimary',
                       PDFurl NVARCHAR2(255) PATH './PDFurl',
                       SystemType NVARCHAR2(255) PATH './SystemType'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_isfolder  = IsFolder, col_pdfurl = PDFurl, 
         col_parentid  = Parentid, col_url = DocumentURL, col_name = Name_,
         col_isdeleted = IsDeleted, col_folderorder = FolderOrder, 
         col_doctype = DocumentType, col_description = Descr, 
         col_isglobalresource = IsGlobalResource, 
         COL_CUSTOMDATA = decode (xmlleng,0 ,NULL,  xmltype(CustomData)),
         col_versionindex = VersionIndex, col_isprimary = IsPrimary,
         col_doc_documentsystemtype = SystemType
    WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_isfolder, col_parentid, col_url, col_name, col_isdeleted, col_folderorder, 
         col_doctype, col_description, col_isglobalresource, col_customdata, col_versionindex, 
         col_isprimary, col_pdfurl,  col_doc_documentsystemtype )
  VALUES (Ucode, IsFolder, Parentid, DocumentURL, Name_ , IsDeleted, FolderOrder, 
         DocumentType, Descr, IsGlobalResource, decode (xmlleng,0 ,NULL,  xmltype(CustomData)), VersionIndex, 
         IsPrimary, PDFurl, SystemType);
         
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DOC_DOCUMENT with '||SQL%ROWCOUNT||' rows', IsError => 0);

MERGE INTO TBL_DOC_DOCUMENT
USING(
SELECT Ucode,
(SELECT col_id FROM TBL_DOC_DOCUMENT WHERE col_ucode = Parentid) Parentid
             FROM XMLTABLE('Documents'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
											 Parentid NVARCHAR2(255) PATH './Parentid'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_parentid  = nvl(Parentid,-1)
    WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
/***************************************************************************************************/
--TBL_DOC_DOCCASETYPE
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_input.extract('/CaseType/DocCaseType');
 
MERGE INTO TBL_DOC_DOCCASETYPE
USING(
SELECT Ucode,
(SELECT col_id FROM tbl_dict_casesystype WHERE lower(col_code) = lower(CaseType)) CaseType,
(SELECT col_id FROM tbl_doc_document WHERE col_ucode = Document_) Document_
            FROM XMLTABLE('DocCaseType'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       CaseType NVARCHAR2(255) PATH './CaseType',
                       Document_ NVARCHAR2(255) PATH './Document'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_doccsetypetype = CaseType, col_doccsetypedoc = Document_
    WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_doccsetypetype, col_doccsetypedoc )
  VALUES (Ucode, CaseType, Document_);

p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_DOC_DOCCASETYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;

/******************************************************************************/

--TBL_MDM_MODEL
/******************************************************************************/
 BEGIN 
 v_xmlresult := v_input.extract('/CaseType/MdmModel');
 
   MERGE INTO TBL_MDM_MODEL
   USING (
   SELECT Code, Description, Config, IsDeleted, NAME, Ucode, UsedFor, 
      (SELECT col_id FROM tbl_fom_object WHERE lower(col_code) = lower(FomObjectCode) ) FomObjectCode
            FROM XMLTABLE('MdmModel'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Description NCLOB PATH './Description',
                       Config NCLOB PATH './Config',
                       IsDeleted NUMBER PATH './IsDeleted',
                       NAME NVARCHAR2(255) PATH './Name',
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       UsedFor NVARCHAR2(255) PATH './UsedFor',
                       FomObjectCode NVARCHAR2(255) PATH './FomObjectCode'
                       )
)
   ON (col_ucode = ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_code  = Code, col_config   = Config, col_description  = Description,
     col_isdeleted = IsDeleted, col_name = NAME, col_usedfor = UsedFor,
     col_mdm_modelfom_object = FomObjectCode
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
     WHEN NOT MATCHED THEN
       INSERT (col_code,col_config, col_description, col_isdeleted, col_name, col_usedfor,
        col_mdm_modelfom_object, col_ucode )
       VALUES (Code, Config, Description, IsDeleted, NAME, UsedFor,
        FomObjectCode, ucode);
 

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_MDM_MODEL with '||SQL%ROWCOUNT||' rows', IsError => 0);

BEGIN
SELECT col_id 
 INTO
v_mdmModelId 
FROM TBL_MDM_MODEL 
WHERE col_ucode = f_UTIL_extract_value_xml(Input => v_input, Path => '/CaseType/MdmModel/Ucode/text()');

EXCEPTION 
  WHEN NO_DATA_FOUND THEN 
  v_mdmModelId := 0;
END;
v_xmlresult := v_input.extract('/CaseType/CaseTypeConfig');
  MERGE INTO tbl_dict_casesystype
  USING
  (SELECT Code,
		(SELECT col_id FROM tbl_MDM_Model WHERE col_ucode = MdmModel) MdmModel
    FROM  XMLTABLE('CaseTypeConfig'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
					   MdmModel NVARCHAR2(255) PATH './MdmModel'
                       )
 )
  ON ( lower(col_code)  = lower(Code))
  WHEN MATCHED THEN
   UPDATE  SET  
		 col_casesystypemodel = MdmModel
   WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')         ;

v_xmlresult := v_input.extract('/CaseType/DomModel');
  
MERGE INTO tbl_DOM_Model
 USING(
SELECT Ucode,
(SELECT col_id FROM tbl_mdm_model WHERE col_ucode = MdmModelUcode) MdmModelUcode 
            FROM XMLTABLE('/DomModel'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       MdmModelUcode NVARCHAR2(255) PATH './MdmModelUcode'  
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_dom_modelmdm_model = MdmModelUcode 
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
;

     
p_util_update_log ( XmlIdLog => XmlId, Message => '       Update TBL_SOM_CONFIG FK to tbl_som_model in '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 

  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
/******************************************************************************/

--TBL_MDM_MODELVERSION
/******************************************************************************/
 BEGIN 
 v_xmlresult := v_input.extract('/CaseType/MdmModelVersion');
	 FOR rec IN (
   SELECT Code, Description, Config, IsDeleted, NAME, Ucode, UsedFor, ErrorMessage, Order_, 
   (SELECT col_id FROM tbl_mdm_model WHERE col_ucode = MdmModelUcode ) MdmModelUcode
            FROM XMLTABLE('MdmModelVersion'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Description NCLOB PATH './Description',
                       Config NCLOB PATH './Config',
                       IsDeleted NUMBER PATH './IsDeleted',
                       NAME NVARCHAR2(255) PATH './Name',
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       UsedFor NVARCHAR2(255) PATH './UsedFor',
                       ErrorMessage NCLOB PATH './ErrorMessage',
                       MdmModelUcode NVARCHAR2(255) PATH './MdmModelUcode',
                       Order_ NUMBER PATH './Order'
                       )
Order by Order_                       
) LOOP

SELECT COUNT(*) INTO v_cnt FROM tbl_MDM_MODELVERSION WHERE col_ucode = rec.ucode; 

IF v_cnt = 0 THEN 
       INSERT  INTO tbl_MDM_MODELVERSION 
        (col_code,col_config, col_description, col_isdeleted, col_name, col_usedfor,
        col_errormessage, col_mdm_modelversionmdm_model, col_ucode )
       VALUES (rec.Code, rec.Config, rec.Description, rec.IsDeleted, rec.NAME, rec.UsedFor,
        rec.ErrorMessage , rec.MdmModelUcode, rec.ucode);
p_util_update_log ( XmlIdLog => XmlId, Message => '       Inserted into TBL_MDM_MODELVERSION UCODE '||rec.ucode||', order - '||rec.Order_, IsError => 0);   
ELSE 
     UPDATE tbl_MDM_MODELVERSION 
     SET  col_code  = rec.Code, col_config = rec.Config, col_description  = rec.Description,
     col_isdeleted = rec.IsDeleted, col_name = rec.NAME, col_usedfor = rec.UsedFor,
     col_errormessage  = rec.ErrorMessage, col_mdm_modelversionmdm_model  = rec.MdmModelUcode
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
     AND col_ucode = rec.ucode;
p_util_update_log ( XmlIdLog => XmlId, Message => '       Updated TBL_MDM_MODELVERSION UCODE '||rec.ucode||', order - '||rec.Order_, IsError => 0);        
END IF;	


END LOOP;
EXCEPTION 
  WHEN OTHERS THEN 

  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
 
/******************************************************************************/

--TBL_SOM_MODEL
/******************************************************************************/
 BEGIN 
 v_xmlresult := v_input.extract('/CaseType/SomModel');
/*
DELETE FROM TBL_SOM_MODEL 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('SomModel'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = Ucode);

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_SOM_MODEL '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
 */
   MERGE INTO TBL_SOM_MODEL
   USING (
   SELECT Code, Description, Config, IsDeleted, NAME, Ucode, UsedFor, 
   (SELECT col_id FROM tbl_fom_object WHERE lower(col_code) = lower(FomObjectCode)) FomObjectCode,
   (SELECT col_id FROM tbl_mdm_model WHERE col_ucode = MdmModel ) MdmModel
            FROM XMLTABLE('SomModel'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Description NCLOB PATH './Description',
                       Config NCLOB PATH './Config',
                       IsDeleted NUMBER PATH './IsDeleted',
                       NAME NVARCHAR2(255) PATH './Name',
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       UsedFor NVARCHAR2(255) PATH './UsedFor',
                       FomObjectCode NVARCHAR2(255) PATH './FomObjectCode',
                       MdmModel NVARCHAR2(255) PATH './MdmModel'
                       )
)
   ON (col_ucode = ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_code  = Code, col_config   = Config, col_description  = Description,
     col_isdeleted = IsDeleted, col_name = NAME, col_usedfor = UsedFor,
     col_som_modelfom_object  = FomObjectCode, col_som_modelmdm_model  = MdmModel
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
     WHEN NOT MATCHED THEN
       INSERT (col_code,col_config, col_description, col_isdeleted, col_name, col_usedfor,
        col_som_modelfom_object, col_som_modelmdm_model, col_ucode )
       VALUES (Code,Config, Description, IsDeleted, NAME, UsedFor,
        FomObjectCode , MdmModel, ucode);
       
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_SOM_MODEL with '||SQL%ROWCOUNT||' rows', IsError => 0);

v_xmlresult2 := v_input.extract('/CaseType/SomConfig');
MERGE INTO TBL_SOM_CONFIG
   USING (
   SELECT Code,
          (SELECT col_id FROM tbl_som_model WHERE col_ucode = SomModelUcode) SomModelUcode
            FROM XMLTABLE('SomConfig'
              PASSING v_xmlresult2
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       SomModelUcode NVARCHAR2(255) PATH './SomModelUcode'
                       )
          )
   ON (lower(col_code) = lower(Code))
   WHEN MATCHED THEN
     UPDATE  SET  col_som_configsom_model = SomModelUcode
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');


EXCEPTION 
  WHEN OTHERS THEN 

  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
/******************************************************************************/

--TBL_SOM_OBJECT
/******************************************************************************/
 BEGIN 
 v_xmlresult := v_input.extract('/CaseType/SomObject');

   MERGE INTO TBL_SOM_OBJECT
   USING (
   SELECT Code, Description, IsRoot, IsSharable, NAME, Ucode, SomObjectType, 
   (SELECT col_id FROM tbl_fom_object WHERE lower(col_code) = lower(FomObjectCode)) FomObjectCode,
   (SELECT col_id FROM tbl_som_model WHERE col_ucode = SomModelUcode ) SomModelUcode
            FROM XMLTABLE('SomObject'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Description NCLOB PATH './Description',
                       IsRoot NUMBER PATH './IsRoot',
                       IsSharable NUMBER PATH './IsSharable',
                       NAME NVARCHAR2(255) PATH './Name',
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       SomObjectType NVARCHAR2(255) PATH './SomObjectType',
                       FomObjectCode NVARCHAR2(255) PATH './FomObjectCode',
                       SomModelUcode NVARCHAR2(255) PATH './SomModelUcode'
                       )
)
   ON (col_ucode = ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_code  = Code, col_isroot = IsRoot, col_description  = Description,
     col_issharable  = IsSharable, col_name = NAME, col_type  = SomObjectType,
     col_som_objectfom_object  = FomObjectCode, col_som_objectsom_model = SomModelUcode
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
     WHEN NOT MATCHED THEN
       INSERT (col_code,col_isroot , col_description, col_issharable , col_name, col_type ,
        col_som_objectfom_object , col_som_objectsom_model , col_ucode )
       VALUES (Code, IsRoot , Description, IsSharable, NAME, SomObjectType,
        FomObjectCode , SomModelUcode, ucode);
       
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_SOM_OBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 

  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;

/******************************************************************************/

--TBL_SOM_ATTRIBUTE
/******************************************************************************/
 BEGIN 
 v_xmlresult := v_input.extract('/CaseType/SomAttribute');

   MERGE INTO TBL_SOM_ATTRIBUTE
   USING (
   SELECT Code, Description, DOrder, IsInsertable, IsRetrievableInDetail,
   IsretRievableInList, IsSearchable, IsUpdatable, IsSystem,
    NAME, Ucode, Config, 
   (SELECT col_id FROM tbl_fom_attribute WHERE col_ucode = FomAttributeUcode) FomAttributeUcode,
   (SELECT col_id FROM tbl_som_object WHERE col_ucode = SomObjectUcode ) SomObjectUcode,
   (SELECT col_id FROM tbl_dom_renderobject WHERE col_ucode = DomRenderObjectUcode ) DomRenderObjectUcode,
   (SELECT col_id FROM tbl_dom_referenceobject WHERE col_ucode = DomReferenceObjectUcode ) DomReferenceObjectUcode,
   (SELECT col_id FROM tbl_ac_accessobject WHERE lower(col_code) = lower(AccessObjectCode) ) AccessObjectCode
            FROM XMLTABLE('SomAttribute'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Description NCLOB PATH './Description',
                       DOrder NUMBER PATH './DOrder',
                       IsInsertable NUMBER PATH './IsInsertable',
                       IsRetrievableInDetail NUMBER PATH './IsRetrievableInDetail',
                       IsretRievableInList NUMBER PATH './IsretRievableInList',
                       IsSearchable NUMBER PATH './IsSearchable',
                       IsUpdatable NUMBER PATH './IsUpdatable',
                       IsSystem NUMBER PATH './IsSystem',
                       Config NCLOB PATH './Config',
                       NAME NVARCHAR2(255) PATH './Name',
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       FomAttributeUcode NVARCHAR2(255) PATH './FomAttributeUcode',
                       SomObjectUcode NVARCHAR2(255) PATH './SomObjectUcode',
                       DomRenderObjectUcode NVARCHAR2(255) PATH './DomRenderObjectUcode',
                       DomReferenceObjectUcode NVARCHAR2(255) PATH './DomReferenceObjectUcode',
                       AccessObjectCode NVARCHAR2(255) PATH './AccessObjectCode'
                       )
)
   ON (col_ucode = ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_code  = Code, col_dorder  = DOrder, col_description  = Description,
     col_isinsertable   = IsInsertable, col_isretrievableindetail = IsRetrievableInDetail,
     col_isretrievableinlist = IsretRievableInList, col_issearchable = IsSearchable, col_issystem = IsSystem,
     col_config = Config, col_name = NAME,  col_isupdatable = IsUpdatable,
     col_som_attrfom_attr  = FomAttributeUcode, col_som_attributesom_object = SomObjectUcode,
     col_som_attributerenderobject  = DomRenderObjectUcode, col_som_attributerefobject = DomReferenceObjectUcode,
     col_som_attributeaccessobject = AccessObjectCode
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
     WHEN NOT MATCHED THEN
       INSERT (col_code, col_dorder, col_description, col_isinsertable, col_isretrievableindetail,  
       col_isretrievableinlist, col_issearchable, col_issystem, 
       col_config, col_name, col_isupdatable, 
        col_som_attrfom_attr , col_som_attributesom_object , col_ucode,
       col_som_attributerenderobject, col_som_attributerefobject, col_som_attributeaccessobject )
       VALUES (Code, DOrder , Description, IsInsertable, IsRetrievableInDetail,
       IsretRievableInList, IsSearchable, IsSystem,
       Config,  NAME, IsUpdatable,
       FomAttributeUcode , SomObjectUcode, ucode,
       DomRenderObjectUcode, DomReferenceObjectUcode, AccessObjectCode);
       
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_SOM_ATTRIBUTE with '||SQL%ROWCOUNT||' rows', IsError => 0);

 v_xmlresult := v_input.extract('/CaseType/SomResultAttr');
  MERGE INTO TBL_SOM_RESULTATTR
   USING (
   SELECT Ucode,
   (SELECT col_id FROM tbl_som_attribute WHERE col_ucode = SomAttribute) SomAttribute
            FROM XMLTABLE('SomResultAttr'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       SomAttribute NVARCHAR2(255) PATH './SomAttribute'
                       )
)
   ON (col_ucode  = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_som_resultattrsom_attr = SomAttribute
            WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');
            
 v_xmlresult := v_input.extract('/CaseType/SomSearchAttr');
 MERGE INTO TBL_SOM_SEARCHATTR
   USING (
   SELECT Ucode,
      (SELECT col_id FROM tbl_som_attribute WHERE col_ucode = SomAttribute) SomAttribute
            FROM XMLTABLE('SomSearchAttr'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       SomAttribute NVARCHAR2(255) PATH './SomAttribute'
                       )
)
   ON (col_ucode  = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_som_searchattrsom_attr = SomAttribute;            

EXCEPTION 
  WHEN OTHERS THEN 

  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
/******************************************************************************/

--TBL_DOM_MODELJOURNAL
/******************************************************************************/
 BEGIN 
 v_xmlresult := v_input.extract('/CaseType/DomModelJournal'); 

FOR rec IN (SELECT Ucode, ParentElementId, ElementId, ResultMessage, ParamXml,Order_, 
   Type, SubType, AppBaseCode, DBName,
   (SELECT col_id FROM tbl_mdm_modelversion WHERE col_ucode = MdmModelversion ) MdmModelversion,
   ErrorMessage, ErrorCode 
            FROM XMLTABLE('DomModelJournal'
              PASSING v_xmlresult
              COLUMNS
                       Ucode nvarchar2(255) PATH './Ucode',
                       ParentElementId NUMBER PATH './ParentElementId',
                       ElementId NUMBER PATH './ElementId',
                       ResultMessage NCLOB PATH './ResultMessage',
                       ParamXml NCLOB PATH './ParamXml',
                       TYPE VARCHAR2(255) PATH './Type',
                       SubType VARCHAR2(255) PATH './SubType',
                       AppBaseCode VARCHAR2(255) PATH './AppBaseCode',
                       MdmModelversion VARCHAR2(255) PATH './MdmModelversion',
                       DBName VARCHAR2(255) PATH './DBName', 
                       ErrorMessage NCLOB PATH './ErrorMessage',
                       ErrorCode NUMBER PATH './ErrorCode',
                       Order_ NUMBER PATH './Order'
                       )
Order by Order_                       
) LOOP
  SELECT COUNT(*) INTO v_cnt FROM TBL_DOM_MODELJOURNAL WHERE col_ucode = rec.ucode;
IF v_cnt = 0 THEN 
   INSERT INTO TBL_DOM_MODELJOURNAL(col_ucode, col_parentelementid, col_elementid, col_resultmessage, col_paramxml,
     col_type, col_subtype, col_appbasecode, col_mdm_modverdom_modjrnl, 
     col_errormessage, col_errorcode, col_dbname  ) 
    VALUES (rec.Ucode, rec.ParentElementId, rec.ElementId, rec.ResultMessage, rec.ParamXml,
     rec.Type, rec.SubType, rec.AppBaseCode, rec.MdmModelversion,
     rec.ErrorMessage, rec.ErrorCode, rec.DBName); 	
p_util_update_log ( XmlIdLog => XmlId, Message => '       Inserted into TBL_DOM_MODELJOURNAL UCODE '||rec.ucode||', order - '||rec.Order_, IsError => 0);        
ELSE 
     UPDATE TBL_DOM_MODELJOURNAL
     SET col_parentelementid = rec.ParentElementId, col_elementid = rec.ElementId, 
       col_resultmessage = rec.ResultMessage, col_paramxml = rec.ParamXml,
       col_type = rec.Type, col_subtype = rec.SubType, col_appbasecode = rec.AppBaseCode,
       col_mdm_modverdom_modjrnl = rec.MdmModelversion, col_errormessage = rec.ErrorMessage ,
       col_errorcode = rec.ErrorCode, col_dbname = rec.DBName
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
      AND col_ucode = rec.ucode;	
p_util_update_log ( XmlIdLog => XmlId, Message => '       Updated TBL_DOM_MODELJOURNAL UCODE '||rec.ucode||', order - '||rec.Order_, IsError => 0);              
END IF;	
END LOOP;

EXCEPTION 
  WHEN OTHERS THEN 

  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;

/******************************************************************************/

--TBL_SOM_RELATIONSHIP
/******************************************************************************/
 BEGIN 
 v_xmlresult := v_input.extract('/CaseType/SomRelationship');
/*
DELETE FROM
TBL_SOM_RELATIONSHIP
WHERE (NOT EXISTS
(SELECT 1 FROM XMLTABLE('/SomRelationship'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode')
 WHERE  Ucode = col_ucode
)
OR col_ucode IS NULL)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

*/
   MERGE INTO TBL_SOM_RELATIONSHIP
   USING (
SELECT * FROM (   
   SELECT Code, NAME, Ucode, 
   (SELECT col_id FROM tbl_som_object WHERE col_ucode = SomObjectCodeCh ) SomObjectCodeCh,
   (SELECT col_id FROM tbl_som_object WHERE col_ucode = SomObjectCodePr ) SomObjectCodePr,
   (SELECT col_id FROM tbl_fom_relationship WHERE col_code = FomRelationship) FomRelationship
            FROM XMLTABLE('SomRelationship'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       NAME NVARCHAR2(255) PATH './Name',
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       SomObjectCodeCh NVARCHAR2(255) PATH './SomObjectCodeCh',
                       SomObjectCodePr NVARCHAR2(255) PATH './SomObjectCodePr',
                       FomRelationship NVARCHAR2(255) PATH './FomRelationship'
                       )
)
WHERE SomObjectCodeCh IS NOT NULL                       
)
   ON (col_ucode = ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_code  = Code, col_name = NAME, 
     col_childsom_relsom_object = SomObjectCodeCh, 
     col_parentsom_relsom_object = SomObjectCodePr, 
     col_som_relfom_rel = FomRelationship 
   WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')  
     WHEN NOT MATCHED THEN
       INSERT (col_code, col_name,  
       col_childsom_relsom_object, col_parentsom_relsom_object, col_som_relfom_rel,
        col_ucode )
       VALUES (Code, NAME ,
       SomObjectCodeCh , SomObjectCodePr, FomRelationship , ucode);
       
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_SOM_RELATIONSHIP with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 

  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
   /**********************************************************************************/

   --Extracting tbl_dict_casestate
   /**********************************************************************************/


BEGIN
  
--Special for Case case states
v_xmlresult := v_input.extract('/CaseType/CaseState');
   MERGE INTO tbl_dict_casestate
   USING (
   SELECT Code, Activity, Name, DefaultOrder, Description, IsAssign, 
          IsDefaultonCreate,IsDefaultonCreate2, IconCode,
          IsDeleted, IsFinish, IsFix, IsHidden, IsResolve, IsStart,  Ucode,Theme, 
          (SELECT col_id FROM tbl_dict_stateconfig WHERE lower(col_code) = lower(Config) ) Config
          FROM XMLTABLE('CaseState'
              PASSING v_xmlresult
              COLUMNS
                       Code         NVARCHAR2(255) PATH './Code',
                       Activity     NVARCHAR2(255) PATH './Activity',
                       Name         NVARCHAR2(255) PATH './Name',
                       DefaultOrder NUMBER PATH './DefaultOrder',
                       Description  NCLOB PATH './Description',
                       IsAssign     NUMBER PATH './IsAssign',
                       IsDefaultonCreate NUMBER PATH './IsDefaultonCreate',
                       IsDefaultonCreate2 NUMBER PATH './IsDefaultonCreate2',
                       IsDeleted    NUMBER PATH './IsDeleted',
                       IsFinish     NUMBER PATH './IsFinish',
                       IsFix        NUMBER PATH './IsFix',
                       IsHidden     NUMBER PATH './IsHidden',
                       IsResolve    NUMBER PATH './IsResolve',
                       IsStart      NUMBER PATH './IsStart',
                       Ucode        NVARCHAR2(255) PATH './Ucode',
                       Config       NVARCHAR2(255) PATH './Config',
                       Theme        NVARCHAR2(255) PATH './Theme',
                       IconCode     NVARCHAR2(255) PATH './IconCode'
                       )
   WHERE  Config IS NOT NULL
   )
   ON (col_ucode = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET col_activity = Activity, col_description = Description,  col_isdeleted = IsDeleted,
     col_name = Name, col_defaultorder = DefaultOrder,
     col_isassign = IsAssign, col_isdefaultoncreate = IsDefaultonCreate, col_isdefaultoncreate2 = IsDefaultonCreate2, 
     col_isfinish = IsFinish, col_isfix = IsFix, col_theme = Theme, 
     col_ishidden = IsHidden, col_isresolve = IsResolve, col_isstart = IsStart,
     col_code = Code, col_stateconfigcasestate = Config, col_iconcode = IconCode
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
   WHEN NOT MATCHED THEN
     INSERT
     (col_activity,  col_code, col_description, col_isdeleted, col_name,
      col_isassign, col_isdefaultoncreate,col_isdefaultoncreate2, col_isfinish, col_isfix, col_ishidden, col_isresolve, col_isstart ,  
      col_ucode , col_defaultorder, col_stateconfigcasestate, col_theme, col_iconcode )
     VALUES
     (Activity, Code,  Description, IsDeleted, Name,
     IsAssign, IsDefaultonCreate,IsDefaultonCreate2, IsFinish, IsFix,  IsHidden, IsResolve, IsStart, 
     Ucode, DefaultOrder, Config, Theme, IconCode );

p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_dict_casestate with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
   p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 

/**********************************************************************************/

--Extracting tbl_CaseSysTypePriority
/**********************************************************************************/

 BEGIN
  
 v_xmlresult := v_input.extract('/CaseType/CaseSysTypePriority');
  
MERGE INTO tbl_CaseSysTypePriority
USING(
SELECT 
(SELECT col_id FROM tbl_stp_priority WHERE lower(col_code) = lower(CodePriority) ) CodePriority,
(SELECT col_id FROM tbl_dict_casesystype WHERE lower(col_code) = lower(CaseType)) CaseType 
            FROM XMLTABLE('CaseSysTypePriority'
              PASSING v_xmlresult
              COLUMNS
                       CodePriority nvarchar2(255) PATH './CodePriority',
                       CaseType nvarchar2(255) PATH './CaseType'
                       )
               )
ON (col_casetypeprioritypriority  = CodePriority AND col_casetypeprioritycasetype = CaseType )
WHEN NOT MATCHED THEN
  INSERT (col_casetypeprioritycasetype, col_casetypeprioritypriority  )
  VALUES (CaseType,  CodePriority);

p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_CaseSysTypePriority with '||SQL%ROWCOUNT||' rows', IsError => 0);     

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/***************************************************************************************************/
 -- TBL_DICT_STATE
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_input.extract('/CaseType/DictState'); 

 MERGE INTO TBL_DICT_STATE
 USING( SELECT  Code,  Name, Activity, Description, DefaultOrder, IconCode ,IsDeleted, IsHidden, Ucode,
 (SELECT col_id FROM tbl_dict_stateconfig WHERE lower(col_code) = lower(StateConfig)) StateConfig,
 (SELECT col_id FROM tbl_dict_casestate WHERE col_ucode = CaseStateUcode) CaseStateUcode,
 ID2, CommonCode
            FROM XMLTABLE('DictState'
              PASSING v_xmlresult
              COLUMNS
                       Name NVARCHAR2(255) PATH './Name',
                       Code  NVARCHAR2(255) PATH './Code',
                       Activity NVARCHAR2(255) PATH './Activity',
                       Description NCLOB PATH './Description',
                       DefaultOrder NUMBER PATH './DefaultOrder',
                       IconCode NVARCHAR2(255) PATH './IconCode',
                       IsDeleted NUMBER PATH './IsDeleted',
                       IsHidden NUMBER PATH './IsHidden',
                       Ucode  NVARCHAR2(255) PATH './Ucode',
                       StateConfig  NVARCHAR2(255) PATH './StateConfig',
                       CaseStateUcode  NVARCHAR2(255) PATH './CaseStateUcode',
                       ID2 NUMBER PATH './ID2', -- Just number
                       CommonCode NVARCHAR2(255) PATH './CommonCode' 
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code = Code, col_activity = Activity, col_description = Description, col_defaultorder = DefaultOrder, col_name = Name,
	   col_iconcode = IconCode, col_isdeleted = IsDeleted, col_ishidden = IsHidden, col_statestateconfig = StateConfig, 
     col_statecasestate = CaseStateUcode, col_id2 = ID2, col_commoncode =  CommonCode 
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_activity, col_description, col_defaultorder, col_name,
	   col_iconcode, col_isdeleted, col_ishidden, col_ucode, col_statestateconfig,
      col_statecasestate, col_id2, col_commoncode)
  VALUES (Code, Activity,  Description, DefaultOrder, Name,
	IconCode, IsDeleted, IsHidden, Ucode,  StateConfig,
  CaseStateUcode, ID2, CommonCode); 
       
  p_util_update_log (XmlIdLog => XmlId, Message => '       Merged TBL_DICT_STATE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log (XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- TBL_DICT_TRANSITION
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_input.extract('/CaseType/DictTransition'); 


 MERGE INTO TBL_DICT_TRANSITION
 USING( SELECT  Code,  Name, Description, IconCode ,IsNextDefault, IsPrevDefault, Ucode,
 ManualOnly,  Transition, ColorCode, Sorder, CommonCode, NotShowInUI,
 (SELECT col_id FROM tbl_dict_state WHERE col_ucode = SourceTransitions) SourceTransitions,
 (SELECT col_id FROM tbl_dict_state WHERE col_ucode = TargetTransitions) TargetTransitions
            FROM XMLTABLE('DictTransition'
              PASSING v_xmlresult
              COLUMNS
             Name NVARCHAR2(255) PATH './Name',
             Code  NVARCHAR2(255) PATH './Code',
             Description NCLOB PATH './Description',
             IconCode NVARCHAR2(255) PATH './IconCode',
             IsNextDefault NUMBER PATH './IsNextDefault',
             IsPrevDefault NUMBER PATH './IsPrevDefault',
             Ucode  NVARCHAR2(255) PATH './Ucode',
             ManualOnly  NUMBER PATH './ManualOnly',
             Transition  NVARCHAR2(255) PATH './Transition',
             SourceTransitions  NVARCHAR2(255) PATH './SourceTransitions',
             TargetTransitions  NVARCHAR2(255) PATH './TargetTransitions',
             ColorCode NVARCHAR2(255) PATH './ColorCode',
             Sorder NUMBER PATH './Sorder',
             CommonCode NVARCHAR2(255) PATH  './CommonCode',
             NotShowInUI NUMBER PATH './NotShowInUI'
                       )
               )
ON (lower(col_code) = lower(code) AND col_sourcetransitionstate =  SourceTransitions 
AND col_targettransitionstate = TargetTransitions
AND lower(col_ucode) = lower(Ucode))
WHEN MATCHED THEN
  UPDATE SET /*col_code = Code,*/ col_name  = Name, col_description = Description, 
     col_iconcode = IconCode, col_isnextdefault  = IsNextDefault, col_isprevdefault  = IsPrevDefault, 
     col_manualonly  = ManualOnly, col_transition = Transition, 
     /*col_sourcetransitionstate = SourceTransitions, col_targettransitionstate = TargetTransitions,*/
     col_colorcode = ColorCode,  col_sorder = Sorder, col_commoncode = CommonCode,
     col_notshowinui = NotShowInUI
         WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code , col_name , col_description, 
     col_iconcode, col_isnextdefault, col_isprevdefault, 
     col_manualonly, col_transition, 
     col_sourcetransitionstate, col_targettransitionstate,
     col_ucode, col_colorcode ,  col_sorder, col_commoncode,
     col_notshowinui)
  VALUES (Code, Name, Description, 
     IconCode, IsNextDefault, IsPrevDefault, 
     ManualOnly, Transition, 
     SourceTransitions, TargetTransitions, 
     Ucode, ColorCode, Sorder, CommonCode,
     NotShowInUI); 
       
  p_util_update_log (XmlIdLog => XmlId, Message => 'Merged TBL_DICT_TRANSITION with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log (XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

   /**********************************************************************************/

   --Extracting tbl_dict_taskstate
   /**********************************************************************************/


BEGIN
  

v_xmlresult := v_input.extract('/CaseType/TaskState');
-- Task states for Case
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

p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_dict_taskstate with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
   /**********************************************************************************/

   --Extracting tbl_DICT_TASKSTATESETUP
   /**********************************************************************************/

BEGIN
  v_xmlresult := v_input.extract('/CaseType/TaskStateSetup');
  
   MERGE INTO tbl_DICT_TASKSTATESETUP
   USING (
SELECT 
  (SELECT col_id FROM tbl_dict_taskstate WHERE col_ucode = tss.TaskState) taskstateId ,
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
 )
   ON (lower(col_code) = lower(Code) AND nvl(col_taskstatesetuptaskstate,-1) = nvl(taskstateId,-1))
   WHEN MATCHED THEN
     UPDATE  SET col_forcednull = FofsedNull, col_forcedoverwrite = ForcedOverWrite, col_name =  Name,
     col_notnulloverwrite = NotNullOverWrite,  col_nulloverwrite = NullOverWrite, col_ucode = Ucode
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
   WHEN NOT MATCHED THEN
     INSERT
     (col_code, col_forcednull, col_forcedoverwrite, col_name, col_notnulloverwrite, col_taskstatesetuptaskstate, col_nulloverwrite, col_Ucode   )
     VALUES
     (Code, FofsedNull, ForcedOverWrite, Name, NotNullOverWrite, taskstateId, NullOverWrite, Ucode );
     
p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_DICT_TASKSTATESETUP with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
   p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
   /**********************************************************************************/

   --Extracting tbl_dict_CASESTATESETUP
   /**********************************************************************************/

BEGIN
  v_xmlresult := v_input.extract('/CaseType/CaseStateSetup');

  
   MERGE INTO tbl_dict_CASESTATESETUP
   USING (
SELECT 
  (SELECT col_id FROM tbl_dict_casestate WHERE col_ucode = tss.CaseState) casestateId ,
   tss.*
FROM
(     SELECT Code, FofsedNull, Name, ForcedOverWrite, NotNullOverWrite, NullOverWrite, Ucode, CaseState
          FROM XMLTABLE('CaseStateSetup'
              PASSING v_xmlresult
              COLUMNS
                       Code         NVARCHAR2(255) PATH './Code',
                       FofsedNull   NUMBER PATH './FofsedNull',
                       Name         NVARCHAR2(255) PATH './Name',
                       ForcedOverWrite    NUMBER PATH './ForcedOverWrite',
                       NotNullOverWrite     NUMBER PATH './NotNullOverWrite',
                       NullOverWrite NUMBER PATH './NullOverWrite',
                       Ucode         NVARCHAR2(255) PATH './Ucode',
                       CaseState     NVARCHAR2(255) PATH './CaseState'
                       )
) tss
)  
ON (lower(col_code) = lower(Code) AND col_casestatesetupcasestate  = casestateId)
   WHEN MATCHED THEN
     UPDATE  SET col_forcednull = FofsedNull, col_forcedoverwrite = ForcedOverWrite, col_name =  Name,
     col_notnulloverwrite = NotNullOverWrite,  col_nulloverwrite = NullOverWrite, col_ucode = Ucode 
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
   WHEN NOT MATCHED THEN
     INSERT
     (col_code, col_forcednull, col_forcedoverwrite, col_name, col_notnulloverwrite, col_casestatesetupcasestate , col_nulloverwrite, col_Ucode   )
     VALUES
     (Code, FofsedNull, ForcedOverWrite, Name, NotNullOverWrite, casestateId, NullOverWrite, Ucode );

p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_dict_CASESTATESETUP with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
  /**********************************************************************************/

  --tbl_dict_casetransition
  /**********************************************************************************/

 BEGIN
   v_xmlresult := v_input.extract('/CaseType/CaseTransition');

MERGE INTO  tbl_dict_casetransition
USING (
       SELECT tss.*,
   (SELECT col_id FROM tbl_dict_casestate WHERE col_ucode = tss.CodeSource) CodeSourceId,
   (SELECT col_id FROM tbl_dict_casestate WHERE col_ucode = tss.CodeTarget) CodeTargetId
       FROM
      (SELECT Code, Ucode, Transition, Name, Manualonly, Description, IconCode, IsNextDefault, IsPrevDefault,
         CodeSource,
         CodeTarget
         FROM XMLTABLE('CaseTransition'
         PASSING v_xmlresult
         COLUMNS
                             Code          NVARCHAR2(255) PATH './Code',
                             Ucode         NVARCHAR2(255) PATH './Ucode',
                             Transition    NVARCHAR2(255) PATH './Transition',
                             Name          NVARCHAR2(255) PATH './Name',
                             Manualonly    NUMBER PATH './Manualonly',
                             Description   NCLOB PATH './Description',
                             IconCode      NVARCHAR2(255) PATH './IconCode',
                             IsNextDefault NUMBER PATH './IsNextDefault',
                             IsPrevDefault NUMBER PATH './IsPrevDefault',
                             CodeSource    NVARCHAR2(255) PATH './CodeSource',
                             CodeTarget    NVARCHAR2(255) PATH './CodeTarget')
         )tss
)
ON (lower(col_code) = lower(Code) AND COL_SOURCECASETRANSCASESTATE = CodeSourceId AND COL_TARGETCASETRANSCASESTATE = CodeTargetId)
WHEN MATCHED THEN
     UPDATE  SET   col_manualonly = Manualonly, col_name = Name, col_transition = Transition,
                   col_description = Description, col_iconcode = IconCode, col_isnextdefault = IsNextDefault,
                   col_isprevdefault = IsPrevDefault, col_ucode = Ucode
                   WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
   WHEN NOT MATCHED THEN
     INSERT (col_ucode, col_code , col_manualonly , col_name , col_transition , col_sourcecasetranscasestate, col_targetcasetranscasestate,
             col_description , col_iconcode  , col_isnextdefault, col_isprevdefault   )
     VALUES (Ucode, Code, Manualonly, Name, Transition, CodeSourceId, CodeTargetId,
             Description, IconCode, IsNextDefault, IsPrevDefault);
             
p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_dict_casetransition with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
  /**********************************************************************************/

--  tbl_map_casestateinitiation
  /**********************************************************************************/

 BEGIN
   v_xmlresult := v_input.extract('/CaseType/CaseStateInitiation');
   
MERGE INTO  tbl_map_casestateinitiation
   USING (
SELECT tss.*,
(SELECT col_id FROM tbl_dict_casestate WHERE col_ucode = tss.CaseState) CaseStateId,
    (SELECT col_id FROM tbl_dict_casesystype WHERE lower(col_code) = lower(CaseTypeCode)) CaseType_,
    (SELECT col_id FROM TBL_DICT_INITMETHOD where lower(col_code) = lower(Initmetod)) Initmetod_
    FROM
   (SELECT Code, AssignProcessorCode, ProcessorCode, Initmetod, CaseTypeCode, CaseState
   FROM XMLTABLE('CaseStateInitiation'
   PASSING v_xmlresult
   COLUMNS
                       Code                NVARCHAR2(255) PATH './Code',
                       AssignProcessorCode NVARCHAR2(255) PATH './AssignProcessorCode',
                       ProcessorCode       NVARCHAR2(255) PATH './ProcessorCode',
                       Initmetod           NVARCHAR2(255) PATH './Initmetod',
                       CaseTypeCode        NVARCHAR2(255) PATH './CaseTypeCode',
                       CaseState           NVARCHAR2(255) PATH './CaseState')
   ) tss
 )
   ON (col_code = Code)
   WHEN MATCHED THEN
     UPDATE  SET col_assignprocessorcode = AssignProcessorCode, col_processorcode = ProcessorCode, col_casestateinit_casesystype = CaseType_,
     col_casestateinit_initmethod = Initmetod_, col_map_csstinit_csst = CaseStateId
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
   WHEN NOT MATCHED THEN
     INSERT ( col_assignprocessorcode, col_code, col_processorcode, col_casestateinit_casesystype, col_casestateinit_initmethod, col_map_csstinit_csst )
     VALUES ( AssignProcessorCode, Code, ProcessorCode, CaseType_, Initmetod_, CaseStateId);
     
p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_map_casestateinitiation with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
  /**********************************************************************************/
--  TBL_MAP_CASESTATEINITTMPL
  /**********************************************************************************/

 BEGIN
   v_xmlresult := v_input.extract('/CaseType/CaseStateInitiationTMPL');
      
MERGE INTO  TBL_MAP_CASESTATEINITTMPL
   USING (
   SELECT tss.*,
    (SELECT col_id FROM tbl_dict_casestate WHERE col_ucode = tss.CaseState) CaseStateId,
    (SELECT col_id FROM tbl_dict_casesystype WHERE lower(col_code) = lower(CaseTypeCode)) CaseType_,
    (SELECT col_id FROM TBL_DICT_INITMETHOD where col_code = Initmetod) Initmetod_,
    (SELECT col_id FROM tbl_tasktemplate WHERE col_code = TaskTempl) TaskTemplID
   FROM
     (SELECT Code, AssignProcessorCode, ProcessorCode, Initmetod, 
      CaseTypeCode, CaseState, ID2, TaskTempl
        FROM XMLTABLE('CaseStateInitiationTMPL'
        PASSING v_xmlresult
                COLUMNS
                       Code                NVARCHAR2(255) PATH './Code',
                       AssignProcessorCode NVARCHAR2(255) PATH './AssignProcessorCode',
                       ProcessorCode       NVARCHAR2(255) PATH './ProcessorCode',
                       Initmetod           NVARCHAR2(255) PATH './Initmetod',
                       CaseTypeCode        NVARCHAR2(255) PATH './CaseTypeCode',
                       CaseState           NVARCHAR2(255) PATH './CaseState',
                       TaskTempl           NVARCHAR2(255) PATH './TaskTempl',
                       ID2                 NUMBER PATH './ID2')
   ) tss
 )
   ON (col_code = Code)
   WHEN MATCHED THEN
     UPDATE  SET col_assignprocessorcode = AssignProcessorCode, col_processorcode = ProcessorCode, col_casestateinittp_casetype  = CaseType_,
     col_casestateinittp_initmtd  = Initmetod_, col_map_csstinittp_csst   = CaseStateId,
     col_map_casestinittpltasktpl = TaskTemplID, col_id2 = ID2
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
   WHEN NOT MATCHED THEN
     INSERT ( col_assignprocessorcode, col_code, col_processorcode, 
              col_casestateinittp_casetype , col_casestateinittp_initmtd , col_map_csstinittp_csst,
              col_map_casestinittpltasktpl, col_id2  )
     VALUES ( AssignProcessorCode, Code, ProcessorCode,
              CaseType_, Initmetod_, CaseStateId,
              TaskTemplID, ID2);
     
p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_MAP_CASESTATEINITTMPL with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
  /**********************************************************************************/

  --EXTRACTING PROCEDURE
  /**********************************************************************************/

  BEGIN
    v_xmlresult := v_input.extract('/CaseType/CaseTypeConfig/Procedure');

IF v_xmlresult.existsnode('Procedure/Code/text()') = 1 THEN
    v_code := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'Procedure/Code/text()');
END IF;
    MERGE INTO tbl_procedure
    USING
    (  SELECT v_code CODE, Name, Description, RootTaskTypeCode, CustomDataProcessor, RetrieveCustomDataProcessor,
              UpdateCustomDataProcessor, CustomValidator, IsDefault, IsDeleted, ConfigProc,
              (SELECT col_id FROM tbl_dict_casestate WHERE  col_ucode = CaseState  ) CaseStateId,
              (SELECT COL_ID FROM tbl_dict_procedureincasetype WHERE col_code = ProcInCaseType) ProcInCaseType,
              CustomValResultProcessor 
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
                                 CustomValResultProcessor NVARCHAR2(255) PATH './CustomValResultProcessor',
                                 IsDefault NUMBER PATH './IsDefault',
                                 IsDeleted NUMBER PATH './IsDeleted',
                                 ProcInCaseType NVARCHAR2(255) PATH './ProcInCaseType',
                                 CaseState  NVARCHAR2(255) PATH './CaseState'
                                 ) 

    )
    ON (lower(col_code) = lower(v_code))
    WHEN MATCHED THEN
      UPDATE SET col_customdataprocessor = CustomDataProcessor, col_customvalidator = CustomValidator, col_description = Description,
      col_isdefault = IsDefault, col_isdeleted = IsDeleted, col_name = Name, col_retcustdataprocessor = RetrieveCustomDataProcessor,
      col_updatecustdataprocessor = UpdateCustomDataProcessor, col_procedurecasestate = CaseStateId, col_proceduredict_casesystype = v_casetypeid,
      col_config = ConfigProc, col_procprocincasetype = ProcInCaseType,
      col_customvalresultprocessor = CustomValResultProcessor
      WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
    WHEN NOT MATCHED THEN
    INSERT (col_code, col_name, col_roottasktypecode, col_proceduredict_casesystype, col_procedurecasestate,
      col_updatecustdataprocessor, col_retcustdataprocessor, col_customvalidator, col_customdataprocessor, 
      col_isdefault, col_isdeleted, col_config, col_procprocincasetype,
      col_customvalresultprocessor  )
    VALUES  (code, Name, RootTaskTypeCode, v_casetypeid, CaseStateId,
      UpdateCustomDataProcessor, RetrieveCustomDataProcessor, CustomValidator, CustomDataProcessor, 
      IsDefault, IsDeleted, ConfigProc, ProcInCaseType,
      CustomValResultProcessor);
      
p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_procedure with '||SQL%ROWCOUNT||' rows', IsError => 0);

    begin
      SELECT col_id
        INTO  v_procedureid
        FROM tbl_procedure
        WHERE lower(col_code) = lower(v_code);

     exception when no_data_found then
          p_util_update_log ( XmlIdLog => XmlId, Message => 'Procedure wasn''t found by code '||v_code, IsError => 1,import_status => 'FAILURE');
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

   
   DECLARE
   v_xmlresult xmltype;
   v_code_case NVARCHAR2(255);

   BEGIN
         v_xmlresult := v_input.extract('/CaseType/CaseTypeConfig');
         v_code_case := f_UTIL_extract_value_xml(v_xmlresult, Path => '/CaseTypeConfig/Code/text()');

         UPDATE tbl_dict_casesystype 
            SET col_casesystypeprocedure = v_procedureid
          WHERE lower(col_code) = lower(v_code_case);

   END;

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 

/*************************************************************/

 --EXTRACTING TASK TYPES
/*************************************************************/

 BEGIN
   v_xmlresult := v_input.extract('/CaseType/TaskType');
     MERGE INTO TBL_DICT_TASKSYSTYPE
      USING ( SELECT  Code, Name,  Description, CustomDataProcessor, 
              DateEventCustDataProc, IsDeleted, ProcessorCode, 
              RetCustDataProcessor, UpdateCustDataProcessor, 
              (SELECT col_id FROM tbl_dict_executionmethod WHERE col_code = TaskSysTypeExecMethod) TaskSysTypeExecMethod,
              (SELECT col_id FROM tbl_dict_stateconfig WHERE lower(col_code) = lower(StateConfig)) StateConfig,
              RouteCustomDataProcessor, IconCode, UiMode, PageCode
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
                       IconCode NVARCHAR2(255) PATH './IconCode',
                       PageCode NVARCHAR2(255) PATH './PageCode',
                       UiMode NVARCHAR2(255) PATH './UiMode'
                       )
      )                 
      ON (lower(col_code) = lower(Code))
      WHEN MATCHED THEN
        UPDATE  SET
        col_name = Name , col_description = Description, col_customdataprocessor = CustomDataProcessor,
        col_processorcode = ProcessorCode,   col_retcustdataprocessor = RetCustDataProcessor,
        col_updatecustdataprocessor = UpdateCustDataProcessor, col_tasksystypeexecmethod = TaskSysTypeExecMethod,
        col_isdeleted = IsDeleted, col_stateconfigtasksystype = StateConfig, 
        col_dateeventcustdataproc = DateEventCustDataProc,
        col_routecustomdataprocessor = RouteCustomDataProcessor, 
        col_iconcode =  IconCode , col_pagecode = PageCode, col_uimode = UiMode 
        WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
        WHEN NOT MATCHED THEN
      INSERT
         (col_code  , col_name      , col_description, col_customdataprocessor,   col_processorcode,
          col_retcustdataprocessor, col_updatecustdataprocessor ,  col_tasksystypeexecmethod , col_isdeleted, 
          col_stateconfigtasksystype, col_dateeventcustdataproc, 
          col_routecustomdataprocessor, col_iconcode, 
          col_pagecode, col_uimode)
      VALUES
         (Code, Name, Description, CustomDataProcessor, ProcessorCode,
         RetCustDataProcessor, UpdateCustDataProcessor,  TaskSysTypeExecMethod, IsDeleted,
         StateConfig,  DateEventCustDataProc,
         RouteCustomDataProcessor, IconCode,
         PageCode, UiMode);

p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_DICT_TASKSYSTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/*************************************************************/

--EXTRACTING TBL_TASKSYSTYPERESOLUTIONCODE
/*************************************************************/

 BEGIN
   v_xmlresult := v_input.extract('/CaseType/TaskSysTypeResolutionCode');

MERGE INTO tbl_tasksystyperesolutioncode
USING 
( SELECT tst.col_id AS TaskTypeId,
         rc.col_id AS ResolutionCodeId,
         code
  FROM 
(SELECT  ResolutionCode, TaskType, Code
            FROM XMLTABLE('TaskSysTypeResolutionCode'
              PASSING v_xmlresult
              COLUMNS
                       ResolutionCode NVARCHAR2(255) PATH './ResolutionCode',
                       TaskType NVARCHAR2(255) PATH './TaskType',
                       Code NVARCHAR2(255) PATH './Code'
                       )) tstrc
  JOIN TBL_DICT_TASKSYSTYPE tst ON tst.col_code = tstrc.TaskType 
  JOIN tbl_stp_resolutioncode rc ON rc.col_code = tstrc.ResolutionCode AND rc.col_type = 'TASK'
)  
ON (col_tbl_stp_resolutioncode = ResolutionCodeId AND col_tbl_dict_tasksystype = TaskTypeId)
WHEN MATCHED THEN UPDATE SET col_code = Code 
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN 
  INSERT (col_tbl_stp_resolutioncode, col_tbl_dict_tasksystype, col_code)
  VALUES (ResolutionCodeId, TaskTypeId,code);  
  
	p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_TASKSYSTYPERESOLUTIONCODE with '||SQL%ROWCOUNT||' rows', IsError => 0);
	
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;   
/******************************************************************************/


/*************************************************************/

--TASKTEMPLATE   TBL_MAP_TASKSTATEINITIATION
/*************************************************************/

BEGIN
  
    IF v_input.existsnode('/CaseType/TaskTemplates') = 0  AND v_input.existsnode('/CaseType/TaskTemplatesTMPL') = 0 THEN 


         IF XmlId IS NOT NULL THEN 
	          p_util_update_log ( XmlIdLog => XmlId, Message => 'TaskTemplates and  TaskTemplatesTMPL are empty', IsError => 1, import_status => 'FAILURE');                 
         END IF;

    return 'TaskTemplates and  TaskTemplatesTMPL are empty';
  end if;
  
  v_count := 1;
  v_path := '/CaseType/TaskTemplates';
  v_xmlresult := v_input.extract(v_path);


  IF v_xmlresult IS NOT NULL THEN  
  
         v_result := f_UTIL_extract_values_recurs(Input => v_input, 
                                           Path => v_path, 
                                           TaskTemplateLevel => v_level + 1, 
                                           ParentId => v_parentid, 
                                           CaseTypeId => v_casetypeid, 
                                           ProcedureId => v_procedureid,
                                           XmlId => XmlId);
  END if;                                         
--TASKTEMPLATE   TBL_MAP_TASKSTATEINITMPL                                           
  v_count := 1;
  v_path := '/CaseType/TaskTemplatesTMPL';
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
      v_xmlresult := v_input.extract('/CaseType/Taskdependency');
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
      WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
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
         WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
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

  END;

  p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_autoruleparameter with rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
      /*************************************************************/

      --TBL_TASKDEPENDENCYTMPL
      /*************************************************************/

 BEGIN  
      v_xmlresult := v_input.extract('/CaseType/TaskdependencyTMPL');
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
     ) tskdpndprnttskstateinit,
     f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskdependencyTMPL['||i||']/ID2/text()') ID2,
     f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskdependencyTMPL['||i||']/IsDefault/text()') IsDefault,
     f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskdependencyTMPL['||i||']/TaskDependencyOrder/text()') TaskDependencyOrder  
    FROM dual)
    ON (col_code = code)
    WHEN MATCHED THEN
      UPDATE SET col_processorcode =ProcessorCode , col_type = Type_ ,
      col_taskdpchldtptaskstinittp  = tskdpndchldtskstateinit,
      col_taskdpprnttptaskstinittp  = tskdpndprnttskstateinit,
      col_id2 = id2, col_taskdependencyorder = TaskDependencyOrder, col_isdefault = IsDefault
    WHEN NOT MATCHED THEN
    INSERT
    (col_code, col_processorcode, col_type , col_taskdpchldtptaskstinittp  , col_taskdpprnttptaskstinittp,
     col_id2,  col_taskdependencyorder, col_isdefault  )
    VALUES
    (v_code  , ProcessorCode, Type_, tskdpndchldtskstateinit ,tskdpndprnttskstateinit,
    id2, TaskDependencyOrder, IsDefault);


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

  END;


EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 

  /***************************************************************************************************/

  -- TBL_SLAEVENT
  /***************************************************************************************************/

 BEGIN
     v_xmlresult := v_input.extract('/CaseType/SlaEvent');
MERGE INTO TBL_SLAEVENT
USING(
SELECT Code, Intervalds,  Intervalym, Isrequired, MaxAttempts, SlaEventOrder, IsPrimary,
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
                       CaseType NVARCHAR2(255) PATH './CaseType',
                       IsPrimary NUMBER PATH './IsPrimary'
                       )
)
    ON (col_code = Code)
    WHEN MATCHED THEN
      UPDATE  SET col_intervalds = Intervalds,  col_intervalym = Intervalym,
      col_isrequired = Isrequired, col_maxattempts = MaxAttempts, col_slaeventorder =  SlaEventOrder,
      col_slaeventdict_slaeventtype = SlaEventType, col_slaeventtasktemplate = TaskTemplate,
      col_slaevent_dateeventtype = DateEventType, col_slaevent_slaeventlevel = SlaEventLevel,
      col_slaeventslacase = CaseType, col_isprimary = IsPrimary
      WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
    WHEN NOT MATCHED THEN
      INSERT (col_code, col_intervalds, col_intervalym, col_isrequired, col_maxattempts,
      col_slaeventorder, col_slaeventdict_slaeventtype, col_slaeventtasktemplate, 
      col_slaevent_dateeventtype,  col_slaevent_slaeventlevel, col_slaeventslacase,
      col_isprimary)
      VALUES (Code, Intervalds, Intervalym, Isrequired, MaxAttempts,
      SlaEventOrder, SlaEventType, TaskTemplate, 
      DateEventType, SlaEventLevel, CaseType,
      IsPrimary);

 p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_SLAEVENT with '||SQL%ROWCOUNT||' rows', IsError => 0);
      
 EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;    

/***************************************************************************************************/
-- TBL_SLAEVENTTMPL
/***************************************************************************************************/

 BEGIN
     v_xmlresult := v_input.extract('/CaseType/SlaEventTMPL');
MERGE INTO TBL_SLAEVENTTMPL
USING(
SELECT Code, Intervalds,  Intervalym, Isrequired, MaxAttempts, SlaEventOrder, 
       (SELECT col_id FROM tbl_dict_slaeventtype WHERE lower(col_code) = lower(SlaEventType)) SlaEventType,
       (SELECT col_id FROM tbl_tasktemplate WHERE col_code = TaskTemplate) TaskTemplate,
       (SELECT col_id FROM TBL_DICT_DATEEVENTTYPE WHERE lower(col_code) = lower(DateEventType)) DateEventType,
       (SELECT col_id FROM TBL_DICT_SLAEVENTLEVEL WHERE lower(col_code) = lower(SlaEventLevel)) SlaEventLevel,
       (SELECT col_id FROM tbl_dict_casesystype WHERE lower(col_code) = lower(CaseType)) CaseType,
       (SELECT col_id FROM tbl_dict_tasksystype WHERE lower(col_code) = lower(TaskType)) TaskType,
        AttemptCount, ID2      
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
                       CaseType NVARCHAR2(255) PATH './CaseType',
                       ID2 NUMBER PATH './ID2',
                       AttemptCount NUMBER PATH './AttemptCount',
                       TaskType NVARCHAR2(255)  PATH './TaskType'
                       )
)
    ON (col_code = Code)
    WHEN MATCHED THEN
      UPDATE  SET col_intervalds = Intervalds,  col_intervalym = Intervalym,
      col_isrequired = Isrequired, col_maxattempts = MaxAttempts, col_slaeventorder =  SlaEventOrder,
      col_slaeventtp_slaeventtype  = SlaEventType, col_slaeventtptasktemplate  = TaskTemplate,
      col_slaeventtp_dateeventtype  = DateEventType, col_slaeventtp_slaeventlevel  = SlaEventLevel,
      COL_SLAEVENTTMPLDICT_CST = CaseType,
      col_attemptcount = AttemptCount, col_id2 = ID2, col_slaeventtp_tasksystype = TaskType
      WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
    WHEN NOT MATCHED THEN
      INSERT (col_code, col_intervalds, col_intervalym, col_isrequired, col_maxattempts,
      col_slaeventorder, col_slaeventtp_slaeventtype , col_slaeventtptasktemplate , 
      col_slaeventtp_dateeventtype, col_slaeventtp_slaeventlevel, COL_SLAEVENTTMPLDICT_CST,
      col_attemptcount , col_id2 , col_slaeventtp_tasksystype )
      VALUES (Code, Intervalds, Intervalym, Isrequired, MaxAttempts,
      SlaEventOrder, SlaEventType, TaskTemplate, 
      DateEventType, SlaEventLevel, CaseType,
      AttemptCount,ID2,TaskType);
 
p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_SLAEVENTTMPL with '||SQL%ROWCOUNT||' rows', IsError => 0);
     
 EXCEPTION 
  WHEN OTHERS THEN 
   p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;      

/***************************************************************************************************/
-- TBL_SLAACTION
/***************************************************************************************************/

 BEGIN
   v_xmlresult := v_input.extract('/CaseType/SlaAction');
MERGE INTO tbl_slaaction
USING(
SELECT Code, ActionOrder,  Name, Processorcode,  
(SELECT col_id FROM TBL_SLAEVENT WHERE col_code = SlaEventCode) SlaEventCode,
(SELECT col_id FROM tbl_dict_slaeventlevel WHERE lower(col_code) = lower(SlaEventLevel)) SlaEventLevel
            FROM XMLTABLE('SlaAction'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       ActionOrder NVARCHAR2(255) PATH './ActionOrder',
                       Name NVARCHAR2(255) PATH './Name',
                       Processorcode NVARCHAR2(255) PATH './Processorcode',                       
                       SlaEventCode NVARCHAR2(255) PATH './SlaEventCode',
                       SlaEventLevel NVARCHAR2(255) PATH './SlaEventLevel'
                       )
)         
ON (col_code = Code)
WHEN MATCHED THEN
 UPDATE  SET col_actionorder =  ActionOrder,  col_name = Name,
             col_processorcode = Processorcode,  col_slaactionslaevent = SlaEventCode,
             col_slaaction_slaeventlevel = SlaEventLevel
             WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT (col_code,  col_actionorder,  col_name,  col_processorcode,  col_slaactionslaevent, col_slaaction_slaeventlevel)
VALUES (Code, ActionOrder, Name, Processorcode, SlaEventCode, SlaEventLevel);

p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_SLAACTION with '||SQL%ROWCOUNT||' rows', IsError => 0);

 EXCEPTION 
  WHEN OTHERS THEN 
   p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;      

/***************************************************************************************************/
-- TBL_SLAACTIONTMPL
/***************************************************************************************************/

 BEGIN
   v_xmlresult := v_input.extract('/CaseType/SlaActionTMPL');
MERGE INTO tbl_slaactionTMPL
USING(
SELECT Code, ActionOrder,  Name, Processorcode,  
(SELECT col_id FROM TBL_SLAEVENTTMPL WHERE col_code = SlaEventCode) SlaEventCode,
(SELECT col_id FROM tbl_dict_slaeventlevel WHERE lower(col_code) = lower(SlaEventLevel)) SlaEventLevel
            FROM XMLTABLE('SlaActionTMPL'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       ActionOrder NVARCHAR2(255) PATH './ActionOrder',
                       Name NVARCHAR2(255) PATH './Name',
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',                       
                       SlaEventCode NVARCHAR2(255) PATH './SlaEventCode',
                       SlaEventLevel NVARCHAR2(255) PATH './SlaEventLevel'
                       )
)         
ON (col_code = Code)
WHEN MATCHED THEN
 UPDATE  SET col_actionorder =  ActionOrder,  col_name = Name,
             col_processorcode = Processorcode,  col_slaactiontpslaeventtp  = SlaEventCode,
             col_slaactiontp_slaeventlevel = SlaEventLevel
             WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT (col_code,  col_actionorder,  col_name,  col_processorcode,  col_slaactiontpslaeventtp,
col_slaactiontp_slaeventlevel)
VALUES (Code, ActionOrder, Name, Processorcode, SlaEventCode,
SlaEventLevel);

p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_SLAACTIONTMPL with '||SQL%ROWCOUNT||' rows', IsError => 0);

 EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
 /***************************************************************************************************/

 -- TBL_STP_AVAILABLEADHOC
 /***************************************************************************************************/

  BEGIN
SELECT y.column_value.getstringval()
   INTO v_count
FROM xmltable('count(CaseType/Availableadhoc/CaseProcedure/ProcedureAddition)' passing v_input) y;

  
  IF  v_count >0 THEN 
        v_result := f_util_importprocxmlfn(Input => v_input_clob , XmlId => f_UTIL_importDCMDataXMLfn.XmlId); 
  END IF; 
  
   v_xmlresult := v_input.extract('/CaseType/Availableadhoc');
 MERGE INTO TBL_STP_AVAILABLEADHOC
 USING (SELECT Code, IsDeleted,
       (SELECT col_id FROM tbl_dict_casesystype WHERE lower(col_code) = lower(CaseSysType)) CaseSysType,
       (SELECT col_id FROM tbl_dict_tasksystype WHERE lower(col_code) = lower(TaskSysType)) TaskSysType
       ,(SELECT col_id FROM tbl_procedure WHERE upper(col_code) = upper(CaseProc) ) CaseProc
          FROM XMLTABLE('Availableadhoc'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       TaskSysType nvarchar2(255) PATH './TaskSysType',
                       CaseSysType nvarchar2(255) PATH './CaseSysType'
                       ,CaseProc nvarchar2(255) PATH './CaseProc',
                       IsDeleted NUMBER PATH './IsDeleted'
                       )
      WHERE   TaskSysType IS NOT NULL OR  CaseProc IS NOT NULL                       
 )
 ON (col_code = Code)
 WHEN MATCHED THEN
   UPDATE SET col_casesystype = CaseSysType, 
   col_procedure =  CaseProc, 
   col_tasksystype = TaskSysType, col_isdeleted = IsDeleted
   WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
 WHEN NOT MATCHED THEN
   INSERT (col_code , col_casesystype , col_procedure, col_tasksystype, col_isdeleted)
   VALUES (Code, CaseSysType, CaseProc, TaskSysType, IsDeleted) ;

p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_STP_AVAILABLEADHOC with '||SQL%ROWCOUNT||' rows', IsError => 0);


EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;       
 /***************************************************************************************************/

 -- tbl_dict_tasktransition
 /***************************************************************************************************/
BEGIN
   v_xmlresult := v_input.extract('/CaseType/TaskTransition');

MERGE INTO  tbl_dict_tasktransition 
USING (
SELECT Code, Ucode, Description, ManualOnly, Name, Transition, IconCode, 
(SELECT col_id FROM tbl_dict_taskstate WHERE col_ucode = Source) CodeSourceId,
(SELECT col_id FROM tbl_dict_taskstate WHERE col_ucode = Target) CodeTargetId, 
        SOURCE,
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
                       Target NVARCHAR2(255) PATH './Target',
                       IconCode NVARCHAR2(255) PATH './IconCode')
  )
   ON (lower(col_code) = lower(Code) AND col_sourcetasktranstaskstate = CodeSourceId AND col_targettasktranstaskstate = CodeTargetId )
   WHEN MATCHED THEN
     UPDATE  SET  col_description = Description,  col_manualonly = ManualOnly,
     col_name = Name, col_transition = Transition, col_iconcode = IconCode
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
  WHEN NOT MATCHED THEN
    INSERT (col_code, col_description, col_manualonly, col_name, 
           col_transition, col_sourcetasktranstaskstate, col_targettasktranstaskstate,
           col_ucode, col_iconcode )
    VALUES (Code, Description, ManualOnly, Name, Transition, 
           CodeSourceId, CodeTargetId, 
           Ucode, IconCode);
           
p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_dict_tasktransition with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
   /***************************************************************************************************/

 -- TBL_FOM_UIELEMENT
 /***************************************************************************************************/

BEGIN
  v_xmlresult := v_input.extract('/CaseType/FomUiElement'); 
  v_xmlresult2 := v_input.extract('/CaseType/Dictionary/FomUiElement');

MERGE INTO TBL_FOM_UIELEMENT
   USING (
      SELECT Code,  Description, IsDelete, IsHidden, NAME ,
      (SELECT col_id FROM TBL_FOM_UIELEMENT WHERE lower(col_code) = lower(ParentCode)) ParentCode , 
      ProcessorCode, Title, UiElementOrder,
      (SELECT col_id FROM tbl_dict_casesystype WHERE lower(col_code) = lower(CaseType)) CaseType,
      (SELECT col_id  FROM tbl_dict_casetransition WHERE col_ucode = CaseTtansition) CaseTtansition, /*default transition*/
      (SELECT col_id FROM tbl_dict_tasksystype WHERE lower(col_code) = lower(TaskType)) TaskType,
      (SELECT col_id FROM tbl_dict_tasktransition  WHERE col_ucode = TaskTtansition) TaskTtansition, /*default transition*/
      (SELECT col_id FROM tbl_fom_uielementtype  WHERE col_code = UserElementType) UserElementType,
      (SELECT col_id FROM tbl_dict_casestate  WHERE col_ucode = CaseState) CaseState,  /*default*/
      (SELECT col_id FROM tbl_dict_taskstate  WHERE col_ucode = TaskState) TaskState, /*default*/
      Config, IsEditable, RegionId, PositionIndex, JsonData, RuleVisibility, ElementCode, 
      (SELECT col_id FROM tbl_fom_page fp WHERE lower(col_code) = lower(UIElementPage))  UIElementPage,
      (SELECT col_id FROM tbl_fom_widget WHERE upper(col_code) = upper(FomWidget)) FomWidget,
      (SELECT col_id FROM tbl_fom_dashboard WHERE upper(col_code) = upper(FomDashboard)) FomDashboard,
      (SELECT col_id FROM tbl_dom_object WHERE col_ucode = DomObject) DomObject,
      (SELECT col_id FROM tbl_mdm_form WHERE upper(col_code) = upper(MdmForm)) MdmForm,
      (SELECT col_id FROM tbl_som_config WHERE lower(col_code) = lower(SomConfig)) SomConfig,      
      UserEditable,
      (SELECT listagg(to_char(fom.col_id),',') WITHIN GROUP(ORDER BY fom.col_id) FROM tbl_fom_form fom WHERE 
                                                        fom.col_code IN (SELECT * FROM TABLE(split_casetype_list(FomFormList)))) FomFormList,
      (SELECT listagg(to_char(fom.col_id),',') WITHIN GROUP(ORDER BY fom.col_id) FROM tbl_fom_codedpage fom WHERE 
                                                        fom.col_code IN (SELECT * FROM TABLE(split_casetype_list(CodedPageList)))) CodedPageList   
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
                       SomConfig  NVARCHAR2(255) PATH './SomConfig',
                       FomFormList NVARCHAR2(255) PATH './FomFormList',
                       CodedPageList NVARCHAR2(255) PATH './CodedPageList'
      ) 
)
   ON (lower(col_code) = lower(Code))
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
      col_fom_uielementsom_config = SomConfig, 
      col_codedpageidlist = CodedPageList, col_formidlist = FomFormList
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
      col_fom_uielementsom_config,
      col_codedpageidlist, col_formidlist   
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
      SomConfig,
      CodedPageList, FomFormList);
      
p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_FOM_UIELEMENT with '||SQL%ROWCOUNT||' rows', IsError => 0);

MERGE INTO TBL_FOM_UIELEMENT
   USING (
      SELECT CODE,
			(SELECT listagg(to_char(fom.col_id),',') WITHIN GROUP(ORDER BY fom.col_id) FROM tbl_fom_form fom WHERE
                                                        fom.col_code IN (SELECT * FROM TABLE(split_casetype_list(FomFormList)))) FomFormList,
      (SELECT listagg(to_char(fom.col_id),',') WITHIN GROUP(ORDER BY fom.col_id) FROM tbl_fom_codedpage fom WHERE
                                                        fom.col_code IN (SELECT * FROM TABLE(split_casetype_list(CodedPageList)))) CodedPageList,
      (SELECT col_id FROM TBL_FOM_UIELEMENT WHERE col_code =  ParentCode) ParentCode
      FROM XMLTABLE('FomUiElement'
      PASSING v_xmlresult
          COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       ParentCode NVARCHAR2(255) PATH './ParentCode',
                       FomFormList NVARCHAR2(255) PATH './FomFormList',
                       CodedPageList NVARCHAR2(255) PATH './CodedPageList'
      )
			UNION 
      SELECT CODE,
			(SELECT listagg(to_char(fom.col_id),',') WITHIN GROUP(ORDER BY fom.col_id) FROM tbl_fom_form fom WHERE
                                                        fom.col_code IN (SELECT * FROM TABLE(split_casetype_list(FomFormList)))) FomFormList,
      (SELECT listagg(to_char(fom.col_id),',') WITHIN GROUP(ORDER BY fom.col_id) FROM tbl_fom_codedpage fom WHERE
                                                        fom.col_code IN (SELECT * FROM TABLE(split_casetype_list(CodedPageList)))) CodedPageList,
      (SELECT col_id FROM TBL_FOM_UIELEMENT WHERE col_code =  ParentCode) ParentCode
      FROM XMLTABLE('FomUiElement'
      PASSING v_xmlresult2
          COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       ParentCode NVARCHAR2(255) PATH './ParentCode',
                       FomFormList NVARCHAR2(255) PATH './FomFormList',
                       CodedPageList NVARCHAR2(255) PATH './CodedPageList'
      )			
)
   ON (col_code = Code)
   WHEN MATCHED THEN
      UPDATE  SET col_parentid = ParentCode, COL_CODEDPAGEIDLIST =  CodedPageList, col_formidlist = FomFormList;

EXCEPTION 
  WHEN OTHERS THEN 
   p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
   /***************************************************************************************************/

 -- tbl_AC_ACCESSOBJECT
 /***************************************************************************************************/

 BEGIN
    v_xmlresult := v_input.extract('/CaseType/AccessObject');
   v_xmlresult2 := v_input.extract('/CaseType/Dictionary/CaseState');
   v_xmlresult3 := v_input.extract('/CaseType/CaseState');

 MERGE INTO tbl_AC_ACCESSOBJECT
USING
(SELECT /*CASE WHEN ts.Config IS NULL THEN
         (SELECT col_id FROM tbl_dict_casestate WHERE col_code = ts.Code AND col_stateconfigcasestate   IS NULL)
       WHEN ts.Config IS NOT NULL THEN*/
         (SELECT col_id FROM tbl_dict_casestate WHERE col_ucode = tss.CaseState)
  /* END */ casestateId ,
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
/*LEFT JOIN
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
*/
)
ON (col_code = Code)
WHEN MATCHED THEN UPDATE
  SET col_name = NAME,col_accessobjaccessobjtype = AccessObjectTypeCode ,col_accessobjcasetransition = CaseTransition,
  col_accessobjectaccesstype = AccessTypeCode,col_accessobjectcasestate = casestateId ,col_accessobjectcasesystype = CaseTypeCode ,
  col_accessobjecttasksystype = TaskTypeCode ,col_accessobjectuielement = UserElement
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT
 (col_code, col_name, col_accessobjaccessobjtype, col_accessobjcasetransition,
 col_accessobjectaccesstype, col_accessobjectcasestate, col_accessobjectcasesystype,
 col_accessobjecttasksystype, col_accessobjectuielement)
VALUES
 (code, NAME,AccessObjectTypeCode, CaseTransition, AccessTypeCode, casestateId, CaseTypeCode, TaskTypeCode, UserElement);
 
p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_AC_ACCESSOBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0); 
   
v_xmlresult := v_input.extract('/CaseType/SomAttribute');

   MERGE INTO TBL_SOM_ATTRIBUTE
   USING (
   SELECT Ucode,
   (SELECT col_id FROM tbl_ac_accessobject WHERE col_code = AccessObjectCode ) AccessObjectCode
            FROM XMLTABLE('SomAttribute'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       AccessObjectCode NVARCHAR2(255) PATH './AccessObjectCode'
                       )
)
   ON (col_ucode = ucode)
   WHEN MATCHED THEN
     UPDATE  SET  
     col_som_attributeaccessobject = AccessObjectCode
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');   
     
MERGE INTO tbl_DOM_Attribute
 USING(
SELECT Ucode, 
(SELECT col_id FROM tbl_ac_accessobject WHERE col_code = AccesObject) AccesObject
            FROM XMLTABLE('/DomAttribute'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       AccesObject NVARCHAR2(255) PATH './AccesObject')
                       )
               
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_dom_attributeaccessobject = AccesObject 
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');
  
EXCEPTION 
  WHEN OTHERS THEN 
   p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 

   /***************************************************************************************************/

 -- TBL_AC_ACCESSSUBJECT
 /***************************************************************************************************/

 BEGIN
    v_xmlresult := v_input.extract('/CaseType/AccessSubject');
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
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_Type )
  VALUES (Code, Name, Type);

 p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_AC_ACCESSSUBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0); 
 
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 

  /***************************************************************************************************/

 -- TBL_UIELEMENT_DOM_ATTRIBUTE
 /***************************************************************************************************/

BEGIN  
     v_xmlresult := v_input.extract('/CaseType/UiElementDomAttr');
     v_count := 0;
  SELECT y.column_value.getstringval()
    INTO v_count
    FROM xmltable('count(UiElementDomAttr)' passing v_xmlresult) y ;


DECLARE

  v_DomAttrUcode        NVARCHAR2(255);
  v_FomUIElCode         NVARCHAR2(255);

BEGIN
  FOR i IN 1..v_count LOOP
    v_DomAttrUcode := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'UiElementDomAttr['||i||']/DOMAttrUcode/text()');
    v_FomUIElCode := f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'UiElementDomAttr['||i||']/FomUIElCode/text()');
    
    IF v_DomAttrUcode IS NOT NULL AND v_FomUIElCode IS NOT NULL THEN 
      INSERT INTO tbl_uielement_dom_attribute
      (col_dom_attribute_id, col_fom_uielement_id  )
      VALUES 
      ( (SELECT col_id FROM tbl_DOM_Attribute WHERE col_ucode = v_DomAttrUcode),
        (SELECT col_id FROM tbl_fom_uielement WHERE col_code = v_FomUIElCode)      
      );  
    
    END IF;
    
    
  END LOOP;
  
  END;

END; 
/***************************************************************************************************/

 -- tbl_ASSOCPAGE
/***************************************************************************************************/

BEGIN
   v_xmlresult := v_input.extract('/CaseType/Assocpage');

MERGE INTO tbl_ASSOCPAGE
USING
(
SELECT Code, Description, IsDeleted, Owner, Order_, Pagecode,  Pageparam, 
Required, Title, 
AssocpageType,  
(SELECT col_id FROM tbl_DICT_ASSOCPAGETYPE WHERE col_code = AssocpageType) AssocpageTypeID,
CodedPage, 
(SELECT col_id FROM tbl_fom_codedpage WHERE col_code = CodedPage) CodedPageID,
CaseType,
(SELECT col_id FROM tbl_dict_casesystype WHERE col_code = CaseType) CaseTypeID,
TaskType,
(SELECT col_id FROM tbl_dict_tasksystype WHERE col_code = TaskType) TaskTypeID,
Form,
(SELECT col_id FROM tbl_fom_form WHERE col_code = Form) FormID,
TaskTemplate, 
(SELECT col_id FROM tbl_tasktemplate WHERE col_code = TaskTemplate) TaskTemplateID,
PartyType,
(SELECT col_id FROM tbl_dict_partytype WHERE col_code = PartyType) PartyTypeID,
AllowAspx, AllowCodedPage, AllowForm, AllowFormInTab, 
FomPage,
(SELECT col_id FROM tbl_fom_page WHERE lower(col_code) = lower(FomPage)) FomPageID,
WorkActivityType,
(SELECT col_id FROM tbl_dict_workactivitytype WHERE col_code = WorkActivityType) WorkActivityTypeID,
DocTypeCode,
(SELECT col_id FROM tbl_dict_documenttype WHERE col_code = DocTypeCode) DocTypeCodeID,
MDMFormCode,
(SELECT col_id FROM tbl_mdm_form WHERE col_code = MDMFormCode) MDMFormCodeID
FROM  XMLTABLE('Assocpage'
              PASSING 	v_xmlresult
              COLUMNS
                       Code           NVARCHAR2(255) PATH './Code',
                       Description    NCLOB PATH './Description',
                       IsDeleted      NUMBER PATH './IsDeleted',
                       Owner          NVARCHAR2(255) PATH './Owner',
                       Order_         NUMBER PATH './Order',
                       Pagecode       NVARCHAR2(255) PATH './Pagecode',
                       Pageparam      NCLOB PATH './Pageparam',
                       Required       NUMBER PATH './Required',
                       Title          NVARCHAR2(255) PATH './Title',
                       AssocpageType  NVARCHAR2(255) PATH './AssocpageType',
                       CodedPage      NVARCHAR2(255) PATH './CodedPage',
                       CaseType       NVARCHAR2(255) PATH './CaseType',
                       TaskType       NVARCHAR2(255) PATH './TaskType',
                       Form           NVARCHAR2(255) PATH './Form',
                       PartyType      NVARCHAR2(255) PATH './PartyType',
                       TaskTemplate   NVARCHAR2(255) PATH './TaskTemplate',
                       AllowAspx      NUMBER PATH './AllowAspx',
                       AllowCodedPage NUMBER PATH './AllowCodedPage',
                       AllowForm      NUMBER PATH './AllowForm',
                       AllowFormInTab NUMBER PATH './AllowFormInTab',
                       FomPage        NVARCHAR2(255) PATH './FomPage',
                       WorkActivityType NVARCHAR2(255) PATH './WorkActivityType',
                       DocTypeCode    NVARCHAR2(255) PATH './DocTypeCode',
                       MDMFormCode    NVARCHAR2(255) PATH './MDMFormCode')
)
ON (col_code = Code)
WHEN MATCHED THEN UPDATE
  SET  col_description = Description, col_isdeleted = IsDeleted,   col_owner = Owner,
  col_order = Order_, col_pagecode = Pagecode, col_pageparams = Pageparam,
  col_required = Required, col_title = Title, col_assocpageassocpagetype = AssocpageTypeID,
  col_assocpagecodedpage = nvl(CodedPageID,0),col_assocpagedict_casesystype = NVL(CaseTypeID,0),
	col_assocpagedict_tasksystype = nvl(TaskTypeID,0),
  col_assocpageform= FormID, col_assocpagetasktemplate = TaskTemplateID,col_partytypeassocpage = PartyTypeID,
  col_assocpagepage = FomPageID, col_dict_watypeassocpage = NVL(WorkActivityTypeID,0),
  col_assocpagedict_doctype =  NVL(DocTypeCodeID,0),  col_assocpagemdm_form = MDMFormCodeID
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
 Order_, Pagecode, Pageparam, Required, Title, AssocpageTypeID,
 NVL(CodedPageID,0), NVL(CaseTypeID,0), nvl(TaskTypeID,0),
 FormID, NVL(TaskTemplateID,0), NVL(PartyTypeID,0), FomPageID, NVL(WorkActivityTypeID,0),
 NVL(DocTypeCodeID,0), MDMFormCodeID)
 ;

p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_ASSOCPAGE with '||SQL%ROWCOUNT||' rows', IsError => 0); 

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/***************************************************************************************************/

 -- Tbl_Ppl_Team
/***************************************************************************************************/

 BEGIN
  v_xmlresult := v_input.extract('/CaseType/Team');
MERGE INTO Tbl_Ppl_Team
 USING (
SELECT Code, Description, Name,  GroupId,
(SELECT col_id FROM Tbl_Ppl_Team WHERE col_code = ParentCode) ParentCode,
(SELECT col_id FROM TBL_AC_ACCESSSUBJECT WHERE col_code = AccessSubject) AccessSubject
            FROM XMLTABLE('Team'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Description NCLOB PATH './Description',
                       Name NVARCHAR2(255) PATH './Name',
                       GroupId NUMBER PATH './GroupId',
                       ParentCode NVARCHAR2(255) PATH './ParentCode',
                       AccessSubject NVARCHAR2(255) PATH './AccessSubject'
                       )
)
ON (col_code = Code)
WHEN MATCHED THEN UPDATE
  SET  col_description = Description, col_name =  Name , col_groupid =  GroupId, col_parentteamid =  ParentCode, col_teamaccesssubject = AccessSubject
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT
 ( col_code,  col_description,  col_name, col_groupid,  col_parentteamid, col_teamaccesssubject)
VALUES
 (Code, Description,  Name,  GroupId,ParentCode,  AccessSubject);

 p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged Tbl_Ppl_Team with '||SQL%ROWCOUNT||' rows', IsError => 0); 
 
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/***************************************************************************************************/

 -- Tbl_Ppl_Businessrole
/***************************************************************************************************/

 BEGIN
  v_xmlresult := v_input.extract('/CaseType/BusinessRole');
 MERGE INTO Tbl_Ppl_Businessrole
USING (
SELECT Code, Description, Name, (SELECT col_id FROM TBL_AC_ACCESSSUBJECT WHERE col_code = AccessSubject) AccessSubject
            FROM XMLTABLE('BusinessRole'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Description nvarchar2(255) PATH './Description',
                       Name NVARCHAR2(255) PATH './Name',
                       AccessSubject NVARCHAR2(255) PATH './AccessSubject'
                       )
)
ON (col_code = Code)
WHEN MATCHED THEN UPDATE
  SET  col_description = Description, col_name =  Name , col_businessroleaccesssubject = AccessSubject
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT
 ( col_code,  col_description,  col_name, col_businessroleaccesssubject)
VALUES
 (Code, Description,  Name, AccessSubject);

 p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged Tbl_Ppl_Businessrole with '||SQL%ROWCOUNT||' rows', IsError => 0); 
 
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/***************************************************************************************************/

 -- TBL_PPL_WORKBASKET
/***************************************************************************************************/

 BEGIN
  v_xmlresult := v_input.extract('/CaseType/WorkBasket');

  MERGE INTO TBL_PPL_WORKBASKET
USING
(SELECT CODE,  Description, IsDefault, IsPrivate, Name_, ProcessorCode,
ProcessorCode2, ProcessorCode3, Ucode,
(SELECT col_id FROM tbl_dict_workbaskettype WHERE col_code =  WorkbasketType) WorkbasketType,
(SELECT col_id FROM tbl_ppl_team WHERE col_code = Team) Team,
(SELECT col_id FROM tbl_ppl_businessrole WHERE col_code = BusinessRole) BusinessRole
FROM  XMLTABLE('WorkBasket'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Description NCLOB PATH './Description',
                       IsDefault NUMBER PATH './IsDefault',
                       IsPrivate NUMBER PATH './IsPrivate',
                       Name_ NVARCHAR2(255) PATH './Name',
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',
                       ProcessorCode2 NVARCHAR2(255) PATH './ProcessorCode2',
                       ProcessorCode3 NVARCHAR2(255) PATH './ProcessorCode3',
                       WorkbasketType NVARCHAR2(255) PATH './WorkbasketType',
                       Team NVARCHAR2(255) PATH './Team',
                       BusinessRole NVARCHAR2(255) PATH './BusinessRole',
                       Ucode NVARCHAR2(255) PATH './Ucode'
)
)
ON (col_code = Code)
WHEN MATCHED THEN UPDATE
  SET col_name = NAME_, col_description = Description, col_isdefault = IsDefault,
  col_isprivate = IsPrivate, col_processorcode = ProcessorCode, col_processorcode2 =ProcessorCode2 ,
  col_processorcode3 = ProcessorCode3, col_workbasketworkbaskettype = WorkbasketType ,
   col_workbasketbusinessrole  = BusinessRole, col_workbasketteam = Team,
   col_ucode = ucode
   WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')  
WHEN NOT MATCHED THEN
INSERT
 ( col_code, col_name , col_description, col_isdefault,  col_isprivate,
  col_processorcode,  col_processorcode2,  col_processorcode3, col_workbasketworkbaskettype, col_workbasketbusinessrole, col_workbasketteam,
  col_ucode)
VALUES
 (Code, NAME_,  Description, IsDefault, IsPrivate,
  ProcessorCode, ProcessorCode2, ProcessorCode3, WorkbasketType, BusinessRole, Team,
  Ucode);

 p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_PPL_WORKBASKET with '||v_count||' rows', IsError => 0); 

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 

/***************************************************************************************************/

 -- tbl_map_workbasketbusnessrole
/***************************************************************************************************/

 BEGIN
  v_xmlresult := v_input.extract('/CaseType/MapWorkBasketBR');
   SELECT y.column_value.getstringval()
    INTO v_count
    FROM xmltable('count(MapWorkBasketBR)' passing v_xmlresult) y ;


DECLARE
WB_ID NUMBER;
BR_ID NUMBER;
v_cntt  PLS_INTEGER;

BEGIN
 FOR i IN 1..v_count LOOP

SELECT col_id
       INTO
       BR_ID
FROM
Tbl_Ppl_Businessrole br
WHERE br.col_code = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'MapWorkBasketBR['||i||']/BusinesRole/text()');


SELECT col_id
       INTO
       WB_ID
FROM
tbl_ppl_workbasket wb
WHERE wb.col_code = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'MapWorkBasketBR['||i||']/WorkBasket/text()');



SELECT COUNT(*)
INTO
v_cntt
FROM tbl_map_workbasketbusnessrole mwb
WHERE mwb.col_map_wb_wr_businessrole = BR_ID
AND mwb.col_map_wb_br_workbasket = WB_ID;



    IF v_cntt = 0 THEN
      INSERT INTO tbl_map_workbasketbusnessrole
      (col_map_wb_br_workbasket, col_map_wb_wr_businessrole  )
      VALUES
      (WB_ID, BR_ID);

    END IF;


END LOOP;

END;

 p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_map_workbasketbusnessrole with '||v_count||' rows', IsError => 0); 

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/***************************************************************************************************/

 -- tbl_participant
/***************************************************************************************************/

 BEGIN
  v_xmlresult := v_input.extract('/CaseType/Participant');
 
    MERGE INTO tbl_participant
    USING
    (  SELECT Code, Name, Description, CustomConfig, IsOwner, Owner, Required_, 
       (SELECT col_id FROM tbl_dict_casesystype WHERE col_code = CaseCode) CaseCode, 
       (SELECT col_id FROM tbl_dict_tasksystype WHERE col_code = TaskSysType)TaskSysType, 
       (SELECT col_id FROM tbl_ppl_businessrole WHERE col_code = BusinessRole )BusinessRole, 
        IsDeleted,  Allowmultiple, IsSupervisor, IsCreator,
       (SELECT col_id FROM tbl_dict_partytype WHERE col_code = PartyType) PartyType,  
       (SELECT col_id FROM tbl_ppl_team WHERE col_code = TeamCode) TeamCode, 
       (SELECT col_id FROM tbl_procedure WHERE col_code = Procedure_ )Procedure_, GetProcessorCode,
       (SELECT col_id FROM tbl_dict_participantunittype WHERE col_code = PartiUnitType)PartiUnitType
       FROM XMLTABLE('Participant'
                        PASSING v_xmlresult
                        COLUMNS
                                 Code NVARCHAR2(255) PATH './Code',
                                 CustomConfig NCLOB PATH './CustomConfig',
                                 Description NCLOB PATH './Description',
                                 IsOwner NUMBER PATH './IsOwner',
                                 Name NVARCHAR2(255) PATH './Name',
                                 Owner NVARCHAR2(255) PATH './Owner',
                                 Required_ NUMBER PATH './Required',
                                 CaseCode NVARCHAR2(255) PATH './CaseCode',
                                 TaskSysType NVARCHAR2(255) PATH './TaskSysType',
                                 BusinessRole NVARCHAR2(255) PATH './BusinessRole',
                                 IsDeleted NUMBER PATH './IsDeleted',
                                 PartyType NVARCHAR2(255) PATH './PartyType',
                                 Allowmultiple NUMBER PATH './Allowmultiple',
                                 TeamCode NVARCHAR2(255) PATH './TeamCode',
                                 Procedure_ NVARCHAR2(255) PATH './Procedure',
                                 GetProcessorCode NVARCHAR2(255) PATH './GetProcessorCode',
                                 PartiUnitType NVARCHAR2(255) PATH './PartiUnitType',
                                 IsSupervisor NUMBER PATH './IsSupervisor',
                                 IsCreator NUMBER PATH './IsCreator'   
                                 ) 

    )
    ON (col_code = code)
    WHEN MATCHED THEN
      UPDATE SET col_description  = Description, col_isowner = IsOwner, col_owner  = Owner,
      col_required  = Required_, col_participantcasesystype  = CaseCode, col_name = Name, 
      col_participanttasksystype = TaskSysType, col_participantbusinessrole  = BusinessRole, 
      col_isdeleted  = IsDeleted, col_participantdict_partytype  = PartyType,
      col_customconfig  = CustomConfig, col_allowmultiple = Allowmultiple, col_participantteam = TeamCode,
      col_participantprocedure = Procedure_, col_getprocessorcode = GetProcessorCode,
      col_participantdict_unittype = PartiUnitType, col_issupervisor = IsSupervisor, col_iscreator =IsCreator
      WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
    WHEN NOT MATCHED THEN
    INSERT (col_code, col_name, col_description, col_isowner, col_owner,
      col_required, col_participantcasesystype, col_participanttasksystype, col_participantbusinessrole,
      col_isdeleted, col_participantdict_partytype, col_customconfig, col_allowmultiple, col_participantteam,
      col_participantprocedure, col_getprocessorcode, col_participantdict_unittype,
      col_issupervisor, col_iscreator)
    VALUES  (code, Name, Description, IsOwner, Owner, 
      Required_, CaseCode, TaskSysType, BusinessRole, IsDeleted, PartyType, CustomConfig, Allowmultiple, 
      TeamCode, Procedure_, GetProcessorCode,PartiUnitType,
      IsSupervisor, IsCreator);

 p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_participant with '||SQL%ROWCOUNT||' rows', IsError => 0); 
 
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
/***************************************************************************************************/

 -- tbl_map_workbasketteam
/***************************************************************************************************/

 BEGIN
  v_xmlresult := v_input.extract('/CaseType/MapWorkBasketTeam');
   SELECT y.column_value.getstringval()
    INTO v_count
    FROM xmltable('count(MapWorkBasketTeam)' passing v_xmlresult) y ;


DECLARE
WB_ID NUMBER;
BR_ID NUMBER;
v_cntt  PLS_INTEGER;

BEGIN
 FOR i IN 1..v_count LOOP

SELECT col_id
       INTO
       BR_ID
FROM
Tbl_Ppl_Team br
WHERE br.col_code = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => '/MapWorkBasketTeam['||i||']/Team/text()');


SELECT col_id
       INTO
       WB_ID
FROM
tbl_ppl_workbasket wb
WHERE wb.col_code = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => '/MapWorkBasketTeam['||i||']/WorkBasket/text()');



SELECT COUNT(*)
INTO
v_cntt
FROM tbl_map_workbasketteam mwb
WHERE mwb.col_map_wb_tm_team = BR_ID
AND mwb.col_map_wb_tm_workbasket = WB_ID;



    IF v_cntt = 0 THEN
      INSERT INTO tbl_map_workbasketteam
      (col_map_wb_tm_workbasket , col_map_wb_tm_team   )
      VALUES
      (WB_ID, BR_ID);

    END IF;


END LOOP;

END;

 p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_map_workbasketteam with '||v_count||' rows', IsError => 0); 

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/***************************************************************************************************/

 -- TBL_DICT_CSEST_DTEVTP
/***************************************************************************************************/

BEGIN
  v_xmlresult := v_input.extract('/CaseType/CaseStateDateEventType');
   SELECT y.column_value.getstringval()
    INTO v_count
    FROM xmltable('count(CaseStateDateEventType)' passing v_xmlresult) y ;


DECLARE
DataEvent NUMBER;
CaseState NUMBER;
v_cntt  PLS_INTEGER;

BEGIN
FOR i IN 1..v_count LOOP

SELECT COUNT(*)
INTO v_cnt
FROM tbl_dict_casestate cst
WHERE cst.col_ucode = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'CaseStateDateEventType['||i||']/CaseState/text()');


IF v_cnt = 0 THEN
 SELECT COUNT(*)
INTO v_cnt
FROM tbl_dict_stateconfig WHERE col_code =
    f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'CaseStateDateEventType['||i||']/Config/text()');

      IF v_cnt = 0 THEN
        v_cnt := NULL;
        CONTINUE;
      END IF;

END IF;




    SELECT col_id
           INTO
           CaseState
    FROM
    tbl_dict_casestate cst
    WHERE cst.col_ucode = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'CaseStateDateEventType['||i||']/CaseState/text()')
    AND (cst.col_stateconfigcasestate IS NULL
    OR cst.col_stateconfigcasestate = (
    SELECT col_id FROM tbl_dict_stateconfig WHERE col_code =
    f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'CaseStateDateEventType['||i||']/Config/text()')));


      SELECT col_id
             INTO
             DataEvent
      FROM
      tbl_dict_dateeventtype det
      WHERE det.col_code = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'CaseStateDateEventType['||i||']/DateEventType/text()');



      SELECT COUNT(*)
      INTO
      v_cntt
      FROM TBL_DICT_CSEST_DTEVTP detp
      WHERE detp.col_csest_dtevtpcasestate = CaseState
      AND detp.col_csest_dtevtpdateeventtype = DataEvent;



    IF v_cntt = 0 THEN
      INSERT INTO TBL_DICT_CSEST_DTEVTP
      (col_csest_dtevtpcasestate , col_csest_dtevtpdateeventtype   )
      VALUES
      (CaseState, DataEvent);

    END IF;


END LOOP;

END;
 p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_DICT_CSEST_DTEVTP with '||v_count||' rows', IsError => 0); 

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/***************************************************************************************************/

 -- TBL_DICT_TSKST_DTEVTP
/***************************************************************************************************/

 BEGIN
  v_xmlresult := v_input.extract('/CaseType/TaskStateDateEventType');
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

 p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_DICT_TSKST_DTEVTP with '||v_count||' rows', IsError => 0); 
 
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/******************************************************************************/

--tbl_DICT_CUSTOMCATEGORY
/******************************************************************************/

 BEGIN
  v_xmlresult := v_input.extract('/CaseType/CustomCategory');
MERGE INTO tbl_DICT_CUSTOMCATEGORY
USING
(
SELECT Code, Description, Name, IsDeleted, 
(SELECT col_id FROM tbl_DICT_CUSTOMCATEGORY WHERE col_code = CustCategoryCode) CustCategoryID,
IconCode, ColorCode, Categoryorder
            FROM XMLTABLE('CustomCategory'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Description NCLOB PATH './Description',
                       Name NVARCHAR2(255) PATH './Name',
                       IsDeleted NUMBER PATH './IsDeleted',
                       CustCategoryCode NVARCHAR2(255) PATH './CustCategoryCode',
                       IconCode NVARCHAR2(255) PATH './IconCode',
                       ColorCode NVARCHAR2(255) PATH './ColorCode',
                       Categoryorder NUMBER(10,2) PATH './Categoryorder'
                       )
)
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN UPDATE
  SET  col_description = Description, col_isdeleted = IsDeleted,  col_name =  Name,
      col_categorycategory = nvl(CustCategoryID,-1), col_iconcode = IconCode,
      col_colorcode = ColorCode, col_categoryorder =  Categoryorder
   WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')      
WHEN NOT MATCHED THEN
INSERT
 ( col_code,  col_description, col_isdeleted,  col_name, col_categorycategory, col_iconcode, col_colorcode, col_categoryorder    )
VALUES
 (Code, Description, IsDeleted, Name, nvl(CustCategoryID,-1), IconCode, ColorCode, Categoryorder);
 
 p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_DICT_CUSTOMCATEGORY with '||SQL%ROWCOUNT||' rows', IsError => 0); 

MERGE INTO tbl_DICT_CUSTOMCATEGORY
USING
(
SELECT Code, 
(SELECT col_id FROM tbl_DICT_CUSTOMCATEGORY WHERE col_code = CustCategoryCode) CustCategoryID

            FROM XMLTABLE('CustomCategory'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       CustCategoryCode NVARCHAR2(255) PATH './CustCategoryCode'
                       )
WHERE  CustCategoryCode IS NOT NULL                    
)
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN UPDATE
  SET col_categorycategory = CustCategoryID
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
;

 p_util_update_log ( XmlIdLog => XmlId, Message => 'Updated col_categorycategory in table tbl_DICT_CUSTOMCATEGORY '||SQL%ROWCOUNT||' rows', IsError => 0); 
 
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/******************************************************************************/

--tbl_DICT_CUSTOMWORD
/******************************************************************************/

 BEGIN
  v_xmlresult := v_input.extract('/CaseType/CustomWord');

MERGE INTO tbl_DICT_CUSTOMWORD
USING
(SELECT Code, Description, Name, IsDeleted, "Order", RowStyle, Status, Style, "Value", WordOrder,Ucode,
 nvl((SELECT col_id FROM tbl_dict_customcategory WHERE col_code = WordCategory),0)WordCategory
            FROM XMLTABLE('CustomWord'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Description nvarchar2(255) PATH './Description',
                       Name NVARCHAR2(255) PATH './Name',
                       IsDeleted NUMBER PATH './IsDeleted',
                       "Order" NUMBER(10,2) PATH './Order',
                       RowStyle NVARCHAR2(255) PATH './RowStyle',
                       Status NVARCHAR2(255) PATH './Status',
                       Style NVARCHAR2(255) PATH './Style',
                       "Value" NVARCHAR2(255) PATH './Value',
                       WordOrder NUMBER PATH './WordOrder',
                       WordCategory NVARCHAR2(255) PATH './WordCategory',
                       Ucode nvarchar2(255) PATH './Ucode'
                       )
)
ON (col_ucode = ucode  )

WHEN MATCHED THEN UPDATE
  SET  col_description = Description, col_isdeleted = IsDeleted,  col_name =  Name ,
  col_order = "Order",  col_rowstyle = RowStyle,  col_status = Status, col_style = Style,
  col_value = "Value", col_wordorder = WordOrder, col_code = Code , col_wordcategory = WordCategory
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT
 ( col_code,  col_description, col_isdeleted, col_order , col_name,  col_rowstyle, col_status, col_style ,
  col_wordorder, col_wordcategory, col_value, col_ucode )
VALUES
 (Code,   Description, IsDeleted, "Order", Name,  RowStyle, Status, Style,
  WordOrder,  WordCategory, "Value", Ucode);
  p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_DICT_CUSTOMWORD with '||SQL%ROWCOUNT||' rows', IsError => 0); 
  

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/******************************************************************************/

--TBL_DOCFOLDER
/******************************************************************************/

/*
BEGIN
  v_xmlresult := v_input.extract('/CaseType/DocFolder');
   MERGE INTO TBL_DOCFOLDER
   USING (
   SELECT Code, Description, Name, IsDeleted, (SELECT col_id FROM tbl_dict_casesystype WHERE col_code = FolderCaseType)FolderCaseType
            FROM XMLTABLE('DocFolder'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Description nvarchar2(255) PATH './Description',
                       Name NVARCHAR2(255) PATH './Name',
                       IsDeleted NUMBER PATH './IsDeleted',
                       FolderCaseType NVARCHAR2(255) PATH './FolderCaseType'
                       )
)
   ON (col_code = Code)
   WHEN MATCHED THEN
     UPDATE  SET  col_description = Description, col_isdeleted = IsDeleted, col_name = Name,  col_docfoldercasesystype = FolderCaseType
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
     WHEN NOT MATCHED THEN
       INSERT (col_code, col_description, col_isdeleted, col_name, col_docfoldercasesystype )
       VALUES (Code,Description, IsDeleted, Name ,FolderCaseType);

  p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_DOCFOLDER with '||SQL%ROWCOUNT||' rows', IsError => 0); 
         
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
*/

/******************************************************************************/
--TBL_PPL_ORGCHART
/******************************************************************************/

BEGIN
  v_xmlresult := v_input.extract('/CaseType/Orgchart');
   MERGE INTO TBL_PPL_ORGCHART
   USING (
   SELECT Code, Owner, Name, IsPrimary, 
   (SELECT col_id FROM tbl_ppl_team WHERE col_code = Team) Team,
   (SELECT col_id FROM tbl_dict_casesystype WHERE col_code = CaseType) CaseType
            FROM XMLTABLE('Orgchart'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Owner NVARCHAR2(255) PATH './Owner',
                       Name NVARCHAR2(255) PATH './Name',
                       IsPrimary NUMBER PATH './IsPrimary',
                       Team NVARCHAR2(255) PATH './Team',
                       CaseType NVARCHAR2(255) PATH './CaseType'
                       )
)
   ON (col_code = Code)
   WHEN MATCHED THEN
     UPDATE  SET  col_owner  = Owner, col_isprimary  = IsPrimary, col_name = Name,  col_casesystypeorgchart  = CaseType,
     col_teamorgchart = Team
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
     WHEN NOT MATCHED THEN
       INSERT (col_code, col_owner , col_isprimary , col_name, col_casesystypeorgchart, col_teamorgchart   )
       VALUES (Code, Owner, IsPrimary, Name ,CaseType, Team);

  p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_PPL_ORGCHART with '||SQL%ROWCOUNT||' rows', IsError => 0); 
         
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 
/***************************************************************************************************/
--TBL_DICT_STATEEVENT
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_input.extract('/CaseType/StateEvent');
 
MERGE INTO TBL_DICT_STATEEVENT
USING(
SELECT Ucode, EventOrder, EventSubType, EventType, ProcessorCode, 
(SELECT col_id FROM tbl_dict_state WHERE col_ucode = StateUcode) StateUcode, 
(SELECT col_id FROM tbl_dict_taskeventmoment WHERE lower(col_code) = lower(TaskEventMomentCode)) TaskEventMomentCode,
(SELECT col_id FROM tbl_dict_taskeventtype WHERE lower(col_code) = lower(TaskEventTypeCode)) TaskEventTypeCode,
(SELECT col_id FROM tbl_dict_transition WHERE col_ucode = Transition) Transition,
EventCode, EventName
            FROM XMLTABLE('StateEvent'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       EventOrder NUMBER PATH './EventOrder',
                       EventSubType NVARCHAR2(255) PATH './EventSubType',
                       EventType NVARCHAR2(255) PATH './EventType',
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',                       
                       StateUcode NVARCHAR2(255) PATH './StateUcode',
                       TaskEventMomentCode NVARCHAR2(255) PATH './TaskEventMomentCode',
                       TaskEventTypeCode NVARCHAR2(255) PATH './TaskEventTypeCode',
                       EventCode NVARCHAR2(255) PATH './EventCode',
                       EventName NVARCHAR2(255) PATH './EventName',
                       Transition NVARCHAR2(255) PATH './Transition'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_eventorder = EventOrder, col_eventsubtype = EventSubType,
  col_eventtype = EventType, col_processorcode = ProcessorCode, 
  col_stateeventstate = StateUcode, col_stateeventeventmoment = TaskEventMomentCode,
  col_stateeventeventtype = TaskEventTypeCode,
  col_eventcode =  EventCode, col_eventname = EventName,
  col_stevt_trans = Transition 
    WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_eventorder , col_eventsubtype, col_eventtype , col_processorcode,
          col_stateeventstate, col_stateeventeventmoment, col_stateeventeventtype,
          col_eventcode, col_eventname, col_stevt_trans )
  VALUES (Ucode, EventOrder, EventSubType, EventType, ProcessorCode,
          StateUcode, TaskEventMomentCode, TaskEventTypeCode,
          EventCode, EventName,Transition);
          
p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_DICT_STATEEVENT with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;

/***************************************************************************************************/
--TBL_DICT_STATESLAEVENT
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_input.extract('/CaseType/StateSlaEvent');
 
MERGE INTO TBL_DICT_STATESLAEVENT
USING(
SELECT Ucode, Code, AttemptCount, Intervalds, Intervalym, MaxAttempts, Name, SlaEventOrder,
(SELECT col_id FROM tbl_dict_state WHERE col_ucode = StateUcode) StateUcode, 
(SELECT col_id FROM tbl_dict_slaeventlevel WHERE lower(col_code) = lower(SlaEventLevelCode)) SlaEventLevelCode,
(SELECT col_id FROM tbl_dict_transition WHERE col_ucode = Transition) Transition,
(SELECT col_id FROM tbl_dict_slaeventtype WHERE col_code = SlaEventType) SlaEventType,
ServiceSubType, ServiceType,EventCode, EventName
            FROM XMLTABLE('StateSlaEvent'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code NVARCHAR2(255) PATH './Code',
                       AttemptCount NUMBER PATH './AttemptCount',
                       Intervalds NVARCHAR2(255) PATH './Intervalds',
                       Intervalym NVARCHAR2(255) PATH './Intervalym',
                       MaxAttempts NUMBER PATH './MaxAttempts',
                       Name NVARCHAR2(255) PATH './Name',
                       SlaEventOrder NUMBER PATH './SlaEventOrder', 
                       StateUcode NVARCHAR2(255) PATH './StateUcode',
                       SlaEventLevelCode NVARCHAR2(255) PATH './SlaEventLevelCode',
                       ServiceSubType NVARCHAR2(255) PATH './ServiceSubType',
                       ServiceType NVARCHAR2(255) PATH './ServiceType',
                       EventCode NVARCHAR2(255) PATH './EventCode',
                       EventName NVARCHAR2(255) PATH './EventName',
                       Transition NVARCHAR2(255) PATH './Transition',
                       SlaEventType NVARCHAR2(255) PATH './SlaEventType'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET  col_attemptcount = AttemptCount,
  col_intervalds = Intervalds, col_intervalym = Intervalym, 
	col_maxattempts = MaxAttempts, 
	col_slaeventorder = SlaEventOrder , col_stateslaeventslaeventlvl = SlaEventLevelCode, 
	col_stateslaeventdict_state = StateUcode,
  col_servicesubtype = ServiceSubType, col_servicetype = ServiceType,
  col_eventcode =  EventCode, col_eventname = EventName,
  col_stslaevt_trans = Transition, col_dict_sse_slaeventtype = SlaEventType
    WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_attemptcount, col_intervalds, col_intervalym,
          col_maxattempts, col_slaeventorder,
          col_stateslaeventslaeventlvl, col_stateslaeventdict_state,
          col_servicesubtype, col_servicetype,
          col_eventcode, col_eventname, col_stslaevt_trans,
          col_dict_sse_slaeventtype)
  VALUES (Ucode,  AttemptCount, Intervalds, Intervalym,
          MaxAttempts,  SlaEventOrder, 
	      SlaEventLevelCode, StateUcode,
          ServiceSubType, ServiceType,
          EventCode, EventName, Transition,
          SlaEventType);

p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_DICT_STATESLAEVENT with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;


/***************************************************************************************************/
--TBL_DICT_STATESLAACTION
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_input.extract('/CaseType/StateSlaAction');
 
MERGE INTO TBL_DICT_STATESLAACTION
USING(
SELECT Ucode, ProcessorCode, SlaActionOrder,
(SELECT col_id FROM tbl_dict_stateslaevent WHERE col_ucode = StateSlaEvent) StateSlaEvent,
EventCode, EventName
            FROM XMLTABLE('StateSlaAction'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',
                       SlaActionOrder NUMBER PATH './SlaActionOrder',
                       StateSlaEvent NVARCHAR2(255) PATH './StateSlaEvent',
                       EventCode NVARCHAR2(255) PATH './EventCode',
                       EventName NVARCHAR2(255) PATH './EventName'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_processorcode  = ProcessorCode, 
	col_slaactionorder  = SlaActionOrder, col_stateslaactnstateslaevnt  = StateSlaEvent,
  col_eventcode =  EventCode, col_eventname = EventName
    WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_processorcode, 
          col_slaactionorder, col_stateslaactnstateslaevnt,
          col_eventcode, col_eventname)
  VALUES (Ucode,  ProcessorCode,
          SlaActionOrder, StateSlaEvent,
          EventCode, EventName);
          
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_STATESLAACTION with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
end;
/******************************************************************************/

  IF  v_input.existsnode('/CaseType/Availableadhoc') = 1 THEN

      v_result := f_UTIL_importProcXMLfn(XmlId => XmlId , Input => v_input_clob);
  p_util_update_log ( XmlIdLog => XmlId, Message => 'Exists adhoc procedure and it was loaded', IsError => 0); 
  END IF;
/******************************************************************************/

--tbl_autoruleparamtmpl
/******************************************************************************/
begin
  v_xmlresult := v_input.extract('/CaseType/AutoRuleParamTmpl');
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

               p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_AUTORULEPARAMTMPL with '||SQL%ROWCOUNT||' rows', IsError => 0); 
  
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/******************************************************************************/

  IF  v_input.existsnode('/CaseType/AutoruleParamProc') = 1 THEN

      v_result := f_UTIL_importProcXMLfn(XmlId => XmlId , Input => v_input_clob, procType =>'AutoruleParamProc' );
  p_util_update_log ( XmlIdLog => XmlId, Message => 'Exists Procedure for autoruleparam and it was loaded', IsError => 0); 
  END IF;


/******************************************************************************/

--tbl_autoruleparameter
/******************************************************************************/
BEGIN
  v_xmlresult := v_input.extract('/CaseType/AutoRuleParam');
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
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
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
 
  p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_AUTORULEPARAMETER with '||SQL%ROWCOUNT||' rows', IsError => 0); 
                
EXCEPTION 
  WHEN OTHERS THEN 
   p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);               
END;           

/***************************************************************************************************/
 -- tbl_AC_PERMISSION
/***************************************************************************************************/
 BEGIN
   v_xmlresult := v_input.extract('/CaseType/ACPermition');

MERGE INTO tbl_AC_PERMISSION
USING(
SELECT Code, Name,  Description, DefaultACL,OrderACL, Position, Ucode,
(SELECT col_id FROM tbl_ac_accessobjecttype WHERE col_code = AccessObjectType) AccessObjectType
            FROM XMLTABLE('ACPermition'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Description NCLOB PATH './Description',
                       DefaultACL NUMBER PATH './DefaultACL',
                       OrderACL NUMBER PATH './OrderACL',
                       Position NUMBER PATH './Position',
                       AccessObjectType NVARCHAR2(255) PATH './AccessObjectType',
                       Ucode NVARCHAR2(255) PATH './Ucode'
                       )
               )
ON (col_ucode = ucode )
WHEN MATCHED THEN
  UPDATE SET col_name = Name,  col_description = Description ,
  col_defaultacl = DefaultACL, col_orderacl= OrderACL, col_position = Position,
  col_permissionaccessobjtype = AccessObjectType, col_code = code
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name,  col_description,col_defaultacl, col_orderacl, col_position, col_permissionaccessobjtype, col_ucode )
  VALUES (Code, Name,  Description, DefaultACL, OrderACL, Position, AccessObjectType, ucode )
  LOG ERRORS INTO er$AC_PERMISSION ('IMPOTR') REJECT LIMIT 5;
      
  p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_AC_PERMISSION with '||SQL%ROWCOUNT||' rows', IsError => 0);  

    FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$AC_PERMISSION d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into tbl_AC_PERMISSION '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
    END LOOP; 
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/**********************************************************************************/
--Extracting tbl_ac_acl
/**********************************************************************************/
BEGIN
 v_xmlresult := v_input.extract('/CaseType/AcAcl'); 

MERGE INTO tbl_ac_acl
USING(
SELECT Code, AclType, ProcessorCode, 
(SELECT col_id FROM tbl_ac_accessobject WHERE col_code = AccessObject) AccessObject,
(SELECT col_id FROM tbl_ac_accesssubject WHERE col_code = AccessSubject) AccessSubject, 
(SELECT col_id FROM tbl_ac_permission WHERE col_ucode = Permission) Permission
            FROM XMLTABLE('AcAcl'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       AclType NUMBER PATH './AclType',
                       ProcessorCode NVARCHAR2(255) PATH './ProcessorCode',
                       AccessObject NVARCHAR2(255) PATH './AccessObject',
                       AccessSubject NVARCHAR2(255) PATH './AccessSubject',
                       Permission NVARCHAR2(255) PATH './Permission'
                       )
               )
ON (col_code = Code)
WHEN MATCHED THEN
  UPDATE SET col_type = AclType, col_processorcode = ProcessorCode, 
	col_aclaccessobject = AccessObject, col_aclaccesssubject = AccessSubject,
	col_aclpermission = Permission
    WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_type, col_processorcode, col_aclaccessobject, col_aclaccesssubject, col_aclpermission)
  VALUES (Code, AclType, ProcessorCode, AccessObject, AccessSubject, Permission);

    p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_AC_ACL with '||SQL%ROWCOUNT||' rows '||$$PLSQL_LINE, IsError => 0);
      
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/******************************************************************************/

--tbl_commonevent
/******************************************************************************/
begin
  v_xmlresult := v_input.extract('/CaseType/CommonEvent');
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
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
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

  p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_COMMONEVENT with '||SQL%ROWCOUNT||' rows', IsError => 0); 
  

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/******************************************************************************/

--tbl_commoneventtmpl
/******************************************************************************/
begin
  v_xmlresult := v_input.extract('/CaseType/CommonEventTmpl');
   MERGE INTO tbl_commoneventtmpl
   USING (
   SELECT Code, EventOrder, ProcessorCode, Name,  RepeatingEvent, Description,
         (SELECT col_id FROM tbl_dict_commoneventtype WHERE col_code = CommonEventType) CommonEventType,
         (SELECT col_id FROM tbl_dict_casesystype WHERE col_code = CaseType) CaseType,
         (SELECT col_id FROM tbl_tasktemplate WHERE col_code = TaskTemplate )TaskTemplate,
         (SELECT col_id FROM tbl_dict_tasksystype WHERE col_code = TaskType) TaskType,
         (SELECT col_id FROM tbl_dict_taskeventmoment WHERE col_code = TaskEventMoment) TaskEventMoment,
         (SELECT col_id FROM tbl_dict_taskeventsynctype WHERE col_code = TaskEventSyncType) TaskEventSyncType,
         (SELECT col_id FROM tbl_dict_taskeventtype WHERE col_code = TaskEventType) TaskEventType,
         (SELECT col_id FROM tbl_procedure WHERE col_code = Procedure_) Procedure_,
          Ucode, CustomConfig                          
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
                       Ucode  NVARCHAR2(255) PATH './Ucode',
                       CustomConfig NCLOB PATH './CustomConfig',
                       RepeatingEvent NUMBER PATH './RepeatingEvent',
                       Description NCLOB PATH './Description'
                       )
)
   ON (col_ucode = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET  col_code  = Code, col_eventorder  = EventOrder, col_processorcode  = ProcessorCode, 
     col_name  = Name, col_comeventtmplcomeventtype   = CommonEventType, col_commoneventtmplcasetype   = CaseType, 
     col_commoneventtmpltasktmpl   = TaskTemplate, col_commoneventtmpltasktype   = TaskType, 
     col_comevttmplevtmmnt   = TaskEventMoment, col_comevttmplevtsynct   = TaskEventSyncType, 
     col_comevttmpltaskevtt   = TaskEventType, col_commoneventtmplprocedure  = Procedure_,
     col_customconfig = CustomConfig, col_repeatingevent = RepeatingEvent,
     col_description = Description
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
     WHEN NOT MATCHED THEN
       INSERT (col_code,   col_eventorder , col_processorcode  , col_name , 
               col_comeventtmplcomeventtype  , col_commoneventtmplcasetype  , col_commoneventtmpltasktmpl   , 
               col_commoneventtmpltasktype   , col_comevttmplevtmmnt  ,  
               col_comevttmplevtsynct   , col_comevttmpltaskevtt  , col_commoneventtmplprocedure   , 
                col_ucode, col_customconfig, col_repeatingevent, col_description)
       VALUES (Code, EventOrder, ProcessorCode, NAME,
               CommonEventType, CaseType, TaskTemplate, 
               TaskType, TaskEventMoment, 
               TaskEventSyncType, TaskEventType, Procedure_,
               Ucode, CustomConfig, RepeatingEvent, Description);

  p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged tbl_commoneventtmpl with '||SQL%ROWCOUNT||' rows', IsError => 0); 
  

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;



/******************************************************************************/

--TBL_CASESYSTYPERESOLUTIONCODE
/******************************************************************************/

BEGIN
  v_xmlresult := v_input.extract('/CaseType/CaseResolutionCode');
SELECT y.column_value.getstringval()
    INTO v_count
    FROM xmltable('count(CaseResolutionCode)' passing v_xmlresult) y ;


DECLARE 
v_case_code        NVARCHAR2(255);
v_resolution_code  NVARCHAR2(255);
v_cnt                NUMBER;

BEGIN
FOR i IN 1..v_count LOOP 

v_case_code :=  f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'CaseResolutionCode['||i||']/CaseCode/text()');
v_resolution_code :=  f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'CaseResolutionCode['||i||']/ResolutionCode/text()');

      IF v_case_code IS NOT NULL AND v_resolution_code IS NOT NULL 
        THEN 
              SELECT COUNT(*) 
              INTO v_cnt
              FROM TBL_CASESYSTYPERESOLUTIONCODE 
              WHERE col_casetyperesolutioncode = (SELECT col_id FROM tbl_stp_resolutioncode WHERE lower(col_code) = lower(v_resolution_code) AND col_type =  'CASE')
              AND col_tbl_dict_casesystype = (SELECT col_id FROM tbl_dict_casesystype WHERE col_code = v_case_code ) ;

              
              IF v_cnt = 0 THEN 
                INSERT INTO TBL_CASESYSTYPERESOLUTIONCODE 
                (col_tbl_dict_casesystype, 
                 col_casetyperesolutioncode
                )
                VALUES 
                ((SELECT col_id FROM tbl_dict_casesystype WHERE col_code = v_case_code ), 
                (SELECT col_id FROM tbl_stp_resolutioncode WHERE col_code = v_resolution_code AND col_type =  'CASE')
                 );

              END IF;

      END IF;  

END LOOP;


END;

  p_util_update_log ( XmlIdLog => XmlId, Message => 'Merged TBL_CASESYSTYPERESOLUTIONCODE with '||v_count||' rows', IsError => 0); 
 
EXCEPTION 
  WHEN OTHERS THEN 
   p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 


IF  v_input.existsnode('/CaseType/Tags') = 1 THEN
 
 v_result := f_UTIL_importTagXMLfn (XmlId =>  XmlId);
 
END IF;


END IF;    




IF XmlId IS NOT NULL THEN 
   BEGIN 
     SELECT col_error_cnt 
     INTO v_cnt
     FROM tbl_importXML
     WHERE col_id = XmlId;

     
     IF  nvl(v_cnt,0) = 0 THEN
         p_util_update_log ( XmlIdLog => XmlId, Message => 'END Load SUCCESSFULLY', IsError => 0,import_status => 'SUCCESS');       
     ELSE 
         p_util_update_log ( XmlIdLog => XmlId, Message => 'END Load with ERROR', IsError => 0,import_status => 'LOADED WITH ERROR');       
     END IF;

   END;

END IF;

 COMMIT;
 
CASE WHEN v_dict = 0 and nvl(v_cnt,0) = 0 THEN 
     v_result := 'Case Type was imported successfully';
     WHEN v_dict = 1 and nvl(v_cnt,0) = 0 THEN 
     v_result := 'Case Type and Dictionary were successfully imported'; 
     WHEN v_dict = 2 and nvl(v_cnt,0) = 0 THEN 
     v_result := 'Dictionary was successfully imported';
     WHEN v_dict = 0 and nvl(v_cnt,0) > 0 THEN
        v_result := 'Case Type was imported with error';
     WHEN v_dict = 1 and nvl(v_cnt,0) > 0 THEN    
     v_result := 'Case Type and Dictionary were imported with error'; 
     WHEN v_dict = 2 and nvl(v_cnt,0) > 0 THEN 
     v_result := 'Dictionary was imported with error';        
     ELSE 
       v_result := '';
 END CASE; 
DBMS_SESSION.SET_CONTEXT('CLIENTCONTEXT', 'AccessSubject', v_username);


IF v_mdmModelId != 0 THEN 
  INSERT INTO queue_event
    (code, domainid, 
    createdby, createddate, 
    owner, scheduleddate, objecttype, 
    processedstatus, priority, objectcode, 
    PARAMETERS)
  VALUES
    (Sys_guid(), 
    (SELECT col_value FROM tbl_config WHERE col_name = 'TOKEN_DOMAIN' ), 
    v_username, SYSDATE, 
    v_username, SYSDATE, 
  --  1, 1, 100, 'root_DOM_saveDomModelById_cs', 
      1, 1, 100, 'root_MDM_saveAppBaseObjects',
    '[{"Name":"ModelId","Value":"'||v_mdmModelId||'"}]');
 END IF;   
 
 return v_result;


EXCEPTION
  WHEN OTHERS THEN
 ROLLBACK;
   p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1,import_status => 'FAILURE' );

DBMS_SESSION.SET_CONTEXT('CLIENTCONTEXT', 'AccessSubject', v_username);
 
 RETURN dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;



END;