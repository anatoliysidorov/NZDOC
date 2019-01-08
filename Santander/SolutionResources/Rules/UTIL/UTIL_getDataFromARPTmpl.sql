DECLARE
    v_typeOfQuery    NVARCHAR2(255);
    v_DataTypeFormat NVARCHAR2(255);
    v_Attributes     NVARCHAR2(4000);
    v_parentId    NUMBER;
    v_Id1         NUMBER;
	  v_data        NCLOB;
    v_CaseId      NUMBER;

BEGIN
    v_CaseId      := :CaseId; 
    v_parentId    := :parentId;
    v_typeOfQuery := :typeOfQuery;
    v_DataTypeFormat := :DataTypeFormat;
    v_Attributes     := :Attributes;
    
    v_Id1  := NULL;
    v_data := NULL;    

    IF (v_parentId IS NULL) THEN 
      RETURN 'Data not found. Passed Id is NULL'; 
    END IF;

    --supported types are
    --'MILESTONE' 
    --'SLAACTION'
    IF (v_typeOfQuery IS NULL) OR (UPPER(v_typeOfQuery) NOT IN ('MILESTONE', 'SLAACTION')) THEN
      RETURN 'Passed TYPEOFQUERY unknown OR must be NOT NULL';              
    END IF;

    IF (v_DataTypeFormat IS NULL) OR (UPPER(v_DataTypeFormat) NOT IN ('JSON', 'XML')) THEN
      RETURN 'Passed DATATYPEFORMAT must be JSON or XML value';
    END IF;
    
    IF UPPER(v_DataTypeFormat)='JSON' THEN
      IF NVL(v_CaseId, 0)=0 THEN
        v_data :='[';
      END IF;
      IF NVL(v_CaseId, 0)<>0 THEN
        v_data :='[{"name": "CaseId", "value": "' || TO_CHAR(v_CaseId) || '"},';
      END IF;
      IF v_Attributes IS NOT NULL THEN
        v_Attributes :='<CustomData><Attributes>'||v_Attributes||'</Attributes></CustomData>';
        v_data :=v_data|| '{"name": "ResolutionId", "value": "' || 
                 F_form_getparambyname(v_Attributes, 'ResolutionId')|| '"},';
        v_data :=v_data|| '{"name": "WorkbasketId", "value": "' || 
                 F_form_getparambyname(v_Attributes, 'WorkbasketId')|| '"},';
      END IF;      
    END IF;
    
    IF UPPER(v_DataTypeFormat)='XML' THEN
      IF NVL(v_CaseId, 0)=0 THEN
        v_data :='<CustomData><Attributes>';
      END IF;
      IF NVL(v_CaseId, 0)<>0 THEN
        v_data :='<CustomData><Attributes><CaseId>' || TO_CHAR(v_CaseId) || '</CaseId>';
      END IF;
      IF v_Attributes IS NOT NULL THEN
        v_data :=v_data || v_Attributes;
      END IF;      
    END IF;    

    IF UPPER(v_typeOfQuery)=UPPER('MILESTONE') THEN
      FOR rec IN 
      ( 
        SELECT col_ParamCode, col_ParamValue
        FROM TBL_AUTORULEPARAMTMPL
        WHERE COL_AUTORULEPARTMPLSTATEEVENT = v_parentId
      )        
      LOOP
        IF UPPER(v_DataTypeFormat)='JSON' THEN      
          v_data := v_data || '{"name": "' || rec.col_ParamCode || '", "value": "' || rec.col_ParamValue || '"},';             
        END IF; 
        IF UPPER(v_DataTypeFormat)='XML' THEN
        v_data := v_data || '<' || rec.col_ParamCode || '>' || rec.col_ParamValue || '</' || rec.col_ParamCode || '>';        
        END IF;        
      END LOOP;
      
      v_Id1 :=NULL;
      BEGIN
        SELECT COL_STATEEVENTSTATE INTO v_Id1
        FROM TBL_DICT_StateEvent
        WHERE col_id=v_parentId; 
      EXCEPTION
        WHEN NO_DATA_FOUND THEN v_Id1 :=NULL;
        WHEN OTHERS THEN v_Id1 :=NULL;
      END;

      IF UPPER(v_DataTypeFormat)='JSON' THEN        
        IF v_Id1 IS NOT NULL THEN 
          v_data := v_data || '{"name": "StateId", "value": "' || v_Id1 || '"}, ';
        END IF;
        v_data := v_data || '{"name": "StateEventId", "value": "' || v_parentId || '"}]';      
      END IF;  
      
      IF UPPER(v_DataTypeFormat)='XML' THEN        
        IF v_Id1 IS NOT NULL THEN           
          v_data := v_data || '<StateId>' || v_Id1 || '</StateId>';        
        END IF;
        v_data := v_data || '<StateEventId>' || v_parentId || '</StateEventId></Attributes></CustomData>';                
      END IF;      
    END IF; --MILESTONE

    IF UPPER(v_typeOfQuery)=UPPER('SLAACTION') THEN
      FOR rec IN 
      ( 
        SELECT col_ParamCode, col_ParamValue
        FROM TBL_AUTORULEPARAMTMPL
        WHERE COL_DICT_STATESLAACTIONARP = v_parentId        
  		)        
      LOOP
        IF UPPER(v_DataTypeFormat)='JSON' THEN      
          v_data := v_data || '{"name": "' || rec.col_ParamCode || '", "value": "' || rec.col_ParamValue || '"},';             
        END IF; 
        IF UPPER(v_DataTypeFormat)='XML' THEN
        v_data := v_data || '<' || rec.col_ParamCode || '>' || rec.col_ParamValue || '</' || rec.col_ParamCode || '>';        
        END IF;        
      END LOOP;
      
      IF UPPER(v_DataTypeFormat)='JSON' THEN        
        v_data := v_data || '{"name": "StateSLAActionId", "value": "' || v_parentId || '"}]';      
      END IF;  
      
      IF UPPER(v_DataTypeFormat)='XML' THEN        
        v_data := v_data || '<StateSLAActionId>' || v_parentId || '</StateSLAActionId></Attributes></CustomData>';                
      END IF;      
    END IF; --SLAACTION
        
    RETURN v_data;
  END;