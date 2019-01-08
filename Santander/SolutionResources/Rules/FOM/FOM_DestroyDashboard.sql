DECLARE
  v_Id      INTEGER;
  v_Ids     NVARCHAR2(32767);
  v_errCode NUMBER;
  v_errMsg  NVARCHAR2(255);
  v_return  NUMBER;
BEGIN
  :ErrorCode       := 0;
  :ErrorMessage    := '';
  :affectedRows    := 0;
  v_Ids            := :Ids;
  v_Id             := :Id;
  :SuccessResponse := EMPTY_CLOB();

  --Input params check 
  IF (v_Id IS NULL AND v_Ids IS NULL) THEN
    :ErrorMessage := 'Id can not be empty';
    :ErrorCode    := 101;
    RETURN;
  END IF;

  IF (v_Id IS NOT NULL) THEN
    v_Ids := TO_CHAR(v_Id);
  END IF;

  -- delete from ac_acl
  DELETE FROM tbl_ac_acl
   WHERE col_aclaccessobject IN
         (SELECT col_id
            FROM tbl_ac_accessobject
           WHERE col_accessobjectuielement IN
                 (SELECT col_id
                    FROM tbl_fom_uielement
                   WHERE col_uielementdashboard IN
                         (SELECT TO_NUMBER(COLUMN_VALUE) AS id
                            FROM TABLE(ASF_SPLIT(v_Ids, ',')))));

  -- delete from ac_accessobject
  DELETE FROM tbl_ac_accessobject
   WHERE col_accessobjectuielement IN
         (SELECT col_id
            FROM tbl_fom_uielement
           WHERE col_uielementdashboard IN
                 (SELECT TO_NUMBER(COLUMN_VALUE) AS id
                    FROM TABLE(ASF_SPLIT(v_Ids, ','))));

  DELETE TBL_FOM_UIELEMENT
   WHERE col_UIElementDashboard IN
         (SELECT TO_NUMBER(COLUMN_VALUE) AS id
            FROM TABLE(ASF_SPLIT(v_Ids, ',')));

  DELETE TBL_FOM_DASHBOARD
   WHERE COL_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) AS id
                      FROM TABLE(ASF_SPLIT(v_Ids, ',')));
  :affectedRows := SQL%ROWCOUNT;

  DELETE TBL_FOM_DASHBOARDCW
   WHERE col_Dashboard IN
         (SELECT TO_NUMBER(COLUMN_VALUE) AS id
            FROM TABLE(ASF_SPLIT(v_Ids, ',')));

  -- delete some localization key for the page
  FOR rec IN (SELECT TO_NUMBER(COLUMN_VALUE) AS ID
                FROM TABLE(ASF_SPLIT(v_Ids, ','))) LOOP
    v_return := F_LOC_IMPORTKEY(ERRORCODE    => v_errCode,
                                ERRORMESSAGE => v_errMsg,
                                NAMESPACE    => 'Builder',
                                SOURCEID     => rec.ID,
                                SOURCETYPE   => 'Dashboard',
                                XML_INPUT    => NULL);
  END LOOP;
  :ErrorMessage := v_errMsg;
  :ErrorCode    := v_errCode;
  --get affected rows
  v_return := LOC_i18n(MessageText   => 'Deleted {{MESS_COUNT}} items',
                       MessageResult => :SuccessResponse,
                       MessageParams => NES_TABLE(Key_Value('MESS_COUNT',
                                                            :affectedRows)));
END;