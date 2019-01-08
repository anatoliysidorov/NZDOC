DECLARE
    sql_text       VARCHAR2(1000) ;
    v_UnitId       NUMBER;
    v_WorkbasketId NUMBER;
    v_UnitType NVARCHAR2(255) ;
    v_unitTable  VARCHAR2(255) ;
    v_unitColumn VARCHAR2(255) ;
BEGIN
    v_UnitId := :UnitId;
    v_UnitType := :UnitType;
    
    IF v_UnitId IS NULL THEN
        RETURN -1;
    END IF;
    
    IF v_UnitType IS NULL THEN
        RETURN -1;
    END IF;
    
    IF UPPER(v_UnitType) = 'TEAM' THEN
        v_unitTable := 'TBL_PPL_TEAM';
        v_unitColumn := 'COL_WORKBASKETTEAM';
    ELSIF UPPER(v_UnitType) = 'SKILL' THEN
        v_unitTable := 'TBL_PPL_SKILL';
        v_unitColumn := 'COL_WORKBASKETSKILL';
    ELSIF UPPER(v_UnitType) = 'BUSINESSROLE' THEN
        v_unitTable := 'TBL_PPL_BUSINESSROLE';
        v_unitColumn := 'COL_WORKBASKETBUSINESSROLE';
    ELSIF UPPER(v_UnitType) = 'EXTERNALPARTY' THEN
        v_unitTable := 'TBL_EXTERNALPARTY';
        v_unitColumn := 'COL_WORKBASKETEXTERNALPARTY';
    ELSIF UPPER(v_UnitType) = 'EXTERNAL_PARTY' THEN
        /*-- same as for 'EXTERNALPARTY'*/
        v_unitTable := 'TBL_EXTERNALPARTY';
        v_unitColumn := 'COL_WORKBASKETEXTERNALPARTY';
    ELSIF UPPER(v_UnitType) = 'CASEWORKER' THEN
        v_unitTable := 'TBL_PPL_CASEWORKER';
        v_unitColumn := 'COL_CASEWORKERWORKBASKET';
    END IF;
    
    sql_text := '        
SELECT            
wb.COL_ID        
FROM TBL_PPL_WORKBASKET wb            
INNER JOIN TBL_DICT_WORKBASKETTYPE wb_type ON (wb_type.COL_ID = wb.COL_WORKBASKETWORKBASKETTYPE AND lower(wb_type.COL_CODE) = ''personal'')            
INNER JOIN __UNIT_TABLE__ unit_table ON (wb.__KEY_COLUMN__ = unit_table.COL_ID AND unit_table.COL_ID = :'||'1)        
WHERE wb.COL_ISDEFAULT = 1 AND ROWNUM = 1';
    sql_text := REPLACE(sql_text,'__UNIT_TABLE__',v_unitTable) ;
    sql_text := REPLACE(sql_text,'__KEY_COLUMN__',v_unitColumn) ;
    
    BEGIN
        EXECUTE IMMEDIATE sql_text INTO v_WorkbasketId USING v_UnitId;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_WorkbasketId := -1;
    END;
    
    RETURN v_WorkbasketId;
    /*--DBMS_OUTPUT.PUT_LINE('' || v_WorkbasketId);*/
END;