DECLARE
  v_typeOfQuery     NVARCHAR2(255);
  v_DataTypeFormat  NVARCHAR2(255);
  v_Attributes      NCLOB;
  v_parentId        NUMBER;
  v_Id1             NUMBER;  
  v_data            NCLOB;
  v_CaseId          NUMBER;
  v_CSisInCache     INTEGER;

BEGIN
  --input
  v_CaseId      := :CaseId; 
  v_parentId    := :parentId;
  v_typeOfQuery := :typeOfQuery;
  v_DataTypeFormat := :DataTypeFormat;
  v_Attributes     := :Attributes;
  
  --init
  v_Id1  := NULL;
  v_data := NULL; 
  v_CSisInCache := f_DCM_CSisCaseInCache(v_CaseId);--new cache
  v_CSisInCache := NVL(v_CSisInCache,0);

  --validation
  IF (v_parentId IS NULL) THEN 
    RETURN 'Data not found. Passed Id is NULL'; 
  END IF;

  --supported types are    
  --'SLACASES' , 'COMMONEVENTS'
  IF (v_typeOfQuery IS NULL) OR (UPPER(v_typeOfQuery) NOT IN ('SLACASES', 'COMMONEVENTS')) THEN
    RETURN 'Passed TYPEOFQUERY unknown OR must be NOT NULL';              
  END IF;

  IF (v_DataTypeFormat IS NULL) OR (UPPER(v_DataTypeFormat) NOT IN ('JSON', 'XML')) THEN
    RETURN 'Passed DATATYPEFORMAT must be JSON or XML value';
  END IF;
        
  --processing
  --SLACASES not fully tested yet
  IF UPPER(v_typeOfQuery)=UPPER('SLACASES') THEN
    IF UPPER(v_DataTypeFormat)='JSON' THEN      
      v_data :='[{"name": "CaseId", "value": "' || TO_CHAR(v_CaseId) || '"},';
    END IF;
  
    IF UPPER(v_DataTypeFormat)='XML' THEN       
      v_data :='<CustomData><Attributes><CaseId>' || TO_CHAR(v_CaseId) || '</CaseId>';
    END IF; 

    --when data not in cache
    IF v_CSisInCache<>1 THEN
      FOR rec IN 
      ( 
        SELECT col_ParamCode, col_ParamValue
        FROM TBL_AUTORULEPARAMETER
        WHERE COL_AUTORULEPARAMSLAACTION = v_parentId
      )        
      LOOP
        IF UPPER(v_DataTypeFormat)='JSON' THEN      
          v_data := v_data || '{"name": "' || rec.col_ParamCode || '", "value": "' || rec.col_ParamValue || '"},';             
        END IF; 
        IF UPPER(v_DataTypeFormat)='XML' THEN
          v_data := v_data || '<' || rec.col_ParamCode || '>' || rec.col_ParamValue || '</' || rec.col_ParamCode || '>';        
        END IF;        
      END LOOP;
    END IF;--v_CSisInCache<>1
      
    --when data in cache
    IF v_CSisInCache=1 THEN
      FOR rec IN 
      ( 
        SELECT col_ParamCode, col_ParamValue
        FROM TBL_CSAUTORULEPARAMETER
        WHERE COL_AUTORULEPARAMSLAACTION = v_parentId
      )        
      LOOP
        IF UPPER(v_DataTypeFormat)='JSON' THEN      
          v_data := v_data || '{"name": "' || rec.col_ParamCode || '", "value": "' || rec.col_ParamValue || '"},';             
        END IF; 
        IF UPPER(v_DataTypeFormat)='XML' THEN
          v_data := v_data || '<' || rec.col_ParamCode || '>' || rec.col_ParamValue || '</' || rec.col_ParamCode || '>';        
        END IF;        
      END LOOP;
    END IF;--v_CSisInCache<>1

    v_Id1 :=NULL;
    BEGIN
      SELECT COL_SLAACTIONSLAEVENT INTO v_Id1
      FROM TBL_SLAACTION
      WHERE col_id=v_parentId; 
    EXCEPTION
      WHEN NO_DATA_FOUND THEN v_Id1 :=NULL;
      WHEN OTHERS THEN v_Id1 :=NULL;
    END;

    IF UPPER(v_DataTypeFormat)='JSON' THEN        
      IF v_Id1 IS NOT NULL THEN 
        v_data := v_data || '{"name": "SLAEventId", "value": "' || v_Id1 || '"}, ';
      END IF;
      v_data := v_data || '{"name": "CaseInCache", "value": "' || v_CSisInCache || '"},';
      v_data := v_data || '{"name": "SLAActionId", "value": "' || v_parentId || '"}]';      
    END IF;  
    
    IF UPPER(v_DataTypeFormat)='XML' THEN        
      IF v_Id1 IS NOT NULL THEN           
        v_data := v_data || '<SLAEventId>' || v_Id1 || '</SLAEventId>';        
      END IF;
      v_data := v_data || '<CaseInCache>' || v_CSisInCache || '</CaseInCache>';
      v_data := v_data || '<SLAActionId>' || v_parentId || '</SLAActionId></Attributes></CustomData>';                
    END IF;      
  END IF; --SLACASES


  IF UPPER(v_typeOfQuery)=UPPER('COMMONEVENTS') THEN 
    IF UPPER(v_DataTypeFormat)='JSON' THEN      
      v_data :='[{"name": "CaseId", "value": "' || TO_CHAR(v_CaseId) || '"},';
      IF v_Attributes IS NOT NULL THEN
        v_Attributes :='<CustomData><Attributes>'||v_Attributes||'</Attributes></CustomData>';
        v_data :=v_data|| '{"name": "ResolutionId", "value": "' || 
                 F_form_getparambyname(v_Attributes, 'ResolutionId')|| '"},';
        v_data :=v_data|| '{"name": "WorkbasketId", "value": "' || 
                 F_form_getparambyname(v_Attributes, 'WorkbasketId')|| '"},';
        v_data :=v_data|| '{"name": "CaseTypeId", "value": "' || 
                 F_form_getparambyname(v_Attributes, 'CaseTypeId')|| '"},';
        v_data :=v_data|| '{"name": "ProcedureId", "value": "' || 
                 F_form_getparambyname(v_Attributes, 'ProcedureId')|| '"},';
        v_data :=v_data|| '{"name": "TaskId", "value": "' || 
                 F_form_getparambyname(v_Attributes, 'TaskId')|| '"},';
        v_data :=v_data|| '{"name": "TaskTypeId", "value": "' || 
                 F_form_getparambyname(v_Attributes, 'TaskTypeId')|| '"},';
      END IF; 
    END IF;
    
    IF UPPER(v_DataTypeFormat)='XML' THEN 
      v_data :='<CustomData><Attributes>'; 
      IF v_Attributes IS NOT NULL THEN v_data :=v_data || v_Attributes; END IF; 
    END IF;

    --when data not in cache
    IF v_CSisInCache<>1 THEN
      FOR rec IN 
      ( 
        SELECT col_ParamCode, col_ParamValue
        FROM TBL_AUTORULEPARAMETER
        WHERE COL_AUTORULEPARAMCOMMONEVENT = v_parentId
      )        
      LOOP
        IF UPPER(v_DataTypeFormat)='JSON' THEN      
          v_data := v_data || '{"name": "' || rec.col_ParamCode || '", "value": "' || rec.col_ParamValue || '"},';             
        END IF; 
        IF UPPER(v_DataTypeFormat)='XML' THEN
        v_data := v_data || '<' || rec.col_ParamCode || '>' || rec.col_ParamValue || '</' || rec.col_ParamCode || '>';        
        END IF;        
      END LOOP;
    END IF;--v_CSisInCache<>1

    --when data  in cache
    IF v_CSisInCache=1 THEN
      FOR rec IN 
      ( 
        SELECT col_ParamCode, col_ParamValue
        FROM TBL_CSAUTORULEPARAMETER
        WHERE COL_AUTORULEPARAMCOMMONEVENT = v_parentId
      )        
      LOOP
        IF UPPER(v_DataTypeFormat)='JSON' THEN      
          v_data := v_data || '{"name": "' || rec.col_ParamCode || '", "value": "' || rec.col_ParamValue || '"},';             
        END IF; 
        IF UPPER(v_DataTypeFormat)='XML' THEN
        v_data := v_data || '<' || rec.col_ParamCode || '>' || rec.col_ParamValue || '</' || rec.col_ParamCode || '>';        
        END IF;        
      END LOOP;
    END IF;--v_CSisInCache=1
      
    IF UPPER(v_DataTypeFormat)='JSON' THEN        
      v_data := v_data || '{"name": "CaseInCache", "value": "' || v_CSisInCache || '"},';      
      v_data := v_data || '{"name": "CommonEventId", "value": "' || v_parentId || '"}]';            
    END IF;  

    
    IF UPPER(v_DataTypeFormat)='XML' THEN        
      v_data := v_data || '<CaseInCache>' || v_CSisInCache || '</CaseInCache>';
      v_data := v_data || '<CommonEventId>' || v_parentId || '</CommonEventId></Attributes></CustomData>';                
    END IF;      
  END IF; --COMMONEVENTS
       
  RETURN v_data;
END;