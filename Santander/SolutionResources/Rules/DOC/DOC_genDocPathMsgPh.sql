BEGIN  
  :PlaceholderResult := '<b>' || f_DOC_getDocumentPath(:documentid) || '</b>';
EXCEPTION
WHEN no_data_found THEN
  :PlaceholderResult := 'NONE';
WHEN OTHERS THEN
  :PlaceholderResult := 'SYSTEM ERROR';
END;