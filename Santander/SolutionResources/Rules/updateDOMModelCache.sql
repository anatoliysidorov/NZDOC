DECLARE

    XMLPARAMETERS XMLTYPE;

BEGIN

    IF :XML_STRING IS NOT NULL AND LENGTH(:XML_STRING) IS NOT NULL THEN
    
        XMLPARAMETERS := XMLTYPE('<?xml version="1.0" ?>' || NVL(:XML_STRING,''));
        
        FOR RECORD_PARAMETERS IN 
            (
            SELECT 
            EXTRACTVALUE(VALUE(XMLPARAMETERSTABLE),'/RECORD/DBNAME/text()')        AS DBNAME,
            EXTRACTVALUE(VALUE(XMLPARAMETERSTABLE),'/RECORD/RESULTMESSAGE/text()') AS RESULTMESSAGE,
            EXTRACTVALUE(VALUE(XMLPARAMETERSTABLE),'/RECORD/ERRORMESSAGE/text()')  AS ERRORMESSAGE,
            EXTRACTVALUE(VALUE(XMLPARAMETERSTABLE),'/RECORD/ERRORCODE/text()')     AS ERRORCODE,
            EXTRACTVALUE(VALUE(XMLPARAMETERSTABLE),'/RECORD/CODE/text()')          AS CODE
            FROM   TABLE(XMLSEQUENCE(EXTRACT(XMLPARAMETERS,'/RECORDS/RECORD'))) XMLPARAMETERSTABLE
            ) 
        LOOP
    
            UPDATE TBL_DOM_MODELCACHE
            SET COL_DBNAME    = RECORD_PARAMETERS.DBNAME,
            COL_RESULTMESSAGE = RECORD_PARAMETERS.RESULTMESSAGE,
            COL_ERRORMESSAGE  = RECORD_PARAMETERS.ERRORMESSAGE,
            COL_ERRORCODE     = RECORD_PARAMETERS.ERRORCODE
            WHERE F_UTIL_EXTRACT_VALUE_XML(INPUT => XMLTYPE(COL_PARAMXML), PATH => '/Parameters/Parameter[@name="Code"]/@value') = RECORD_PARAMETERS.CODE;
    
        END LOOP;
        
    END IF;
    
END;