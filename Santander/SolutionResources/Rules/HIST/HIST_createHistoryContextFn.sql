DECLARE
    v_targettype NVARCHAR2(255);
BEGIN
    v_targettype := lower(:targettype);
    IF v_targettype = 'slamsevent' THEN
        RETURN f_HIST_createSlaMsHistoryFn(StateSLAEventId => :TargetId,
                                           StateSLAActionId =>NULL,
                                           issystem => :IsSystem,
                                           MESSAGE => :Message,
                                           messagecode => :MessageCode,
                                           additionalinfo => :AdditionalInfo,
                                           AttachTargetId => :AttachTargetId,
                                           AttachTargetType => :AttachTargetType);
    ELSIF v_targettype = 'slamsaction' THEN
        RETURN f_HIST_createSlaMsHistoryFn(StateSLAEventId => NULL,
                                           StateSLAActionId =>:TargetId,
                                           issystem => :IsSystem,
                                           MESSAGE => :Message,
                                           messagecode => :MessageCode,
                                           additionalinfo => :AdditionalInfo,
                                           AttachTargetId => :AttachTargetId,
                                           AttachTargetType => :AttachTargetType);
    ELSIF v_targettype = 'slaevent' THEN
        RETURN F_hist_createslahistoryfn(slaeventid =>:TargetId,
                                         issystem => :IsSystem,
                                         MESSAGE => :Message,
                                         messagecode => :MessageCode,
                                         additionalinfo => :AdditionalInfo,
                                         AttachTargetId => :AttachTargetId,
                                         AttachTargetType => :AttachTargetType);
    ELSE
        RETURN F_hist_createotherhistoryfn(issystem => :IsSystem,
                                           MESSAGE => :Message,
                                           messagecode => :MessageCode,
                                           additionalinfo => :AdditionalInfo);
    END IF;
END;