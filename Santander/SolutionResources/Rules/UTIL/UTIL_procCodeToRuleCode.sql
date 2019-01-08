DECLARE 
    v_CodedText NVARCHAR2(255);
BEGIN
SELECT 
	regexp_replace(TRIM(:UncodedText),'^(root_|f_)','',1,1,'i') 

INTO v_CodedText

FROM DUAL;


    RETURN v_CodedText; 
END;