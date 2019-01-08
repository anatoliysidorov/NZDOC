DECLARE 
v_dictionary      XMLTYPE;
v_xmlresult       XMLTYPE;
v_xmlresult2                   xmltype;
v_xmlresult3                   xmltype;
v_path            NVARCHAR2(255);
v_path_tmp        NVARCHAR2(255);
v_count           PLS_INTEGER;
v_cnt             PLS_INTEGER;
v_clob            NCLOB := empty_clob();
v_error           NVARCHAR2(32000);
XmlId			  NUMBER;
BEGIN

v_dictionary := XML_DICT;
XmlId := Xml_Id;
v_xmlresult := v_dictionary.extract('/Dictionary');

/**********************************************************************************/
--Extracting TBL_DICT_ACCESSTYPE
/**********************************************************************************/
BEGIN



    v_xmlresult := v_dictionary.extract('/Dictionary/DictAccessType');
/*
DELETE FROM TBL_DICT_ACCESSTYPE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictAccessType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_ACCESSTYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/    
MERGE INTO TBL_DICT_ACCESSTYPE
USING(
SELECT Code, Name_, Owner
            FROM XMLTABLE('DictAccessType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner'
                       )
               )
ON (col_code = Code)
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner )
  VALUES (Code, Name_, Owner);
  
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_ACCESSTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/**********************************************************************************/
--Extracting TBL_DICT_ACTIONTYPE
/**********************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/DictActionType'); 
 /*
DELETE FROM TBL_DICT_ACTIONTYPE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictActionType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and  col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_ACTIONTYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
MERGE INTO TBL_DICT_ACTIONTYPE
USING(
SELECT Code, Name_, Owner, ProcessorCode, Descr, SlaProcessorCode, MSProcessorCode,
IsCaseType, IsDocType, IsParty, IsProcedure, IsTaskType, 
(SELECT col_id FROM tbl_dict_taskeventtype WHERE col_code = TaskEventType )TaskEventType
            FROM XMLTABLE('DictActionType'
              PASSING v_xmlresult
              COLUMNS
                       Code varchar2(255) PATH './Code',
                       Name_ varchar2(255) PATH './Name',
                       Owner VARCHAR2(255) PATH './Owner',
                       Descr VARCHAR2(255) PATH './Description',
                       ProcessorCode VARCHAR2(255) PATH './ProcessorCode',
                       SlaProcessorCode VARCHAR2(255) PATH './SlaProcessorCode',
                       MSProcessorCode VARCHAR2(255) PATH './MSProcessorCode',
                       IsCaseType NUMBER PATH './IsCaseType',
                       IsDocType NUMBER PATH './IsDocType',
                       IsParty NUMBER PATH './IsParty',
                       IsProcedure NUMBER PATH './IsProcedure',
                       IsTaskType NUMBER PATH './IsTaskType',
                       TaskEventType VARCHAR2(255) PATH './TaskEventType'
                        )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner, COL_PROCESSORCODE = ProcessorCode, 
  col_description = Descr, col_SlaProcessorCode = SlaProcessorCode,
  col_msprocessorcode = MSProcessorCode,
	col_iscasetype = IsCaseType, col_isdoctype = IsDocType, col_isparty = IsParty, 
	col_isprocedure = IsProcedure, col_istasktype = IsTaskType,
    col_actiontype_taskeventtype = TaskEventType
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, COL_PROCESSORCODE, col_description, col_SlaProcessorCode, col_msprocessorcode,
          col_iscasetype, col_isdoctype, col_isparty, col_isprocedure, col_istasktype,
          col_actiontype_taskeventtype)
  VALUES (Code, Name_, Owner, ProcessorCode, Descr, SlaProcessorCode, MSProcessorCode,
          IsCaseType, IsDocType, IsParty, IsProcedure, IsTaskType,
          TaskEventType);
  
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_ACTIONTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- TBL_DICT_STATECONFIGTYPE
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/DictStateConfigType'); 
/*										
DELETE FROM TBL_DICT_STATECONFIGTYPE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictStateConfigType'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = ucode);

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from DictStateConfigType '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;*/
 
 MERGE INTO TBL_DICT_STATECONFIGTYPE
 USING( SELECT  *
            FROM XMLTABLE('DictStateConfigType'
              PASSING v_xmlresult
              COLUMNS
                       Ucode  NVARCHAR2(255) PATH './Ucode',
                       Code  NVARCHAR2(255) PATH './Code',
                       Name  NVARCHAR2(255) PATH './Name',
                       Description  NCLOB PATH './Description' 
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN UPDATE 
	  SET col_code = Code, col_description = Description, col_name = Name
      WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code, col_description, col_name)
  VALUES (Ucode, Code, Description, Name )
  LOG ERRORS INTO er$DICT_STATECONFIGTYPE ('IMPOTR') REJECT LIMIT 5; 
   
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Inserted into TBL_DICT_STATECONFIGTYPE '||SQL%ROWCOUNT||' rows', IsError => 0);  

  FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_ucode  FROM er$DICT_STATECONFIGTYPE d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_DICT_STATECONFIGTYPE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'UCODE = '||rec.col_ucode, IsError => 1);	
  END LOOP;	
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/**********************************************************************************/
--Extracting TBL_DICT_BUSINESSOBJECT
/**********************************************************************************/
BEGIN
  v_xmlresult := v_dictionary.extract('/Dictionary/DictBusinessObject'); 
/*
DELETE FROM TBL_DICT_BUSINESSOBJECT 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictBusinessObject'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_BUSINESSOBJECT '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
MERGE INTO TBL_DICT_BUSINESSOBJECT
USING(
SELECT Code, Name_, Owner, IsDeleted
            FROM XMLTABLE('DictBusinessObject'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       IsDeleted NUMBER PATH './IsDeleted'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner, col_isdeleted = IsDeleted
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, col_isdeleted )
  VALUES (Code, Name_, Owner, IsDeleted);
  
    p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_BUSINESSOBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0);
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/**********************************************************************************/
--Extracting TBL_DICT_DATATYPE
/**********************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/DictDataType'); 
/*
DELETE FROM TBL_DICT_DATATYPE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictDataType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_DATATYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
 */  
MERGE  INTO TBL_DICT_DATATYPE
USING(
SELECT Code, Name_, Owner, IsDeleted, Descr, IconCode, SearchType, DOrder,
TypeCode, Processorcode,
(select col_id from TBL_DICT_DATATYPE where col_code = Parentdatatype) Parentdatatype
            FROM XMLTABLE('DictDataType'
              PASSING v_xmlresult
              COLUMNS
                       Code varchar2(255) PATH './Code',
                       Name_ varchar2(255) PATH './Name',
                       Owner VARCHAR2(255) PATH './Owner',
                       IsDeleted NUMBER PATH './IsDeleted',
                       Descr NCLOB PATH './Description',
                       IconCode  VARCHAR2(255) PATH './IconCode',
                       SearchType  VARCHAR2(255) PATH './SearchType',
                       DOrder  VARCHAR2(255) PATH './DOrder',
                       TypeCode  VARCHAR2(255) PATH './TypeCode',
                       Processorcode VARCHAR2(255) PATH './Processorcode',
                       Parentdatatype VARCHAR2(255) PATH './Parentdatatype'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner, col_isdeleted = IsDeleted,
  col_description = Descr, col_iconcode = IconCode, col_searchtype = SearchType, 
	col_dorder = DOrder, col_typecode = TypeCode, col_processorcode = Processorcode,
    col_datatypeparentdatatype = Parentdatatype
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')  
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, col_isdeleted, col_description,
	col_iconcode, col_searchtype, col_dorder, col_typecode, col_processorcode, col_datatypeparentdatatype  )
  VALUES (Code, Name_, Owner, IsDeleted, Descr,
	IconCode, SearchType, DOrder, TypeCode, Processorcode, Parentdatatype);

    p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_DATATYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);
      
MERGE  INTO TBL_DICT_DATATYPE
USING(
SELECT Code, (select col_id from TBL_DICT_DATATYPE where col_code = Parentdatatype) Parentdatatype
            FROM XMLTABLE('DictDataType'
              PASSING v_xmlresult
              COLUMNS
                       Code varchar2(255) PATH './Code',
                       Parentdatatype VARCHAR2(255) PATH './Parentdatatype'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_datatypeparentdatatype = Parentdatatype
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/**********************************************************************************/
--Extracting tbl_dict_documenttype
/**********************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/DictDocumentType'); 
 /*
DELETE FROM tbl_dict_documenttype 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictDocumentType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code);
 
    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_DOCUMENTTYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
v_cnt := f_util_softDelete(InputTableName =>'TBL_DICT_DOCUMENTTYPE',
                  partOfXml =>  v_xmlresult,
                  fieldMerge => 'code',
                  xmlID => XmlId,
                  tagName => 'DictDocumentType');
                  
MERGE INTO tbl_dict_documenttype
USING(
SELECT Code, Name_, Owner, IsDeleted, Description
            FROM XMLTABLE('DictDocumentType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       IsDeleted NUMBER PATH './IsDeleted',
                       Description NCLOB PATH './Description'
                  )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner, col_isdeleted = IsDeleted, col_description = Description
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, col_isdeleted, col_description )
  VALUES (Code, Name_, Owner, IsDeleted, Description)
  LOG ERRORS INTO er$dict_documenttype ('IMPOTR') REJECT LIMIT 5;

    p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_DOCUMENTTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);
    
    FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$dict_documenttype d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_DICT_DOCUMENTTYPE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
	END LOOP;
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/**********************************************************************************/
--Extracting tbl_dict_exportcontenttype
/**********************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/DictExportContentType'); 
/*
DELETE FROM tbl_dict_exportcontenttype 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictExportContentType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_EXPORTCONTENTTYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/  
MERGE INTO tbl_dict_exportcontenttype
USING(
SELECT Code, Name_, Owner
            FROM XMLTABLE('DictExportContentType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner'
                       )
               )
ON (col_code = Code)
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner
 WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT') 
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner )
  VALUES (Code, Name_, Owner);
  
   p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_EXPORTCONTENTTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);
   
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/**********************************************************************************/
--Extracting TBL_DICT_ITEMTYPE
/**********************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/DictItemType'); 
/*
DELETE FROM TBL_DICT_ITEMTYPE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictItemType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_ITEMTYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
MERGE INTO TBL_DICT_ITEMTYPE
USING(
SELECT Code, Name_, Owner
            FROM XMLTABLE('DictItemType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner
WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')  
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner )
  VALUES (Code, Name_, Owner);
  
     p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_ITEMTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);
     
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/**********************************************************************************/
--Extracting TBL_DICT_NOTIFICATIONOBJECT
/**********************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/DictNotificationObject'); 
/*
DELETE FROM TBL_DICT_NOTIFICATIONOBJECT 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictNotificationObject'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_NOTIFICATIONOBJECT '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
MERGE INTO TBL_DICT_NOTIFICATIONOBJECT
USING(
SELECT Code, Name_, Owner
            FROM XMLTABLE('DictNotificationObject'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner
WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')  
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner )
  VALUES (Code, Name_, Owner);

     p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_NOTIFICATIONOBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0);
       
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/**********************************************************************************/
--Extracting TBL_DICT_MESSAGETYPE
/**********************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/MessageType'); 
/*   
DELETE FROM TBL_DICT_MESSAGETYPE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('MessageType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_MESSAGETYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;   
*/

MERGE  INTO TBL_DICT_MESSAGETYPE
USING(
SELECT Code, Name_, Owner, ColorTheme, Descr
            FROM XMLTABLE('MessageType'
              PASSING v_xmlresult
              COLUMNS
                       Code varchar2(255) PATH './Code',
                       Name_ varchar2(255) PATH './Name',
                       Owner VARCHAR2(255) PATH './Owner',
                       ColorTheme VARCHAR2(255) PATH './ColorTheme',
                       Descr NCLOB PATH './Description' 
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner, col_colortheme = ColorTheme,
  col_description = Descr
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, col_colortheme , col_description )
  VALUES (Code, Name_, Owner, ColorTheme, Descr)
  LOG ERRORS INTO er$DICT_MESSAGETYPE ('IMPOTR') REJECT LIMIT 5;
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_MESSAGETYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
  	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$DICT_MESSAGETYPE d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_DICT_MESSAGETYPE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
	END LOOP;	
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/******************************************************************************/
--TBL_MESSAGE
/******************************************************************************/
 BEGIN 
 v_xmlresult := v_dictionary.extract('/Dictionary/Message');
/*
DELETE FROM TBL_MESSAGE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('Message'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code);

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_MESSAGE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/

   MERGE INTO TBL_MESSAGE
   USING (
   SELECT Code, Template, Description,
   (SELECT col_id FROM tbl_dict_messagetype WHERE col_code = MessageType ) MessageType
            FROM XMLTABLE('Message'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Template NCLOB PATH './Template',
                       Description NCLOB PATH './Description',
                       MessageType NVARCHAR2(255) PATH './MessageType'
                       )
)
   ON (lower(col_code) = lower(Code))
   WHEN MATCHED THEN
     UPDATE  SET  col_description = Description, col_template  = Template, col_messagetypemessage = MessageType
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
     WHEN NOT MATCHED THEN
       INSERT (col_code, col_description, col_template, col_messagetypemessage  )
       VALUES (Code,Description, Template , MessageType)
       LOG ERRORS INTO er$MESSAGE ('IMPOTR') REJECT LIMIT 5;
       
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_MESSAGE with '||SQL%ROWCOUNT||' rows', IsError => 0);

  	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$MESSAGE d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_MESSAGE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
	END LOOP;	
      
EXCEPTION 
  WHEN OTHERS THEN 

  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;     

/**********************************************************************************/
--Extracting tbl_dict_notificationtype
/**********************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/DictNotificationType'); 
 /*
DELETE FROM tbl_dict_notificationtype 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictNotificationType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_NOTIFICATIONTYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
MERGE INTO tbl_dict_notificationtype
USING(
SELECT Code, Name_, Owner, 
(SELECT col_id FROM TBL_DICT_NOTIFICATIONOBJECT WHERE lower(col_code) =lower(NotificationObject) ) notifictypenotifobject,
(SELECT col_id FROM tbl_message WHERE col_code = Message ) Message
            FROM XMLTABLE('DictNotificationType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       NotificationObject NVARCHAR2(255) PATH './NotificationObject',
                       Message NVARCHAR2(255) PATH './Message'
                       )
               )
ON (lower(col_code) = lower(Code) AND col_notifictypenotifobject = notifictypenotifobject)
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner, 
  col_notificationtypemessage = Message
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner , col_notifictypenotifobject, col_notificationtypemessage)
  VALUES (Code, Name_, Owner , notifictypenotifobject, Message);
  
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_NOTIFICATIONTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);
      
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/**********************************************************************************/
--Extracting TBL_DICT_OPERATION
/**********************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/DictOperation'); 
/*
DELETE FROM TBL_DICT_OPERATION 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictOperation'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_OPERATION '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
MERGE INTO TBL_DICT_OPERATION
USING(
SELECT Code, Name_, Owner
            FROM XMLTABLE('DictOperation'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner'
                       )
               )
ON (col_code = Code)
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner )
  VALUES (Code, Name_, Owner);

  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_OPERATION with '||SQL%ROWCOUNT||' rows', IsError => 0);
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/**********************************************************************************/
--Extracting TBL_DICT_PROCESSINGSTATUS
/**********************************************************************************/
 BEGIN
  v_xmlresult := v_dictionary.extract('/Dictionary/DictProcessingStatus'); 
/*  
DELETE FROM TBL_DICT_PROCESSINGSTATUS 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictProcessingStatus'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_PROCESSINGSTATUS '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
 */ 
MERGE INTO TBL_DICT_PROCESSINGSTATUS
USING(
SELECT Code, Name_, Owner
            FROM XMLTABLE('DictProcessingStatus'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner
WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')  
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner )
  VALUES (Code, Name_, Owner);

  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_PROCESSINGSTATUS with '||SQL%ROWCOUNT||' rows', IsError => 0);
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/**********************************************************************************/
--Extracting TBL_DICT_WORKACTIVITYTYPE
/**********************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/DictWorkActivityType'); 

/*DELETE FROM TBL_DICT_WORKACTIVITYTYPE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictWorkActivityType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code);

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_WORKACTIVITYTYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
 
MERGE INTO TBL_DICT_WORKACTIVITYTYPE
USING(
SELECT Code, Name_, Owner, IsDeleted, Description,  IconCode
            FROM XMLTABLE('DictWorkActivityType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       IsDeleted NUMBER PATH './IsDeleted',
                       Description NCLOB PATH './Description',
                       IconCode  NVARCHAR2(255) PATH './IconCode'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner, col_isdeleted = IsDeleted, col_description = Description ,col_iconcode =  IconCode
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, col_isdeleted, col_description, col_iconcode )
  VALUES (Code, Name_, Owner, IsDeleted, Description,  IconCode)
  LOG ERRORS INTO er$DICT_WORKACTIVITYTYPE ('IMPOTR') REJECT LIMIT 5;
  
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_WORKACTIVITYTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);
    
  	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$DICT_WORKACTIVITYTYPE d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_DICT_WORKACTIVITYTYPE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
	END LOOP;	    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/**********************************************************************************/
--Extracting TBL_DICT_TASKEVENTSYNCTYPE
/**********************************************************************************/
 BEGIN
  v_xmlresult := v_dictionary.extract('/Dictionary/DictTaskEventSyncType'); 
/*  
DELETE FROM TBL_DICT_TASKEVENTSYNCTYPE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictTaskEventSyncType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code);

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_TASKEVENTSYNCTYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
 */
MERGE INTO TBL_DICT_TASKEVENTSYNCTYPE
USING(
SELECT Code, Name_, Owner
            FROM XMLTABLE('DictTaskEventSyncType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner )
  VALUES (Code, Name_, Owner);

  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_TASKEVENTSYNCTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/**********************************************************************************/
--Extracting tbl_dict_tagtype
/**********************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/DictTagType'); 
/*
DELETE FROM tbl_dict_tagtype 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictTagType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code);

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_TAGTYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
MERGE INTO tbl_dict_tagtype
USING(
SELECT Code, Name_, Owner
            FROM XMLTABLE('DictTagType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner )
  VALUES (Code, Name_, Owner);

  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_TAGTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/**********************************************************************************/
--Extracting tbl_dict_tag
/**********************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/DictTag'); 
/*   
DELETE FROM tbl_dict_tag 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictTag'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code);

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_TAG '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/  
MERGE INTO tbl_dict_tag
USING(
SELECT Code, Name_, Owner, 
(SELECT col_id FROM tbl_dict_tagtype WHERE lower(col_code) = lower(TagType)) TagType
            FROM XMLTABLE('DictTag'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       TagType NVARCHAR2(255) PATH './TagType'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner, col_dict_tagdict_tagtype = TagType
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, col_dict_tagdict_tagtype )
  VALUES (Code, Name_, Owner, TagType);

  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_TAG with '||SQL%ROWCOUNT||' rows', IsError => 0);
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- tbl_dict_stateconfig
/***************************************************************************************************/       
BEGIN
  
v_xmlresult := v_dictionary.extract('/Dictionary/StateConfigs');
v_clob := v_dictionary.getClobVal();
/*    
DELETE FROM tbl_dict_stateconfig 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('StateConfigs'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
AND col_isdefault = 1;
*/

    MERGE INTO tbl_dict_stateconfig t
    USING (
    SELECT t1.*,
    f_util_extract_clob_from_xml(Input => v_clob ,Path => '/Dictionary/StateConfigs['||t1.rn||']/Config/text()') Config,
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
       VersionID, CaseTypeId)
       LOG ERRORS INTO er$dict_stateconfig ('IMPOTR') REJECT LIMIT 5;
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_STATECONFIG with '||SQL%ROWCOUNT||' rows', IsError => 0);       

  	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$dict_stateconfig d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_DICT_STATECONFIG '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
	END LOOP;
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

   /**********************************************************************************/
   --Extracting tbl_dict_casestate
   /**********************************************************************************/
BEGIN
  
--DEFAULT case states
 v_xmlresult := v_dictionary.extract('/Dictionary/CaseState'); 

/*
DELETE FROM tbl_dict_casestate 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('CaseState'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = Ucode)
and 
(col_stateconfigcasestate is null
or 
col_stateconfigcasestate in (select col_id from tbl_dict_stateconfig where col_code = 'DEFAULT_CASE')
);


    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_CASESTATE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/

   MERGE INTO tbl_dict_casestate
   USING (
   SELECT Code, Activity, Name, DefaultOrder, Description, IsAssign, IsDefaultonCreate, IsDefaultonCreate2,
          IsDeleted, IsFinish, IsFix, IsHidden, IsResolve, IsStart,  Ucode, Theme,
          (SELECT col_id FROM tbl_dict_stateconfig WHERE lower(col_code) = lower(Config)) Config
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
                       Theme        NVARCHAR2(255) PATH './Theme'
                       )

   )
   ON (col_ucode = Ucode )
   WHEN MATCHED THEN
     UPDATE  SET col_activity = Activity, col_description = Description,  col_isdeleted = IsDeleted,
     col_name = Name, col_defaultorder = DefaultOrder,
     col_isassign = IsAssign, col_isdefaultoncreate = IsDefaultonCreate, col_isdefaultoncreate2 = IsDefaultonCreate2,
     col_isfinish = IsFinish, col_isfix = IsFix,
     col_ishidden = IsHidden, col_isresolve = IsResolve, col_isstart = IsStart,  
     col_code = code, col_stateconfigcasestate = Config, col_theme = Theme
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
   WHEN NOT MATCHED THEN
     INSERT
     (col_activity,  col_code, col_description, col_isdeleted, col_name,
      col_isassign, col_isdefaultoncreate, col_isdefaultoncreate2, col_isfinish, 
      col_isfix, col_ishidden, col_isresolve, col_isstart ,  
      col_ucode , col_defaultorder, col_stateconfigcasestate,
      col_theme)
     VALUES
     (Activity, Code,  Description, IsDeleted, Name,
     IsAssign, IsDefaultonCreate, IsDefaultonCreate2, IsFinish, 
     IsFix,  IsHidden, IsResolve, IsStart,  
     Ucode, DefaultOrder, Config,
     Theme)
     LOG ERRORS INTO er$dict_casestate ('IMPOTR') REJECT LIMIT 5;

  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_CASESTATE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
  	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_ucode  FROM er$dict_casestate d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_DICT_CASESTATE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'UCODE = '||rec.col_ucode, IsError => 1);	
    END LOOP;
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/**********************************************************************************/
--Extracting tbl_dict_taskstate
/**********************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/TaskState'); 
--Default task states
/*
DELETE FROM tbl_dict_taskstate 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('TaskState'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = Ucode)
and 
(col_stateconfigtaskstate is null
or 
col_stateconfigtaskstate in (select col_id from tbl_dict_stateconfig where col_code = 'DEFAULT_TASK')
)
and 
;
    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_TASKSTATE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/

v_cnt := f_util_softDelete(InputTableName =>'TBL_DICT_TASKSTATE',
                  partOfXml =>  v_xmlresult,
                  fieldMerge => 'ucode',
                  xmlID => XmlId,
                  tagName => 'TaskState');


    
     MERGE INTO tbl_dict_taskstate
   USING (
      SELECT Code, Activity, Name, CanAssign, DefaultOrder, Description, IsAssign, IsDefaultonCreate,IsDefaultonCreate2,
          IsDeleted, IsFinish, IsHidden, IsResolve, IsStart, dbms_xmlgen.convert(StyleInfo,1) StyleInfo, 
          Ucode, length(dbms_xmlgen.convert(StyleInfo,1)) xmlleng, Iconcode,
          (SELECT col_id FROM tbl_dict_stateconfig WHERE lower(col_code) = lower(Config)) Config
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
                       StyleInfo    NCLOB PATH './StyleInfo',
                       Ucode        NVARCHAR2(255) PATH './Ucode',
                       Config       NVARCHAR2(255) PATH './StateConfig',
                       Iconcode     NVARCHAR2(255) PATH './Iconcode'
                       )
   
   )
   ON (col_ucode = Ucode)
   WHEN MATCHED THEN
     UPDATE  SET col_activity = Activity, col_description = Description,  col_isdeleted = IsDeleted,
     col_name = Name,  col_canassign = CanAssign, col_isassign = IsAssign,
     col_isdefaultoncreate = IsDefaultonCreate, col_isdefaultoncreate2 = IsDefaultonCreate2,
     col_isfinish = IsFinish, col_iconcode = Iconcode, col_isstart = IsStart,
     col_ishidden = IsHidden, col_isresolve = IsResolve, 
     col_defaultorder = DefaultOrder, col_styleinfo =  decode (xmlleng,0 ,NULL,  xmltype(StyleInfo)), col_code = code,
     col_stateconfigtaskstate = Config
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
   WHEN NOT MATCHED THEN
     INSERT
     (col_activity, col_canassign, col_code, col_defaultorder, col_description,
      col_isassign, col_isdefaultoncreate, col_isdefaultoncreate2, col_isdeleted, col_isfinish,
      col_ishidden, col_isresolve, col_isstart, col_name, col_styleinfo , col_ucode, col_stateconfigtaskstate ,col_iconcode  )
     VALUES
     (Activity, CanAssign, Code,  DefaultOrder, Description,
      IsAssign, IsDefaultonCreate, IsDefaultonCreate2, IsDeleted, IsFinish,
      IsHidden, IsResolve,  IsStart,  Name,  decode(xmlleng,0 ,NULL,  xmltype(StyleInfo)), Ucode, Config, Iconcode )
      ;
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_TASKSTATE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
        
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/*****************************************************************************************/
--TBL_DICT_INITMETHOD
/*****************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/InitMetod'); 
/*
DELETE FROM TBL_DICT_INITMETHOD 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('InitMetod'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

*/
MERGE INTO TBL_DICT_INITMETHOD
USING
(
SELECT Code, Name,  Description
            FROM XMLTABLE('InitMetod'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name nvarchar2(255) PATH './Name',
                       Description NCLOB PATH './Description'
                       )

)
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN UPDATE
  SET  col_name =  Name, col_description = Description
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT
 ( col_code, col_name, col_description)
VALUES
 (Code, Name, Description);
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_INITMETHOD with '||SQL%ROWCOUNT||' rows', IsError => 0);  
 
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/*************************************************************/
--EXTRACTING Resolution codes
/*************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/ResolutionCode'); 

v_cnt := f_util_softDelete(InputTableName =>'TBL_STP_RESOLUTIONCODE',
                  partOfXml =>  v_xmlresult,
                  fieldMerge => 'code',
                  xmlID => XmlId,
                  tagName => 'ResolutionCode');
                  
   
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
        col_ucode = ucode, col_iconcode = IconCode ,col_theme = Theme 
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
/******************************************************************************/
--tbl_dict_slaeventtype
/******************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/SlaEventType'); 
/*
DELETE FROM TBL_DICT_SLAEVENTTYPE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('SlaEventType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_SLAEVENTTYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/

 MERGE INTO tbl_dict_slaeventtype
USING
(SELECT Code, Name, Description, IsDeleted, IntervalDS, IntervalYM
            FROM XMLTABLE('SlaEventType'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       IntervalDS NVARCHAR2(255) PATH './IntervalDS',
                       IntervalYM NVARCHAR2(255) PATH './IntervalYM',
                       Description NCLOB PATH './Description',
                       IsDeleted NUMBER PATH './IsDeleted'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN UPDATE
  SET  col_description = Description, col_isdeleted = IsDeleted, col_name = Name,
  col_intervalds  = IntervalDS, col_intervalym  = IntervalYM
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT
 ( col_code, col_name , col_description, col_isdeleted, col_intervalds , col_intervalym   )
VALUES
 (Code, Name,  Description, IsDeleted, IntervalDS, IntervalYM);
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_SLAEVENTTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
 
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/******************************************************************************/
--tbl_dict_slaeventlevel
/******************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/SlaEventLevel'); 
/*
DELETE FROM tbl_dict_slaeventlevel 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('SlaEventLevel'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from tbl_dict_slaeventlevel '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;

*/
 MERGE INTO tbl_dict_slaeventlevel
USING(
SELECT Code, Name, IsDeleted, Description
            FROM XMLTABLE('SlaEventLevel'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name nvarchar2(255) PATH './Name',
                       IsDeleted NUMBER PATH './IsDeleted',
                       Description NCLOB PATH './Description'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name,  col_isdeleted = IsDeleted, col_description = Description
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name,  col_isdeleted, col_description )
  VALUES (Code, Name,  IsDeleted, Description);
        
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_SLAEVENTLEVEL with '||SQL%ROWCOUNT||' rows', IsError => 0);  
 
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
 /***************************************************************************************************/
 -- tbl_dict_tasktransition
 /***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/TaskTransition');  


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
   ON (lower(col_code) = lower(Code) 
   AND col_sourcetasktranstaskstate = CodeSourceId 
	 AND col_targettasktranstaskstate = CodeTargetId )
   WHEN MATCHED THEN
     UPDATE  SET  col_description = Description,  col_manualonly = ManualOnly,
     col_name = Name, col_transition = Transition, col_ucode = Ucode,
     col_iconcode = IconCode
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
  WHEN NOT MATCHED THEN
    INSERT (col_code, col_description, col_manualonly, col_name, col_transition, 
    col_sourcetasktranstaskstate, col_targettasktranstaskstate, col_ucode,
    col_iconcode)
    VALUES (Code, Description, ManualOnly, Name, Transition, 
    CodeSourceId, CodeTargetId, Ucode,
    IconCode);
    
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_TASKTRANSITION with '||SQL%ROWCOUNT||' rows', IsError => 0);  
     
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END; 
   /***************************************************************************************************/
 -- TBL_FOM_UIELEMENTTYPE
 /***************************************************************************************************/
 BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/FomUielementType'); 
   MERGE INTO TBL_FOM_UIELEMENTTYPE
   USING(
      SELECT Code, Name
                  FROM XMLTABLE('FomUielementType'
                    PASSING v_xmlresult
                    COLUMNS
                             Code nvarchar2(255) PATH './Code',
                             Name nvarchar2(255) PATH './Name'
                             )
      )
   ON (col_code = Code)
   WHEN MATCHED THEN UPDATE
      SET  col_name = Name
      WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
   WHEN NOT MATCHED THEN
      INSERT
       ( col_code,  col_name)
      VALUES
       (Code, Name);
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_FOM_UIELEMENTTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
        
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;       
/***************************************************************************************************/
 -- tbl_STP_PRIORITY
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/STPPriority'); 

/*DELETE FROM tbl_STP_PRIORITY 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('STPPriority'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code);

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from tbl_STP_PRIORITY '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
 
 MERGE INTO tbl_STP_PRIORITY
USING
(SELECT Code, IsDeleted, Description, Icon, Name, IconCode, IconName, IsDefault, Value 
          FROM XMLTABLE('STPPriority'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       IsDeleted NUMBER PATH './IsDeleted',
                       Description NCLOB PATH './Description',
                       Icon NVARCHAR2(255) PATH './Icon',
                       IconCode NVARCHAR2(255) PATH './IconCode',
                       IconName NVARCHAR2(255) PATH './IconName',
                       IsDefault NUMBER PATH './IsDefault',
                       Value NUMBER(10,2) PATH './Value')
)
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN UPDATE
  SET col_name = Name, col_description = Description,  col_icon = Icon,
  col_iconcode = IconCode,  col_iconname = IconName , col_isdefault = IsDefault,
  col_value = Value,  col_isdeleted = IsDeleted
 WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT
 ( col_code, col_name ,col_description,  col_icon,  col_iconcode,  col_iconname, col_isdefault , col_value,  col_isdeleted  )
VALUES
 (Code, Name, Description, Icon, IconCode, IconName, IsDefault, Value, IsDeleted)
 LOG ERRORS INTO er$STP_PRIORITY ('IMPOTR') REJECT LIMIT 5;
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_STP_PRIORITY with '||SQL%ROWCOUNT||' rows', IsError => 0);  

  	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$STP_PRIORITY d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into tbl_STP_PRIORITY '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
	END LOOP;
      
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
   /***************************************************************************************************/
 -- tbl_dict_participanttype
 /***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/ParticipantType'); 
/*
DELETE FROM TBL_DICT_PARTICIPANTTYPE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('ParticipantType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_PARTICIPANTTYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
 MERGE INTO tbl_dict_participanttype
 USING(
SELECT Code, Name, Owner,  Description
            FROM XMLTABLE('ParticipantType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       Description NCLOB PATH './Description'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_owner = Owner, col_description = Description
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner,  col_description )
  VALUES (Code, Name, Owner, Description);
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_PARTICIPANTTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
   
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- tbl_DICT_ASSOCPAGETYPE
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/AssocpageType'); 
/*
DELETE FROM tbl_DICT_ASSOCPAGETYPE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('AssocpageType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code);
    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from tbl_DICT_ASSOCPAGETYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;	
*/

 MERGE INTO tbl_DICT_ASSOCPAGETYPE
 USING(
SELECT Code, Name, Owner, Description, AllowMultiple
            FROM XMLTABLE('AssocpageType'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       Description NCLOB PATH './Description',
                       AllowMultiple NUMBER PATH './AllowMultiple' 
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_owner = Owner, col_description = Description, col_allowmultiple = AllowMultiple
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, col_description , col_allowmultiple)
  VALUES (Code, Name, Owner, Description, AllowMultiple)
  LOG ERRORS INTO er$DICT_ASSOCPAGETYPE ('IMPOTR') REJECT LIMIT 5;
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_ASSOCPAGETYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  

  	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$DICT_ASSOCPAGETYPE d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into tbl_DICT_ASSOCPAGETYPE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
	END LOOP; 
      
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
   /***************************************************************************************************/
 -- tbl_dict_partytype
 /***************************************************************************************************/
 BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/PartyType'); 
   
/*DELETE FROM tbl_dict_partytype 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('PartyType'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = Code);

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from tbl_dict_partytype '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/

 MERGE INTO tbl_dict_partytype
USING(
SELECT Code, Name, Owner, IsDeleted, Description, IsSystem, PageCode, DisableManagement,
RetCustDataProcessor, UpdateCustDataProcessor, CustomDataProcessor, DelCustomDataProcessor, 
(SELECT col_id FROM tbl_dict_participanttype WHERE col_code = ParticipantType) ParticipantType,
(SELECT col_id FROM tbl_mdm_model WHERE col_ucode = MDMModel) MDMModel
            FROM XMLTABLE('PartyType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       IsDeleted NUMBER PATH './IsDeleted',
                       Description NCLOB PATH './Description',
                       IsSystem NUMBER PATH './IsSystem',
                       PageCode NVARCHAR2(255) PATH './PageCode',
                       ParticipantType NVARCHAR2(255) PATH './ParticipantType',
                       CustomDataProcessor NVARCHAR2(255) PATH './CustomDataProcessor',
                       DelCustomDataProcessor NVARCHAR2(255) PATH './DelCustomDataProcessor',
                       RetCustDataProcessor NVARCHAR2(255) PATH './RetCustDataProcessor',
                       UpdateCustDataProcessor NVARCHAR2(255) PATH './UpdateCustDataProcessor',
                       DisableManagement NUMBER path './DisableManagement',
                       MDMModel NVARCHAR2(255) PATH './MDMModel'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_owner = Owner, col_isdeleted = IsDeleted, col_description = Description,
  col_issystem = IsSystem, col_pagecode = PageCode, col_partytypeparticiptype =  ParticipantType,
  col_retcustdataprocessor =RetCustDataProcessor ,col_updatecustdataprocessor = UpdateCustDataProcessor, col_customdataprocessor = CustomDataProcessor, 
  col_delcustdataprocessor =DelCustomDataProcessor, col_disablemanagement =  DisableManagement,
  col_partytypemodel = MDMModel
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, col_isdeleted, col_description, col_issystem, col_pagecode, col_partytypeparticiptype,
  col_retcustdataprocessor, col_updatecustdataprocessor, col_customdataprocessor, col_delcustdataprocessor,
  col_disablemanagement, col_partytypemodel 
  )
  VALUES (Code, Name, Owner, IsDeleted, Description, IsSystem,PageCode, ParticipantType,
  RetCustDataProcessor, UpdateCustDataProcessor, CustomDataProcessor,DelCustomDataProcessor,
  DisableManagement, MDMModel)
  LOG ERRORS INTO er$dict_partytype ('IMPOTR') REJECT LIMIT 5;
  
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_PARTYTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  

  	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$dict_partytype d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_DICT_PARTYTYPE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
    END LOOP;
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- tbl_dict_workbaskettype
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/WorkbasketType'); 
 MERGE INTO tbl_dict_workbaskettype
 USING(
SELECT Code, Name_, Owner
            FROM XMLTABLE('WorkbasketType'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name_ NVARCHAR2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner )
  VALUES (Code, Name_, Owner);
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_WORKBASKETTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
   
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/

 -- TBL_PPL_WORKBASKET
/***************************************************************************************************/

 BEGIN
  v_xmlresult := v_dictionary.extract('/Dictionary/WorkBasket');

 MERGE INTO TBL_PPL_WORKBASKET
USING
(SELECT CODE,  Description, IsDefault, IsPrivate, Name_, ProcessorCode,
ProcessorCode2, ProcessorCode3, Ucode,
(SELECT col_id FROM tbl_dict_workbaskettype WHERE lower(col_code) =  lower(WorkbasketType)) WorkbasketType,
(SELECT col_id FROM tbl_ppl_team WHERE col_code = Team) Team,
(SELECT col_id FROM tbl_ppl_businessrole WHERE lower(col_code) = lower(BusinessRole)) BusinessRole
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
ON (col_ucode = uCode)
WHEN MATCHED THEN UPDATE
  SET col_name = NAME_, col_description = Description, col_isdefault = IsDefault,
  col_isprivate = IsPrivate, col_processorcode = ProcessorCode, col_processorcode2 =ProcessorCode2 ,
  col_processorcode3 = ProcessorCode3, col_workbasketworkbaskettype = WorkbasketType ,
   col_workbasketbusinessrole  = BusinessRole, col_workbasketteam = Team,
   col_code = code
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
 
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_PPL_WORKBASKET with '||SQL%ROWCOUNT||' rows', IsError => 0); 

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 

/******************************************************************************/
--tbl_DICT_DATEEVENTTYPE
/******************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/DateEventType'); 

MERGE INTO tbl_DICT_DATEEVENTTYPE
USING
(SELECT Code, Name, CanOverWrite, Description, IsDeleted, IsSlaEnd, IsSlaStart, IsState, 
Multipleallowed, Type, IsCaseMainFlag
            FROM XMLTABLE('DateEventType'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       CanOverWrite NUMBER PATH './CanOverWrite',
                       Description NCLOB PATH './Description',
                       IsDeleted NUMBER PATH './IsDeleted',
                       IsSlaEnd NUMBER PATH './IsSlaEnd',
                       IsSlaStart NUMBER PATH './IsSlaStart',
                       IsState NUMBER PATH './IsSlaState',
                       Multipleallowed NUMBER PATH './Multipleallowed',
                       Type NVARCHAR2(255) PATH './Type',
                       IsCaseMainFlag NUMBER PATH './IsCaseMainFlag'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN UPDATE
  SET  col_description = Description, col_isdeleted = IsDeleted, col_isslaend = IsSlaEnd,
  col_isslastart = IsSlaStart, col_isstate = IsState, col_type = Type, col_multipleallowed = Multipleallowed,
  col_canoverwrite = CanOverWrite, col_name = Name, col_iscasemainflag = IsCaseMainFlag
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT
 ( col_code, col_name , col_description, col_isdeleted, col_isslaend, col_isslastart, col_isstate, 
   col_multipleallowed, col_type , col_canoverwrite, col_iscasemainflag )
VALUES
 (Code, Name,  Description, IsDeleted, IsSlaEnd, IsSlaStart,  IsState , 
   Multipleallowed, Type, CanOverWrite, IsCaseMainFlag);
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_DICT_DATEEVENTTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
 
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/*****************************************************************************************/
--TBL_DICT_TASKEVENTMOMENT
/*****************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/TaskEventMoment'); 
 MERGE INTO TBL_DICT_TASKEVENTMOMENT
USING
     USING (
    SELECT Code, Name
            FROM XMLTABLE('TaskEventMoment'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name'
                       )
)
    ON (lower(col_code) = lower(Code))
    WHEN MATCHED THEN UPDATE  SET
        col_name = Name
        WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
    WHEN NOT MATCHED THEN
    INSERT
    (col_code      , col_name   )
    VALUES
    (Code, Name )
;
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_TASKEVENTMOMENT with '||SQL%ROWCOUNT||' rows', IsError => 0);  
 
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/*****************************************************************************************/
--TBL_DICT_TASKEVENTTYPE
/*****************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/TaskEventType'); 
 MERGE INTO TBL_DICT_TASKEVENTTYPE
     USING (
    SELECT Code, Name
            FROM XMLTABLE('TaskEventType'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name'
                       )
)
    ON (lower(col_code) = lower(Code))
    WHEN MATCHED THEN UPDATE  SET
        col_name = Name
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')   
    WHEN NOT MATCHED THEN
    INSERT
    (col_code      , col_name   )
    VALUES
    (Code, Name )
;
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_TASKEVENTTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  

v_xmlresult := v_dictionary.extract('/Dictionary/DictActionType');   

MERGE INTO TBL_DICT_ACTIONTYPE
USING(
SELECT Code,
(SELECT col_id FROM tbl_dict_taskeventtype WHERE col_code = TaskEventType )TaskEventType
            FROM XMLTABLE('DictActionType'
              PASSING v_xmlresult
              COLUMNS
                       Code varchar2(255) PATH './Code',
                       TaskEventType VARCHAR2(255) PATH './TaskEventType'
                        )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET 
    col_actiontype_taskeventtype = TaskEventType
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
;
 
 
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/******************************************************************************/
--tbl_DICT_VALIDATIONSTATUS
/******************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/ValidationStatus'); 
   
MERGE INTO tbl_DICT_VALIDATIONSTATUS
USING
(
SELECT Code, Description
            FROM XMLTABLE('ValidationStatus'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Description nvarchar2(255) PATH './Description'
                       )
)
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN UPDATE
SET  col_description = Description
WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT
 ( col_code,  col_description)
VALUES
 (Code, Description);
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_DICT_VALIDATIONSTATUS with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/******************************************************************************/
--DependencyType
/******************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/DependencyType'); 
 MERGE INTO TBL_DICT_DEPENDENCYTYPE
    USING (
   SELECT Code, Description, Name
            FROM XMLTABLE('DependencyType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Description nvarchar2(255) PATH './Description',
                       Name NVARCHAR2(255) PATH './Name'
                       )
)
   ON (lower(col_code) = lower(Code))
   WHEN MATCHED THEN
     UPDATE  SET  col_description = Description, col_name = Name
     WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
     WHEN NOT MATCHED THEN
       INSERT (col_code, col_description,  col_name )
       VALUES (Code, Description,  Name );
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_DEPENDENCYTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
 
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/******************************************************************************/
--PatamType
/******************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/PatamType'); 
 MERGE INTO TBL_DICT_PARAMTYPE
 USING(
SELECT Code, ProcessorCode, Name
            FROM XMLTABLE('PatamType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       ProcessorCode nvarchar2(255) PATH './ProcessorCode',
                       Name NVARCHAR2(255) PATH './Name'
                       )
               )
ON (lower(col_code) = lower(Code) and nvl(ProcessorCode,' ') = nvl(col_processorcode,' ') )
WHEN MATCHED THEN
  UPDATE SET col_name = Name 
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_processorcode)
  VALUES (Code, Name, ProcessorCode);
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_PARAMTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
   
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
 /*****************************************************************************************/
--TBL_DICT_EXECUTIONMETHOD
/*****************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/DictExecutionMethod'); 
MERGE INTO TBL_DICT_EXECUTIONMETHOD
USING(
SELECT Code, Name_, Owner, Description, IsDeleted
            FROM XMLTABLE('DictExecutionMethod'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       Description NCLOB PATH './Description',
                       IsDeleted NUMBER PATH './IsDeleted'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner, col_description = Description, col_isdeleted = IsDeleted
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, col_description , col_isdeleted  )
  VALUES (Code, Name_, Owner, Description ,IsDeleted);
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_EXECUTIONMETHOD with '||SQL%ROWCOUNT||' rows', IsError => 0);  
   
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;  
 /*****************************************************************************************/
--TBL_DICT_CASETRANSITION
/*****************************************************************************************/  
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/CaseTransition'); 
 v_xmlresult2 := v_dictionary.extract('/Dictionary/CaseState'); 
 
MERGE INTO  tbl_dict_casetransition
USING (
SELECT Code, Ucode, Transition, Name, Manualonly, Description, IconCode, IsNextDefault, IsPrevDefault,
(SELECT col_id FROM tbl_dict_casestate WHERE col_ucode = CodeSource) CodeSourceId,
(SELECT col_id FROM tbl_dict_casestate WHERE col_ucode = CodeTarget) CodeTargetId,
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
                          
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_CASETRANSITION with '||SQL%ROWCOUNT||' rows', IsError => 0);  
              
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- TBL_DICT_CSEST_DTEVTP
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/CaseStateDateEventType'); 
v_path_tmp := 'count(CaseStateDateEventType)';
   SELECT y.column_value.getstringval()
    INTO v_count
    FROM xmltable(v_path_tmp passing v_xmlresult) y ;

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
    WHERE cst.col_ucode = f_UTIL_extract_value_xml(Input => v_xmlresult, Path =>'CaseStateDateEventType['||i||']/CaseState/text()')
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
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_CSEST_DTEVTP with '||SQL%ROWCOUNT||' rows', IsError => 0);  
 
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/*************************************************************/
 --EXTRACTING TASK TYPES
/*************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/TaskType'); 
   
     MERGE INTO TBL_DICT_TASKSYSTYPE
      USING ( SELECT  Code, Name,  Description, CustomDataProcessor, 
              DateEventCustDataProc, IsDeleted, ProcessorCode, 
              RetCustDataProcessor, UpdateCustDataProcessor, 
              (SELECT col_id FROM tbl_dict_executionmethod WHERE lower(col_code) = lower(TaskSysTypeExecMethod)) TaskSysTypeExecMethod,
              (SELECT col_id FROM tbl_dict_stateconfig WHERE lower(col_code) = lower(StateConfig)) StateConfig,
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
      ON (lower(col_code) = lower(Code))
      WHEN MATCHED THEN
        UPDATE  SET
        col_name = Name , col_description = Description, col_customdataprocessor = CustomDataProcessor,
        col_processorcode = ProcessorCode,   col_retcustdataprocessor = RetCustDataProcessor,
        col_updatecustdataprocessor = UpdateCustDataProcessor, col_tasksystypeexecmethod = TaskSysTypeExecMethod,
        col_isdeleted = IsDeleted, col_stateconfigtasksystype = StateConfig, 
        col_dateeventcustdataproc = DateEventCustDataProc, 
        col_routecustomdataprocessor = RouteCustomDataProcessor, 
        col_iconcode =  IconCode 
        WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
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
         RouteCustomDataProcessor, IconCode)
         LOG ERRORS INTO er$DICT_TASKSYSTYPE ('IMPOTR') REJECT LIMIT 5;
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_TASKSYSTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  

  	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$DICT_TASKSYSTYPE d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_DICT_TASKSYSTYPE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
	END LOOP;
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/***************************************************************************************************/
 -- TBL_TASKSYSTYPERESOLUTIONCODE
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/TaskSysTypeResolutionCode');

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
  JOIN TBL_DICT_TASKSYSTYPE tst ON lower(tst.col_code) = lower(tstrc.TaskType) 
  JOIN tbl_stp_resolutioncode rc ON lower(rc.col_code) = lower(tstrc.ResolutionCode) AND rc.col_type = 'TASK'
)  
ON (col_tbl_stp_resolutioncode = ResolutionCodeId AND col_tbl_dict_tasksystype = TaskTypeId)
WHEN MATCHED THEN UPDATE SET col_code = Code 
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN 
  INSERT (col_tbl_stp_resolutioncode, col_tbl_dict_tasksystype, col_code)
  VALUES (ResolutionCodeId, TaskTypeId, Code);  
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_TASKSYSTYPERESOLUTIONCODE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
   
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- TBL_DICT_TSKST_DTEVTP
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/TaskStateDateEventType'); 
v_path_tmp := 'count(TaskStateDateEventType)';

   SELECT y.column_value.getstringval()
    INTO v_count
    FROM xmltable(v_path_tmp passing v_xmlresult) y ;

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
WHERE cst.col_ucode = f_UTIL_extract_value_xml(Input => v_xmlresult, Path => 'TaskStateDateEventType['||i||']/TaskState/text()');

SELECT col_id
       INTO
       DataEvent
FROM
tbl_dict_dateeventtype det
WHERE det.col_code = f_UTIL_extract_value_xml(Input => v_xmlresult, Path =>'/TaskStateDateEventType['||i||']/DateEventType/text()');


SELECT COUNT(*)
INTO
v_cntt
FROM TBL_DICT_TSKST_DTEVTP detp
WHERE detp.col_tskst_dtevtptaskstate = TaskState
AND detp.col_tskst_dtevtpdateeventtype = DataEvent;


    IF v_cntt = 0 THEN
      INSERT INTO TBL_DICT_TSKST_DTEVTP
      (col_tskst_dtevtptaskstate , col_tskst_dtevtpdateeventtype   )
      VALUES
      (TaskState, DataEvent);
    END IF;

END LOOP;
END;
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_TSKST_DTEVTP with '||SQL%ROWCOUNT||' rows', IsError => 0);  
 
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
-- tbl_FOM_Widget
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/FOMWidget'); 
 MERGE INTO tbl_FOM_Widget
 USING(
SELECT Code, Name, Owner,  IsDeleted, Descriptio, Config, Image, Type, Category
            FROM XMLTABLE('FOMWidget'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       IsDeleted NUMBER PATH './IsDeleted',
                       Descriptio NCLOB PATH './Description',
                       Config NCLOB PATH './Config',
                       Image BLOB PATH './Image',
                       Type NVARCHAR2(255) PATH './Type',
                       Category NVARCHAR2(255) PATH './Category'
                       )
               )
ON (upper(col_code) = upper(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_owner = Owner, col_isdeleted = IsDeleted, 
  col_description = Descriptio, col_config = Config, col_image = Image, col_type = Type, 
  col_category = Category
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, col_isdeleted , col_description,
          col_config, col_image, col_type , col_category    )
  VALUES (Code, Name, Owner, IsDeleted, Descriptio , Config, Image, Type, Category ); 
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_FOM_WIDGET with '||SQL%ROWCOUNT||' rows', IsError => 0);  
     
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
-- tbl_FOM_Dashboard
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/FOMDashboard'); 
 MERGE INTO tbl_FOM_Dashboard
 USING(
SELECT Code, Name, Owner,  IsDeleted, Descriptio, Config, IsSystem, IsDefault
            FROM XMLTABLE('FOMDashboard'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       IsDeleted NUMBER PATH './IsDeleted',
                       Descriptio NCLOB PATH './Description',
                       Config NCLOB PATH './Config',
                       IsSystem NUMBER PATH './IsSystem',
                       IsDefault NUMBER PATH './IsDefault'
                       )
               )
ON (upper(col_code) = upper(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_owner = Owner, col_isdeleted = IsDeleted, 
  col_description = Descriptio, col_config = Config, 
  col_issystem  = IsSystem, col_isdefault  = IsDefault
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, col_isdeleted , col_description,
          col_config, col_issystem, col_isdefault )
  VALUES (Code, Name, Owner, IsDeleted, Descriptio , Config,  IsSystem, IsDefault); 
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_FOM_DASHBOARD with '||SQL%ROWCOUNT||' rows', IsError => 0);  
     
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/***************************************************************************************************/
 -- TBL_FOM_UIELEMENT
/***************************************************************************************************/
BEGIN
  v_xmlresult := v_dictionary.extract('/Dictionary/FomUiElement'); 
  

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
                                                        upper(fom.col_code) IN (SELECT upper(column_value) FROM TABLE(split_casetype_list(FomFormList)))) FomFormList,
      (SELECT listagg(to_char(fom.col_id),',') WITHIN GROUP(ORDER BY fom.col_id) FROM tbl_fom_codedpage fom WHERE 
                                                        upper(fom.col_code) IN (SELECT upper(column_value) FROM TABLE(split_casetype_list(CodedPageList)))) CodedPageList   
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
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_FOM_UIELEMENT with '||SQL%ROWCOUNT||' rows', IsError => 0);  
       
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
   ON (lower(col_code) = lower(Code))
   WHEN MATCHED THEN
      UPDATE  SET col_parentid = ParentCode;
      
 EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;     
/***************************************************************************************************/
 -- tbl_DICT_TASKSTATESETUP
/***************************************************************************************************/      
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/TaskStateSetup');

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
                       NotNullOverWrite   NUMBER PATH './NotNullOverWrite',
                       NullOverWrite NUMBER PATH './NullOverWrite',
                       Ucode         NVARCHAR2(255) PATH './Ucode',
                       CaseConfig    NVARCHAR2(255) PATH './CaseConfig',
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
     
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_DICT_TASKSTATESETUP with '||SQL%ROWCOUNT||' rows', IsError => 0);  
      
  EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;    
/***************************************************************************************************/
 -- tbl_dict_CASESTATESETUP
/***************************************************************************************************/      
BEGIN
  
v_xmlresult := v_dictionary.extract('/Dictionary/CaseStateSetup');
v_xmlresult2 := v_dictionary.extract('/Dictionary/CaseState');   

   MERGE INTO tbl_dict_CASESTATESETUP
   USING (
SELECT 
  (SELECT col_id FROM tbl_dict_casestate WHERE col_ucode = tss.CaseState)   casestateId, 
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
                       CaseConfig    NVARCHAR2(255) PATH './CaseConfig',
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
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_CASESTATESETUP with '||SQL%ROWCOUNT||' rows', IsError => 0);  
      
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
 /*****************************************************************************************/
--tbl_DICT_ParticipantUnitType
/*****************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/ParticipantUnitType'); 
MERGE INTO tbl_DICT_ParticipantUnitType
USING(
SELECT Code, Name_, Owner, Description, GetProcessorCode
            FROM XMLTABLE('ParticipantUnitType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       Description NCLOB PATH './Description',
                       GetProcessorCode NVARCHAR2(255) PATH './GetProcessorCode'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner, col_description = Description, col_getprocessorcode = GetProcessorCode
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, col_description , col_getprocessorcode  )
  VALUES (Code, Name_, Owner, Description ,GetProcessorCode);
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_PARTICIPANTUNITTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
   
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
   /***************************************************************************************************/
 -- tbl_ac_accessobjecttype
 /***************************************************************************************************/
BEGIN
    v_xmlresult := v_dictionary.extract('/Dictionary/AccessObjectType');
  
v_cnt := f_util_softDelete(InputTableName =>'TBL_AC_ACCESSOBJECTTYPE',
                  partOfXml =>  v_xmlresult,
                  fieldMerge => 'code',
                  xmlID => XmlId,
                  tagName => 'AccessObjectType');
                  
 MERGE INTO tbl_ac_accessobjecttype
 USING(
SELECT Code, Name, IsDeleted, Description
            FROM XMLTABLE('AccessObjectType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name nvarchar2(255) PATH './Name',
                       IsDeleted NUMBER PATH './IsDeleted',
                        Description NCLOB PATH './Description'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_isdeleted = IsDeleted, col_description = Description
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name,  col_isdeleted, col_description )
  VALUES (Code, Name,  IsDeleted, Description)
  LOG ERRORS INTO er$AC_ACCESSOBJECTTYPE ('IMPOTR') REJECT LIMIT 5;
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_AC_ACCESSOBJECTTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  

    FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$AC_ACCESSOBJECTTYPE d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_AC_ACCESSOBJECTTYPE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
    END LOOP;
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
   /***************************************************************************************************/

 -- TBL_AC_ACCESSSUBJECT
 /***************************************************************************************************/

 BEGIN
    v_xmlresult := v_dictionary.extract('/Dictionary/AccessSubject');
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
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_Type = Type
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_Type )
  VALUES (Code, Name, Type);

 p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_AC_ACCESSSUBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0); 
 
EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END; 

/*****************************************************************************************/
--tbl_DICT_CommonEventType
/*****************************************************************************************/
BEGIN
  v_xmlresult := v_dictionary.extract('/Dictionary/CommonEventType'); 
MERGE INTO tbl_DICT_CommonEventType
USING(
SELECT Code, Name_, Owner, Ucode, Purpose, RepeatingEvent
            FROM XMLTABLE('CommonEventType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name_ nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Purpose NVARCHAR2(255) PATH  './Purpose',
                       RepeatingEvent NUMBER PATH './RepeatingEvent'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_name = Name_, col_owner = Owner, col_code = Code,
  col_purpose = Purpose, col_repeatingevent = RepeatingEvent
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner, col_ucode,  col_purpose, col_repeatingevent)
  VALUES (Code, Name_, Owner, Ucode, Purpose, RepeatingEvent);
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_COMMONEVENTTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
   
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;  
/***************************************************************************************************/
 -- tbl_AC_PERMISSION
/***************************************************************************************************/
 BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/ACPermition');
/*
DELETE FROM tbl_AC_PERMISSION 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('ACPermition'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = Ucode)
and (col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT'))
or col_ucode is null;	 

*/
MERGE INTO tbl_AC_PERMISSION
USING(
SELECT Code, Name,  Description, DefaultACL,OrderACL, Position, Ucode,
(SELECT col_id FROM tbl_ac_accessobjecttype WHERE lower(col_code) = lower(AccessObjectType)) AccessObjectType
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
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_AC_PERMISSION with '||SQL%ROWCOUNT||' rows', IsError => 0);  

    FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$AC_PERMISSION d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into tbl_AC_PERMISSION '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
    END LOOP; 
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
   /***************************************************************************************************/
 -- tbl_AC_ACCESSOBJECT
 /***************************************************************************************************/
BEGIN
     v_xmlresult := v_dictionary.extract('/Dictionary/AccessObject');


 MERGE INTO tbl_AC_ACCESSOBJECT
USING
(SELECT 
         (SELECT col_id FROM tbl_dict_casestate WHERE col_ucode = tss.CaseState) casestateId ,
   tss.*
FROM
(
SELECT
 Code, Name,
 (SELECT col_id FROM tbl_ac_accessobjecttype WHERE lower(col_code) = lower(AccessObjectTypeCode)) AccessObjectTypeCode,
 CaseState, /*default*/
 (SELECT col_id FROM tbl_dict_casesystype WHERE lower(col_code) = lower(CaseTypeCode)) CaseTypeCode,
 (SELECT col_id FROM tbl_dict_tasksystype WHERE lower(col_code) = lower(TaskTypeCode)) TaskTypeCode,
 (SELECT col_id FROM tbl_fom_uielement WHERE lower(col_code) = lower(UserElement)) UserElement,
 (SELECT col_id FROM tbl_dict_casetransition WHERE col_ucode = CaseTransition) CaseTransition,
 (SELECT col_id FROM tbl_dict_accesstype WHERE col_code = AccessTypeCode) AccessTypeCode --index without lower()
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
)
ON (lower(col_code) = lower(Code))
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
 (code, NAME,AccessObjectTypeCode, CaseTransition, AccessTypeCode, casestateId, CaseTypeCode, TaskTypeCode, UserElement)
 LOG ERRORS INTO er$AC_ACCESSOBJECT ('IMPOTR') REJECT LIMIT 5;
 
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged tbl_AC_ACCESSOBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0);  

	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$AC_ACCESSOBJECT d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into tbl_AC_ACCESSOBJECT '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
    END LOOP; 
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- TBL_DICT_PROCEDUREINCASETYPE
/***************************************************************************************************/
BEGIN
  v_xmlresult := v_dictionary.extract('/Dictionary/DictProcedureInCaseType');

MERGE INTO TBL_DICT_PROCEDUREINCASETYPE
USING (SELECT Code, Name,  Owner
            FROM XMLTABLE('DictProcedureInCaseType'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner'
                       )

    ) t2
    ON (t2.Code = col_code) --index without lower()
    WHEN MATCHED THEN
      UPDATE SET col_name = Name,  col_owner  = Owner 
      WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
    WHEN NOT MATCHED THEN
      INSERT
       (col_code , col_name,  col_owner)
      VALUES
       (Code, Name, Owner)
       LOG ERRORS INTO er$DICT_PROCEDUREINCASETYPE ('IMPOTR') REJECT LIMIT 5;
     
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_PROCEDUREINCASETYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  

	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$DICT_PROCEDUREINCASETYPE d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_DICT_PROCEDUREINCASETYPE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
    END LOOP; 
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;       
   /***************************************************************************************************/
 -- tbl_dict_LinkType
 /***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/LinkType'); 
 MERGE INTO tbl_dict_LinkType
 USING(
SELECT Code, Name, Owner,  Description, IsDeleted
            FROM XMLTABLE('LinkType'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       Description NCLOB PATH './Description',
                       IsDeleted NUMBER PATH './IsDeleted'
                       )
               )
ON (upper(col_code) = upper(Code))
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_owner = Owner, col_description = Description,
  col_isdeleted = IsDeleted
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner,  col_description, col_isdeleted )
  VALUES (Code, Name, Owner, Description, IsDeleted)
  LOG ERRORS INTO er$DICT_LINKTYPE ('IMPOTR') REJECT LIMIT 5;   
      
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_LINKTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$DICT_LINKTYPE d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_DICT_LINKTYPE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
    END LOOP;
    
EXCEPTION 
  WHEN OTHERS THEN  
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

   /***************************************************************************************************/
 -- Tbl_Ppl_Orgchart
 /***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/Orgchart'); 

 MERGE INTO Tbl_Ppl_Orgchart
 USING(
SELECT Code, Name, Owner,  IsPrimary, /*Config DCM-5413*/ NULL as Config , Description, 
(SELECT col_id FROM tbl_ppl_team WHERE col_code = Team) Team
            FROM XMLTABLE('Orgchart'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name nvarchar2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner',
                       IsPrimary NUMBER PATH './IsPrimary',
                       Config NCLOB PATH './Config',
                       Description NCLOB PATH './Description',
                       Team NVARCHAR2(255) PATH './Team'
                       )
               )
ON (col_code = Code)
WHEN MATCHED THEN
  UPDATE SET col_name = Name, col_owner = Owner, col_isprimary  = IsPrimary,
         col_config = Config, col_description = Description , col_teamorgchart = Team 
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner,  col_isprimary,
          col_config, col_description, col_teamorgchart   )
  VALUES (Code, Name, Owner, IsPrimary, 
          Config, Description, Team);
          
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_PPL_ORGCHART with '||SQL%ROWCOUNT||' rows', IsError => 0);  
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/***************************************************************************************************/
 -- tbl_LOC_Namespace
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/LocNamespace'); 
  /* 
DELETE FROM tbl_LOC_Namespace 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('LocNamespace'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = Ucode)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');
 
    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_LOC_NAMESPACE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/   
 MERGE INTO tbl_LOC_Namespace
 USING(
SELECT Ucode, Owner, Name, Description
            FROM XMLTABLE('LocNamespace'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Owner NVARCHAR2(255) PATH './Owner',
                       Name  NVARCHAR2(255) PATH './Name',
                       Description NCLOB PATH './Description'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET  col_owner  = Owner, col_name  = Name, col_description = Description 
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode , col_owner , col_name, col_description )
  VALUES (Ucode, Owner, Name, Description)
  LOG ERRORS INTO er$LOC_NAMESPACE ('IMPOTR') REJECT LIMIT 15; 
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_LOC_NAMESPACE with '||SQL%ROWCOUNT||' rows', IsError => 0);  

	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_ucode  FROM er$LOC_NAMESPACE d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_LOC_NAMESPACE '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'UCODE = '||rec.col_Ucode, IsError => 1);	
    END LOOP;
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- tbl_loc_pluralform
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/LocPluralForm'); 
   
/*      DELETE FROM tbl_loc_pluralform 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('LocPluralForm'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = Ucode);
 
    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_LOC_PLURALFORM '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/     
 MERGE INTO tbl_loc_pluralform
 USING(
SELECT Ucode, Language, Pluralforms
            FROM XMLTABLE('LocPluralForm'
              PASSING v_xmlresult
              COLUMNS
                       Ucode nvarchar2(255) PATH './Ucode',
                       Language nvarchar2(255) PATH './Language',
                       Pluralforms NUMBER(10,2) PATH './Pluralforms'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET  col_language = Language, col_pluralforms = Pluralforms
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode , col_language , col_pluralforms)
  VALUES (Ucode, Language, Pluralforms)
  LOG ERRORS INTO er$LOC_PLURALFORM ('IMPOTR') REJECT LIMIT 5; 
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_LOC_PLURALFORM with '||SQL%ROWCOUNT||' rows', IsError => 0);  

	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_ucode  FROM er$LOC_PLURALFORM d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_LOC_PLURALFORM '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'UCODE = '||rec.col_Ucode, IsError => 1);	
    END LOOP;

EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/***************************************************************************************************/
 -- tbl_LOC_Key
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/LocKey'); 
/*
DELETE FROM tbl_LOC_Key k
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('LocKey'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = Ucode)
AND col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
AND NOT EXISTS (SELECT 1 FROM tbl_loc_keysources ks WHERE ks.col_keyid = k.col_id);

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_LOC_KEY '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/

MERGE INTO tbl_LOC_Key t
 USING(
SELECT 
(SELECT col_id FROM tbl_loc_namespace ns WHERE ns.col_ucode = NameSpase) NameSpaseID, 
  IsPlural,  IsDeleted, Descr, Name, Owner, Contex, Ucode
            FROM XMLTABLE('LocKey'
              PASSING v_xmlresult
              COLUMNS
                       NameSpase NVARCHAR2(255) PATH './NameSpase',
                       IsPlural NUMBER PATH './IsPlural',
                       IsDeleted NUMBER PATH './IsDeleted',
                       Descr  NCLOB PATH './Description', 
                       Name  NVARCHAR2(255) PATH './Name',
                       Owner  NVARCHAR2(255) PATH './Owner',
                       Contex  NVARCHAR2(255) PATH './Context',
                       Ucode  NVARCHAR2(255) PATH './Ucode'                                                                     
                       )
               )
ON (nvl(COL_NAME,'0') = nvl(NAME,'0') AND nvl(COL_CONTEXT,'0') = nvl(contex,'0') AND  COL_NAMESPACEID = NameSpaseID)
WHEN MATCHED THEN
  UPDATE SET  col_owner  = Owner, col_ucode = Ucode,
              col_isplural = IsPlural, 
              col_isnew =  CASE WHEN IsDeleted = 1 AND (SELECT COUNT(*) FROM tbl_loc_keysources KS WHERE KS.COL_KEYID = t.col_id)>0
							THEN col_isnew
								ELSE 1
							END	, 
              col_isdeleted =  IsDeleted, 
              col_description = Descr
              WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode , col_owner , col_name, col_namespaceid, col_isplural, col_isnew , col_isdeleted, col_description , col_context)
  VALUES (Ucode, Owner, Name, NameSpaseID, IsPlural, 1, IsDeleted, Descr, Contex )
  LOG ERRORS INTO er$LOC_KEY ('IMPOTR') REJECT LIMIT 15; 
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_LOC_KEY with '||SQL%ROWCOUNT||' rows', IsError => 0);  

	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_ucode  FROM er$LOC_KEY d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_LOC_KEY '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'UCODE = '||rec.col_Ucode, IsError => 1);	
    END LOOP;

EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;

/***************************************************************************************************/
 -- tbl_LOC_Languages
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/LocLanguages'); 
/*   
DELETE FROM tbl_loc_languages 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('LocLanguages'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = Ucode);

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_LOC_LANGUAGES '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/   
 MERGE INTO tbl_LOC_Languages
 USING(
SELECT IsDefault, AppbaseLangId, Owner, LanguageName, LanguageCode, ExtCode,
(SELECT col_id FROM tbl_loc_pluralform ns WHERE ns.col_ucode = PluralForm) PluralForm, 
  IsDeleted, Ucode, MomentCode
            FROM XMLTABLE('LocLanguages'
              PASSING v_xmlresult
              COLUMNS
                       IsDefault NUMBER PATH './IsDefault',
                       AppbaseLangId NUMBER PATH './AppbaseLangId',
                       Owner  NVARCHAR2(255) PATH './Owner',
                       LanguageName NVARCHAR2(255) PATH './LanguageName',
                       LanguageCode NVARCHAR2(255) PATH './LanguageCode',
                       MomentCode NVARCHAR2(255) PATH './MomentCode',
                       ExtCode  NVARCHAR2(255) PATH './ExtCode',
                       PluralForm  NVARCHAR2(255) PATH './PluralForm',
                       IsDeleted  NUMBER PATH './IsDeleted',
                       Ucode  NVARCHAR2(255) PATH './Ucode'                                                                     
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET  col_isdefault = IsDefault,  col_appbaselangid = AppbaseLangId, col_owner = Owner, 
              col_languagename = LanguageName, col_languagecode = LanguageCode, col_momentcode = MomentCode, 
              col_extcode = ExtCode, col_pluralformid = PluralForm, col_isdeleted =  IsDeleted
              WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_isdefault, col_appbaselangid, col_owner, col_languagename, col_languagecode, 
         col_momentcode, col_extcode, col_pluralformid, col_isdeleted, col_ucode )
  VALUES (IsDefault, AppbaseLangId, Owner, LanguageName, LanguageCode, 
          MomentCode, ExtCode, PluralForm, IsDeleted, Ucode)
          LOG ERRORS INTO er$LOC_LANGUAGES ('IMPOTR') REJECT LIMIT 15; 
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_LOC_LANGUAGES with '||SQL%ROWCOUNT||' rows', IsError => 0);  

	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_ucode  FROM er$LOC_LANGUAGES d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_LOC_LANGUAGES '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'UCODE = '||rec.col_Ucode, IsError => 1);	
    END LOOP;
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;



/***************************************************************************************************/
 -- tbl_LOC_Translation
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/LocTranslation'); 
/*
DELETE FROM tbl_LOC_Translation 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('LocTranslation'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = Ucode)
AND col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT') ;

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_LOC_TRANSLATION '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
MERGE INTO tbl_LOC_Translation
 USING(
SELECT 
--(SELECT col_id FROM tbl_loc_pluralform ns WHERE ns.col_ucode = PluralForm) PluralForm, 
PluralForm,
(SELECT col_id FROM tbl_loc_languages WHERE col_ucode = Lang) Lang,
(SELECT col_id FROM tbl_loc_key WHERE col_ucode = LocKey) LocKey,
Owner, IsDraft, Descr, Valu, Ucode
            FROM XMLTABLE('LocTranslation'
              PASSING v_xmlresult
              COLUMNS
                       PluralForm NUMBER PATH './PluralForm',
                       Lang NVARCHAR2(255) PATH './Language',
                       LocKey NVARCHAR2(255) PATH './LocKey',
                       Owner  NVARCHAR2(255) PATH './Owner',
                       IsDraft NUMBER PATH './IsDraft',
                       Descr NCLOB PATH './Description',
                       Valu NCLOB PATH './Value',
                       Ucode  NVARCHAR2(255) PATH './Ucode'                                                                     
                       )
               )
ON (nvl(col_pluralform,0) = nvl(PluralForm,0) AND 
nvl(col_langid,-1) = nvl(Lang,-1) 
AND 
nvl(col_keyid,-1) = nvl(LocKey,-1) 
)
WHEN MATCHED THEN
  UPDATE SET 
              col_isdraft = IsDraft ,col_description = Descr , col_owner = Owner, col_value = Valu,
              col_ucode = Ucode
       WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')              
WHEN NOT MATCHED THEN
  INSERT (col_pluralform, col_langid, col_keyid, col_isdraft, col_description, col_owner, col_value, col_ucode )
  VALUES (PluralForm, Lang, LocKey, IsDraft, Descr, Owner, Valu, Ucode )
  LOG ERRORS INTO er$LOC_TRANSLATION ('IMPOTR') REJECT LIMIT 15; 
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_LOC_TRANSLATION with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_ucode  FROM er$LOC_TRANSLATION  d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_LOC_TRANSLATION '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'UCODE = '||rec.col_Ucode, IsError => 1);	
    END LOOP;
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- Tbl_Loc_Keysources
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/LocKeySources'); 
/*
DELETE FROM Tbl_Loc_Keysources 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('LocKeySources'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = Ucode)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_LOC_KEYSOURCES '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/

MERGE INTO Tbl_Loc_Keysources
 USING(
SELECT 
 SourceType, 
CASE WHEN UPPER(SourceType) = 'PAGE' THEN 
    (SELECT col_id FROM tbl_fom_page WHERE lower(col_code) = lower(SourceCode)) 
    WHEN UPPER(SourceType) = 'DASHBOARD' THEN  
    (SELECT col_id FROM tbl_fom_dashboard WHERE upper(col_code) = upper(SourceCode))   
END sourceId ,     
(SELECT col_id FROM tbl_loc_key WHERE col_ucode = LocKey) LocKey, Ucode
            FROM XMLTABLE('LocKeySources'
              PASSING v_xmlresult
              COLUMNS
                       SourceCode NVARCHAR2(255) PATH './SourceCode',
                       SourceType NVARCHAR2(255) PATH './SourceType',
                       LocKey NVARCHAR2(255) PATH './LocKey',
                       Ucode  NVARCHAR2(255) PATH './Ucode'                                                                     
                       )
               )
ON (COL_SOURCEID = sourceId AND  nvl(COL_SOURCETYPE,'0') = nvl(SourceType,'0') AND  COL_KEYID = LocKey)
WHEN MATCHED THEN
  UPDATE SET  col_ucode = Ucode
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_sourceid , col_keyid, col_sourcetype, col_ucode )
  VALUES (SourceId,  LocKey, SourceType, Ucode )
  LOG ERRORS INTO er$LOC_KEYSOURCES ('IMPOTR') REJECT LIMIT 5; 
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_LOC_KEYSOURCES with '||SQL%ROWCOUNT||' rows', IsError => 0);  

	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_ucode  FROM er$LOC_KEYSOURCES  d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_LOC_KEYSOURCES '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'UCODE = '||rec.col_Ucode, IsError => 1);	
    END LOOP;
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- Tbl_Int_Integtarget
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/IntIntegtarget'); 
/*
DELETE FROM Tbl_Int_Integtarget 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('IntIntegtarget'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = code);

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_INT_INTEGTARGET '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
 */
v_cnt := f_util_softDelete(InputTableName =>'TBL_INT_INTEGTARGET',
                  partOfXml =>  v_xmlresult,
                  fieldMerge => 'code',
                  xmlID => XmlId,
                  tagName => 'IntIntegtarget');
                  
 MERGE INTO Tbl_Int_Integtarget
 USING( SELECT
IsDeleted, Code, Config, Description, Name
            FROM XMLTABLE('IntIntegtarget'
              PASSING v_xmlresult
              COLUMNS
                       IsDeleted NUMBER PATH './IsDeleted',
                       Description NCLOB PATH './Description',
                       Config NCLOB PATH './Config',
                       Name NVARCHAR2(255) PATH './Name',
                       Code  NVARCHAR2(255) PATH './Code'                                                                     
                       )
               )
ON (upper(col_code) = upper(Code))
WHEN MATCHED THEN
  UPDATE SET  col_isdeleted  = IsDeleted, col_description  = Description , col_config  = dbms_xmlgen.convert(Config,1) , col_name = Name 
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_isdeleted  , col_description , col_config , col_name, col_code)
  VALUES (IsDeleted,  Description, dbms_xmlgen.convert(Config,1), Name, Code )
  LOG ERRORS INTO er$INT_INTEGTARGET ('IMPOTR') REJECT LIMIT 5; 
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_INT_INTEGTARGET with '||SQL%ROWCOUNT||' rows', IsError => 0);  

	FOR rec IN (SELECT d.ora_err_number$, d.ora_err_mesg$, d.col_code  FROM er$INT_INTEGTARGET  d) LOOP
	      p_util_update_log ( XmlIdLog => XmlId, Message => 'Error duaring insetr into TBL_INT_INTEGTARGET '
				||rec.ora_err_number$||' '||rec.ora_err_mesg$||'CODE = '||rec.col_code, IsError => 1);	
    END LOOP;
    
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- TBL_DICT_CASEROLE
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/CaseRole'); 
/*										
DELETE FROM TBL_DICT_CASEROLE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('CaseRole'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_CASEROLE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/ 
 MERGE INTO TBL_DICT_CASEROLE
 USING( SELECT IsDeleted, Code,  Description, Name
            FROM XMLTABLE('CaseRole'
              PASSING v_xmlresult
              COLUMNS
                       IsDeleted NUMBER PATH './IsDeleted',
                       Description NCLOB PATH './Description',
                       Name NVARCHAR2(255) PATH './Name',
                       Code  NVARCHAR2(255) PATH './Code'                                                                     
                       )
               )
ON (col_code = Code)
WHEN MATCHED THEN
  UPDATE SET  col_isdeleted  = IsDeleted, col_description  = Description , col_name = Name
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_isdeleted  , col_description ,  col_name, col_code)
  VALUES (IsDeleted,  Description,  Name, Code ); 
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_CASEROLE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- TBL_DICT_DCMTYPE
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/DcmType'); 
/*										
DELETE FROM TBL_DICT_DCMTYPE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DcmType'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = Ucode);

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_DCMTYPE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/ 
 MERGE INTO TBL_DICT_DCMTYPE
 USING( SELECT Code,  Description, Name, Ucode
            FROM XMLTABLE('DcmType'
              PASSING v_xmlresult
              COLUMNS
                       Description NCLOB PATH './Description',
                       Name NVARCHAR2(255) PATH './Name',
                       Code  NVARCHAR2(255) PATH './Code',
                       Ucode  NVARCHAR2(255) PATH './Ucode'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_description  = Description , col_name = Name, col_code = Code 
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT ( col_description ,  col_name, col_code, col_ucode)
  VALUES (  Description,  Name, Code, Ucode); 
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_DCMTYPE with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- TBL_DICT_TAGOBJECT
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/DictTagObject'); 
/*										
DELETE FROM TBL_DICT_TAGOBJECT 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictTagObject'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_TAGOBJECT '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/ 
 MERGE INTO TBL_DICT_TAGOBJECT
 USING( SELECT  Code,  Name
            FROM XMLTABLE('DictTagObject'
              PASSING v_xmlresult
              COLUMNS
                       Name NVARCHAR2(255) PATH './Name',
                       Code  NVARCHAR2(255) PATH './Code'                                                                     
                       )
               )
ON (col_code = Code)
WHEN MATCHED THEN
  UPDATE SET  col_name = Name 
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_name, col_code)
  VALUES (Name, Code); 
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_TAGOBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- TBL_DICT_TAGTOTAGOBJECT
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/DictTagToTagObject'); 
/*										
DELETE FROM TBL_DICT_TAGTOTAGOBJECT 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictTagToTagObject'
              PASSING v_xmlresult
              COLUMNS Code NVARCHAR2(255) PATH './Code')
WHERE col_code = code)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_TAGTOTAGOBJECT '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/
 MERGE INTO TBL_DICT_TAGTOTAGOBJECT
 USING( SELECT  Code,  Name, 
 (SELECT col_id FROM tbl_dict_tagobject WHERE col_code = TagObject) TagObject,
 (SELECT col_id FROM tbl_dict_tag WHERE col_code = Tag) Tag
            FROM XMLTABLE('DictTagToTagObject'
              PASSING v_xmlresult
              COLUMNS
                       Name NVARCHAR2(255) PATH './Name',
                       Code  NVARCHAR2(255) PATH './Code',
                       TagObject NVARCHAR2(255) PATH './TagObject',
                       Tag NVARCHAR2(255) PATH './Tag'
                       )
               )
ON (lower(col_code) = lower(Code))
WHEN MATCHED THEN
  UPDATE SET  col_name = Name, col_tagtotagobjectdict_tag = Tag, col_tagtotagobjectdict_tagobj = TagObject 
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_name, col_code, col_tagtotagobjectdict_tag, col_tagtotagobjectdict_tagobj)
  VALUES (Name, Code, Tag, TagObject); 
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_TAGTOTAGOBJECT with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
 -- TBL_DICT_STATE
/***************************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/DictState'); 
/*					
DELETE FROM TBL_DICT_STATE 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictState'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = ucode)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');

    IF SQL%ROWCOUNT >0 THEN 
       p_util_update_log ( XmlIdLog => XmlId, Message => '       Deleted from TBL_DICT_STATE '||SQL%ROWCOUNT||' rows', IsError => 0);
    END IF;
*/    
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
                       ID2 NUMBER PATH './ID2',
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
   v_xmlresult := v_dictionary.extract('/Dictionary/DictTransition'); 
	    																					
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
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code = Code, col_name  = Name, col_description = Description, 
	   col_iconcode = IconCode, col_isnextdefault  = IsNextDefault, col_isprevdefault  = IsPrevDefault, 
		 col_manualonly  = ManualOnly, col_transition = Transition, 
		 col_sourcetransitionstate = SourceTransitions, col_targettransitionstate = TargetTransitions,
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
       
  p_util_update_log (XmlIdLog => XmlId, Message => '       Merged TBL_DICT_TRANSITION with '||SQL%ROWCOUNT||' rows', IsError => 0);  
  
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log (XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/*****************************************************************************************/
--TBL_DICT_LINKDIRECTION
/*****************************************************************************************/
BEGIN
   v_xmlresult := v_dictionary.extract('/Dictionary/DictLinkDirection'); 
/*
DELETE FROM TBL_DICT_LINKDIRECTION 
WHERE NOT EXISTS (SELECT 1 FROM 
XMLTABLE ('DictLinkDirection'
              PASSING v_xmlresult
              COLUMNS Ucode NVARCHAR2(255) PATH './Ucode')
WHERE col_ucode = Ucode)
and col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT');
*/

MERGE INTO TBL_DICT_LINKDIRECTION
USING
(
SELECT Code, Name,  Description, Ucode
            FROM XMLTABLE('DictLinkDirection'
              PASSING v_xmlresult
              COLUMNS
                       Code nvarchar2(255) PATH './Code',
                       Name nvarchar2(255) PATH './Name',
                       Description NCLOB PATH './Description',
                       Ucode nvarchar2(255) PATH './Ucode'
                       )

)
ON (col_ucode = Ucode)
WHEN MATCHED THEN UPDATE
  SET  col_name =  Name, col_description = Description, col_code = code
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
INSERT
 ( col_code, col_name, col_description, col_ucode)
VALUES
 (Code, Name, Description, ucode);
       
  p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_LINKDIRECTION with '||SQL%ROWCOUNT||' rows', IsError => 0);  
 
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
--TBL_DICT_STATEEVENT
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/StateEvent');
 
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
          
p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_STATEEVENT with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
/***************************************************************************************************/
--TBL_DICT_STATESLAEVENT
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/StateSlaEvent');
 
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

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_STATESLAEVENT with '||SQL%ROWCOUNT||' rows', IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
/***************************************************************************************************/
--TBL_DICT_STATESLAACTION
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/StateSlaAction');
 
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

END;
/***************************************************************************************************/
--TBL_DICT_CONTAINERTYPE
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/DictContainerType');
 
MERGE INTO tbl_DICT_ContainerType
USING(
SELECT *
            FROM XMLTABLE('DictContainerType'
              PASSING v_xmlresult
              COLUMNS  
                       ID_  NUMBER PATH './ID',
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name'
                       )
               )
ON (col_ucode = Ucode)

WHEN MATCHED THEN
  UPDATE SET col_id = ID_, col_code  = Code,  col_name  = NAME
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code, col_name, col_ID)
  VALUES (Ucode, code,  NAME, ID_);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_CONTAINERTYPE with '||SQL%ROWCOUNT||' rows :'||$$PLSQL_LINE, IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
/**********************************************************************************/
--Extracting tbl_ac_acl
/**********************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/AcAcl'); 

MERGE INTO tbl_ac_acl
USING(
SELECT Code, AclType, ProcessorCode, 
(SELECT col_id FROM tbl_ac_accessobject WHERE lower(col_code) = lower(AccessObject)) AccessObject,
(SELECT col_id FROM tbl_ac_accesssubject WHERE lower(col_code) = lower(AccessSubject)) AccessSubject, 
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

    p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_AC_ACL with '||SQL%ROWCOUNT||' rows '||$$PLSQL_LINE, IsError => 0);
      
EXCEPTION 
  WHEN OTHERS THEN   
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);
END;
/***************************************************************************************************/
--TBL_DICT_SYSTEMTYPE
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/DictSystemType');
 
MERGE INTO TBL_DICT_SYSTEMTYPE
USING(
SELECT *
            FROM XMLTABLE('DictSystemType'
              PASSING v_xmlresult
              COLUMNS
                       ID_  NUMBER PATH './ID',
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code  = Code,  col_name  = NAME, Col_id = ID_
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code, col_name, Col_id)
  VALUES (Ucode, code,  NAME, ID_);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_SYSTEMTYPE with '||SQL%ROWCOUNT||' rows :'||$$PLSQL_LINE, IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
/***************************************************************************************************/
--TBL_DICT_BLACKLIST
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/DictBlackList');
 
MERGE INTO Tbl_Dict_Blacklist
USING(
SELECT *
            FROM XMLTABLE('DictBlackList'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Code NVARCHAR2(255) PATH './Code',
                       BlackListType NVARCHAR2(255) PATH './BlackListType'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_code  = Code,  col_type = BlackListType
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_code, col_type )
  VALUES (Ucode, code,  BlackListType);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_BLACKLIST with '||SQL%ROWCOUNT||' rows :'||$$PLSQL_LINE, IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
/***************************************************************************************************/
--TBL_DICT_PARTYORGTYPE
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/PartyorgType');
 
MERGE INTO TBL_DICT_PARTYORGTYPE
USING(
SELECT *
            FROM XMLTABLE('PartyorgType'
              PASSING v_xmlresult
              COLUMNS
                       Code NVARCHAR2(255) PATH './Code',
                       Name NVARCHAR2(255) PATH './Name',
                       Owner NVARCHAR2(255) PATH './Owner'
                       )
               )
ON (col_code = code)
WHEN MATCHED THEN
  UPDATE SET col_name  = NAME, col_owner = Owner
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_code, col_name, col_owner)
  VALUES (code,  NAME, Owner);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_DICT_PARTYORGTYPE with '||SQL%ROWCOUNT||' rows :'||$$PLSQL_LINE, IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;
/***************************************************************************************************/
--TBL_THREADSETTING
/***************************************************************************************************/
BEGIN
 v_xmlresult := v_dictionary.extract('/Dictionary/ThreadSetting');
 
MERGE INTO TBL_THREADSETTING
USING(
SELECT *
            FROM XMLTABLE('ThreadSetting'
              PASSING v_xmlresult
              COLUMNS
                       Ucode NVARCHAR2(255) PATH './Ucode',
                       Owner NVARCHAR2(255) PATH './Owner',
                       AllowAddPeople NVARCHAR2(255) PATH './AllowAddPeople',
                       AllowCommentDiscussion NVARCHAR2(255) PATH './AllowCommentDiscussion',
                       AllowCreateDiscussion NVARCHAR2(255) PATH './AllowCreateDiscussion',
                       AllowDeleteComment NVARCHAR2(255) PATH './AllowDeleteComment',
                       AllowDeleteDiscussion NVARCHAR2(255) PATH './AllowDeleteDiscussion',
                       AllowEditComment NVARCHAR2(255) PATH './AllowEditComment',
                       AllowJoinDiscussion NVARCHAR2(255) PATH './AllowJoinDiscussion',
                       AllowLeaveDiscussion NVARCHAR2(255) PATH './AllowLeaveDiscussion',
                       AllowRemovePeople NVARCHAR2(255) PATH './AllowRemovePeople'
                       )
               )
ON (col_ucode = Ucode)
WHEN MATCHED THEN
  UPDATE SET col_owner = Owner, col_allowaddpeople  = AllowAddPeople, 
  col_allowcommentdiscussion = AllowCommentDiscussion, col_allowcreatediscussion = AllowCreateDiscussion,
  col_allowdeletecomment = AllowDeleteComment, col_allowdeletediscussion = AllowDeleteDiscussion,
  col_alloweditcomment = AllowEditComment, col_allowjoindiscussion = AllowJoinDiscussion,
  col_allowleavediscussion = AllowLeaveDiscussion, col_allowremovepeople = AllowRemovePeople
  WHERE col_createdby = 'IMPORT' AND (col_modifiedby IS NULL OR col_modifiedby = 'IMPORT')
WHEN NOT MATCHED THEN
  INSERT (col_ucode, col_owner, col_allowaddpeople, 
  col_allowcommentdiscussion, col_allowcreatediscussion,
  col_allowdeletecomment, col_allowdeletediscussion,
  col_alloweditcomment, col_allowjoindiscussion,
  col_allowleavediscussion, col_allowremovepeople)
  VALUES (Ucode, Owner, AllowAddPeople, 
  AllowCommentDiscussion, AllowCreateDiscussion,
  AllowDeleteComment, AllowDeleteDiscussion,
  AllowEditComment, AllowJoinDiscussion,
  AllowLeaveDiscussion, AllowRemovePeople);

p_util_update_log ( XmlIdLog => XmlId, Message => '       Merged TBL_THREADSETTING with '||SQL%ROWCOUNT||' rows :'||$$PLSQL_LINE, IsError => 0);

EXCEPTION 
  WHEN OTHERS THEN 
  p_util_update_log ( XmlIdLog => XmlId, Message => dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, IsError => 1);

END;


/***************************************************************************************************/
    IF v_error IS NOT NULL THEN 
    RETURN v_error;
    ELSE 
    RETURN 'Ok';
    END IF;
END;