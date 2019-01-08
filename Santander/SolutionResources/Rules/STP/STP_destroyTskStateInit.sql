DECLARE
   v_errorCode         NUMERIC;
   v_errorMessage      NVARCHAR2(255);

   v_TaskStateInitId   NUMERIC;
BEGIN
   v_errorCode := 0;
   v_errorMessage := '';

   v_TaskStateInitId := :Id;

   -- delete Auto Rule Parameters
   BEGIN
      DELETE FROM TBL_AUTORULEPARAMETER
            WHERE COL_RULEPARAM_TASKSTATEINIT = v_TaskStateInitId;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errorCode := 100;
         v_errorMessage := SUBSTR(SQLERRM, 1, 200);
         GOTO cleanup;
   END;

   -- delete Case Dependency
   BEGIN
      DELETE FROM TBL_CASEDEPENDENCY
            WHERE COL_CASEDPNDCHLDTASKSTATEINIT = v_TaskStateInitId;

      DELETE FROM TBL_CASEDEPENDENCY
            WHERE COL_CASEDPNDPRNTTASKSTATEINIT = v_TaskStateInitId;
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
            WHERE COL_TSKDPNDCHLDTSKSTATEINIT = v_TaskStateInitId;

      DELETE FROM TBL_TASKDEPENDENCY
            WHERE COL_TSKDPNDPRNTTSKSTATEINIT = v_TaskStateInitId;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errorCode := 100;
         v_errorMessage := SUBSTR(SQLERRM, 1, 200);
         GOTO cleanup;
   END;

   -- delete Task Event
   BEGIN
      DELETE FROM TBL_TASKEVENT
            WHERE COL_TASKEVENTTASKSTATEINIT = v_TaskStateInitId;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errorCode := 100;
         v_errorMessage := SUBSTR(SQLERRM, 1, 200);
         GOTO cleanup;
   END;

   -- delete Task State Initiation
   BEGIN
      DELETE FROM TBL_MAP_TASKSTATEINITIATION
            WHERE COL_ID = v_TaskStateInitId;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errorCode := 1;
         v_errorMessage := 'Error during deleting Task State Initiation';
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