DECLARE 
    v_CodedText NCLOB;
BEGIN

SELECT
  UPPER(REGEXP_REPLACE (
    REGEXP_REPLACE(TRIM(:UncodedText), '[^0-9A-Za-z]*$', '')
  ,'[^0-9A-Za-z]'
  ,'_'))
INTO v_CodedText
FROM DUAL;


    RETURN v_CodedText; 
END;