DECLARE
    v_taskid INTEGER;
    v_target nvarchar2(255) ;
    v_result NUMBER;
    v_resolutionid INTEGER;
    v_workbasketid INTEGER;
    v_CustomData NCLOB;
    v_routecustomdataprocessor nvarchar2(255) ;
    v_tasktypeid INTEGER;
    v_errorcode NUMBER;
    v_errormessage NCLOB;
BEGIN
    v_taskid := :TaskId;
    v_target := :Target;
    v_resolutionid := :ResolutionId;
    v_workbasketid := :WorkbasketId;
    v_CustomData := :CUSTOMDATA;
    v_result := f_DCM_taskTransitionManualFn(CUSTOMDATA => v_CustomData,
                                             ErrorCode => v_errorcode,
                                             ErrorMessage => v_errormessage,
                                             ResolutionId => v_resolutionid,
                                             Target => v_target,
                                             TaskId => v_taskid,
                                             WorkbasketId => v_workbasketid) ;
    :ErrorCode := v_errorcode;
    :ErrorMessage := v_errormessage;
END;