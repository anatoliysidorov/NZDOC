DECLARE
    v_result INTEGER;
    v_validationresult INTEGER;
    v_message NCLOB;
BEGIN
    v_result := f_EVN_injectTaskType(
                                      taskid => F_dcm_gettaskidbyslafn(:SLAActionID),
                                      input => :INPUT,
                                      validationresult => v_validationresult,
                                      MESSAGE => v_message
                                    ) ;
    :ValidationResult := v_validationresult;
    :Message := v_message;
END;