  /*
      A two ways to use this function
      
      1. Pass a existing CaseSysTypeId and get a new custom milestone for this 
         CaseSysType (XML and db records). (if custom milestone for this CaseSysType absent)
         
      2. Pass a DefStateConfigId and get a new custom milestone XML only (based on the 
         XML from state config record)
         
      3. A passing two parameters both not allowed   
  */
  
  --start of rule
  DECLARE 
    v_CaseSysTypeId    NUMBER;
    v_Input            CLOB;
    v_InputXML         XMLTYPE;
    v_count            NUMBER;
    v_iconcode         NVARCHAR2(255);
    v_name             NVARCHAR2(255);
    v_code             NVARCHAR2(255); 
    v_codeSC           NVARCHAR2(255);
    v_nameSC           NVARCHAR2(255);
    v_iconcodeSC       NVARCHAR2(255); 
    v_paramname        NVARCHAR2(255);     
    v_paramvalue       NVARCHAR2(255);          
    v_modeStr          NVARCHAR2(255);
    v_stateConfigId    NUMBER; 
    v_stateConfigIdNew NUMBER;
    v_DefStateConfigId NUMBER;
    v_tmpNUM           NUMBER;

    --temp variables 
    v_Result        NUMBER;
    v_SuccessResponse CLOB; 

    --errors variables
    v_errorCode     NUMBER;
    v_errorMessage  NVARCHAR2(4000);

  BEGIN
    --init
    v_CaseSysTypeId    := :CaseSysTypeId;
    v_DefStateConfigId := :DefStateConfigId;
            
    v_Input         := NULL;    
    v_name          := NULL;
    v_code          := NULL;
    v_iconcode      := NULL;    
    v_paramname     := NULL;
    v_paramvalue    := NULL;          
    v_tmpNUM        := NULL;

    v_codeSC        := NULL;
    v_nameSC        := NULL;
    v_iconcodeSC    := NULL; 
    v_modeStr       := NULL; 
           
    v_count             := NULL;    
    v_stateConfigIdNew  := NULL;
    v_stateConfigId     := NULL;  
    v_Result            := NULL;
    v_SuccessResponse   :=EMPTY_CLOB();
     
    --check input data
    IF (v_CaseSysTypeId IS NULL) AND (v_DefStateConfigId IS NULL) THEN
      v_errorCode :=101;
      v_errorMessage :='Case Type Id and Default State Config Id cannot be NULL both.';
      GOTO cleanup;
    END IF;


    --"convertation" mode    
    IF NVL(v_CaseSysTypeId,0)<>0 AND NVL(v_DefStateConfigId,0)= 0 THEN
  
      v_modeStr :='Case Type';
      v_tmpNUM  := v_CaseSysTypeId;

      BEGIN
        SELECT COL_CODE, COL_ICONCODE, COL_NAME, COL_STATECONFIGCASESYSTYPE 
        INTO v_code, v_iconcode, v_name, v_stateConfigId
        FROM TBL_DICT_CASESYSTYPE
        WHERE COL_ID=v_CaseSysTypeId;
      EXCEPTION WHEN NO_DATA_FOUND THEN    
        v_name          := NULL;
        v_code          := NULL;
        v_iconcode      := NULL;
        v_stateConfigId := NULL;
      END;
      
      --define if custom state machine is exists
      BEGIN
        SELECT  COUNT(1) INTO v_count
        FROM TBL_DICT_STATECONFIG
        WHERE COL_CASESYSTYPESTATECONFIG=v_CaseSysTypeId AND COL_ISCURRENT=1;
      EXCEPTION WHEN OTHERS THEN
        v_count :=0;
      END; 
      
      IF v_count<>0 THEN 
        v_errorCode :=102;
        v_errorMessage :='Custom Milestone already exists for Case Type "'||v_name||
                         '". Case Type Code is: "'||v_code||'". Case Type Id is:'||TO_CHAR(v_CaseSysTypeId);
        GOTO cleanup;
      END IF; 
  
      IF NVL(v_stateConfigId,0)=0 THEN 
        v_errorCode :=102;
        v_errorMessage :='Cannot define a Config Id for Case Type "'||v_name||
                         '". Case Type Code is: "'||v_code||'". Case Type Id is:'||TO_CHAR(v_CaseSysTypeId);
        GOTO cleanup;
      END IF;

    END IF; --NVL(v_CaseSysTypeId,0)<>0
     
    IF NVL(v_CaseSysTypeId,0)=0 AND NVL(v_DefStateConfigId,0)<> 0 THEN 
      v_tmpNUM  := v_DefStateConfigId;
      v_modeStr :='State Config';
      v_stateConfigId :=v_DefStateConfigId;
    END IF;--NVL(v_CaseSysTypeId,0)=0
 
    --define a xml data aka "system state diagram"
    BEGIN
      SELECT COL_CONFIG, COL_CODE, COL_NAME, COL_ICONCODE 
      INTO v_Input, v_codeSC, v_nameSC, v_iconcodeSC
      FROM TBL_DICT_STATECONFIG
      WHERE col_id=v_stateConfigId;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      v_Input :=NULL;
      v_codeSC := NULL;
      v_nameSC := NULL;
      v_iconcodeSC:= NULL;
    END;

    IF NVL(v_CaseSysTypeId,0)=0 AND NVL(v_DefStateConfigId,0)<> 0 THEN 
        v_name          := NVL(v_nameSC, ' ');
        v_code          := NVL(v_codeSC, ' ');
        v_iconcode      := NVL(v_iconcodeSC, ' ');
    END IF;--NVL(v_CaseSysTypeId,0)=0

    IF v_Input IS NULL THEN 
      v_errorCode :=102;
      v_errorMessage :='Cannot define a XML Data for '||v_modeStr||' "'||v_name||
                       '". '||v_modeStr||' Code is: "'||v_code||'". '||v_modeStr||' Id is:'||TO_CHAR(v_tmpNUM)||                       
                       '. Please contact your System Administrator';
      GOTO cleanup;
    END IF;

   --convert a "system state diagram" into "custom milestone diagram"
   BEGIN
    v_InputXML := XMLTYPE(v_Input); 
   EXCEPTION WHEN OTHERS THEN
    v_errorCode :=103;
    v_errorMessage :='Error: A source XML Data is invalid. '||v_modeStr||' "'||v_name||
                     '". '||v_modeStr||' Code is: "'||v_code||'".  '||v_modeStr||'  Id is:'||TO_CHAR(v_tmpNUM)||                     
                     '. Please contact your System Administrator';
    GOTO cleanup;
   END;

   --For each mxCell = milestone
   FOR rec IN
   (
    SELECT NODEID, CODE, NAME, SUBSTR(OBJ,1, 4000) AS OBJ, NEWOBJ
    FROM XMLTABLE('/mxGraphModel/root/mxCell'
      PASSING XMLTYPE.CREATEXML(v_Input) 
      COLUMNS
      NODEID              NUMBER         path '//@id',
      NODETYPE            VARCHAR2(255)  path '//@type',          
      NAME                VARCHAR2(255)  path '//Object/@NAME',
      CODE                VARCHAR2(255)  path '//Object/@CODE',
      OBJ                 XMLType        path '//Object',
      NEWOBJ              VARCHAR2(4000) path '//Object/@CODE'
    ) WHERE UPPER(NODETYPE)='MILESTONE'
   )
   LOOP 
    IF  rec.OBJ IS NOT NULL THEN                       
      rec.NEWOBJ :='<Object ';
      FOR recXML IN (SELECT SUBSTR(substr1, 1, 4000) AS substr2 FROM
          (
          SELECT REGEXP_SUBSTR(str1, '\w+=\"[^\"]+\"', 1, LEVEL) AS substr1
          FROM (SELECT rec.OBJ AS str1 FROM DUAL)
          CONNECT BY LEVEL <= LENGTH(REGEXP_REPLACE(str1, '\w+=\"[^\"]+\"')) + 1
          )
          WHERE substr1 IS NOT NULL
      )LOOP
        IF (recXML.substr2 IS NOT NULL OR recXML.substr2<>'') THEN        
        
          v_paramname := NULL; 
          v_paramvalue := NULL;
            
          BEGIN
            SELECT REGEXP_SUBSTR(recXML.substr2, '\w+', 1,1),
                   REGEXP_SUBSTR(recXML.substr2, '\"[^\"]+\"', 1,1) INTO v_paramname, v_paramvalue FROM dual;
          EXCEPTION
          WHEN OTHERS THEN
            v_paramname := NULL;
            v_paramvalue := NULL;
          END;
          
          IF (v_paramname IS NOT NULL) AND (v_paramvalue IS NOT NULL)  AND
             (UPPER(v_paramname)='CODE') THEN
          rec.NEWOBJ :=rec.NEWOBJ||' SYSTEMCODE="'||v_codeSC||'_'||REPLACE(v_paramvalue, '"', '')||'" ';
          END IF;

          IF (v_paramname IS NOT NULL) AND (v_paramvalue IS NOT NULL)  AND
             (UPPER(v_paramname)='NAME') THEN
          rec.NEWOBJ :=rec.NEWOBJ||' SYSTEMNAME='||v_paramvalue||' ';
          END IF;

          rec.NEWOBJ :=rec.NEWOBJ||recXML.substr2||' ';
        END IF;--recXML.substr2
       END LOOP;--extract a params  
       
       rec.NEWOBJ :=rec.NEWOBJ||' />';

       --update a XML
       BEGIN
        SELECT UPDATEXML(v_InputXML, '//mxGraphModel/root/mxCell[@id='||TO_CHAR(rec.NODEID)||']/Object', XMLType(rec.NEWOBJ)) INTO v_InputXML FROM dual;
       EXCEPTION WHEN OTHERS THEN
        v_errorCode :=103;
        v_errorMessage :='Cannot update a XML Data for '||v_modeStr||' "'||v_name||
                         '". '||v_modeStr||' Code is: "'||v_code||'". '||v_modeStr||' Id is:'||TO_CHAR(v_tmpNUM)||
                         'Error: XML Data is invalid for Node Id '||TO_CHAR(rec.NODEID)||
                         '; Node Name is "'||rec.Name||'"; Node Code is: "'||rec.CODE||
                         '". Please contact your System Administrator';
        GOTO cleanup;
       END;

    END IF;--rec.OBJ IS NOT NULL 
     
    IF  rec.OBJ IS NULL THEN
      v_errorCode :=103;
      v_errorMessage :='Cannot parse a XML Data for '||v_modeStr||' "'||v_name||
                       '". '||v_modeStr||' Code is: "'||v_code||'". '||v_modeStr||' Id is:'||TO_CHAR(v_tmpNUM)||                       
                       'Error: XML Data is invalid for Node Id '||TO_CHAR(rec.NODEID)||
                       '; Node Name is "'||rec.Name||'"; Node Code is: "'||rec.CODE||
                       '". Please contact your System Administrator';
      GOTO cleanup;
    END IF;
   END LOOP;
   
   -- validate result XML
   v_Input := v_InputXML.getClobVal();
   v_InputXML :=NULL;
   BEGIN
    v_InputXML   :=XMLTYPE(v_Input);
   EXCEPTION WHEN OTHERS THEN
    v_errorCode :=103;
    v_errorMessage :='Error: A result XML Data is invalid. '||v_modeStr||' "'||v_name||
                     '". '||v_modeStr||' Code is: "'||v_code||'". '||v_modeStr||' Id is:'||TO_CHAR(v_tmpNUM)||                   
                     '. Please contact your System Administrator';
    GOTO cleanup;
   END;

   IF NVL(v_CaseSysTypeId,0)<>0 AND NVL(v_DefStateConfigId,0)= 0 THEN
     --create custom milestone data
     v_codeSC := 'MS_'||NVL(v_code, NVL(v_codeSC, 'CASESYSTYPE_'||TO_CHAR(v_CaseSysTypeId)));
     v_nameSC := NVL(v_name, NVL(v_nameSC, 'CASESYSTYPE_'||TO_CHAR(v_CaseSysTypeId)));
     v_iconcodeSC:= NVL(v_iconcode, NVL(v_iconcodeSC, NULL));
  
     v_Result :=f_STP_ModifyCaseStateDetailFn(SUCCESSRESPONSE=>v_SuccessResponse,
                                              CASESYSTYPEID =>v_CaseSysTypeId, 
                                              CODE=>v_codeSC, 
                                              ERRORCODE=>v_errorCode, 
                                              ERRORMESSAGE=>v_errorMessage, 
                                              ICONCODE=>v_iconcodeSC, 
                                              INPUT=>v_Input, 
                                              NAME=>v_nameSC, 
                                              NEW_STATECONFIGID=>v_stateConfigIdNew,
                                              CREATIONMODE   => 'MULTIPLE_VER');    
  
     IF NVL(v_errorCode,0)<>0 THEN GOTO cleanup; END IF;
  
     v_errorMessage :='Case Type "'||v_name||'" was successfully modified. A Milestone Diagram "'||v_nameSC||'" was successfully created.';
   END IF;

   IF NVL(v_CaseSysTypeId,0)=0 AND NVL(v_DefStateConfigId,0)<> 0 THEN
    v_errorMessage := NULL;
   END IF;
             
   --exit block           
   v_errorCode :=NULL;   
   :NEW_CUSTOMCONFIG := v_Input; 
   :ErrorCode := v_errorCode;
   :ErrorMessage := v_errorMessage;
   :NEW_STATECONFIGID := v_stateConfigIdNew;     
   RETURN 0; 
    
   --error block
   <<cleanup>>
   :NEW_CUSTOMCONFIG :=NULL;
   :ErrorCode := v_errorCode;
   :ErrorMessage := v_errorMessage;  
   :NEW_STATECONFIGID := v_stateConfigIdNew;     
   RETURN -1;
   
  END;--eof rule