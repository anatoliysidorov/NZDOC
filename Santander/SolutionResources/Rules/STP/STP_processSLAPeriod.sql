DECLARE  
  
  v_iYEARS      INTEGER;
  v_iMONTHS     INTEGER;
  v_iDAYS       INTEGER;
  v_iHOURS      INTEGER;
  v_iMINUTES    INTEGER;
  v_iSECONDS    INTEGER;
  v_iWEEKS      INTEGER; 

  v_YEARS       NVARCHAR2(255);
  v_MONTHS      NVARCHAR2(255);
  v_DAYS        NVARCHAR2(255);
  v_HOURS       NVARCHAR2(255);
  v_MINUTES     NVARCHAR2(255);
  v_SECONDS     NVARCHAR2(255);
  v_WEEKS       NVARCHAR2(255);  
  v_intervalYM  NVARCHAR2(255);
  v_intervalDS  NVARCHAR2(255);
 
  --errors variables
  v_tmpNumber     NUMBER;
  v_errorCode     NUMBER;
  v_errorMessage  NVARCHAR2(255);
 
BEGIN
    
  v_YEARS      := :pYEARS;
  v_MONTHS     := :pMONTHS; 
  v_DAYS       := :pDAYS; 
  v_HOURS      := :pHOURS;
  v_MINUTES    := :pMINUTES;
  v_SECONDS    := :pSECONDS;
  v_WEEKS      := :pWEEKS;
  
  v_intervalYM := NULL;
  v_intervalDS := NULL;
  v_tmpNumber  := NULL; 

  v_iYEARS     :=0; 
  v_iMONTHS    :=0; 
  v_iDAYS      :=0; 
  v_iHOURS     :=0; 
  v_iMINUTES   :=0; 
  v_iSECONDS   :=0; 
  v_iWEEKS     :=0;  
  
  v_errorMessage  := NULL;
  v_errorCode     := NULL;
  
  --error(s) handling
  IF v_MONTHS IS NULL AND v_DAYS IS NULL AND v_HOURS IS NULL AND v_MINUTES IS NULL AND 
     v_SECONDS IS NULL AND v_WEEKS IS NULL AND v_YEARS IS NULL THEN
    v_errorcode      := 101;
    v_errormessage   := 'At least one parameter required for the SLA event';
    GOTO cleanup;
  END IF; 

  v_tmpNumber:=NULL;
  SELECT MOD(TO_NUMBER(NVL(v_YEARS, '0')), 1) INTO v_tmpNumber FROM dual;
  IF v_tmpNumber =0 THEN v_iYEARS := TO_NUMBER(NVL(v_YEARS, '0')); END IF;
  IF v_tmpNumber <>0 THEN 
    v_errorcode      := 101;
    v_errormessage   := 'Parameter Years is invalid. Only Integer value(s) allowed';
    GOTO cleanup;
  END IF;    

  v_tmpNumber:=NULL;
  SELECT MOD(TO_NUMBER(NVL(v_MONTHS, '0')), 1) INTO v_tmpNumber FROM dual;
  IF v_tmpNumber =0 THEN v_iMONTHS := TO_NUMBER(NVL(v_MONTHS, '0')); END IF;
  IF v_tmpNumber <>0 THEN 
    v_errorcode      := 101;
    v_errormessage   := 'Parameter Months is invalid. Only Integer value(s) allowed';
    GOTO cleanup;
  END IF; 

  SELECT MOD(TO_NUMBER(NVL(v_DAYS, '0')), 1) INTO v_tmpNumber FROM dual;
  IF v_tmpNumber =0 THEN v_iDAYS := TO_NUMBER(NVL(v_DAYS, '0')); END IF;
  IF v_tmpNumber <>0 THEN 
    v_errorcode      := 101;
    v_errormessage   := 'Parameter Days is invalid. Only Integer value(s) allowed';
    GOTO cleanup;
  END IF; 

  SELECT MOD(TO_NUMBER(NVL(v_HOURS, '0')), 1) INTO v_tmpNumber FROM dual;
  IF v_tmpNumber =0 THEN v_IHOURS := TO_NUMBER(NVL(v_HOURS, '0')); END IF;
  IF v_tmpNumber <>0 THEN 
    v_errorcode      := 101;
    v_errormessage   := 'Parameter Hours is invalid. Only Integer value(s) allowed';
    GOTO cleanup;
  END IF; 

  SELECT MOD(TO_NUMBER(NVL(v_MINUTES, '0')), 1) INTO v_tmpNumber FROM dual;
  IF v_tmpNumber =0 THEN v_iMINUTES := TO_NUMBER(NVL(v_MINUTES, '0')); END IF;
  IF v_tmpNumber <>0 THEN 
    v_errorcode      := 101;
    v_errormessage   := 'Parameter Minutes is invalid. Only Integer value(s) allowed';
    GOTO cleanup;
  END IF; 

  SELECT MOD(TO_NUMBER(NVL(v_SECONDS, '0')), 1) INTO v_tmpNumber FROM dual;
  IF v_tmpNumber =0 THEN v_iSECONDS := TO_NUMBER(NVL(v_SECONDS, '0')); END IF;
  IF v_tmpNumber <>0 THEN 
    v_errorcode      := 101;
    v_errormessage   := 'Parameter Seconds is invalid. Only Integer value(s) allowed';
    GOTO cleanup;
  END IF; 

  SELECT MOD(TO_NUMBER(NVL(v_WEEKS, '0')), 1) INTO v_tmpNumber FROM dual;
  IF v_tmpNumber =0 THEN v_iWEEKS := TO_NUMBER(NVL(v_WEEKS, '0')); END IF;
  IF v_tmpNumber <>0 THEN 
    v_errorcode      := 101;
    v_errormessage   := 'Parameter Weeks is invalid. Only Integer value(s) allowed';
    GOTO cleanup;
  END IF;

  IF v_iSECONDS>=60 THEN
    v_iMINUTES :=v_iMINUTES+TRUNC(v_iSECONDS/60);
    v_iSECONDS := v_iSECONDS - (TRUNC(v_iSECONDS/60)*60);
  END IF;

  IF v_iMINUTES>=60 THEN
    v_iHOURS :=v_iHOURS+TRUNC(v_iMINUTES/60);
    v_iMINUTES := v_iMINUTES - (TRUNC(v_iMINUTES/60)*60);
  END IF;

  IF v_iHOURS>=24 THEN
    v_iDAYS :=v_iDAYS+TRUNC(v_iHOURS/24);
    v_iHOURS := v_iHOURS - (TRUNC(v_iHOURS/24)*24);
  END IF;

  v_iDAYS := v_iDAYS + (v_iWEEKS*7);
  
  IF v_iDAYS>=31 THEN
    v_iMONTHS :=v_iMONTHS+TRUNC(v_iDAYS/31);
    v_iDAYS := v_iDAYS - (TRUNC(v_iDAYS/31)*31);
  END IF;

  IF v_iMONTHS>=12 THEN
    v_iYEARS :=v_iYEARS+TRUNC(v_iMONTHS/12);
    v_iMONTHS := v_iMONTHS - (TRUNC(v_iMONTHS/12)*12);
  END IF;

  IF v_iSECONDS<10 THEN v_SECONDS := '0'||TO_CHAR(v_iSECONDS); END IF;
  IF v_iSECONDS>=10 THEN v_SECONDS := TO_CHAR(v_iSECONDS); END IF;

  IF v_iMINUTES<10 THEN v_MINUTES := '0'||TO_CHAR(v_iMINUTES); END IF;
  IF v_iMINUTES>=10 THEN v_MINUTES := TO_CHAR(v_iMINUTES); END IF;

  IF v_iHOURS<10 THEN v_HOURS := '0'||TO_CHAR(v_iHOURS); END IF;
  IF v_iHOURS>=10 THEN v_HOURS := TO_CHAR(v_iHOURS); END IF;

  IF v_iDAYS<10 THEN v_DAYS := '0'||TO_CHAR(v_iDAYS); END IF;
  IF v_iDAYS>=10 THEN v_DAYS := TO_CHAR(v_iDAYS); END IF;

  IF v_iMONTHS<10 THEN v_MONTHS := '0'||TO_CHAR(v_iMONTHS); END IF;
  IF v_iMONTHS>=10 THEN v_MONTHS := TO_CHAR(v_iMONTHS); END IF;

  IF v_iYEARS<10 THEN v_YEARS := '0'||TO_CHAR(v_iYEARS); END IF;
  IF v_iYEARS>=10 THEN v_YEARS := TO_CHAR(v_iYEARS); END IF;
         
  v_intervalYM := v_YEARS||'-' || v_MONTHS;
  v_intervalDS := v_DAYS || ' ' ||v_HOURS || ':' ||v_MINUTES || ':' ||v_SECONDS;
           
  v_errorCode :=NULL;
  v_errorMessage :=NULL;
  
  :intYM := v_intervalYM;
  :intDS := v_intervalDS;  

  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
  RETURN 0;  

  --error block
  <<cleanup>>
  :intYM := NULL;
  :intDS := NULL;    
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;  
  RETURN -1; 

END;