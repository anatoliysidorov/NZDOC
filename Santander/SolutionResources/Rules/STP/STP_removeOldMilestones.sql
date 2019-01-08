DECLARE
  v_CaseSysTypeId NUMBER;

  --errors variables
  v_errorCode INTEGER;
  v_errorMessage NCLOB;

BEGIN
  --input
  v_CaseSysTypeId :=  :CaseSysTypeId;


  --init
  v_errorCode    := NULL;
  v_errorMessage := '';


  IF NVL(v_CaseSysTypeId,0)=0 THEN
    v_errorCode := 101;
    v_errorMessage := 'CaseSysTypeId cannot be NULL or empty';
    GOTO cleanup;
  END IF;

  FOR rec IN
  (
    SELECT s1.StateConfigId--, SUM(s1.CasesCount) AS CasesCount
    FROM
    (
      SELECT --s.COL_ID AS StateId, 
             s.COL_STATESTATECONFIG AS StateConfigId,
             COUNT(C.COL_ID)  AS CasesCount      
      FROM TBL_DICT_STATE s
      LEFT JOIN TBL_CASE  c on c.COL_CASEDICT_STATE=s.COL_ID
      WHERE s.COL_STATESTATECONFIG IN
        (
        SELECT stc.COL_ID
        FROM TBL_DICT_STATECONFIG stc
        WHERE stc.COL_STATECONFIGVERSION IN
              (
                SELECT COL_DICTVERCASESYSTYPE 
                FROM TBL_DICT_CASESYSTYPE 
                WHERE COL_ID = v_CaseSysTypeId
              ) 
              AND stc.COL_ISCURRENT <>1 
              AND stc.COL_REVISION <>1
      )
      GROUP BY s.COL_ID, s.COL_STATESTATECONFIG
    ) s1
    GROUP BY s1.StateConfigId
    HAVING SUM(s1.CasesCount)=0
    ORDER BY s1.StateConfigId
  )
  LOOP
    --arp sla
    DELETE  FROM TBL_AUTORULEPARAMTMPL
    WHERE COL_DICT_STATESLAACTIONARP IN
      (SELECT COL_ID 
       FROM TBL_DICT_STATESLAACTION
       WHERE COL_STATESLAACTNSTATESLAEVNT IN
        (SELECT COL_ID 
         FROM TBL_DICT_STATESLAEVENT
         WHERE COL_STATESLAEVENTDICT_STATE IN
          (SELECT COl_ID 
           FROM TBL_DICT_STATE
           WHERE COL_STATESTATECONFIG=:StateConfigId)
         )
      );

    --arp events
    DELETE FROM TBL_AUTORULEPARAMTMPL
    WHERE COL_AUTORULEPARTMPLSTATEEVENT IN
      (SELECT COL_ID 
       FROM TBL_DICT_STATEEVENT
       WHERE COL_STATEEVENTSTATE IN
        (SELECT COl_ID
         FROM TBL_DICT_STATE
         WHERE COL_STATESTATECONFIG=rec.StateConfigId)
      );

    --sla actions
    DELETE FROM TBL_DICT_STATESLAACTION
    WHERE COL_STATESLAACTNSTATESLAEVNT IN
      (SELECT COL_ID 
       FROM TBL_DICT_STATESLAEVENT
       WHERE COL_STATESLAEVENTDICT_STATE IN
        (SELECT COl_ID 
         FROM TBL_DICT_STATE
         WHERE COL_STATESTATECONFIG=:StateConfigId)
       );

    --sla events    
    DELETE FROM TBL_DICT_STATESLAEVENT
     WHERE COL_STATESLAEVENTDICT_STATE IN
      (SELECT COl_ID 
       FROM TBL_DICT_STATE
       WHERE COL_STATESTATECONFIG=:StateConfigId);

    --state events
    DELETE FROM TBL_DICT_STATEEVENT
    WHERE COL_STATEEVENTSTATE IN
    (SELECT COl_ID
     FROM TBL_DICT_STATE
     WHERE COL_STATESTATECONFIG=rec.StateConfigId);

    --transitions
    DELETE FROM TBL_DICT_TRANSITION
    WHERE COL_SOURCETRANSITIONSTATE IN
    (SELECT COl_ID
     FROM TBL_DICT_STATE
     WHERE COL_STATESTATECONFIG=rec.StateConfigId);
    
    DELETE FROM TBL_DICT_TRANSITION    
    WHERE COL_TARGETTRANSITIONSTATE IN
    (SELECT COl_ID
     FROM TBL_DICT_STATE
     WHERE COL_STATESTATECONFIG=rec.StateConfigId);

    --states
    DELETE FROM TBL_DICT_STATE
    WHERE COL_STATESTATECONFIG=rec.StateConfigId;

   --state config
   DELETE FROM TBL_DICT_STATECONFIG WHERE COL_ID=rec.StateConfigId;
  END LOOP;-- rec

  --END
  :ErrorCode := NULL;
  :ErrorMessage := '';
  RETURN ;
  
  --error block
  <<cleanup>> 
 :ErrorCode := v_errorCode;
 :ErrorMessage := v_errorMessage;	
 RETURN ;

END;