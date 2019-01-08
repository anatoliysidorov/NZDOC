declare
  v_input nclob;
  v_result number;
  v_modeloverwrite number;
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
begin
  v_input := :Input;
  v_modeloverwrite := :ModelOverwrite;
  v_result := f_MDM_modifyModelConfig (Config => v_input, Id => ID, ErrorXMLData => v_ErrorMessage, IsModelValid => 1);
  v_result := f_DOM_parseDOMModel(ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, Input => v_input);
  v_result := f_DOM_executeDOMModel(ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, ModelOverwrite => v_modeloverwrite, RootOnly => 1);
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  
  -- Temporary success response
  :SUCCESSRESPONSE := 'Updated {{MESS_NAME}} model';
  V_RESULT := LOC_I18N(MESSAGETEXT  => :SUCCESSRESPONSE,
                        MESSAGERESULT => :SUCCESSRESPONSE,
                        MESSAGEPARAMS => NES_TABLE(KEY_VALUE('MESS_NAME', :NAME)));
end;