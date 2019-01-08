DECLARE
  v_MessageText   NCLOB;
  v_MessageParams NCLOB;
  v_Result        NUMBER;
BEGIN
  v_MessageParams := :MessageParams;
  v_MessageText   := :MessageText;
  v_Result := LOC_i18n(
    MessageText => v_MessageText,
    MessageResult => v_MessageText,
    MessageParams => NULL,
    MessageParams2 => v_MessageParams
  );
  :MessageResult := v_MessageText;
END;