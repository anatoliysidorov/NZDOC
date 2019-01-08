DECLARE 
    v_orgchartId     INTEGER; 
    v_dataXML NVARCHAR2(32767);
BEGIN 
    v_orgchartId := :OrgChartId; 
    v_dataXML := :DATAXML;   

    IF(v_dataXML IS NULL OR v_orgchartId IS NULL) THEN
      :ErrorMessage  := 'Input params are not found';
      :ErrorCode     := 101;
      RETURN;
    END IF;

    FOR rec IN (SELECT 
                    CHILDID AS CHILDID, 
                    PARENTID AS PARENTID 
                FROM
                XMLTABLE('/ITEMS/ITEM'
                    PASSING xmltype(v_dataXML)
                    COLUMNS
                        CHILDID  INTEGER PATH './CHILDID',
                        PARENTID  INTEGER PATH './PARENTID'
                ) xmlt
    ) LOOP        
    
        DELETE FROM tbl_ppl_orgchartmap
        WHERE col_orgchartorgchartmap = v_orgchartId 
            AND col_CaseWorkerChild = rec.CHILDID 
            AND col_CaseWorkerParent = rec.PARENTID; 
    
    END LOOP;         

END; 