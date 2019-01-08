declare  
 v_stateConfigId    NUMBER;  
 v_CaseSysTypeId    NUMBER;
   
  --errors variables
  v_errorCode     NUMBER;
  v_errorMessage  NVARCHAR2(255);
  v_tempErrMsg    NCLOB; 
  v_tempErrCd     INTEGER;  
 
begin
  
  v_stateConfigId := :CustomStateConfigId; 
  v_CaseSysTypeId := :CaseSysTypeId;

  v_errorMessage  := NULL;
  v_errorCode     := NULL;

  IF (v_stateConfigId IS NULL) AND (v_CaseSysTypeId IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='Milestone IDs is missing';
    GOTO cleanup;
  END IF;

  IF (v_stateConfigId IS NOT NULL) AND (v_CaseSysTypeId IS  NULL) THEN
    BEGIN
      SELECT COL_CASESYSTYPESTATECONFIG INTO v_CaseSysTypeId
      FROM TBL_DICT_STATECONFIG
      WHERE COl_ID=v_stateConfigId;
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN
        v_errorCode :=101;
        v_errorMessage :='Milestone IDs is missing';
        GOTO cleanup;
    END;
  END IF;

  FOR rec IN
  (SELECT COL_ID AS stateConfigId, COL_STATECONFIGVERSION AS VersionId
   FROM TBL_DICT_STATECONFIG
   WHERE COL_CASESYSTYPESTATECONFIG=v_CaseSysTypeId
  )
  LOOP
    DELETE FROM TBL_AUTORULEPARAMTMPL
    WHERE COL_AUTORULEPARTMPLSTATEEVENT IN
          (SELECT COL_ID FROM TBL_DICT_STATEEVENT  WHERE COL_STATEEVENTSTATE IN
           (SELECT COL_ID  FROM TBL_DICT_STATE 
            WHERE COL_STATESTATECONFIG=rec.stateConfigId));
            
    DELETE FROM TBL_AUTORULEPARAMTMPL
    WHERE COL_DICT_STATESLAACTIONARP IN
          (SELECT COl_ID FROM TBL_DICT_STATESLAACTION WHERE
           COL_STATESLAACTNSTATESLAEVNT IN
           (SELECT COL_ID FROM TBL_DICT_STATESLAEVENT WHERE 
            COL_STATESLAEVENTDICT_STATE IN
            (SELECT COL_ID FROM TBL_DICT_STATE WHERE COL_STATESTATECONFIG=rec.stateConfigId)));
   
    DELETE FROM TBL_DICT_STATESLAACTION 
    WHERE COL_STATESLAACTNSTATESLAEVNT IN
     (SELECT COL_ID FROM TBL_DICT_STATESLAEVENT WHERE 
      COL_STATESLAEVENTDICT_STATE IN
      (SELECT COL_ID FROM TBL_DICT_STATE WHERE COL_STATESTATECONFIG=rec.stateConfigId));    

    DELETE FROM TBL_DICT_STATESLAEVENT 
    WHERE  COL_STATESLAEVENTDICT_STATE IN
           (SELECT COL_ID FROM TBL_DICT_STATE WHERE COL_STATESTATECONFIG=rec.stateConfigId);            
                
    DELETE FROM TBL_DICT_TRANSITION 
    WHERE (COL_SOURCETRANSITIONSTATE IN 
    (SELECT COL_ID FROM TBL_DICT_STATE WHERE COL_STATESTATECONFIG=rec.stateConfigId))
    AND 
    (COL_TARGETTRANSITIONSTATE IN 
    (SELECT COL_ID FROM TBL_DICT_STATE WHERE COL_STATESTATECONFIG=rec.stateConfigId));
        
    DELETE FROM TBL_DICT_STATEEVENT WHERE COL_STATEEVENTSTATE IN
    (SELECT COL_ID FROM TBL_DICT_STATE WHERE COL_STATESTATECONFIG=rec.stateConfigId);
    
    DELETE FROM TBL_DICT_STATE WHERE COL_STATESTATECONFIG=rec.stateConfigId;

    DELETE FROM TBL_DICT_VERSION WHERE COL_id=rec.VersionId;

    DELETE FROM TBL_DICT_STATECONFIG WHERE COl_ID=rec.stateConfigId;
  END LOOP;

      
  v_errorCode :=NULL;
  v_errorMessage :=NULL;

  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
  --RETURN 0;  

  --error block
  <<cleanup>>
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;  
  --RETURN -1; 

end;