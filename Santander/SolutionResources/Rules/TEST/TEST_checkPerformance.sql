DECLARE
    
    v_result    NUMBER;
    v_errorCode NUMBER;
    v_errorMessage NCLOB;
    v_debugRecordsCount NUMBER;
    v_deploysCount      NUMBER;
    v_errorMessage1 NCLOB;
    v_errorMessage2 NCLOB;

BEGIN
    
    v_errorCode := 0;
    v_debugRecordsCount := 0 ;
    v_errorMessage := '';
    v_errorMessage1 := '';
    v_errorMessage2 := '';
    
    :ErrorCode := v_errorCode;
    :ErrorMessage := v_errorMessage;
    /*--Check DebugTrace table is not overflowed*/
    SELECT COUNT(col_id)
    INTO   v_debugRecordsCount
    FROM   Tbl_Debugtrace;
    
    IF v_debugRecordsCount > 50000 THEN
        v_errorCode := 139;
        v_errorMessage1 := '<li>There are a lot of records in the Case Debugger. Considering cleaning out old logs.</li>';
    END IF;
    /*-- Check if there were too many deployments*/
    SELECT     COUNT(1)
    INTO       v_deploysCount
    FROM       @TOKEN_SYSTEMDOMAINUSER@.conf_environment e
	LEFT JOIN  @TOKEN_SYSTEMDOMAINUSER@.conf_solution s ON(
			   s.environmentid = e.environmentid
			   )
	INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_component c ON(
			   lower(s.code) = lower(c.code)
			   )
	WHERE      lower(e.code) = lower('@TOKEN_DOMAIN@');
    
    IF v_deploysCount > 50 THEN
        v_errorCode := 140;
        v_errorMessage2 := '<li>There are a lot of old versions of this solution, which can affect deployment performance. Considering purging those old versions.</li>';
    END IF;
    
    /*--Check if any CaseType has Debug Mode turned on*/
    FOR rec IN(
    SELECT col_name CaseTypeName
    FROM   tbl_dict_casesystype
    WHERE  Col_Debugmode = 1
    )
    LOOP
        v_errorCode := 138;
        v_errorMessage := v_errorMessage || '<li>Case Type <b>'||rec.CaseTypeName||'</b> is in Debug Mode and can affect performance</li>';
    END LOOP;
    
    :ErrorCode := v_errorCode;
    :ErrorMessage := v_errorMessage1||v_errorMessage2||v_errorMessage;

END;