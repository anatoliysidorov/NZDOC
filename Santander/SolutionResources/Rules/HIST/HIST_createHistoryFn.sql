DECLARE
    v_targettype NVARCHAR2(255) ;
BEGIN
    v_targettype := lower(:targettype) ;
	
    IF v_targettype = 'task' THEN        
        RETURN F_hist_createtaskhistoryfn(taskid =>:TargetId,
                                          issystem => :IsSystem,
                                          MESSAGE => :Message,
                                          messagecode => :MessageCode,
                                          additionalinfo => :AdditionalInfo,
										  MessageTypeId => NULL);
    ELSIF v_targettype = 'case' THEN
        RETURN F_hist_createcasehistoryfn(caseid => :TargetId,
                                          issystem => :IsSystem,
                                          MESSAGE => :Message,
                                          messagecode => :MessageCode,
                                          additionalinfo => :AdditionalInfo,
										  MessageTypeId => NULL) ;
    ELSE
        RETURN F_hist_createotherhistoryfn(issystem => :IsSystem,
                                           MESSAGE => :Message,
                                           messagecode => :MessageCode,
                                           additionalinfo => :AdditionalInfo) ;
    END IF;
END;