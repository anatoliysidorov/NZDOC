DECLARE
   v_errorCode          NUMERIC;
   v_errorMessage       NVARCHAR2(255);

   v_TaskDependencyId   NUMERIC;
BEGIN
   v_errorCode := 0;
   v_errorMessage := '';

   v_TaskDependencyId := :Id;

   -- delete Auto Rule Parameters
   BEGIN
      DELETE FROM TBL_AUTORULEPARAMETER
            WHERE COL_AUTORULEPARAMTASKDEP = v_TaskDependencyId;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errorCode := 100;
         v_errorMessage := SUBSTR(SQLERRM, 1, 200);
         GOTO cleanup;
   END;

   -- delete Task Dependency
   BEGIN
      DELETE FROM TBL_TASKDEPENDENCY
            WHERE COL_ID = v_TaskDependencyId;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errorCode := 1;
         v_errorMessage := 'Error during deleting Task Dependency';
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