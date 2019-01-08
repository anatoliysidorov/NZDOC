DECLARE
   v_result   NUMBER;
BEGIN
   v_result := 0;

   BEGIN
      SELECT id
        INTO v_result
        FROM vw_ppl_activecaseworkersusers
       WHERE accode = SYS_CONTEXT('CLIENTCONTEXT', 'AccessSubject');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_result := 0;
   END;

   RETURN v_result;
END;