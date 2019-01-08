DECLARE
  v_orgchartId INTEGER;
  v_dataXML NVARCHAR2(32767);
BEGIN

   v_dataXML := :DATAXML;
   v_orgchartId := :OrgChartId;  
   :ErrorMessage := '';
   :ErrorCode := 0;

   IF(v_dataXML IS NULL OR v_orgchartId IS NULL) THEN
      :ErrorMessage  := 'Input params are not found';
      :ErrorCode     := 101;
      RETURN;
   END IF;

   -- Modification data
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
        
         INSERT INTO tbl_ppl_orgchartmap (
            col_caseworkerparent, 
            col_caseworkerchild, 
            col_orgchartorgchartmap) 
         VALUES
         (
            rec.PARENTID, 
            rec.CHILDID, 
            v_orgchartId
         );
            
   END LOOP;

END;