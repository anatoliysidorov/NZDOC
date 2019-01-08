DECLARE
	--CUSTOM 
	V_ID          NUMBER;
	V_TYPELINK    NUMBER;
	V_PARENT      NUMBER;
	V_CHILD       NCLOB;
	V_DESCRIPTION NCLOB;
	v_childCaseIds NCLOB;

	--STANDARD 
	V_ERRORCODE    NUMBER;
	V_ERRORMESSAGE NVARCHAR2(2000);

	V_COUNTOFCHILD NUMBER;
	V_RESULT NVARCHAR2(255);
	V_FULLERRORMESSAGE NVARCHAR2(2000) := '';

BEGIN
  --CUSTOM 
  V_ID          := :LINKID;
  V_PARENT      := :LINK_PARENTCASEID;
  V_CHILD       := :LINK_CHILDCASEID;
  V_DESCRIPTION := :LINK_DESCRIPTION;
  V_TYPELINK    := :LINK_TYPE;
  V_COUNTOFCHILD := 0;

  --STANDARD 
  :AFFECTEDROWS  := 0;
  V_ERRORCODE    := 0;
  V_ERRORMESSAGE := '';
  :SUCCESSRESPONSE := '';
  :ExecutionLog := '';
  :ERRORCODE := '';
  :ERRORMESSAGE := '';

  IF V_PARENT IS NULL OR V_CHILD IS NULL THEN
    V_ERRORCODE    := 101;
    V_ERRORMESSAGE := 'Parent or Source case is undefined';
    GOTO CLEANUP;
  END IF;

 -- Validation for existing a Case Link with such parameters
  Select Count(*)
  Into V_ERRORCODE
  From TBL_CASELINK
  Where COL_CASELINKPARENTCASE = V_PARENT
      AND COL_CASELINKCHILDCASE in (SELECT to_number(trim(regexp_substr(V_CHILD,'[^,]+',1,LEVEL))) l FROM dual
       					    			 CONNECT BY LEVEL <= regexp_count(V_CHILD,',') + 1)
      AND COL_CASELINKDICT_LINKTYPE = V_TYPELINK
      AND COL_ID <> nvl(V_ID, -1);

  IF V_ERRORCODE > 0 THEN
		V_ERRORCODE := 103;
		V_ERRORMESSAGE := 'There already exists a Case(s) with the same Link Type (see execution log)';

		begin
			select list_collect(cast(collect(to_char(cm.col_caseid) order by to_char(cm.col_caseid)) as split_tbl), ', ',1) into v_childCaseIds
			from tbl_case cm
			inner join tbl_caselink cl on cl.col_caselinkchildcase = cm.col_id
			where cm.col_id in (SELECT to_number(trim(regexp_substr(V_CHILD, '[^,]+',1,LEVEL))) l FROM dual
									 CONNECT BY LEVEL <= regexp_count(V_CHILD, ',') + 1)
					and cl.col_caselinkdict_linktype = v_typelink
      			and cl.col_id <> nvl(v_id, -1);				 
		exception
			when no_data_found then
				NULL;
		end;	
		:ExecutionLog := 'List of linked case(s): ' || v_childCaseIds;
		:SUCCESSRESPONSE := '';
		GOTO CLEANUP;
  END IF;

  --SET ASSUMED SUCCESS MESSAGE
  IF V_ID IS NOT NULL THEN
    	:SUCCESSRESPONSE := 'Updated';
  ELSE
    	:SUCCESSRESPONSE := 'Cases were successfully linked';
  END IF;

  BEGIN
    --ADD NEW RECORD OR UPDATE EXISTING ONE 
    IF V_ID IS NULL THEN
      FOR CHILD_IDS IN 
      (
		  	SELECT to_number(trim(regexp_substr(V_CHILD, '[^,]+', 1, LEVEL))) as COLUMN_VALUE
			FROM dual
			CONNECT BY LEVEL <= regexp_count(V_CHILD,',') + 1		
      )
      LOOP

        V_RESULT := F_DCM_VALPTNCLCASELINK( 
                            ERRORCODE        => V_ERRORCODE,
                            ERRORMESSAGE     => v_ERRORMESSAGE,
                            FULLERRORMESSAGE => V_FULLERRORMESSAGE,
                            CASE_ID          => V_PARENT,
                            POTENTAL_CHILD   => CHILD_IDS.COLUMN_VALUE,
                            POTENTIAL_PARENT => V_PARENT
                            );

        IF(NVL(V_ERRORCODE,0) != 0) THEN
          :SUCCESSRESPONSE := '';
          v_ERRORMESSAGE := v_ERRORMESSAGE || ' (see execution log) ';
			 :ExecutionLog := V_FULLERRORMESSAGE;
          ROLLBACK;
          GOTO CLEANUP;
        END IF;

        INSERT INTO TBL_CASELINK
          (COL_CASELINKPARENTCASE, COL_CASELINKCHILDCASE, COL_CASELINKDICT_LINKTYPE, COL_CASELINKLINKDIRECTION, COL_DESCRIPTION)
        VALUES
          (V_PARENT, CHILD_IDS.COLUMN_VALUE, V_TYPELINK, 1, V_DESCRIPTION);
      END LOOP CHILD_IDS;
    ELSE
      UPDATE TBL_CASELINK
         SET COL_CASELINKDICT_LINKTYPE = V_TYPELINK,
             COL_DESCRIPTION           = V_DESCRIPTION
       WHERE COL_ID = V_ID;
    END IF;
  
    :AFFECTEDROWS := SQL%ROWCOUNT;
    :RECORDID     := V_ID;
  
  EXCEPTION
    WHEN OTHERS THEN
      :AFFECTEDROWS    := 0;
      V_ERRORCODE      := 102;
      V_ERRORMESSAGE   := SUBSTR(SQLERRM, 1, 200);
      :SUCCESSRESPONSE := '';
  END;

  <<CLEANUP>>
  :ERRORCODE    := V_ERRORCODE;
  :ERRORMESSAGE := V_ERRORMESSAGE;
END;