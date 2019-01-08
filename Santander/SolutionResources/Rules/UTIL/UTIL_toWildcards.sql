DECLARE 
    v_SearchText NCLOB;
BEGIN

	v_SearchText := '%'||LOWER(NVL(:SearchText, ''))|| '%';
    RETURN v_SearchText; 
END;