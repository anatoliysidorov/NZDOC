DECLARE
  v_CaseId Integer; 
  v_createdby nvarchar2(255);
  v_createddate date;
  v_modifiedby nvarchar2(255);
  v_modifieddate date;
  v_owner nvarchar2(255);
  v_counter number;  
  v_CSisInCache INTEGER;
  v_caseSysType NUMBER;

BEGIN
  v_CaseId        := :CaseId;
  v_owner         := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  v_createdby     := v_owner;
  v_createddate   := sysdate;
  v_modifiedby    := v_createdby;
  v_modifieddate  := v_createddate;
  v_CSisInCache   := f_DCM_CSisCaseInCache(v_caseid);--new cache

  --case not in new cache
  IF v_CSisInCache=0 THEN	
    select gen_tbl_map_casestateinitiat.nextval into v_counter from dual;

    SELECT COL_CASEDICT_CASESYSTYPE INTO v_caseSysType
    FROM TBL_CASE 
    WHERE COL_ID = v_CaseId;

    begin
      insert into tbl_map_casestateinitiation(col_code, col_map_casestateinitcase, col_map_csstinit_csst, col_processorcode, col_assignprocessorcode, col_casestateinit_initmethod,
                                              col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
        (select sys_guid(), v_CaseId, col_map_csstinittp_csst, col_processorcode, col_assignprocessorcode, col_casestateinittp_initmtd, v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
           from tbl_map_casestateinittmpl
           where col_casestateinittp_casetype = v_caseSysType);
     exception
       when DUP_VAL_ON_INDEX then
         return -1;
       when OTHERS then
         return -1;
    end;

  END IF;

  --case in new cache
  IF v_CSisInCache=1 THEN	
    SELECT gen_tbl_map_casestateinitiat.nextval INTO v_counter FROM dual;

    SELECT COL_CASEDICT_CASESYSTYPE INTO v_caseSysType
    FROM TBL_CSCASE 
    WHERE COL_ID = v_CaseId;

    FOR rec IN
    (SELECT COL_MAP_CSSTINITTP_CSST, COL_PROCESSORCODE, COL_ASSIGNPROCESSORCODE, COL_CASESTATEINITTP_INITMTD 
     FROM TBL_MAP_CASESTATEINITTMPL
     WHERE COL_CASESTATEINITTP_CASETYPE = v_caseSysType)
    LOOP  
      SELECT gen_tbl_map_casestateinitiat.nextval INTO v_counter FROM dual;     
      INSERT INTO TBL_MAP_CASESTATEINITIATION(COL_ID, COL_CODE, COL_MAP_CASESTATEINITCASE, 
                                              COL_MAP_CSSTINIT_CSST, COL_PROCESSORCODE, COL_ASSIGNPROCESSORCODE, 
                                              COL_CASESTATEINIT_INITMETHOD, COL_CREATEDBY, COL_CREATEDDATE, 
                                              COL_MODIFIEDBY,COL_MODIFIEDDATE,COL_OWNER)
      VALUES
      (
        v_counter,  SYS_GUID(), v_CaseId,
        rec.COL_MAP_CSSTINITTP_CSST, rec.COL_PROCESSORCODE, rec.COL_ASSIGNPROCESSORCODE, 
        rec.COL_CASESTATEINITTP_INITMTD, v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
      );
      
    END LOOP;
  END IF;
END;