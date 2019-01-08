/*
    rule PATCH_updateCTVersion.sql

    Important information

    This patch applied to DCM version 4.3.130 "Sunrise" (build 4.3.130.0) or earlier.
    A patch do update a DICT_CaseSysType: (fill COL_DICTVERCASESYSTYPE from DICT_Version)
    This patch takes only "MILESTONE" records what linked to case type.
     
    
    A next conditions must be required before use a patch:

    Add a relationship        
    Source business object :  DICT_Version
    Target business object :  DICT_CaseSysType
    Cardinality            :  One source to many targets
    Relationship Name      :  DICTVerCaseSysType
          
    Delete a relationship   
    Source business object :  DICT_StateConfig
    Relationship Name      :  MSStateConfigCaseSysType 
           
*/


DECLARE
  v_column_exists NUMBER;

  --errors variables
  v_errorCode     NUMBER;
  v_errorMessage  NVARCHAR2(255);
  v_statBefore    NUMBER;
  v_statPatched   NUMBER;
   

BEGIN

  v_column_exists := 0;
  v_errorCode     := NULL;
  v_errorMessage  := NULL;

  v_statBefore    := NULL;
  v_statPatched   := 0;


  SELECT COUNT(*) INTO v_column_exists
  FROM user_tab_cols
  WHERE column_name = 'COL_DICTVERCASESYSTYPE' AND table_name = 'TBL_DICT_CASESYSTYPE';
      
  IF (v_column_exists = 0) THEN
    v_errorCode :=-1;
    v_errorMessage :='Cannot found a column "COL_DICTVERCASESYSTYPE" in the "TBL_DICT_CASESYSTYPE" (must be added)';
    GOTO cleanup;      
  END IF;

  v_column_exists :=0;
  SELECT COUNT(*) INTO v_column_exists
  FROM user_tab_cols
  WHERE column_name = 'COL_MSSTATECONFIGCASESYSTYPE' AND table_name = 'TBL_DICT_CASESYSTYPE';
      
  IF (v_column_exists <> 0) THEN
    v_errorCode :=-1;
    v_errorMessage :='A column "COL_MSSTATECONFIGCASESYSTYPE" was found in the "TBL_DICT_CASESYSTYPE" (must be deleted)';
    GOTO cleanup;      
  END IF;


  SELECT COUNT(1) INTO v_statBefore
  FROM
  (
     SELECT DISTINCT sc.COL_CASESYSTYPESTATECONFIG AS CASESYSTYPEID,
                     sc.COL_STATECONFIGVERSION AS VERID 
     FROM TBL_DICT_STATECONFIG sc
     INNER JOIN TBL_DICT_CASESYSTYPE cs ON cs.col_id=sc.COL_CASESYSTYPESTATECONFIG
     WHERE sc.COL_TYPE='MILESTONE' AND 
           sc.COL_STATECONFIGVERSION IS NOT NULL AND 
           sc.COL_CASESYSTYPESTATECONFIG IS NOT NULL AND
           cs.COL_DICTVERCASESYSTYPE IS NULL
   ) s;

  IF (v_statBefore=0) THEN
    v_errorCode :=0;
    v_errorMessage :='Completed. No records found to patch.';
    GOTO cleanup;      
  END IF;

  --patch
  FOR rec IN
  (
   SELECT DISTINCT sc.COL_CASESYSTYPESTATECONFIG AS CASESYSTYPEID,
                   sc.COL_STATECONFIGVERSION AS VERID 
   FROM TBL_DICT_STATECONFIG sc
   INNER JOIN TBL_DICT_CASESYSTYPE cs ON cs.col_id=sc.COL_CASESYSTYPESTATECONFIG
   WHERE sc.COL_TYPE='MILESTONE' AND 
         sc.COL_STATECONFIGVERSION IS NOT NULL AND 
         sc.COL_CASESYSTYPESTATECONFIG IS NOT NULL AND
         cs.COL_DICTVERCASESYSTYPE IS NULL) --we can run this patch a again and again
  LOOP
    BEGIN
      UPDATE TBL_DICT_CASESYSTYPE
      SET COL_DICTVERCASESYSTYPE=rec.VERID
      WHERE COL_ID=rec.CASESYSTYPEID;

    v_statPatched :=v_statPatched+1;
        
    EXCEPTION       
      WHEN OTHERS THEN 
        v_errorCode :=-1;
        v_errorMessage :='Error: Cant update a Case Type with Id: '||TO_CHAR(rec.CASESYSTYPEID)||
                         '. Please contact your Sysrem Administrator';
        GOTO cleanup; 
    END;
  END LOOP;

  --exit block           
  :ErrorCode := 0;
  :ErrorMessage := 'Update was successful! Updated records '||TO_CHAR(v_statPatched)||' of '||TO_CHAR(v_statBefore);    
  RETURN;


  --error block
  <<cleanup>>
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;    
  RETURN;

END;