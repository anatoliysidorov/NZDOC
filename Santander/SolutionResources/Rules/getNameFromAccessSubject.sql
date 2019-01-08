DECLARE
   v_name        NVARCHAR2(255);
   v_type        NVARCHAR2(255);
   v_firstname   NVARCHAR2(255);
   v_lastname    NVARCHAR2(255);
BEGIN
   SELECT NAME,
          TYPE,
          firstname,
          lastname
     INTO v_name,
          v_type,
          v_firstname,
          v_lastname
     FROM vw_UTIL_AccessSubject
    WHERE code = :P_Code;

   IF (v_type = 'USER' AND v_firstname IS NOT NULL AND v_lastname IS NOT NULL)
   THEN
      RETURN v_firstname || ' ' || v_lastname;
   ELSE
      RETURN v_name;
   END IF;
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      RETURN '';
END;