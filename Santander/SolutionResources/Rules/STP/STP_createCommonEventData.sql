DECLARE   
  v_result            NUMBER;
  v_CustomConfig      NCLOB;
  v_ErrorCode         NUMBER;
  v_ErrorMessage      NVARCHAR2(255);
  v_CommonEventId     NUMBER;
  v_eventType         NVARCHAR2(255);
  

BEGIN
  --input  
  v_CommonEventId := :CommonEventId; 

  --init
  v_CustomConfig :=NULL;
  v_eventType    :=NULL;

  --validation
  IF NVL(v_CommonEventId,0)=0 THEN
    v_ErrorCode :=101;
    v_ErrorMessage :='Id parameter cannot be NULL or empty.';
    GOTO cleanup;
  END IF;

  BEGIN
    SELECT COL_CUSTOMCONFIG, COL_CODE INTO v_CustomConfig, v_eventType
    FROM TBL_COMMONEVENTTMPL 
    WHERE COL_ID=v_CommonEventId;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    v_CustomConfig :=NULL;
    v_eventType    :=NULL;
  END;
  
  IF v_CustomConfig IS NULL THEN
    v_ErrorCode :=101;
    v_ErrorMessage :='XML data cannot be NULL or empty.';
    GOTO cleanup;
  END IF;

  --delete old data
  DELETE FROM TBL_AUTORULEPARAMTMPL
  WHERE COL_ARPTMPL_CETMPL=v_CommonEventId;
 
  --process a XML data
  FOR rec IN 
  (
  SELECT *
  FROM XMLTABLE('for $node in //* return <x><PNAME>{name($node/..)}</PNAME><NAME>{name($node)}</NAME><VALUE>{$node/text()}</VALUE></x>' 
                PASSING XMLTYPE(v_CustomConfig)
                columns PNAME, NAME, VALUE) AS xmlD
  WHERE xmlD.PNAME IS NOT NULL AND UPPER(xmlD.NAME) NOT IN ('CUSTOMDATA', 'ATTRIBUTES', 'RULE_PARAMS')
  ) 
  LOOP
    --convert a parameter's name to the same name as in the procedure builder
    --send email event          
    IF UPPER(v_eventType)='MAIL' THEN
      IF UPPER(rec.NAME)='DISTRIBUTIONCHANNEL' THEN rec.NAME :='DistributionChannel'; END IF;
      IF UPPER(rec.NAME)='FROM' THEN rec.NAME :='From'; END IF;
      IF UPPER(rec.NAME)='FROM_RULE' THEN rec.NAME :='FromRule'; END IF;
      IF UPPER(rec.NAME)='TO' THEN rec.NAME :='To'; END IF;
      IF UPPER(rec.NAME)='TO_RULE' THEN rec.NAME :='ToRule'; END IF;
      IF UPPER(rec.NAME)='CC' THEN rec.NAME :='Cc'; END IF;
      IF UPPER(rec.NAME)='BCC' THEN rec.NAME :='Bcc'; END IF;
      IF UPPER(rec.NAME)='TEMPLATE' THEN rec.NAME :='Template'; END IF;
      IF UPPER(rec.NAME)='TEMPLATE_RULE' THEN rec.NAME :='TemplateRule'; END IF;
      IF UPPER(rec.NAME)='CC_RULE' THEN rec.NAME :='CcRule'; END IF;
      IF UPPER(rec.NAME)='ATTACHMENTS_RULE' THEN rec.NAME :='AttachmentsRule'; END IF;
      IF UPPER(rec.NAME)='BCC_RULE' THEN rec.NAME :='BccRule'; END IF;
    END IF;--send email event
  
    --send sms event          
    IF UPPER(v_eventType)='MESSAGETXT' THEN
      IF UPPER(rec.NAME)='MESSAGE_CODE' THEN rec.NAME :='MessageCode'; END IF;
      IF UPPER(rec.NAME)='MESSAGE_RULE' THEN rec.NAME :='MessageRule'; END IF;
      IF UPPER(rec.NAME)='TO' THEN rec.NAME :='To'; END IF;
      IF UPPER(rec.NAME)='TO_RULE' THEN rec.NAME :='ToRule'; END IF;
      IF UPPER(rec.NAME)='TO_RULE' THEN rec.NAME :='ToRule'; END IF;
      IF UPPER(rec.NAME)='FROM' THEN rec.NAME :='From'; END IF;
      IF UPPER(rec.NAME)='FROM_RULE' THEN rec.NAME :='FromRule'; END IF;
    END IF;--send sms event  

    INSERT INTO TBL_AUTORULEPARAMTMPL(COL_PARAMVALUE,COL_PARAMCODE, COL_CODE, COL_ARPTMPL_CETMPL)
    VALUES(rec.VALUE,rec.NAME, SYS_GUID(), v_CommonEventId);
  END LOOP;

  :ErrorCode := 0;
  :ErrorMessage := '';    
  RETURN 0;

  <<cleanup>>
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;    
  RETURN -1;
END;