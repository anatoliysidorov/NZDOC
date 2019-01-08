DECLARE
   v_id             NUMBER;

   v_errorcode      NUMBER;
   v_errormessage   NVARCHAR2(255);
BEGIN
   v_id := :Id;

   :affectedRows := 0;
   v_errorcode := 0;
   v_errormessage := '';

   --Input params check
   IF v_id IS NULL
   THEN
      v_errormessage := 'Id can not be empty';
      v_errorcode := 101;
      GOTO cleanup;
   END IF;

   BEGIN
      -- delete AutoRuleParameters
      DELETE TBL_AUTORULEPARAMETER
       WHERE col_autoruleparamslaaction = v_id;

      -- delete SLAEvent
      DELETE TBL_SLAEVENT
       WHERE col_id = (SELECT col_slaactionslaevent
                         FROM TBL_SLAACTION
                        WHERE col_id = v_id);

      -- delete SLAAction
      DELETE TBL_SLAACTION
       WHERE col_id = v_id;

      :SuccessResponse := 'Record has been deleted';
      :affectedRows := SQL%ROWCOUNT;
   EXCEPTION
      WHEN OTHERS
      THEN
         :affectedRows := 0;
         v_errorcode := 102;
         v_errormessage := SUBSTR(SQLERRM, 1, 200);
         :SuccessResponse := '';         
   END;

  <<cleanup>>
   :errorCode := v_errorcode;
   :errorMessage := v_errormessage;
END;