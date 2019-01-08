DECLARE
   v_Id             NUMBER;
   v_StateId        NUMBER;
   v_WorkbasketId   NUMBER;

   v_errorcode      NUMBER;
   v_errormessage   NVARCHAR2(255);
BEGIN
   v_Id := :Id;
   v_StateId := :TaskState_Id;
   v_WorkbasketId := :WorkBasket_Id;

   :affectedRows := 0;
   v_errorcode := 0;
   v_errormessage := '';

   -- Validation
   IF (v_Id IS NULL)
   THEN
      v_errorcode := 101;
      v_errormessage := 'Id cannot be empty.';
      GOTO error_exception;
   END IF;

   BEGIN
      UPDATE TBL_TASK
         SET col_taskpreviousworkbasket = col_taskppl_workbasket, col_taskppl_workbasket = v_WorkbasketId
       WHERE col_id = v_Id;

      UPDATE TBL_TW_WORKITEM
         SET col_tw_workitemdict_taskstate = v_StateId, col_tw_workitemprevtaskstate = col_tw_workitemdict_taskstate
       WHERE col_id = (SELECT col_tw_workitemtask
                         FROM TBL_TASK
                        WHERE col_id = v_Id);

      :affectedRows := 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         :affectedRows := 0;
         v_errorcode := 102;
         v_errormessage := SUBSTR(SQLERRM, 1, 200);
   END;

  <<error_exception>>
   :errorCode := v_errorcode;
   :errorMessage := v_errormessage;
END;