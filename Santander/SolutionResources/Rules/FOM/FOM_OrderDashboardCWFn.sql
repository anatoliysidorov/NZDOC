DECLARE
	v_FromID	   NUMBER;
	v_ToID		   NUMBER;
	--v_vector       NUMBER;
	v_CW_ID		   NUMBER;
	v_FromOrder    NUMBER;
	v_ToOrder      NUMBER;
	v_errorCode	   NUMBER;
	v_isNew   	   NUMBER;
	v_count   	   NUMBER;
	v_errorMessage NVARCHAR2(255);
	v_Position     NVARCHAR2(255);
    v_Condition1   NVARCHAR2(255);
    v_Condition2   NVARCHAR2(255);
    v_flagFirst    NUMBER;
BEGIN
	v_errorCode		:= 0;
	v_errorMessage	:= '';
	:affectedRows   := 0;
	v_FromID        := :FromID;
	v_ToID          := :ToID;
	v_isNew         := 0;
	v_Position      := :Position;
    v_count         := 9999999;
    
	--Check the input params
	IF v_FromID IS NULL THEN
		v_errorMessage := 'From Id can not be empty';
		v_errorCode    := 101;
		GOTO cleanup;
	ELSIF v_ToID IS NULL THEN
		v_errorMessage := 'To Id can not be empty';
		v_errorCode    := 101;
		GOTO cleanup;
	ELSIF v_Position IS NULL THEN
		v_errorMessage := 'Position can not be empty';
		v_errorCode    := 101;
		GOTO cleanup;
	END IF;

    -- Get case worker ID
    v_CW_ID := f_dcm_getcaseworkerId();
    IF v_CW_ID Is Null THEN
		v_errorMessage := 'Caseworker ID can not be empty';
		v_errorCode    := 102;
		GOTO cleanup;
    END IF;

    -- Get the start order value 
    Begin
        Select COL_DASHBOARDORDER Into v_FromOrder From TBL_FOM_DASHBOARDCW  Where COL_CASEWORKER = v_CW_ID AND COL_DASHBOARD = v_FromID;
    Exception
        When NO_DATA_FOUND Then
            --Select NVL(Min(COL_DASHBOARDORDER), 0) Into v_FromOrder From TBL_FOM_DASHBOARDCW  Where COL_CASEWORKER = v_CW_ID;
            v_isNew := 1;
    End;
    
    BEGIN
        v_flagFirst := 0;
        FOR rec IN (
            SELECT dbd.col_id AS DashboardID, dbd_cw.col_id as DashboardCW_ID, nvl(dbd_cw.COL_DASHBOARDORDER, 0) AS DASHBOARDORDER, COUNT( * ) OVER (PARTITION BY 1) TOTALCOUNT
            FROM tbl_fom_dashboard dbd
                Left Join TBL_FOM_DASHBOARDCW dbd_cw On (dbd_cw.COL_DASHBOARD = dbd.col_id AND dbd_cw.COL_CASEWORKER = v_CW_ID)
            Where ((dbd.COL_DASHBOARDCASEWORKER = v_CW_ID) or (dbd.col_isSystem = 1 and nvl(dbd.COL_DASHBOARDCASEWORKER, 0) = 0))
                AND nvl(dbd.col_isDeleted, 0) = 0
            Order By nvl(dbd_cw.COL_DASHBOARDORDER, 0) DESC
        )
        LOOP
            IF (v_flagFirst = 0) THEN
                v_count := rec.TOTALCOUNT;
                v_flagFirst := 1;
            End If;
            If rec.DashboardID = v_FromID Then
                Continue;
            End If;
            
            IF (rec.DashboardID = v_ToID AND lower(v_Position) = 'before') Then
                v_ToOrder := v_count;
                v_count := v_count - 1;
            End If;
            
            If rec.DashboardCW_ID is null Then
                INSERT INTO TBL_FOM_DASHBOARDCW (COL_CASEWORKER, COL_DASHBOARD, COL_DASHBOARDORDER) VALUES (v_CW_ID, rec.DashboardID, v_count);
            Else
                UPDATE TBL_FOM_DASHBOARDCW SET COL_DASHBOARDORDER = v_count Where COL_ID = rec.DashboardCW_ID;
            End If;
            
            IF (rec.DashboardID = v_ToID AND lower(v_Position) = 'after') Then
                v_count := v_count - 1;
                v_ToOrder := v_count;
            End If;
            v_count := v_count - 1;
        END LOOP;
    
        If v_isNew = 1 Then
            INSERT INTO TBL_FOM_DASHBOARDCW (COL_CASEWORKER, COL_DASHBOARD, COL_DASHBOARDORDER) VALUES (v_CW_ID, v_FromID, v_ToOrder);
        Else
            UPDATE TBL_FOM_DASHBOARDCW SET COL_DASHBOARDORDER = v_ToOrder Where COL_CASEWORKER = v_CW_ID AND COL_DASHBOARD = v_FromID;
        End If;
    
  Exception
      WHEN OTHERS THEN
          v_errorcode      := 103;
          v_errormessage   := substr(SQLERRM, 1, 200);
          ROLLBACK;
          GOTO cleanup;
  End;

	--get affected rows
	:affectedRows := SQL%ROWCOUNT;

	<<cleanup>>
	:errorMessage := v_errorMessage;
	:errorCode    := v_errorCode;
END;