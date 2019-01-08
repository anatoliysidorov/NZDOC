DECLARE
   v_errorCode        NUMERIC;
   v_errorMessage     NVARCHAR2(255);

   v_TaskTemplateId   NUMERIC;
BEGIN
   v_errorCode := 0;
   v_errorMessage := '';

   v_TaskTemplateId := :Id;

   -- delete Task State Initiation
   BEGIN
      DELETE FROM TBL_MAP_TASKSTATEINITIATION
            WHERE COL_MAP_TASKSTATEINITTASKTMPL = v_TaskTemplateId;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errorCode := 100;
         v_errorMessage := SUBSTR(SQLERRM, 1, 200);
         GOTO cleanup;
   END;

   -- recursive delete Task Template
   BEGIN
      DELETE FROM TBL_TASKTEMPLATE
            WHERE COL_ID = (    SELECT COL_ID
                                  FROM TBL_TASKTEMPLATE
                            CONNECT BY PRIOR COL_ID = COL_PARENTTTID
                            START WITH COL_ID = v_TaskTemplateId);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errorCode := 1;
         v_errorMessage := 'Error during deleting Task Template';
         GOTO cleanup;
      WHEN OTHERS
      THEN
         v_errorCode := 100;
         v_errorMessage := SUBSTR(SQLERRM, 1, 200);
         GOTO cleanup;
   END;

  <<cleanup>>
   :errorMessage := v_errorMessage;
   :errorCode := v_errorCode;
END;