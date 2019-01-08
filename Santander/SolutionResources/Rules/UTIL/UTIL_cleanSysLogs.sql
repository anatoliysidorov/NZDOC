DECLARE
  v_Result NUMBER;
BEGIN
  DELETE FROM TBL_UTIL_Log;
  v_Result := LOC_i18n(
    MessageText => 'Log was cleared successfully.',
    MessageResult => :SuccessResponse
  );
END;