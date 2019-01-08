BEGIN 
    DECLARE 
        v_errorcode         NUMBER; 
        v_errormessage      NVARCHAR2(255); 
        v_intervalds        NVARCHAR2(255); 
        v_intervalym        NVARCHAR2(255); 
        v_slaeventtype_id   INTEGER;
		v_slaeventlevel_id   INTEGER; 
		v_dateeventtype_id   INTEGER; 
        v_seconds           INTEGER; 
        v_minutes           INTEGER; 
        v_hours             INTEGER; 
        v_days              INTEGER; 
        v_weeks             INTEGER; 
        v_months            INTEGER; 
        v_maxattempts       INTEGER;
        v_SlaEventOrder     INTEGER;
		
		v_Case_Id INTEGER;
		v_TaskTemplate_Id INTEGER;
		v_TaskSysType_Id INTEGER;
						
        v_secondsstr        NVARCHAR2(255); 
        v_minutesstr        NVARCHAR2(255); 
        v_hoursstr          NVARCHAR2(255); 
        v_daysstr           NVARCHAR2(255); 
        v_weeksstr          NVARCHAR2(255); 
        v_monthsstr         NVARCHAR2(255); 
    BEGIN 
        BEGIN 
            v_errorcode := 0; 
            v_errormessage := ''; 
            :affectedRows := 0; 
            :recordId := 0; 

            v_maxattempts := :MaxAttempts; 
			v_slaeventtype_id := :SLAEventType_Id; 
			v_slaeventlevel_id := :SLAEventLevel_Id; 
			v_dateeventtype_id := :DateEventType_Id; 
			v_Case_Id := :Case_Id; 
			v_TaskTemplate_Id := :TaskTemplate_Id; 
			v_TaskSysType_Id := :TaskSysType_Id; 
			
			-- set default interval data
            v_seconds := CASE 
                           WHEN ( :Seconds IS NULL ) THEN 0 
                           ELSE :Seconds 
                         END; 

            v_minutes := CASE 
                           WHEN ( :Minutes IS NULL ) THEN 0 
                           ELSE :Minutes 
                         END; 

            v_hours := CASE 
                         WHEN ( :Hours IS NULL ) THEN 0 
                         ELSE :Hours 
                       END; 

            v_days := CASE 
                        WHEN ( :Days IS NULL ) THEN 0 
                        ELSE :Days 
                      END; 

            v_weeks := CASE 
                         WHEN ( :Weeks IS NULL ) THEN 0 
                         ELSE :Weeks 
                       END; 

            v_months := CASE 
                          WHEN ( :Months IS NULL ) THEN 0 
                          ELSE :Months 
                        END; 

            -- convert weeks to days 
            v_days := ( v_weeks * 7 ) + v_days; 

            -- convert to Interval 
            v_intervalds := To_dsinterval(v_days 
                                          || ' ' 
                                          || v_hours 
                                          || ':' 
                                          || v_minutes 
                                          || ':' 
                                          || v_seconds); 

            v_intervalym := To_yminterval('00' 
                                          || '-' 
                                          || v_months); 


            begin
              select nvl(max(col_slaeventorder),0) + 1 into v_SlaEventOrder from tbl_slaevent where col_slaeventtasktemplate = v_TaskTemplate_Id;
              exception
              when NO_DATA_FOUND then
              v_SlaEventOrder := 1;
            end;

            -- insert record
            INSERT INTO tbl_slaevent 
                        (col_code,
                         col_intervalds, 
                         col_intervalym, 
                         col_maxattempts, 
                         col_attemptcount,
						 COL_SLAEVENTDICT_SLAEVENTTYPE,
						 COL_SLAEVENT_DATEEVENTTYPE,
						 COL_SLAEVENT_SLAEVENTLEVEL,
						 COL_SLAEVENTCASE,
						COL_SLAEVENTTASKTEMPLATE,
						COL_SLAEVENTDICT_TASKSYSTYPE,
                        COL_SLAEVENTORDER
						 ) 
            VALUES      (sys_guid(),
                         v_intervalds,
                         v_intervalym,
                         v_maxattempts,
                         0,
						 v_slaeventtype_id,
						 v_dateeventtype_id,
						 v_slaeventlevel_id,
						 v_Case_Id,
						 v_TaskTemplate_Id,
						 v_TaskSysType_Id,
                         v_SlaEventOrder
						 ); 

            SELECT gen_tbl_slaevent.CURRVAL 
            INTO   :recordId 
            FROM   dual; 

            :affectedRows := 1; 
        EXCEPTION 
            WHEN no_data_found THEN 
              :affectedRows := 0; 
            WHEN dup_val_on_index THEN 
              :affectedRows := 0; 
            WHEN OTHERS THEN 
              v_errorcode := 100; 
              v_errormessage := Substr(SQLERRM, 1, 200); 
        END; 

        <<cleanup>> 
        :ErrorMessage := v_errormessage;
        :ErrorCode := v_errorcode; 
    END; 
END; 