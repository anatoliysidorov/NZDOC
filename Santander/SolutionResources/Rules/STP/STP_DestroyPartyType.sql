DECLARE
  v_Id INTEGER;
  v_isDetailedInfo BOOLEAN;
  v_Ids NVARCHAR2(32767);
  v_listNotAllowDelete BOOLEAN := FALSE;
  v_countDeletedRecords INTEGER;
  v_count_temp INTEGER;
  v_MessageText NCLOB;
  v_MessageParams NES_TABLE := NES_TABLE();
  v_result        NUMBER;

  CURSOR Participant IS
    Select COL_CUSTOMCONFIG as CustomConfig
    From TBL_PARTICIPANT 
    Where DBMS_LOB.GETLENGTH(COL_CUSTOMCONFIG) != 0 and DBMS_LOB.GETLENGTH(COL_CUSTOMCONFIG) is not null;

  CURSOR CaseParty IS
    Select COL_CUSTOMCONFIG as CustomConfig
    From TBL_CASEPARTY 
    Where DBMS_LOB.GETLENGTH(COL_CUSTOMCONFIG) != 0 and DBMS_LOB.GETLENGTH(COL_CUSTOMCONFIG) is not null;
  
  CURSOR cur_DictPartyType (p_Ids IN NVARCHAR2) IS
    SELECT COL_ID AS ID,
           COL_ISSYSTEM AS ISSYSTEM, 
           COL_CODE AS CODE, 
           COL_NAME AS NAME
      FROM TBL_DICT_PartyType
     WHERE COL_ID IN (SELECT TO_NUMBER(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(p_Ids, ',')));

  PROCEDURE getCountInXML (
      xPath     IN NVARCHAR2,
      XML       IN NCLOB,
      UnitCode  IN NVARCHAR2,
      counter   OUT INTEGER
  ) AS
  BEGIN
      SELECT count(*)
      INTO counter
      FROM 
        XMLTABLE(xPath
        PASSING xmlType(XML)
        COLUMNS unit nvarchar2(255) PATH 'text()'
      )
      WHERE unit = UnitCode;
  END;
   
BEGIN
    :affectedRows   := 0;
    v_Id            := :Id;
    v_Ids           := :Ids;
    :SuccessResponse := EMPTY_CLOB();
    v_countDeletedRecords := 0;
    
    -- validate for input parameters
    IF (v_Ids IS NULL AND v_Id IS NULL) THEN
      v_result := LOC_i18n(
        MessageText => 'Id can not be empty',
        MessageResult => :ErrorMessage);
      :ErrorCode := 101;
      RETURN;
    END IF;

    IF(v_Id IS NOT NULL) THEN
      v_Ids := TO_CHAR(v_id);
      v_isDetailedInfo := false;
    ELSE
      v_isDetailedInfo := true;
    END IF;

    FOR mRec IN cur_DictPartyType(v_Ids)
    LOOP
      -- validate for system record
      IF (mRec.ISSYSTEM = 1) THEN
        v_listNotAllowDelete := TRUE;
        IF(v_isDetailedInfo) THEN
          v_MessageParams.EXTEND(1);
          v_MessageParams(v_MessageParams.LAST) := KEY_VALUE('MESS_NAME', mRec.NAME);
          v_MessageText := 'Count of deleted Party Types: {{MESS_COUNT}}'
                        || '<br>List of not deleted Party Type(s): {{MESS_NAME}} (it''s a system record)<br>';
        ELSE
          v_MessageText := 'Count of deleted Party Types: {{MESS_COUNT}}'
                        || '<br>List of not deleted Party Type(s): Party Type is a system record';
        END IF;
        CONTINUE;
      END IF;

      v_count_temp := 0;    
      SELECT COUNT(*) INTO v_count_temp
        FROM TBL_EXTERNALPARTY  
       WHERE COL_EXTERNALPARTYPARTYTYPE = mRec.ID AND ROWNUM = 1;
        
      IF (v_count_temp > 0) THEN
        v_listNotAllowDelete := TRUE;
        IF(v_isDetailedInfo) THEN
          v_MessageParams.EXTEND(1);
          v_MessageParams(v_MessageParams.LAST) := KEY_VALUE('MESS_NAME', mRec.NAME);
          v_MessageText := 'Count of deleted Party Types: {{MESS_COUNT}}'
                        || '<br>List of not deleted Party Type(s): {{MESS_NAME}} (relates with External Party(ies))<br>';
        ELSE
          :ErrorCode := 102;
          v_result := LOC_I18N(
            MessageText => 'Party Type relates with External Party(ies)',
            MessageResult => :ErrorMessage
          );
        END IF;    
        CONTINUE;
      END IF;

      v_count_temp := 0;    
      FOR rec IN CaseParty 
      LOOP
        getCountInXML(
          '/CustomData/Attributes/FILTER_ExternalPartyType',
          rec.CustomConfig,
          mRec.CODE,
          v_count_temp
        );
        IF (v_count_temp != 0) THEN
          EXIT;
        END IF;
      END LOOP;
    
      IF (v_count_temp > 0) THEN
        v_listNotAllowDelete := TRUE;
        IF(v_isDetailedInfo) THEN
          v_MessageParams.EXTEND(1);
          v_MessageParams(v_MessageParams.LAST) := KEY_VALUE('MESS_NAME', mRec.NAME);
          v_MessageText := 'Count of deleted Party Types: {{MESS_COUNT}}'
                        || '<br>List of not deleted Party Type(s): {{MESS_NAME}} (relates with Case Party(ies))<br>';
        ELSE
          :ErrorCode := 102;
          v_result := LOC_I18N(
            MessageText => 'Party Type relates with Case Party(ies)',
            MessageResult => :ErrorMessage
          );
        END IF; 
        CONTINUE;
      END IF;

      v_count_temp := 0;
      FOR rec IN Participant 
      LOOP
        getCountInXML(
          '/CustomData/Attributes/FILTER_ExternalPartyType',
          rec.CustomConfig,
          mRec.CODE,
          v_count_temp
        );
        IF v_count_temp != 0 THEN
          EXIT;
        END IF;
      END LOOP;

      IF (v_count_temp > 0) THEN
        v_listNotAllowDelete := TRUE;
        IF(v_isDetailedInfo) THEN
          v_MessageParams.EXTEND(1);
          v_MessageParams(v_MessageParams.LAST) := KEY_VALUE('MESS_NAME', mRec.NAME);
          v_MessageText := 'Count of deleted Party Types: {{MESS_COUNT}}'
                        || '<br>List of not deleted Party Type(s): {{MESS_NAME}} (relates with Participant(s))<br>';
        ELSE
          :ErrorCode := 102;
          v_result := LOC_I18N(
            MessageText => 'Party Type relates with Participant(s)',
            MessageResult => :ErrorMessage
          );
        END IF; 
        CONTINUE;
      END IF;

       --delete all associations with sub-types
      DELETE TBL_MAP_PARTYTYPE
       WHERE COL_PARENTPARTYTYPE = mRec.ID OR COL_CHILDPARTYTYPE = mRec.ID;
       
      --delete record
      DELETE TBL_DICT_PartyType
       WHERE col_Id = mRec.ID;

      v_countDeletedRecords := v_countDeletedRecords + 1;

    END LOOP; 
    
    :affectedRows := SQL%ROWCOUNT; 
    v_MessageParams.EXTEND(1);
    v_MessageParams(v_MessageParams.LAST) := Key_Value('MESS_COUNT', v_countDeletedRecords);
    
    IF(v_listNotAllowDelete) THEN        
      :ErrorCode := 102;
      IF(v_isDetailedInfo) THEN
        v_result := LOC_I18N(
          MessageText => v_MessageText,
          MessageResult => :ErrorMessage,
          MessageParams => v_MessageParams
        );
      END IF;
    ELSE
      v_result := LOC_I18N(
        MessageText => 'Deleted {{MESS_COUNT}} items',
        MessageResult => :SuccessResponse,
        MessageParams => v_MessageParams
      );
    END IF;
END;