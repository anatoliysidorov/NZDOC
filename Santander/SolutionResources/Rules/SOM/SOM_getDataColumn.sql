DECLARE
  v_query VARCHAR2(32767);
  v_refCursor SYS_REFCURSOR;
  --
  v_tableName NVARCHAR2(255);
  v_columnCode NVARCHAR2(255);
  v_Dir NVARCHAR2(255);
  --
  v_Select NVARCHAR2(255);
  v_From NVARCHAR2(255);
  v_Where NVARCHAR2(255);
  v_Alias NVARCHAR2(255);
  v_XmlAlias NVARCHAR2(255);
  v_Order NVARCHAR2(255);
  --
  v_ObjId NUMBER;
  v_StorageType NVARCHAR2(255);
  v_dataType NVARCHAR2(255);
  v_columnName NVARCHAR2(255);
BEGIN
  v_tableName := :TableName;
  v_columnCode := :ColumnCode;
  v_Dir := NVL(:DIR, 'ASC');
  
  IF (LENGTH(v_tableName) > 0 AND LENGTH(v_columnCode) > 0 
      AND v_tableName IS NOT NULL AND v_columnCode IS NOT NULL)
  THEN
    SELECT COL_TABLENAME, COL_ALIAS, COL_XMLALIAS, COL_ID INTO v_From, v_Alias, v_XmlAlias, v_ObjId
      FROM TBL_FOM_OBJECT
     WHERE COL_NAME = v_tableName
       AND ROWNUM < 2;
  
    SELECT attr.COL_COLUMNNAME, attr.COL_STORAGETYPE, dataType.COL_CODE INTO v_columnName, v_StorageType, v_dataType
      FROM TBL_FOM_ATTRIBUTE attr
      LEFT JOIN TBL_DICT_DATATYPE dataType 
        ON dataType.COL_ID = attr.COL_FOM_ATTRIBUTEDATATYPE
     WHERE attr.COL_FOM_ATTRIBUTEFOM_OBJECT = v_ObjId
       AND attr.COL_CODE = v_columnCode
       AND ROWNUM < 2;  
  
    v_From := 'FROM ' || v_From || ' ' || v_Alias;
    
    IF (UPPER(v_StorageType) = 'XML') 
    THEN
      v_Select := 'SELECT DISTINCT ' || v_XmlAlias || '.' || v_columnCode || ' AS ITEM';
      v_From := v_From || ' ,xmltable(''/CustomData/Attributes'' passing ' 
                || v_Alias || '.'  || v_columnName || ' columns ' || v_columnCode 
                || ' varchar2(255) path ' || '''' || v_columnCode || '''' || ' ) '  || v_XmlAlias;
      v_Where := 'WHERE ' || v_XmlAlias || '.' || v_columnCode || ' IS NOT NULL' ;
    ELSE
      IF (UPPER(v_dataType) = 'DATE')
      THEN
        v_Select := 'SELECT DISTINCT TO_CHAR(' || v_Alias || '.' || v_columnName || ', ''DD-MON-YYYY'') AS ITEM';
      ELSE
        v_Select := 'SELECT DISTINCT ' || v_Alias || '.' || v_columnName || ' AS ITEM';
      END IF;
      v_Where := 'WHERE ' || v_Alias || '.' || v_columnName || ' IS NOT NULL';
    END IF;

    IF (UPPER(v_dataType) = 'DATE')
    THEN
      v_Order := 'ORDER BY TO_DATE(ITEM, ''DD-MON-YYYY'') ' || v_Dir;
    ELSE
      v_Order := 'ORDER BY ITEM ' || v_Dir;
    END IF;

    v_query := v_Select || ' ' ||  v_From || ' ' || v_Where || ' ' || v_Order;
    --DBMS_OUTPUT.PUT_LINE(v_query);
    BEGIN
      OPEN :ITEMS for v_query;
    EXCEPTION
      WHEN OTHERS THEN
        :ErrorCode := SQLCODE;
        :ErrorMessage := SUBSTR('Error on query' || ': ' || SQLERRM, 1, 200);
    END;
  END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      :ErrorCode := SQLCODE;
      :ErrorMessage := SUBSTR(SQLERRM, 1, 200);
END;