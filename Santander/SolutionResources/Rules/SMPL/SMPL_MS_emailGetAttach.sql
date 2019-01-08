DECLARE 
  v_caseid INTEGER; 
  v_result NVARCHAR2(2000); 
BEGIN 
  v_caseid := :CaseId; 
  SELECT   Listagg(to_char(url), '|||') within GROUP (ORDER BY url) 
  INTO     v_result 
  FROM     vw_doc_documents 
  WHERE    caseid = v_caseid; 
   
  :Result := v_result; 
END;