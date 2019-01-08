DECLARE
  v_stateConfig INTEGER;
  v_res         INTEGER;
BEGIN

  :ErrorCode    := 0;
  :ErrorMessage := '';
  v_stateConfig := :STATECONFIG;
  v_res := f_stp_destroycasestatedetail(errorcode =>  :ErrorCode, errormessage => :ErrorMessage, stateconfig => v_stateConfig);
  
 END; 