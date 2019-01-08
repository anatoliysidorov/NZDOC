DECLARE
  v_casetype_id          NUMBER;
  v_exp_dictionaries     NUMBER;
  v_output               NCLOB;
  v_res                  NUMBER;
  v_errorcode            NUMBER;
  v_errormessage         NVARCHAR2(255);
  v_successmessage       NVARCHAR2(255);
  v_casetype_name        NVARCHAR2(255);
  v_casetype_description NVARCHAR2(255);
  v_procedure_id         NVARCHAR2(255);
  v_procedure_code       NVARCHAR2(255);
  v_custombotags         NCLOB;
  v_result               NUMBER;
BEGIN
  v_casetype_id      := nvl(:ExportCaseTypeId, 0);
  v_exp_dictionaries := nvl(:ExportDictionaries, 0);
  v_custombotags     := :CustomBOTags;
  v_output           := '';
  v_errorcode        := 0;
  v_errormessage     := '';
  v_successmessage   := '';
  v_casetype_name    := '';

  :ErrorCode      := 0;
  :ErrorMessage   := '';
  :SuccessMessage := '';
  :XMLdata        := '';

  IF v_casetype_id != 0 THEN
    BEGIN
      SELECT cst.col_name INTO v_casetype_name FROM tbl_dict_casesystype cst WHERE cst.col_id = v_casetype_id;
    EXCEPTION
      WHEN no_data_found THEN
        v_errorcode := 1;
        v_result    := LOC_i18n(MessageText   => 'Case Type with the following id: {{MESS_CASETYPEID}} was not found!',
                                MessageResult => v_errormessage,
                                MessageParams => NES_TABLE(Key_Value('MESS_CASETYPEID', v_casetype_id)));
        GOTO cleanup;
    END;
  END IF;

  v_output := f_UTIL_exportDCMDataXMLfn(ExportCaseTypeId => v_casetype_id, ExportDictionaries => v_exp_dictionaries, custombotags => v_custombotags);
EXECUTE IMMEDIATE 'TRUNCATE TABLE tbl_impcasetype_tmp';
  IF (v_output <> Empty_clob()) THEN
    IF (v_casetype_id != 0 AND v_exp_dictionaries = 0 AND v_custombotags IS NULL) THEN
      v_successmessage := 'Case type "{{MESS_CASETYPE}}" and Global Dictionaries were successfully exported';
      v_result         := LOC_i18n(MessageText => v_successmessage, MessageResult => v_successmessage, MessageParams => NES_TABLE(Key_Value('MESS_CASETYPE', v_casetype_name)));
    ELSIF (v_casetype_id = 0 AND v_exp_dictionaries = 0 AND v_custombotags IS NOT NULL) THEN
      v_successmessage := 'Custom Data and Global Dictionaries were successfully exported';
    ELSIF (v_casetype_id = 0 AND v_exp_dictionaries != 0 AND v_custombotags IS NULL) THEN
      v_successmessage := 'Global Dictionaries were successfully exported';
    ELSE
      v_successmessage := 'Case type "{{MESS_CASETYPE}}", Global Dictionaries and Custom Data were successfully exported';
      v_result         := LOC_i18n(MessageText => v_successmessage, MessageResult => v_successmessage, MessageParams => NES_TABLE(Key_Value('MESS_CASETYPE', v_casetype_name)));
    END IF;
  END IF;

  :SuccessMessage := v_successmessage;
  :XMLdata        := v_output;

  <<cleanup>>
  :ErrorCode    := v_errorcode;
  :ErrorMessage := v_errormessage;
END;