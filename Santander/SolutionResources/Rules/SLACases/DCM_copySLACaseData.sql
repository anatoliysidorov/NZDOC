DECLARE
 v_CaseId           NUMBER;
 v_caseSysTypeId    NUMBER;
 v_slaEventId       NUMBER;
 v_slaActionId      NUMBER;
  
 --calculated
 v_Result           INTEGER;

 --errors variables
 v_errorCode     NUMBER;
 v_errorMessage  NVARCHAR2(255);
 
BEGIN

  v_CaseId        := :CASEID;
       
  v_errorMessage  := NULL;
  v_errorCode     := NULL;
  v_caseSysTypeId := NULL;
  v_slaEventId    := NULL;
  v_slaActionId   := NULL;

  IF (v_CaseId IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='Case Id must be not NULL or empty.';
    GOTO cleanup;
  END IF;
  
  BEGIN 
    SELECT  COL_CASEDICT_CASESYSTYPE INTO v_caseSysTypeId
    FROM TBL_CASE 
    WHERE COL_ID=v_CaseId;
  EXCEPTION 
    WHEN NO_DATA_FOUND THEN v_caseSysTypeId:=NULL;
    WHEN OTHERS THEN v_caseSysTypeId:=NULL;
  END;

  IF (v_caseSysTypeId IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='Case Type Id must be not NULL or empty.';
    GOTO cleanup;
  END IF;

  
  FOR rec IN 
  (
   SELECT se_tmpl.COL_ID, se_tmpl.COL_ATTEMPTCOUNT, se_tmpl.COL_CODE,   se_tmpl.COL_ID2,    
          se_tmpl.COL_INTERVALDS, se_tmpl.COL_INTERVALYM, se_tmpl.COL_ISREQUIRED,
          se_tmpl.COL_MAXATTEMPTS, se_tmpl.COL_SLAEVENTORDER,              
          se_tmpl.COL_SLAEVENTTP_DATEEVENTTYPE,
          se_tmpl.COL_SLAEVENTTP_SLAEVENTLEVEL,
          se_tmpl.COL_SLAEVENTTP_SLAEVENTTYPE
   FROM TBL_SLAEVENTTMPL se_tmpl
   WHERE  se_tmpl.COL_SLAEVENTTMPLDICT_CST=v_caseSysTypeId
  )
  LOOP
    INSERT INTO TBL_SLAEVENT(COL_ATTEMPTCOUNT, COL_CODE, COL_ID2, COL_INTERVALDS,
                             COL_INTERVALYM, COL_ISREQUIRED, COL_MAXATTEMPTS,
                             COL_SLAEVENTORDER, COL_SLAEVENTDICT_SLAEVENTTYPE,           
                             COL_SLAEVENT_DATEEVENTTYPE, COL_SLAEVENT_SLAEVENTLEVEL, 
                             COL_SLAEVENTSLACASE)
    VALUES(rec.COL_ATTEMPTCOUNT, rec.COL_CODE, rec.COL_ID2, rec.COL_INTERVALDS,
           rec.COL_INTERVALYM, rec.COL_ISREQUIRED, rec.COL_MAXATTEMPTS,
           rec.COL_SLAEVENTORDER, rec.COL_SLAEVENTTP_SLAEVENTTYPE,
           rec.COL_SLAEVENTTP_DATEEVENTTYPE, rec.COL_SLAEVENTTP_SLAEVENTLEVEL,
           v_CaseId
    ) RETURNING COL_ID INTO v_slaEventId;

    
    FOR rec2 IN
    (
     SELECT sa_tmpl.COL_ID, sa_tmpl.COL_ACTIONORDER, sa_tmpl.COL_CODE, sa_tmpl.COL_DESCRIPTION,
            sa_tmpl.COL_NAME, sa_tmpl.COL_PROCESSORCODE, 
            sa_tmpl.COL_SLAACTIONTP_SLAEVENTLEVEL
     FROM TBL_SLAACTIONTMPL sa_tmpl
     WHERE sa_tmpl.COL_SLAACTIONTPSLAEVENTTP=rec.COL_ID
    )
    LOOP
      INSERT INTO TBL_SLAACTION(COL_ACTIONORDER, COL_CODE, COL_DESCRIPTION, COL_NAME,
                                COL_PROCESSORCODE, COL_SLAACTIONSLAEVENT,COL_SLAACTION_SLAEVENTLEVEL
      )
      VALUES(rec2.COL_ACTIONORDER, rec2.COL_CODE, rec2.COL_DESCRIPTION,
             rec2.COL_NAME, rec2.COL_PROCESSORCODE, v_slaEventId, rec2.COL_SLAACTIONTP_SLAEVENTLEVEL
      ) RETURNING COL_ID INTO v_slaActionId;

      
      FOR rec3 IN
      (
        SELECT arp_tmpl.COL_ID, arp_tmpl.COL_CODE, arp_tmpl.COL_ISSYSTEM, arp_tmpl.COL_PARAMCODE, 
               arp_tmpl.COL_PARAMVALUE                      
        FROM TBL_AUTORULEPARAMTMPL arp_tmpl
        WHERE arp_tmpl.COL_AUTORULEPARTPSLAACTIONTP=rec2.COL_ID
      ) 
      LOOP 
        INSERT INTO TBL_AUTORULEPARAMETER(COL_CODE, COL_ISSYSTEM, COL_PARAMCODE, COL_PARAMVALUE, COL_AUTORULEPARAMSLAACTION)
        VALUES (rec3.COL_CODE, rec3.COL_ISSYSTEM, rec3.COL_PARAMCODE, rec3.COL_PARAMVALUE, v_slaActionId);
      END LOOP; --TBL_AUTORULEPARAMTMPL
    END LOOP;--TBL_SLAACTIONTMPL
  END LOOP; --TBL_SLAEVENTTMPL

      
  v_errorCode :=NULL;
  v_errorMessage :=NULL;

  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
  RETURN 0;  

  --error block
  <<cleanup>>
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;  
  RETURN -1; 

END;