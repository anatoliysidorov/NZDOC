DECLARE
  v_fromqry            VARCHAR2(32767);
  v_srchqry            VARCHAR2(32767);
  v_xmlfromqry         VARCHAR2(32767);
  v_whereqry           VARCHAR2(32767);
  v_orderBy            VARCHAR2(32767);
  v_query              VARCHAR2(32767);
  v_fromqrycache       VARCHAR2(32767);
  v_srchqrycache       VARCHAR2(32767);
  v_xmlfromqrycache    VARCHAR2(32767);
  v_whereqrycache      VARCHAR2(32767);
  v_isqrysaved         INTEGER;
  v_countquery         VARCHAR2(32767);
  v_configid           INTEGER;
  v_input              VARCHAR2(32767);
  v_roottable          NVARCHAR2(255);
  v_rootalias          NVARCHAR2(255);
  v_rootobjid          INTEGER;
  v_relid              INTEGER;
  v_objectid           INTEGER;
  v_parentobjectid     INTEGER;
  v_parentTable        NVARCHAR2(255);
  v_alias              NVARCHAR2(255);
  v_xmlalias           NVARCHAR2(255);
  v_columnname         NVARCHAR2(255);
  v_expr               NVARCHAR2(32767);
  v_exprstart          NVARCHAR2(255);
  v_exprend            NVARCHAR2(255);
  v_expleft            NVARCHAR2(255);
  v_expright           NVARCHAR2(255);
  TYPE ObjAliasType    IS TABLE OF VARCHAR2(64) INDEX BY VARCHAR2(64);
  TYPE ObjAddedType    IS TABLE OF NUMBER INDEX BY VARCHAR2(64);
  v_ObjectAdded        ObjAddedType;
  v_ObjectAlias        ObjAliasType;
  v_SearchAttrAdded    ObjAddedType;
  v_PathAdded          ObjAddedType;
  ---
  v_data_type_where    NVARCHAR2(255);
  v_data_type_sort     NVARCHAR2(255);
  v_date_format        NVARCHAR2(255);
  v_date_format_sort   NVARCHAR2(255);
  v_date_format_system NVARCHAR2(255);
  v_star_row           INTEGER;
  v_limit_row          INTEGER;
  v_sort               NVARCHAR2(255);
  v_defSort            NVARCHAR2(255);
  v_dir                VARCHAR2(10);
  v_currentParam        NVARCHAR2(32767);
  v_curentSearchAttr   NVARCHAR2(255);
  v_dateFrom           NVARCHAR2(255);
  v_dateTo             NVARCHAR2(255);
  v_condition          VARCHAR2(4);
  v_count              INTEGER;
  v_return             NUMBER;
  v_return2            NUMBER;
  v_ObjectsAdded       NUMBER;
  v_expInSelect        VARCHAR2(8);
  v_expInColValue      VARCHAR2(14);
  v_expInFrom          VARCHAR2(23);
  v_expInEnd           VARCHAR2(8);
  ---
  v_result             SYS_REFCURSOR;
BEGIN
  v_configid := :ConfigId;
  v_input := :Input;
  v_star_row := NVL(:FIRST, 0);
  v_limit_row := :LIMIT;
  v_sort := :SORT;
  v_dir := NVL(:DIR, 'ASC');
  v_date_format_system := 'yyyy-mm-dd"t"hh24:' || 'mi:' || 'ss';
  v_date_format := 'DD-MON-YYYY';
  IF (v_input IS NULL) THEN
    v_input := '<CustomData><Attributes></Attributes></CustomData>';
  END IF;
  --FIND ROOT BUSINESS OBJECT, TABLE, ALIAS AND SORT FIELD FOR CURRENT SEARCH CONFIGURATION
  BEGIN
    SELECT obj.COL_ID,
           obj.COL_TABLENAME,
           obj.COL_ALIAS,
           conf.COL_DEFSORTFIELD
      INTO v_rootobjid,
           v_roottable,
           v_rootalias,
           v_defSort
      FROM TBL_FOM_OBJECT obj
        INNER JOIN TBL_SOM_CONFIG conf ON obj.COL_ID = conf.COL_SOM_CONFIGFOM_OBJECT
      WHERE conf.COL_ID = v_configid;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :ErrorCode := 101;
        :ErrorMessage := 'Search configuration not found';
        RETURN -1;
  END;
  --BUILD ORDER BY CLAUSE AND ORDER BY DATA TYPE
  IF (v_defSort IS NOT NULL AND (v_sort IS NULL OR (v_sort IS NOT NULL AND v_sort = v_defSort))) THEN
    BEGIN
      SELECT v_rootalias || '.' || tfa.COL_COLUMNNAME,
             LOWER(tdd.COL_CODE)
        INTO v_sort,
             v_data_type_sort
        FROM TBL_FOM_ATTRIBUTE tfa
          LEFT JOIN TBL_DICT_DATATYPE tdd ON tdd.COL_ID = tfa.COL_FOM_ATTRIBUTEDATATYPE
        WHERE tfa.COL_FOM_ATTRIBUTEFOM_OBJECT = v_rootobjid
          AND tfa.COL_CODE = v_defSort;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
          :ErrorCode := 102;
          :ErrorMessage := 'Field for default sort does not found';
          RETURN -1;
    END;
  END IF;

  --INITIALIZE VARIABLES  
  FOR REC IN (SELECT col_id FROM tbl_fom_object)
  LOOP
    v_ObjectAdded(rec.col_id) := NULL;
    v_ObjectAlias(rec.col_id) := NULL;
  END LOOP;
  FOR REC IN (SELECT col_id FROM tbl_som_searchattr WHERE col_som_searchattrsom_config = v_configid)
  LOOP
    v_SearchAttrAdded(rec.col_id) := NULL;
  END LOOP;
  FOR rec IN (SELECT pt.COL_ID AS PathId,
                   pt.COL_JOINTYPE AS JoinType,
                   pt.COL_FOM_PATHFOM_RELATIONSHIP AS RelId,
                   LEVEL AS LevelPath
          FROM TBL_FOM_PATH pt
        CONNECT BY PRIOR COL_ID = COL_FOM_PATHFOM_PATH
        START WITH COL_ID IN (SELECT pt.COL_ID
            FROM TBL_FOM_PATH pt
              INNER JOIN TBL_FOM_RELATIONSHIP rl ON pt.COL_FOM_PATHFOM_RELATIONSHIP = rl.COL_ID
              INNER JOIN TBL_FOM_OBJECT cobj ON rl.COL_CHILDFOM_RELFOM_OBJECT = cobj.COL_ID
              INNER JOIN TBL_FOM_OBJECT pobj ON rl.COL_PARENTFOM_RELFOM_OBJECT = pobj.COL_ID
              INNER JOIN (SELECT rat.COL_SOM_RESULTATTRFOM_PATH AS PathId
                FROM TBL_SOM_RESULTATTR rat
                WHERE rat.COL_SOM_RESULTATTRSOM_CONFIG = v_ConfigId
                UNION
              SELECT sat.COL_SOM_SEARCHATTRFOM_PATH AS PathId
                FROM TBL_SOM_SEARCHATTR sat
                WHERE sat.COL_SOM_SEARCHATTRSOM_CONFIG = v_ConfigId) s1 ON pt.COL_ID = s1.PathId))
  LOOP
    v_PathAdded(rec.PathId) := 0;
  END LOOP;

  --FIND SAVED VALUES FOR QUERY PARTS
  BEGIN
    SELECT col_srchqry, col_fromqry, col_xmlfromqry, col_whereqry INTO v_srchqrycache, v_fromqrycache, v_xmlfromqrycache, v_whereqrycache
      FROM tbl_som_config WHERE col_id = v_configid;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :ErrorCode := 101;
        :ErrorMessage := 'Search configuration not found';
        RETURN -1;
  END;
  IF v_srchqrycache IS NOT NULL AND v_fromqrycache IS NOT NULL THEN
    v_isqrysaved := 1;
  ELSE
    v_isqrysaved := 0;
  END IF;
  IF v_isqrysaved = 1 THEN
    GOTO qry_saved;
  END IF;
  --------------------------------------

  --BUILD LIST OF SIMPLE SEARCH ATTRIBUTES
  v_srchqry := 'select ';
  v_fromqry := ' from ' || v_roottable || ' ' || v_rootalias;
  v_ObjectAdded(v_rootobjid) := 1;
  FOR rec IN (SELECT resattr.COL_ID AS ResultAttrId,
                     resattr.COL_CODE AS ResultAttrCode,
                     resattr.COL_CODE AS ResultAttrAlias,
                     resattr.COL_NAME AS ResultAttrName,
                     resattr.COL_METAPROPERTY as ResultAttrMetaProp,
                     resattr.COL_IDPROPERTY as ResultAttrIDProp,
                     resattr.COL_PROCESSORCODE AS ResultAttrProcCode,
                     attr.COL_COLUMNNAME AS ResAttrColumn,
                     attr.COL_ALIAS AS ResAttrAlias,
                     obj.COL_TABLENAME AS TableName,
                     dataType.COL_CODE AS columnType
      FROM TBL_SOM_RESULTATTR resattr
        LEFT JOIN TBL_FOM_PATH pt ON resattr.COL_SOM_RESULTATTRFOM_PATH = pt.COL_ID
        INNER JOIN TBL_FOM_ATTRIBUTE attr ON resattr.COL_SOM_RESULTATTRFOM_ATTR = attr.COL_ID
        INNER JOIN TBL_SOM_CONFIG conf ON resattr.COL_SOM_RESULTATTRSOM_CONFIG = conf.COL_ID
        INNER JOIN TBL_FOM_OBJECT obj ON conf.COL_SOM_CONFIGFOM_OBJECT = obj.COL_ID
        LEFT JOIN TBL_DICT_DATATYPE dataType ON dataType.COL_ID = attr.COL_FOM_ATTRIBUTEDATATYPE
      WHERE conf.COL_ID = v_configid
        AND attr.COL_STORAGETYPE = 'SIMPLE'
        AND attr.COL_FOM_ATTRIBUTEFOM_OBJECT = v_rootobjid
      ORDER BY resattr.COL_SORDER)
  LOOP
    IF (TRIM(v_srchqry) <> 'select') THEN
      v_srchqry := v_srchqry || ', ';
    END IF;
    IF rec.ResultAttrProcCode IS NULL THEN
      if rec.ResultAttrMetaProp = 1 and rec.ResultAttrIDProp = 1 then
        v_srchqry := v_srchqry || to_char(rec.ResultAttrId) || ' as ' || rec.ResultAttrAlias;
      else
        v_srchqry := v_srchqry || v_rootalias || '.' || rec.ResAttrColumn || ' as ' || rec.ResAttrAlias;
      end if;
    ELSE
      if rec.ResultAttrMetaProp = 1 and rec.ResultAttrIDProp = 1 then
        v_srchqry := v_srchqry || rec.ResultAttrProcCode || '(' || to_char(rec.ResultAttrId) || ') as ' || rec.ResultAttrAlias;
      else
        v_srchqry := v_srchqry || rec.ResultAttrProcCode || '(' || v_rootalias || '.' || rec.ResAttrColumn || ') as ' || rec.ResAttrAlias;
      end if;
    END IF;
    IF (v_sort IS NOT NULL AND LOWER(v_sort) = LOWER(rec.ResAttrAlias)) THEN
      v_data_type_sort := LOWER(rec.columnType);
      v_date_format_sort := '';
    END IF;
  END LOOP;
  
  --BUILD JOINS BASED ON INVOLVED PATHS FROM ALL SEARCH ATTRIBUTES AND RESULT ATTRIBUTES
  v_relid := NULL;
  v_parentTable := NULL;
  v_parentobjectid := null;
  --LOOP THROUGH ALL SEARCH AND RESULT ATTRIBUTES IN SEARCH CONFIG, LINKED TO THEIR RESPECTIVE PATH RECORDS
  <<start_from>>
  v_ObjectsAdded := 0;
  FOR rec IN (SELECT s2.LevelPath AS LevelPath,
                     s2.PathId AS PathId,
                     s2.PathCode AS PathCode,
                     s2.PathCode AS ParentAlias,
                     s2.PathCode AS ChildAlias,
                     s2.JoinType AS JoinType,
                     s2.RelId AS RelId,
                     rl.COL_CHILDFOM_RELFOM_OBJECT AS ChildObjectId,
                     rl.COL_PARENTFOM_RELFOM_OBJECT AS ParentObjectId,
                     rl.COL_FOREIGNKEYNAME AS ForeignKeyName,
                     cobj.COL_CODE AS ChildObjectCode,
                     cobj.COL_NAME AS ChildObjectName,
                     cobj.COL_TABLENAME AS ChildTableName,
                     cobj.COL_ALIAS AS ChildObjAlias,
                     pobj.COL_CODE AS ParentObjectCode,
                     pobj.COL_NAME AS ParentObjectName,
                     pobj.COL_TABLENAME AS ParentTableName,
                     pobj.COL_ALIAS AS ParentObjAlias,
                     s3.ResAttr AS ResAttr,
                     s3.SearchAttr AS SearchAttr,
                     s3.RSAttrId AS RSAttrId,
                     s3.AttrCode AS AttrCode,
                     s3.AttrColumnName AS AttrColumnName,
                     s3.AttrStorageType AS AttrStorageType,
                     s3.AttrAlias AS AttrAlias
      FROM (SELECT pt.COL_ID AS PathId,
                   pt.COL_CODE AS PathCode,
                   pt.COL_JOINTYPE AS JoinType,
                   pt.COL_FOM_PATHFOM_RELATIONSHIP AS RelId,
                   LEVEL AS LevelPath
          FROM TBL_FOM_PATH pt
        CONNECT BY PRIOR COL_ID = COL_FOM_PATHFOM_PATH
        START WITH COL_ID IN (SELECT pt.COL_ID
            FROM TBL_FOM_PATH pt
              INNER JOIN TBL_FOM_RELATIONSHIP rl ON pt.COL_FOM_PATHFOM_RELATIONSHIP = rl.COL_ID
              INNER JOIN TBL_FOM_OBJECT cobj ON rl.COL_CHILDFOM_RELFOM_OBJECT = cobj.COL_ID
              INNER JOIN TBL_FOM_OBJECT pobj ON rl.COL_PARENTFOM_RELFOM_OBJECT = pobj.COL_ID
              INNER JOIN (SELECT rat.COL_SOM_RESULTATTRFOM_PATH AS PathId
                FROM TBL_SOM_RESULTATTR rat
                WHERE rat.COL_SOM_RESULTATTRSOM_CONFIG = v_configid
                UNION
              SELECT sat.COL_SOM_SEARCHATTRFOM_PATH AS PathId
                FROM TBL_SOM_SEARCHATTR sat
                WHERE sat.COL_SOM_SEARCHATTRSOM_CONFIG = v_configid) s1 ON pt.COL_ID = s1.PathId)) s2
        INNER JOIN TBL_FOM_RELATIONSHIP rl ON s2.RelId = rl.COL_ID
        INNER JOIN TBL_FOM_OBJECT cobj ON rl.COL_CHILDFOM_RELFOM_OBJECT = cobj.COL_ID
        INNER JOIN TBL_FOM_OBJECT pobj ON rl.COL_PARENTFOM_RELFOM_OBJECT = pobj.COL_ID
        LEFT JOIN (SELECT rat.COL_SOM_RESULTATTRFOM_PATH AS PathId,
                          1 AS ResAttr,
                          0 AS SearchAttr,
                          rat.COL_ID AS RSAttrId,
                          rat.COL_CODE AS RSAttrCode,
                          rat.COL_NAME AS RSAttrName,
                          attr.COL_CODE AS AttrCode,
                          attr.COL_NAME AS AttrName,
                          attr.COL_COLUMNNAME AS AttrColumnName,
                          attr.COL_STORAGETYPE AS AttrStorageType,
                          attr.COL_ALIAS AS AttrAlias
          FROM TBL_SOM_RESULTATTR rat
            INNER JOIN TBL_FOM_ATTRIBUTE attr ON rat.COL_SOM_RESULTATTRFOM_ATTR = attr.COL_ID
          WHERE rat.COL_SOM_RESULTATTRSOM_CONFIG = v_configid
          UNION
        SELECT sat.COL_SOM_SEARCHATTRFOM_PATH AS PathId,
               0 AS ResAttr,
               1 AS SearchAttr,
               sat.COL_ID AS RSAttrId,
               sat.COL_CODE AS RSAttrCode,
               sat.COL_NAME AS RSAttrName,
               attr.COL_CODE AS AttrCode,
               attr.COL_NAME AS AttrName,
               attr.COL_COLUMNNAME AS AttrColumnName,
               attr.COL_STORAGETYPE AS AttrStorageType,
               attr.COL_ALIAS AS AttrAlias
          FROM TBL_SOM_SEARCHATTR sat
            INNER JOIN TBL_FOM_ATTRIBUTE attr ON sat.COL_SOM_SEARCHATTRFOM_ATTR = attr.COL_ID
          WHERE sat.COL_SOM_SEARCHATTRSOM_CONFIG = v_configid) s3 ON s2.PathId = s3.PathId
     ORDER BY s2.PathId DESC)
  LOOP
    --IF CURRENT PATH RECORD IS NOT DIRECTLY LINKED TO ROOT OBJECT THEN LOOP THROUGH ALL PARENTS OF STARTING WITH CURRENT PATH RECORD IN PATH HIERARCHY AND BUILD JOINS
    IF (rec.LevelPath = 1 AND rec.ParentObjectId <> v_rootobjid AND rec.ChildObjectId <> v_rootobjid) THEN
      FOR recJoin IN (SELECT fP.COL_ID AS PathId,
                             fp.COL_CODE as ParentAlias,
                             fp.COL_CODE as ChildAlias,
                             --(select col_code from tbl_fom_path where col_id = v_parentpathid) as PrevParentAlias,
                             --(select col_code from tbl_fom_path where col_id = v_childpathid) as PrevChildAlias,
                             fp.COL_JOINTYPE AS JoinType,
                             cobj.COL_ID AS ChildObjectId,
                             cobj.COL_TABLENAME AS ChildTableName,
                             cobj.COL_ALIAS AS ChildObjAlias,
                             pobj.COL_ID AS ParentObjectId,
                             pobj.COL_TABLENAME AS ParentTableName,
                             pobj.COL_ALIAS AS ParentObjAlias,
                             fR.COL_FOREIGNKEYNAME AS ForeignKeyName,
                             fR.COL_ID AS RelId
          FROM (SELECT COL_ID,
                       COL_CODE,
                       COL_JOINTYPE,
                       COL_FOM_PATHFOM_RELATIONSHIP,
                       LEVEL AS LevelPath
              FROM TBL_FOM_PATH
            CONNECT BY COL_FOM_PATHFOM_PATH = PRIOR COL_ID
            START WITH COL_ID = rec.PathId) fP
            INNER JOIN TBL_FOM_RELATIONSHIP fR ON fR.COL_ID = fP.COL_FOM_PATHFOM_RELATIONSHIP
            INNER JOIN TBL_FOM_OBJECT cobj ON fR.COL_CHILDFOM_RELFOM_OBJECT = cobj.COL_ID
            INNER JOIN TBL_FOM_OBJECT pobj ON fR.COL_PARENTFOM_RELFOM_OBJECT = pobj.COL_ID
          ORDER BY fP.LevelPath DESC)
      LOOP
        IF (v_rootobjid = recJoin.ParentObjectId) THEN
          IF v_PathAdded(recJoin.PathId) = 0 and nvl(v_ObjectAdded(recJoin.ChildObjectId),0) = 0 and nvl(v_ObjectAdded(recJoin.ParentObjectId),0) = 1 THEN
            v_fromqry := v_fromqry || f_dcm_getPathJoinType(PathJoinType => recJoin.JoinType) || ' join ' || recJoin.ChildTableName || ' ' || recJoin.ChildAlias ||
            ' on ' || recJoin.ChildAlias || '.' || recJoin.ForeignKeyName || ' = ' || recJoin.ParentAlias || '.col_id';
            v_ObjectAdded(recJoin.ChildObjectId) := 1;
            v_ObjectAlias(recJoin.ChildObjectId) := recJoin.ChildAlias;
            v_PathAdded(recJoin.PathId) := 1;
            v_objectid := recJoin.ChildObjectId;
            v_ObjectsAdded := 1;
          END IF;
        ELSIF (v_parentobjectid = recJoin.ParentObjectId) THEN
          IF v_PathAdded(recJoin.PathId) = 0 and nvl(v_ObjectAdded(recJoin.ChildObjectId),0) = 0 and nvl(v_ObjectAdded(recJoin.ParentObjectId),0) = 1 THEN
            v_fromqry := v_fromqry || f_dcm_getPathJoinType(PathJoinType => recJoin.JoinType) || ' join ' || recJoin.ChildTableName || ' ' || recJoin.ChildAlias ||
            ' on ' || recJoin.ChildAlias || '.' || recJoin.ForeignKeyName || ' = ' || recJoin.ParentAlias || '.col_id';
            v_ObjectAdded(recJoin.ChildObjectId) := 1;
            v_ObjectAlias(recJoin.ChildObjectId) := recJoin.ChildAlias;
            v_PathAdded(recJoin.PathId) := 1;
            v_objectid := recJoin.ChildObjectId;
            v_ObjectsAdded := 1;
          END IF;
        -------------------------------------------------
        ELSIF v_parentobjectid is not null THEN
        -------------------------------------------------
          IF (v_PathAdded(recJoin.PathId) = 0 and nvl(v_ObjectAdded(recJoin.ParentObjectId),0) = 0 and nvl(v_ObjectAdded(recJoin.ChildObjectId),0) = 1)
             OR
             (v_PathAdded(recJoin.PathId) = 0 and nvl(v_ObjectAdded(recJoin.ParentObjectId),1) = 1 and nvl(v_ObjectAdded(recJoin.ChildObjectId),0) = 1)
             THEN
            v_fromqry := v_fromqry || f_dcm_getPathJoinType(PathJoinType => recJoin.JoinType) || ' join ' || recJoin.ParentTableName || ' ' || recJoin.ParentAlias ||
            ' on ' || v_ObjectAlias(recJoin.ChildObjectId) || '.' || recJoin.ForeignKeyName || ' = ' || recJoin.ParentAlias || '.col_id';
            v_ObjectAdded(recJoin.ParentObjectId) := 1;
            v_ObjectAlias(recJoin.ParentObjectId) := recJoin.ParentAlias;
            v_PathAdded(recJoin.PathId) := 1;
            v_objectid := recJoin.ParentObjectId;
            v_ObjectsAdded := 1;
          END IF;
          IF v_PathAdded(recJoin.PathId) = 0 and nvl(v_ObjectAdded(recJoin.ChildObjectId),0) = 0 and nvl(v_ObjectAdded(recJoin.ParentObjectId),0) = 1 THEN
            v_fromqry := v_fromqry || f_dcm_getPathJoinType(PathJoinType => recJoin.JoinType) || ' join ' || recJoin.ChildTableName || ' ' || recJoin.ChildAlias ||
            ' on ' || recJoin.ChildAlias || '.' || recJoin.ForeignKeyName || ' = ' || v_ObjectAlias(recJoin.ParentObjectId) || '.col_id';
            v_ObjectAdded(recJoin.ChildObjectId) := 1;
            v_ObjectAlias(recJoin.ChildObjectId) := recJoin.ChildAlias;
            v_PathAdded(recJoin.PathId) := 1;
            v_objectid := recJoin.ChildObjectId;
            v_ObjectsAdded := 1;
          END IF;
        ELSE
          v_objectid := null;
        END IF;
        ----------------------------------------------
        IF v_objectid is not null THEN
        ----------------------------------------------
        v_relid := recJoin.RelId;
        v_parentTable := recJoin.ParentTableName;
        v_parentobjectid := recJoin.ParentObjectId;
        ----------------------------------------------
        END IF;
        ----------------------------------------------
      END LOOP;
    END IF;
    --END OF PROCESSING THE SITUATION WHEN CURRENT PATH RECORD IS NOT DIRECTLY LINKED TO ROOT OBJECT
    ------------------------------------------------------------------------------------------------
    --IF CURRENT PATH LINKS ROOT TABLE TO SOME CHILD TABLE, AND CHILD TABLE IS NOT IN QUERY THAN ADD CHILD TABLE TO QUERY
    ------------------------------------------------------------------------------------------------
    IF (v_rootobjid = rec.ParentObjectId AND rec.ResAttr = 1) THEN
      IF v_PathAdded(rec.PathId) = 0 and nvl(v_ObjectAdded(rec.ChildObjectId),0) = 0 and nvl(v_ObjectAdded(rec.ParentObjectId),0) = 1 THEN
        v_fromqry := v_fromqry || f_dcm_getPathJoinType(PathJoinType => rec.JoinType) || ' join ' || rec.ChildTableName || ' ' || rec.ChildAlias ||
        ' on ' || (case when rec.ChildObjectId = v_rootobjid then v_rootalias else rec.ChildAlias end) || '.' || rec.ForeignKeyName ||
        ' = ' || (case when rec.ParentObjectId = v_rootobjid then v_rootalias else rec.ParentAlias end) || '.col_id';
        v_ObjectAdded(rec.ChildObjectId) := 1;
        v_ObjectAlias(rec.ChildObjectId) := rec.ChildAlias;
        v_PathAdded(rec.PathId) := 1;
        v_objectid := rec.ChildObjectId;
        v_ObjectsAdded := 1;
      END IF;
    END IF;
    --IF CURRENT PATH LINKS ROOT TABLE, WHICH IS CHILD TABLE, TO SOME PARENT TABLE, AND PARENT TABLE IS NOT IN QUERY THAN ADD PARENT TABLE TO QUERY
    IF (v_rootobjid = rec.ChildObjectId AND NVL(v_relid, 0) <> rec.RelId) THEN
      IF v_PathAdded(rec.PathId) = 0 and nvl(v_ObjectAdded(rec.ParentObjectId),0) = 0 and nvl(v_ObjectAdded(rec.ChildObjectId),0) = 1 THEN
        v_fromqry := v_fromqry || f_dcm_getPathJoinType(PathJoinType => rec.JoinType) || ' join ' || rec.ParentTableName || ' ' || rec.ParentAlias ||
        ' on ' || (case when rec.ChildObjectId = v_rootobjid then v_rootalias else rec.ChildAlias end) || '.' || rec.ForeignKeyName ||
        ' = ' || (case when rec.ParentObjectId = v_rootobjid then v_rootalias else rec.ParentAlias end) || '.col_id';
        v_ObjectAdded(rec.ParentObjectId) := 1;
        v_ObjectAlias(rec.ParentObjectId) := rec.ParentAlias;
        v_PathAdded(rec.PathId) := 1;
        v_objectid := rec.ParentObjectId;
        v_ObjectsAdded := 1;
      ELSIF v_PathAdded(rec.PathId) = 0 and nvl(v_ObjectAdded(rec.ParentObjectId),0) = 1 and nvl(v_ObjectAdded(rec.ChildObjectId),0) = 1 THEN
        v_fromqry := v_fromqry || f_dcm_getPathJoinType(PathJoinType => rec.JoinType) || ' join ' || rec.ParentTableName || ' ' || rec.ParentAlias ||
        ' on ' || (case when rec.ChildObjectId = v_rootobjid then v_rootalias else rec.ChildAlias end) || '.' || rec.ForeignKeyName ||
        ' = ' || (case when rec.ParentObjectId = v_rootobjid then v_rootalias else rec.ParentAlias end) || '.col_id';
        v_ObjectAdded(rec.ParentObjectId) := 1;
        v_ObjectAdded(rec.ChildObjectId) := 1;
        v_ObjectAlias(rec.ParentObjectId) := rec.ParentAlias;
        v_PathAdded(rec.PathId) := 1;
        v_objectid := rec.ParentObjectId;
        v_ObjectsAdded := 1;
      END IF;
      v_relid := rec.RelId;
      v_parentTable := rec.ParentTableName;
      v_parentobjectid := rec.ParentObjectId;
    --IF CURRENT PATH LINKS ROOT TABLE, WHICH IS PARENT TABLE, TO SOME CHILD TABLE, ADD CHILD TABLE TO QUERY AS SUB-SELECT
    --PROCESSING OF SITUATION WHEN SEARCH ATTRIBUTE BELONGS TO TABLE THAT HAS MANY-TO-ONE RELATIONSHIP TO ROOT TABLE. IN THIS CASE SUB-SELECT IN BUILT AS PART OF THE WHOLE QUERY
    ELSIF (v_rootobjid = rec.ParentObjectId AND NVL(v_relid, 0) <> rec.RelId AND rec.SearchAttr = 1) THEN
      ---------------------------------------------------------------------------------------------------------------------------------
      v_expr := ' in ' || '(select ' || rec.ChildAlias || '.' || rec.ForeignKeyName || ' from ' || rec.ChildTableName || ' ' || rec.ChildAlias || ' where 1 = 1 ';
      IF (v_whereqry IS NULL) THEN
        IF (INSTR(v_whereqry, v_expr) IS NULL) THEN
          v_whereqry := ' where ' || rec.ParentAlias || '.col_id' || ' in ' ||
          '(select ' || rec.ChildAlias || '.' || rec.ForeignKeyName || ' from ' || rec.ChildTableName || ' ' || rec.ChildAlias || ' where 1 = 1 ';
        END IF;
      ELSE
        IF (INSTR(v_whereqry, v_expr) IS NULL) THEN
          v_whereqry := v_whereqry || ' and ' || rec.ParentAlias || '.col_id' || ' in ' ||
          '(select ' || rec.ChildAlias || '.' || rec.ForeignKeyName || ' from ' || rec.ChildTableName || ' ' || rec.ChildAlias || ' where 1 = 1 ';
        END IF;
      END IF;
      --LOOP THROUGH SEARCH ATTRIBUTES FOR CHILD OBJECT TO ROOT OBJECT
      FOR rec2 IN (SELECT srchattr.COL_ID AS SearchAttrId,
                          srchattr.COL_CODE AS SearchAttrCode,
                          srchattr.COL_NAME AS SearchAttrName,
                          srchattr.COL_ISLIKE AS SearchAttrLike,
                          srchattr.COL_ISCASEINCENSITIVE AS SearchAttrCaseIncensitive,
                          pt.COL_CODE AS PathCode,
                          (case when attr.COL_FOM_ATTRIBUTEFOM_OBJECT = v_rootobjid then obj.COL_ALIAS when pt.COL_CODE is not null then pt.COL_CODE else obj.COL_ALIAS end) AS ObjAlias,
                          obj.COL_CODE AS ObjCode,
                          obj.COL_NAME AS ObjName,
                          obj.COL_TABLENAME AS ObjTableName,
                          obj.COL_ALIAS AS ObjectAlias,
                          obj.COL_XMLALIAS AS ObjXMLAlias,
                          attr.COL_CODE AS AttrCode,
                          attr.COL_NAME AS AttrName,
                          attr.COL_COLUMNNAME AS AttrColumnName,
                          attr.COL_STORAGETYPE AS AttrStorageType,
                          dataType.COL_CODE AS columnType
          FROM TBL_SOM_SEARCHATTR srchattr
            LEFT JOIN TBL_FOM_PATH pt ON srchattr.COL_SOM_SEARCHATTRFOM_PATH = pt.COL_ID
            INNER JOIN TBL_FOM_ATTRIBUTE attr ON srchattr.COL_SOM_SEARCHATTRFOM_ATTR = attr.COL_ID
            INNER JOIN TBL_FOM_OBJECT obj ON attr.COL_FOM_ATTRIBUTEFOM_OBJECT = obj.COL_ID
            LEFT JOIN TBL_DICT_DATATYPE dataType ON dataType.COL_ID = attr.COL_FOM_ATTRIBUTEDATATYPE
          WHERE srchattr.COL_SOM_SEARCHATTRSOM_CONFIG = v_configid
            AND obj.COL_CODE = rec.ChildObjectCode
          ORDER BY srchattr.COL_SORDER)
      LOOP
        v_exprstart := '';
        v_exprend := '';
        --EXTRACT SEARCH ATTRIBUTE VALUES THAT ARE PASSED IN INPUT PARAMETER v_input
        IF (F_FORM_GETPARAMBYNAME(v_input, rec2.AttrCode) IS NOT NULL) THEN
          v_data_type_where := LOWER(rec2.columnType);
          IF NVL(rec2.SearchAttrCaseIncensitive, 0) = 0 THEN
            v_exprstart := '';
            v_exprend := '';
          ELSIF (rec2.SearchAttrCaseIncensitive = 1) THEN
            v_exprstart := 'lower(';
            v_exprend := ')';
          ELSE
            v_exprstart := '';
            v_exprend := '';
          END IF;
          IF (v_data_type_where = 'date' or v_data_type_where = 'createddate' or v_data_type_where = 'modifieddate') THEN
            v_exprstart := v_exprstart || 'to_date(';
            v_exprend := v_exprend || ',''' || v_date_format || ''')';
          END IF;
          IF (NVL(rec2.SearchAttrLike, 0) = 0) THEN
            IF (v_data_type_where = 'integer') THEN
              v_expr := ' = ' || v_exprstart || F_FORM_GETPARAMBYNAME(v_input, rec2.AttrCode) || v_exprend;
            ELSIF (v_data_type_where = 'date' or v_data_type_where = 'createddate' or v_data_type_where = 'modifieddate') THEN
              v_expr := ' = ' || v_exprstart || '''' || F_FORM_GETPARAMBYNAME(v_input, rec2.AttrCode) || '''' || v_exprend;
            ELSE
              v_expr := ' = ' || v_exprstart || '''' || F_FORM_GETPARAMBYNAME(v_input, rec2.AttrCode) || '''' || v_exprend;
            END IF;
          ELSIF (rec2.SearchAttrLike = 1) THEN
            v_expr := ' like ' || v_exprstart || '''%' || F_FORM_GETPARAMBYNAME(v_input, rec2.AttrCode) || '%''' || v_exprend;
          ELSE
            v_expr := NULL;
          END IF;
        END IF;
        IF (F_FORM_GETPARAMBYNAME(v_input, rec2.AttrCode) IS NOT NULL) THEN
          v_whereqry := v_whereqry || ' and ' || v_exprstart || rec2.ObjAlias || '.' || rec2.AttrColumnName || v_exprend || v_expr;
          v_SearchAttrAdded(rec2.SearchAttrId) := 1;
        END IF;
      END LOOP;
      --END OF LOOP THROUGH SEARCH ATRIBUTES
      --REMINDER: LOOP IS RELATED TO SUB-SELECT BUILD, WHEN SEARCH ATTRIBUTES BELONG TO OBJECTS THAT ARE PARENT OBJECTS TO ROOT OBJECT
      v_whereqry := v_whereqry || ')';
      ---------------------------------------------------------------------------------------------------------------------------------
      ---------------------------------------------------------------------------------------------------------------------------------
      ----------------------------------------------------------------------------------------------------------------------------------
      v_relid := rec.RelId;
      v_parentTable := rec.ParentTableName;
      v_parentobjectid := rec.ParentObjectId;
    --PROCESSING OF SITUATION WHEN CURRENT PATH IS NOT ATTACHED TO ROOT TABLE (NEITHER CHILD NOT PARENT TABLE IS ROOT TABLE)
    ELSIF v_relid <> rec.RelId THEN
      IF (rec.LevelPath = 1 AND rec.ParentObjectId <> v_rootobjid AND rec.ChildObjectId <> v_rootobjid) THEN
        --LOOP THROUGH CONNECTED PATH RECORDS FOR CURRENT PATH RECORD, IF CONNECTED PATH RECORDS EXIST
        FOR recJoin IN (SELECT fP.COL_ID AS PathId,
                               fp.COL_JOINTYPE AS JoinType,
                               cobj.COL_ID AS ChildObjectId,
                               cobj.COL_TABLENAME AS ChildTableName,
                               cobj.COL_ALIAS AS ChildAlias,
                               pobj.COL_ID AS ParentObjectId,
                               pobj.COL_TABLENAME AS ParentTableName,
                               pobj.COL_ALIAS AS ParentAlias,
                               fR.COL_FOREIGNKEYNAME AS ForeignKeyName,
                               fR.COL_ID AS RelId
            FROM (SELECT COL_ID,
                         COL_JOINTYPE,
                         COL_FOM_PATHFOM_RELATIONSHIP,
                         LEVEL AS LevelPath
                FROM TBL_FOM_PATH
              CONNECT BY COL_FOM_PATHFOM_PATH = PRIOR COL_ID
              START WITH COL_ID = rec.PathId) fP
              INNER JOIN TBL_FOM_RELATIONSHIP fR ON fR.COL_ID = fP.COL_FOM_PATHFOM_RELATIONSHIP
              INNER JOIN TBL_FOM_OBJECT cobj ON fR.COL_CHILDFOM_RELFOM_OBJECT = cobj.COL_ID
              INNER JOIN TBL_FOM_OBJECT pobj ON fR.COL_PARENTFOM_RELFOM_OBJECT = pobj.COL_ID
            ORDER BY fP.LevelPath DESC)
        LOOP
          IF (v_rootobjid = recJoin.ParentObjectId) THEN
            IF v_PathAdded(recJoin.PathId) = 0 and v_ObjectAdded(recJoin.ChildObjectId) = 0 and v_ObjectAdded(recJoin.ParentObjectId) = 1 THEN
              v_fromqry := v_fromqry || f_dcm_getPathJoinType(PathJoinType => recJoin.JoinType) || ' join ' || recJoin.ChildTableName || ' ' || recJoin.ChildAlias ||
              ' on ' || recJoin.ChildAlias || '.' || recJoin.ForeignKeyName || ' = ' || recJoin.ParentAlias || '.col_id';
              v_ObjectAdded(recJoin.ChildObjectId) := 1;
              v_ObjectAlias(recJoin.ChildObjectId) := recJoin.ChildAlias;
              v_PathAdded(recJoin.PathId) := 1;
              v_ObjectsAdded := 1;
            END IF;
          ELSIF v_parentobjectid = recJoin.ParentObjectId THEN
            IF v_PathAdded(recJoin.PathId) = 0 and v_ObjectAdded(recJoin.ChildObjectId) = 0 and v_ObjectAdded(recJoin.ParentObjectId) = 1 THEN
              v_fromqry := v_fromqry || f_dcm_getPathJoinType(PathJoinType => recJoin.JoinType) || ' join ' || recJoin.ChildTableName || ' ' || recJoin.ChildAlias ||
              ' on ' || recJoin.ChildAlias || '.' || recJoin.ForeignKeyName || ' = ' || recJoin.ParentAlias || '.col_id';
              v_ObjectAdded(recJoin.ChildObjectId) := 1;
              v_ObjectAlias(recJoin.ChildObjectId) := recJoin.ChildAlias;
              v_PathAdded(recJoin.PathId) := 1;
              v_ObjectsAdded := 1;
            END IF;
          ELSE
            IF v_PathAdded(recJoin.PathId) = 0 and v_ObjectAdded(recJoin.ParentObjectId) = 0 and v_ObjectAdded(recJoin.ChildObjectId) = 1 THEN
              v_fromqry := v_fromqry || f_dcm_getPathJoinType(PathJoinType => recJoin.JoinType) || ' join ' || recJoin.ParentTableName || ' ' || recJoin.ParentAlias ||
              ' on ' || recJoin.ChildAlias || '.' || recJoin.ForeignKeyName || ' = ' || recJoin.ParentAlias || '.col_id';
              v_ObjectAdded(recJoin.ParentObjectId) := 1;
              v_ObjectAlias(recJoin.ParentObjectId) := recJoin.ParentAlias;
              v_PathAdded(recJoin.PathId) := 1;
              v_ObjectsAdded := 1;
            END IF;
          END IF;
          v_relid := recJoin.RelId;
          v_parentTable := recJoin.ParentTableName;
          v_parentobjectid := recJoin.ParentObjectId;
        END LOOP;
        --END OF LOOP THROUGH CONNECTED PATH RECORDS FOR CURRENT PATH RECORD, IF CONNECTED PATH RECORDS EXIST
      END IF;
      IF (v_rootobjid = rec.ParentObjectId) THEN
        IF v_PathAdded(rec.PathId) = 0 and v_ObjectAdded(rec.ChildObjectId) = 0 and v_ObjectAdded(rec.ParentObjectId) = 1 THEN
          v_fromqry := v_fromqry || f_dcm_getPathJoinType(PathJoinType => rec.JoinType) || ' join ' || rec.ChildTableName || ' ' || rec.ChildAlias ||
          ' on ' || rec.ChildAlias || '.' || rec.ForeignKeyName || ' = ' || rec.ParentAlias || '.col_id';
          v_ObjectAdded(rec.ChildObjectId) := 1;
          v_ObjectAlias(rec.ChildObjectId) := rec.ChildAlias;
          v_PathAdded(rec.PathId) := 1;
          v_ObjectsAdded := 1;
        END IF;
      ELSIF (v_parentObjectId = rec.ParentObjectId)
      THEN
        IF v_PathAdded(rec.PathId) = 0 and v_ObjectAdded(rec.ChildObjectId) = 0 and v_ObjectAdded(rec.ParentObjectId) = 1 THEN
          v_fromqry := v_fromqry || f_dcm_getPathJoinType(PathJoinType => rec.JoinType) || ' join ' || rec.ChildTableName || ' ' || rec.ChildAlias ||
          ' on ' || rec.ChildAlias || '.' || rec.ForeignKeyName || ' = ' || rec.ParentAlias || '.col_id';
          v_ObjectAdded(rec.ChildObjectId) := 1;
          v_ObjectAlias(rec.ChildObjectId) := rec.ChildAlias;
          v_PathAdded(rec.PathId) := 1;
          v_ObjectsAdded := 1;
        END IF;
      ELSE
        IF v_PathAdded(rec.PathId) = 0 and v_ObjectAdded(rec.ParentObjectId) = 0 and v_ObjectAdded(rec.ChildObjectId) = 1 THEN
          v_fromqry := v_fromqry || f_dcm_getPathJoinType(PathJoinType => rec.JoinType) || ' join ' || rec.ParentTableName || ' ' || rec.ParentAlias ||
          ' on ' || rec.ChildAlias || '.' || rec.ForeignKeyName || ' = ' || rec.ParentAlias || '.col_id';
          v_ObjectAdded(rec.ParentObjectId) := 1;
          v_ObjectAlias(rec.ParentObjectId) := rec.ParentAlias;
          v_PathAdded(rec.PathId) := 1;
          v_ObjectsAdded := 1;
        END IF;
      END IF;
      v_relid := rec.RelId;
      v_parentTable := rec.ParentTableName;
      v_parentobjectid := rec.ParentObjectId;
    END IF;
  END LOOP;
  --END OF LOOP THROUGH ALL SEARCH AND RESULT ATTRIBUTES IN SEARCH CONFIG, LINKED TO THEIR RESPECTIVE PATH RECORDS
  IF v_ObjectsAdded = 0 THEN
    :ErrorCode := 101;
    :ErrorMessage := 'Cannot build query for current configuration';
    return -1;
  END IF;
  
  --MAKE SURE ALL OBJECTS IN THE DYNAMIC SEARCH CONFIGURATION ARE INCLUDED INTO SEARCH
  v_return := 1;
  v_return2 := 1;
  FOR rec IN (SELECT s2.LevelPath AS LevelPath,
                     s2.PathId AS PathId,
                     s2.JoinType AS JoinType,
                     s2.RelId AS RelId,
                     rl.COL_CHILDFOM_RELFOM_OBJECT AS ChildObjectId,
                     rl.COL_PARENTFOM_RELFOM_OBJECT AS ParentObjectId,
                     rl.COL_FOREIGNKEYNAME AS ForeignKeyName,
                     cobj.COL_CODE AS ChildObjectCode,
                     cobj.COL_NAME AS ChildObjectName,
                     cobj.COL_TABLENAME AS ChildTableName,
                     cobj.COL_ALIAS AS ChildAlias,
                     pobj.COL_CODE AS ParentObjectCode,
                     pobj.COL_NAME AS ParentObjectName,
                     pobj.COL_TABLENAME AS ParentTableName,
                     pobj.COL_ALIAS AS ParentAlias,
                     s3.ResAttr AS ResAttr,
                     s3.SearchAttr AS SearchAttr,
                     s3.RSAttrId AS RSAttrId,
                     s3.AttrCode AS AttrCode,
                     s3.AttrColumnName AS AttrColumnName,
                     s3.AttrStorageType AS AttrStorageType,
                     s3.AttrAlias AS AttrAlias
      FROM (SELECT pt.COL_ID AS PathId,
                   pt.COL_JOINTYPE AS JoinType,
                   pt.COL_FOM_PATHFOM_RELATIONSHIP AS RelId,
                   LEVEL AS LevelPath
          FROM TBL_FOM_PATH pt
        CONNECT BY PRIOR COL_ID = COL_FOM_PATHFOM_PATH
        START WITH COL_ID IN (SELECT pt.COL_ID
            FROM TBL_FOM_PATH pt
              INNER JOIN TBL_FOM_RELATIONSHIP rl ON pt.COL_FOM_PATHFOM_RELATIONSHIP = rl.COL_ID
              INNER JOIN TBL_FOM_OBJECT cobj ON rl.COL_CHILDFOM_RELFOM_OBJECT = cobj.COL_ID
              INNER JOIN TBL_FOM_OBJECT pobj ON rl.COL_PARENTFOM_RELFOM_OBJECT = pobj.COL_ID
              INNER JOIN (SELECT rat.COL_SOM_RESULTATTRFOM_PATH AS PathId
                FROM TBL_SOM_RESULTATTR rat
                WHERE rat.COL_SOM_RESULTATTRSOM_CONFIG = v_configid
                UNION
              SELECT sat.COL_SOM_SEARCHATTRFOM_PATH AS PathId
                FROM TBL_SOM_SEARCHATTR sat
                WHERE sat.COL_SOM_SEARCHATTRSOM_CONFIG = v_configid) s1 ON pt.COL_ID = s1.PathId)) s2
        INNER JOIN TBL_FOM_RELATIONSHIP rl ON s2.RelId = rl.COL_ID
        INNER JOIN TBL_FOM_OBJECT cobj ON rl.COL_CHILDFOM_RELFOM_OBJECT = cobj.COL_ID
          AND cobj.COL_ID IN
          (SELECT COL_FOM_ATTRIBUTEFOM_OBJECT FROM TBL_FOM_ATTRIBUTE WHERE COL_ID IN (SELECT COL_SOM_RESULTATTRFOM_ATTR FROM TBL_SOM_RESULTATTR WHERE COL_SOM_RESULTATTRSOM_CONFIG = v_configid)
           UNION
           SELECT COL_FOM_ATTRIBUTEFOM_OBJECT from TBL_FOM_ATTRIBUTE WHERE COL_ID IN (SELECT COL_SOM_SEARCHATTRFOM_ATTR FROM TBL_SOM_SEARCHATTR WHERE COL_SOM_SEARCHATTRSOM_CONFIG = v_configid))
        INNER JOIN TBL_FOM_OBJECT pobj ON rl.COL_PARENTFOM_RELFOM_OBJECT = pobj.COL_ID
        LEFT JOIN (SELECT rat.COL_SOM_RESULTATTRFOM_PATH AS PathId,
                          1 AS ResAttr,
                          0 AS SearchAttr,
                          rat.COL_ID AS RSAttrId,
                          rat.COL_CODE AS RSAttrCode,
                          rat.COL_NAME AS RSAttrName,
                          attr.COL_CODE AS AttrCode,
                          attr.COL_NAME AS AttrName,
                          attr.COL_COLUMNNAME AS AttrColumnName,
                          attr.COL_STORAGETYPE AS AttrStorageType,
                          attr.COL_ALIAS AS AttrAlias
          FROM TBL_SOM_RESULTATTR rat
            INNER JOIN TBL_FOM_ATTRIBUTE attr ON rat.COL_SOM_RESULTATTRFOM_ATTR = attr.COL_ID
          WHERE rat.COL_SOM_RESULTATTRSOM_CONFIG = v_configid
          UNION
        SELECT sat.COL_SOM_SEARCHATTRFOM_PATH AS PathId,
               0 AS ResAttr,
               1 AS SearchAttr,
               sat.COL_ID AS RSAttrId,
               sat.COL_CODE AS RSAttrCode,
               sat.COL_NAME AS RSAttrName,
               attr.COL_CODE AS AttrCode,
               attr.COL_NAME AS AttrName,
               attr.COL_COLUMNNAME AS AttrColumnName,
               attr.COL_STORAGETYPE AS AttrStorageType,
               attr.COL_ALIAS AS AttrAlias
          FROM TBL_SOM_SEARCHATTR sat
            INNER JOIN TBL_FOM_ATTRIBUTE attr ON sat.COL_SOM_SEARCHATTRFOM_ATTR = attr.COL_ID
          WHERE sat.COL_SOM_SEARCHATTRSOM_CONFIG = v_configid) s3
        ON s2.PathId = s3.PathId
      ORDER BY s2.PathId)
  LOOP
        v_return := nvl(v_ObjectAdded(rec.ChildObjectId),0);
        v_return2 := nvl(v_ObjectAdded(rec.ParentObjectId),0);
        if v_return = 0 or v_return2 = 0 then
          exit;
        end if;
  END LOOP;
  if v_return = 0 or v_return2 = 0 then
    goto start_from;
  end if;

  --ADD LIST OF SIMPLE STORAGE TYPE SEARCH ATTRIBUTES TO RESULT LIST
  FOR rec IN (SELECT resattr.COL_ID AS ResultAttrId,
                     resattr.COL_CODE AS ResultAttrCode,
                     resattr.COL_CODE AS AttrAlias,
                     resattr.COL_NAME AS ResultAttrName,
                     resattr.COL_METAPROPERTY as ResultAttrMetaProp,
                     resattr.COL_IDPROPERTY as ResultAttrIDProp,
                     resattr.COL_PROCESSORCODE AS ResultAttrProcCode,
                     resattr.COL_SOM_RESULTATTRFOM_ATTR AS AttrId,
                     pt.COL_CODE AS PathCode,
                     (case
                     when (select count(*) from tbl_fom_path where col_fom_pathfom_relationship in
                     (select col_id from tbl_fom_relationship where col_parentfom_relfom_object = obj.col_id
                     and col_childfom_relfom_object in (select col_id from tbl_fom_object where col_id = cobj.COL_ID /*v_rootobjid*/ and col_id in
                     (select col_fom_attributefom_object from tbl_fom_attribute where col_id in
                     (select col_som_resultattrfom_attr from tbl_som_resultattr where col_som_resultattrsom_config = v_ConfigId))))) = 1
                     then (select col_code from tbl_fom_path where col_fom_pathfom_relationship in
                     (select col_id from tbl_fom_relationship where col_parentfom_relfom_object = obj.col_id
                     and col_childfom_relfom_object in (select col_id from tbl_fom_object where col_id = cobj.COL_ID /*v_rootobjid*/ and col_id in
                     (select col_fom_attributefom_object from tbl_fom_attribute where col_id in
                     (select col_som_resultattrfom_attr from tbl_som_resultattr where col_som_resultattrsom_config = v_ConfigId)))))
                     else pt.COL_CODE
                     end) AS ObjAlias,
                     attr.COL_CODE AS AttrCode,
                     attr.COL_NAME AS AttrName,
                     attr.COL_COLUMNNAME AS AttrColumnName,
                     attr.COL_STORAGETYPE AS AttrStorageType,
                     attr.COL_ALIAS AS AttributeAlias,
                     obj.COL_CODE AS ObjCode,
                     obj.COL_NAME AS ObjName,
                     obj.COL_TABLENAME AS ObjTableName,
                     obj.COL_ALIAS AS ObjectAlias,
                     obj.COL_XMLALIAS AS ObjXMLAlias,
                     dataType.COL_CODE AS columnType
      FROM TBL_SOM_RESULTATTR resattr
        LEFT JOIN TBL_FOM_PATH pt ON resattr.COL_SOM_RESULTATTRFOM_PATH = pt.COL_ID
        INNER JOIN TBL_FOM_RELATIONSHIP rl ON pt.COL_FOM_PATHFOM_RELATIONSHIP = rl.COL_ID
        INNER JOIN TBL_FOM_OBJECT cobj ON rl.COL_CHILDFOM_RELFOM_OBJECT = cobj.COL_ID
        INNER JOIN TBL_FOM_ATTRIBUTE attr ON resattr.COL_SOM_RESULTATTRFOM_ATTR = attr.COL_ID
        INNER JOIN TBL_FOM_OBJECT obj ON attr.COL_FOM_ATTRIBUTEFOM_OBJECT = obj.COL_ID
        LEFT JOIN TBL_DICT_DATATYPE dataType ON dataType.COL_ID = attr.COL_FOM_ATTRIBUTEDATATYPE
      WHERE resattr.COL_SOM_RESULTATTRSOM_CONFIG = v_configid
        AND attr.COL_STORAGETYPE = 'SIMPLE'
        AND attr.COL_FOM_ATTRIBUTEFOM_OBJECT <> cobj.COL_ID /*v_rootobjid*/
      ORDER BY resattr.COL_SORDER)
  LOOP
    IF (TRIM(v_srchqry) <> 'select') THEN
      IF rec.ResultAttrProcCode IS NULL THEN
        if rec.ResultAttrMetaProp = 1 and rec.ResultAttrIDProp = 1 then
          v_srchqry := v_srchqry || ', ' || to_char(rec.ResultAttrId) || ' as ' || rec.AttrAlias;
        else
          v_srchqry := v_srchqry || ', ' || rec.ObjAlias || '.' || rec.AttrColumnName || ' as ' || rec.AttrAlias;
        end if;
      ELSE
        if rec.ResultAttrMetaProp = 1 and rec.ResultAttrIDProp = 1 then
          v_srchqry := v_srchqry || ', ' || rec.ResultAttrProcCode || '(' || to_char(rec.ResultAttrId) || ') as ' || rec.AttrAlias;
        else
          v_srchqry := v_srchqry || ', ' || rec.ResultAttrProcCode || '(' || rec.ObjAlias || '.' || rec.AttrColumnName || ') as ' || rec.AttrAlias;
        end if;
      END IF;
    ELSE
      IF rec.ResultAttrProcCode IS NULL THEN
        if rec.ResultAttrMetaProp = 1 and rec.ResultAttrIDProp = 1 then
          v_srchqry := v_srchqry || to_char(rec.ResultAttrId) || ' as ' || rec.AttrAlias;
        else
          v_srchqry := v_srchqry || rec.ObjAlias || '.' || rec.AttrColumnName || ' as ' || rec.AttrAlias;
        end if;
      ELSE
        if rec.ResultAttrMetaProp = 1 and rec.ResultAttrIDProp = 1 then
          v_srchqry := v_srchqry || rec.ResultAttrProcCode || '(' || to_char(rec.ResultAttrId) || ') as ' || rec.AttrAlias;
        else
          v_srchqry := v_srchqry || rec.ResultAttrProcCode || '(' || rec.ObjAlias || '.' || rec.AttrColumnName || ') as ' || rec.AttrAlias;
        end if;
      END IF;
    END IF;
    IF (v_sort IS NOT NULL AND v_data_type_sort IS NULL AND LOWER(v_sort) = LOWER(rec.AttrAlias)) THEN
      v_data_type_sort := LOWER(rec.columnType);
      v_date_format_sort := NULL;
    END IF;
  END LOOP;
  --END OF LOOP THROUGH THE LIST OF SIMPLE STORAGE TYPE SEARCH ATTRIBUTES. ALL SUCH ATTRIBUTES ARE ADDED TO RESULT LIST

  --ADD XML STORAGE TYPE ATTRIBUTES TO LIST OF ATTRIBUTES
  FOR rec IN (SELECT resattr.COL_ID AS ResultAttrId,
                     resattr.COL_CODE AS ResultAttrCode,
                     resattr.COL_NAME AS ResultAttrName,
                     resattr.COL_SOM_RESULTATTRFOM_ATTR AS AttrId,
                     attr.COL_CODE AS AttrCode,
                     attr.COL_NAME AS AttrName,
                     attr.COL_COLUMNNAME AS AttrColumnName,
                     attr.COL_STORAGETYPE AS AttrStorageType,
                     attr.COL_ALIAS AS AttrAlias,
                     obj.COL_CODE AS ObjCode,
                     obj.COL_NAME AS ObjName,
                     obj.COL_TABLENAME AS ObjTableName,
                     obj.COL_ALIAS AS ObjAlias,
                     obj.COL_XMLALIAS AS ObjXMLAlias,
                     dataType.COL_CODE AS columnType
      FROM TBL_SOM_RESULTATTR resattr
        INNER JOIN TBL_FOM_ATTRIBUTE attr ON resattr.COL_SOM_RESULTATTRFOM_ATTR = attr.COL_ID
        INNER JOIN TBL_FOM_OBJECT obj ON attr.COL_FOM_ATTRIBUTEFOM_OBJECT = obj.COL_ID
        LEFT JOIN TBL_DICT_DATATYPE dataType ON dataType.COL_ID = attr.COL_FOM_ATTRIBUTEDATATYPE
      WHERE resattr.COL_SOM_RESULTATTRSOM_CONFIG = v_configid
        AND attr.COL_STORAGETYPE = 'XML'
      ORDER BY resattr.COL_SORDER)
  LOOP
    IF (v_xmlalias IS NULL OR v_xmlalias <> rec.ObjXMLAlias) THEN
      v_xmlfromqry := ' ,xmltable(''/CustomData/Attributes'' passing ' || F_FORM_GETALIASFROMQUERY(v_fromqry, rec.ObjTableName) ||
      '.' || rec.AttrColumnName || ' columns ';
      v_xmlfromqry := v_xmlfromqry || rec.AttrCode || ' varchar2(255) path ' || ''' Form/' || rec.AttrCode || '''';
    ELSE
      v_xmlfromqry := v_xmlfromqry || ',' || rec.AttrCode || ' varchar2(255) path ' || ''' Form/' || rec.AttrCode || '''';
    END IF;
    IF (v_xmlalias IS NOT NULL AND v_xmlalias <> rec.ObjXMLAlias) THEN
      v_xmlfromqry := v_xmlfromqry || ') ' || v_xmlalias;
    END IF;
    v_srchqry := v_srchqry || ', ' || rec.ObjXMLAlias || '.' || rec.AttrCode || ' as ' || rec.AttrAlias;
    v_xmlalias := rec.ObjXMLAlias;
    IF (v_sort IS NOT NULL AND v_data_type_sort IS NULL AND LOWER(v_sort) = LOWER(rec.AttrAlias)) THEN
      v_data_type_sort := LOWER(rec.columnType);
      v_date_format_sort := v_date_format;
    END IF;
  END LOOP;
  --END OF LOOP THROUGH THE LIST OF XML STORAGE TYPE SEARCH ATTRIBUTES. ALL SUCH ATTRIBUTES ARE ADDED TO RESULT LIST

  IF v_isqrysaved = 0 THEN
    IF (v_xmlalias IS NOT NULL) THEN
      v_xmlfromqrycache := v_xmlfromqry || ') ' || v_xmlalias;
    ELSE
      v_xmlfromqrycache := v_xmlfromqry;
    END IF;
    UPDATE TBL_SOM_CONFIG SET col_srchqry = v_srchqry, col_fromqry = v_fromqry, col_xmlfromqry = v_xmlfromqrycache, col_whereqry = v_whereqry WHERE col_id = v_configid;
  END IF;
  
  <<qry_saved>>
  IF v_isqrysaved = 1 THEN
    v_srchqry := v_srchqrycache;
    v_fromqry := v_fromqrycache;
    v_xmlfromqry := v_xmlfromqrycache;
    v_whereqry := v_whereqrycache;
  END IF;
  IF v_isqrysaved = 0 then
    FOR rec IN (SELECT srchattr.COL_ID AS SearchAttrId,
                       srchattr.COL_CODE AS SearchAttrCode,
                       srchattr.COL_NAME AS SearchAttrName,
                       srchattr.COL_ISLIKE AS SearchAttrLike,
                       srchattr.COL_ISCASEINCENSITIVE AS SearchAttrCaseIncensitive,
                       srchattr.COL_ISCOLUMNCOMP AS columnComp,
                       srchattr.COL_LEFT_SEARCHATTRFOM_ATTR AS leftAttr,
                       srchattr.COL_RIGHT_SEARCHATTRFOM_ATTR AS rightAttr
        FROM TBL_SOM_SEARCHATTR srchattr
        WHERE srchattr.COL_SOM_SEARCHATTRSOM_CONFIG = v_configid
        ORDER BY srchattr.COL_SORDER)
    LOOP
      begin
        select fo.col_id into v_return
        from tbl_fom_object fo
        inner join tbl_fom_attribute fa on fo.col_id = fa.col_fom_attributefom_object
        inner join tbl_som_searchattr srchattr on fa.col_id = srchattr.col_left_searchattrfom_attr
        where srchattr.col_id = rec.SearchAttrId;
        exception
        when NO_DATA_FOUND then
        v_return := null;
      end;
      begin
        select fo.col_id into v_return2
        from tbl_fom_object fo
        inner join tbl_fom_attribute fa on fo.col_id = fa.col_fom_attributefom_object
        inner join tbl_som_searchattr srchattr on fa.col_id = srchattr.col_right_searchattrfom_attr
        where srchattr.col_id = rec.SearchAttrId;
        exception
        when NO_DATA_FOUND then
        v_return2 := null;
      end;
      if v_return is not null and v_return2 is not null then
        update tbl_som_searchattr set col_leftalias = v_ObjectAlias(v_return), col_rightalias = v_ObjectAlias(v_return2) where col_id = rec.SearchAttrId;
      end if;
    END LOOP;
  end if;
  -- BUILD WHERE CLAUSE --
  --LOOP THROUGH SEARCH ATTRIBUTES
  FOR rec IN (SELECT srchattr.COL_ID AS SearchAttrId,
                     srchattr.COL_CODE AS SearchAttrCode,
                     srchattr.COL_NAME AS SearchAttrName,
                     srchattr.COL_ISLIKE AS SearchAttrLike,
                     srchattr.COL_ISCASEINCENSITIVE AS SearchAttrCaseIncensitive,
                     pt.COL_CODE AS PathCode,
                     (case 
                      when attr.COL_FOM_ATTRIBUTEFOM_OBJECT = v_rootobjid then obj.COL_ALIAS
                      when pt.COL_CODE is not null then pt.COL_CODE
                      when pt.col_code is null then
                     (select col_code from tbl_fom_path where col_fom_pathfom_relationship in
                     (select col_id from tbl_fom_relationship where col_parentfom_relfom_object = obj.col_id
                     and col_childfom_relfom_object in (select col_id from tbl_fom_object where col_id in
                     (select col_fom_attributefom_object from tbl_fom_attribute where col_id in
                     (select col_som_resultattrfom_attr from tbl_som_resultattr where col_som_resultattrsom_config = v_ConfigId)))))
                     else obj.COL_ALIAS end) AS ObjAlias,
                     uiEl.COL_CODE AS UIElementType,
                     NVL(srchattr.COL_CONSTANT, 0) AS Constant,
                     obj.COL_CODE AS ObjCode,
                     obj.COL_NAME AS ObjName,
                     obj.COL_TABLENAME AS ObjTableName,
                     obj.COL_ALIAS AS ObjectAlias,
                     obj.COL_XMLALIAS AS ObjXMLAlias,
                     attr.COL_ID AS AttrId,
                     attr.COL_CODE AS AttrCode,
                     attr.COL_NAME AS AttrName,
                     attr.COL_COLUMNNAME AS AttrColumnName,
                     attr.COL_STORAGETYPE AS AttrStorageType,
                     dataType.COL_CODE AS columnType,
                     srchattr.COL_ISCOLUMNCOMP AS columnComp,
                     srchattr.COL_LEFT_SEARCHATTRFOM_ATTR AS leftAttr,
                     srchattr.COL_RIGHT_SEARCHATTRFOM_ATTR AS rightAttr,
                     srchattr.COL_LEFTALIAS AS leftAlias,
                     srchattr.COL_RIGHTALIAS AS rightAlias
      FROM TBL_SOM_SEARCHATTR srchattr
        LEFT JOIN TBL_FOM_PATH pt ON srchattr.COL_SOM_SEARCHATTRFOM_PATH = pt.COL_ID
        INNER JOIN TBL_FOM_ATTRIBUTE attr ON srchattr.COL_SOM_SEARCHATTRFOM_ATTR = attr.COL_ID
        INNER JOIN TBL_FOM_OBJECT obj ON attr.COL_FOM_ATTRIBUTEFOM_OBJECT = obj.COL_ID
        LEFT JOIN TBL_DICT_DATATYPE dataType ON dataType.COL_ID = attr.COL_FOM_ATTRIBUTEDATATYPE
        LEFT JOIN TBL_FOM_UIELEMENTTYPE uiEl ON uiEl.COL_ID = srchattr.COL_SEARCHATTR_UIELEMENTTYPE
      WHERE srchattr.COL_SOM_SEARCHATTRSOM_CONFIG = v_configid
      ORDER BY srchattr.COL_SORDER)
  LOOP
    IF rec.columnComp = 1 THEN
      BEGIN
        SELECT fa.COL_COLUMNNAME as ColumnReference INTO v_expleft
        FROM TBL_FOM_ATTRIBUTE fa
        WHERE fa.COL_ID = rec.leftAttr;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
        v_expleft := NULL;
      END;
      v_expleft := rec.leftAlias || '.' || v_expleft;
      BEGIN
        SELECT fa.COL_COLUMNNAME as ColumnReference INTO v_expright
        FROM TBL_FOM_ATTRIBUTE fa
        WHERE fa.COL_ID = rec.rightAttr;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
        v_expright := NULL;
      END;
      v_expright := rec.rightAlias || '.' || v_expright;
      IF v_expleft is NOT NULL and v_expright is NOT NULL THEN
        IF (v_whereqry IS NULL) THEN
          v_whereqry := ' where ' || v_expleft || ' = ' || v_expright;
        ELSE
          v_whereqry := v_whereqry || ' and ' || v_expleft || ' = ' || v_expright;
        END IF;
      END IF;
      CONTINUE;
    END IF;
    IF v_SearchAttrAdded(rec.SearchAttrId) = 1 THEN
      v_SearchAttrAdded(rec.SearchAttrId) := NULL;
      CONTINUE;
    END IF;
    IF (rec.AttrStorageType = 'SIMPLE') THEN
      v_alias := rec.ObjAlias;
      v_columnname := rec.AttrColumnName;
    ELSIF (rec.AttrStorageType = 'XML') THEN
      v_alias := rec.ObjXMLAlias;
      v_columnname := rec.SearchAttrCode;
    END IF;
    v_data_type_where := LOWER(rec.columnType);

    IF (v_data_type_where = 'date' or v_data_type_where = 'createddate' or v_data_type_where = 'modifieddate') THEN
      IF (NVL(rec.Constant, 0) = 0) THEN
        v_dateFrom := F_FORM_GETPARAMBYNAME(v_input, rec.SearchAttrCode || '_FROM');
        v_dateTo := F_FORM_GETPARAMBYNAME(v_input, rec.SearchAttrCode || '_TO');
      ELSE
        v_dateFrom := F_FORM_GETPARAMBYNAME(v_input, rec.SearchAttrCode || '_FROM_CONST');
        v_dateTo := F_FORM_GETPARAMBYNAME(v_input, rec.SearchAttrCode || '_TO_CONST');
      END IF;
    ELSE
      v_dateFrom := NULL;
      v_dateTo := NULL;
    END IF;

    IF (NVL(rec.Constant, 0) <> 0 AND v_data_type_where <> 'date') THEN
      v_curentSearchAttr := rec.SearchAttrCode || '_CONST';
    ELSE
      v_curentSearchAttr := rec.SearchAttrCode;
    END IF;

    IF (F_FORM_GETPARAMBYNAME(v_input, v_curentSearchAttr) IS NOT NULL OR
    ((v_data_type_where = 'date' or v_data_type_where = 'createddate' or v_data_type_where = 'modifieddate') AND (v_dateFrom IS NOT NULL OR v_dateTo IS NOT NULL))) THEN
      v_currentParam := F_FORM_GETPARAMBYNAME(v_input, v_curentSearchAttr);
      IF (UPPER(rec.UIElementType) = 'MULTISELECT_COMBOBOX') THEN
        v_condition := ' in ';
        v_expInSelect := '(SELECT ';
        v_expInColValue := ' COLUMN_VALUE ';
        v_expInFrom := ' FROM TABLE(ASF_SPLIT(''';
        v_expInEnd := ''','','')))';
      ELSIF (NVL(rec.Constant, 0) <> 0 AND v_data_type_where = 'text' AND UPPER(rec.UIElementType) = 'TEXT_FIELD' AND v_currentParam = :AccessSubjectCode) THEN
        v_currentParam := :AccessSubjectCode;
        v_condition := ' = ';
        v_expInSelect := '';
        v_expInColValue := '';
        v_expInFrom := '';
        v_expInEnd := '';
      ELSIF (NVL(rec.Constant, 0) <> 0 AND v_data_type_where = 'integer' AND (NVL(INSTR(v_currentParam, ';'), 0) <> 0 OR NVL(INSTR(v_currentParam, ','), 0) <> 0)) THEN
        v_condition := ' in ';
        v_expInSelect := '';
        v_expInColValue := '';
        v_expInFrom := '(';
        v_expInEnd := ')';
        v_currentParam := REPLACE(v_currentParam, ';', ',');
      ELSIF (v_data_type_where = 'text' AND (NVL(INSTR(v_currentParam, /*'&apos;'*/''''), 0) <> 0)) THEN
        v_condition := ' = ';
        v_expInSelect := '';
        v_expInColValue := '';
        v_expInFrom := '';
        v_expInEnd := '';
        v_currentParam := REPLACE(v_currentParam, /*'&apos;'*/'''', '''''');
      ELSE
        v_condition := ' = ';
        v_expInSelect := '';
        v_expInColValue := '';
        v_expInFrom := '';
        v_expInEnd := '';
      END IF;

      IF NVL(rec.SearchAttrCaseIncensitive, 0) = 0 THEN
        v_exprstart := '';
        v_exprend := '';
      ELSIF rec.SearchAttrCaseIncensitive = 1 THEN
        v_exprstart := 'lower(';
        v_exprend := ')';
      ELSE
        v_exprstart := '';
        v_exprend := '';
      END IF;

      IF (v_data_type_where = 'date' or v_data_type_where = 'createddate' or v_data_type_where = 'modifieddate') THEN
        IF rec.AttrStorageType = 'XML' THEN
          v_exprstart := v_exprstart || 'to_date(';
          v_exprend := v_exprend || ',''' || v_date_format || ''')';
        ELSE
          v_exprstart := v_exprstart || 'trunc(';
          v_exprend := v_exprend || ')';
        END IF;
      END IF;

      IF NVL(rec.SearchAttrLike, 0) = 0 THEN
        IF (v_data_type_where = 'integer') THEN
          IF (TRIM(v_condition) = 'in') THEN
            v_expr := v_condition || v_expInSelect || v_exprstart || v_expInColValue || v_exprend || v_expInFrom || v_currentParam || v_expInEnd;
          ELSE
            v_expr := v_condition || v_exprstart || v_currentParam || v_exprend;
          END IF;
        ELSIF (v_data_type_where = 'date' or v_data_type_where = 'createddate' or v_data_type_where = 'modifieddate') THEN
          IF (v_dateFrom IS NOT NULL AND v_dateTo IS NOT NULL) THEN
            v_count := 0;
            WHILE (v_count < 2)
              LOOP
                IF (v_count = 0) THEN
                  v_currentParam := v_dateFrom;
                  v_condition := '>=';
                ELSE
                  v_currentParam := v_dateTo;
                  v_condition := '<=';
                END IF;
                --if date format DD-MON-YYYY (10-FEB-2016)
                IF (REGEXP_SUBSTR(v_dateFrom, '(\d{1,2})(-)([a-zA-Z]{3})(-)(\d{4})$') IS NOT NULL) THEN
                  IF (rec.AttrStorageType = 'XML') THEN
                    v_expr := v_condition || v_exprstart || '''' || v_currentParam || '''' || v_exprend;
                  ELSE --is simple storage
                    v_expr := v_condition || 'to_date(' || '''' || v_currentParam || '''' || ', ''' || v_date_format || ''')';
                  END IF;
                ELSE -- system format 
                  IF (rec.AttrStorageType = 'XML') THEN
                    v_expr := v_condition || 'trunc(to_date(' || '''' || v_currentParam || '''' || ', ''' || v_date_format_system || '''))';
                  ELSE --is simple storage
                    v_expr := v_condition || v_exprstart || 'to_date(' || '''' || v_currentParam || '''' || ', ''' || v_date_format_system || ''')' || v_exprend;
                  END IF;
                END IF;

                IF (v_whereqry IS NULL) THEN
                  v_whereqry := ' where ' || v_exprstart || v_alias || '.' || v_columnname || v_exprend || v_expr;
                ELSE
                  v_whereqry := v_whereqry || ' and ' || v_exprstart || v_alias || '.' || v_columnname || v_exprend || v_expr;
                END IF;
                v_count := v_count + 1;
              END LOOP;
          ELSE
            IF (v_dateFrom IS NOT NULL AND v_dateTo IS NULL) THEN
              v_currentParam := v_dateFrom;
              v_condition := '>=';
            ELSIF (v_dateFrom IS NULL AND v_dateTo IS NOT NULL) THEN
              v_currentParam := v_dateTo;
              v_condition := '<=';
            ELSE
              CONTINUE;
            END IF;

            IF (REGEXP_SUBSTR(v_currentParam, '(\d{1,2})(-)([a-zA-Z]{3})(-)(\d{4})$') IS NOT NULL) THEN
              IF (rec.AttrStorageType = 'XML') THEN
                v_expr := v_condition || v_exprstart || '''' || v_currentParam || '''' || v_exprend;
              ELSE --is simple storage
                v_expr := v_condition || 'to_date(' || '''' || v_currentParam || '''' || ', ''' || v_date_format || ''')';
              END IF;
            ELSE -- system format 
              IF (rec.AttrStorageType = 'XML') THEN
                v_expr := v_condition || 'trunc(to_date(' || '''' || v_currentParam || '''' || ', ''' || v_date_format_system || '''))';
              ELSE --is simple storage
                v_expr := v_condition || v_exprstart || 'to_date(' || '''' || v_currentParam || '''' || ', ''' || v_date_format_system || ''')' || v_exprend;
              END IF;
            END IF;
            IF v_whereqry IS NULL THEN
              v_whereqry := ' where ' || v_exprstart || v_alias || '.' || v_columnname || v_exprend || v_expr;
            ELSE
              v_whereqry := v_whereqry || ' and ' || v_exprstart || v_alias || '.' || v_columnname || v_exprend || v_expr;
            END IF;
          END IF;
        ELSE
          IF (TRIM(v_condition) = 'in') THEN
            v_expr := v_condition || v_expInSelect || v_exprstart || v_expInColValue || v_exprend || v_expInFrom || v_currentParam || v_expInEnd;
          ELSE
            v_expr := v_condition || v_exprstart || '''' || v_currentParam || '''' || v_exprend;
          END IF;
        END IF;
      ELSIF (rec.SearchAttrLike = 1) THEN
        v_expr := ' like ' || v_exprstart || '''%' || v_currentParam || '%''' || v_exprend;
      ELSE
        v_expr := NULL;
      END IF;
    END IF;
    IF (v_whereqry IS NULL) THEN
      IF (F_FORM_GETPARAMBYNAME(v_input, v_curentSearchAttr) IS NOT NULL) THEN
        v_whereqry := ' where ' || v_exprstart || v_alias || '.' || v_columnname || v_exprend || v_expr;
      END IF;
    ELSE
      IF (F_FORM_GETPARAMBYNAME(v_input, v_curentSearchAttr) IS NOT NULL) THEN
        v_whereqry := v_whereqry || ' and ' || v_exprstart || v_alias || '.' || v_columnname || v_exprend || v_expr;
      END IF;
    END IF;
  END LOOP;
  --END OF LOOP THROUGH SEARCH ATTRIBUTES
  IF (v_xmlalias IS NOT NULL) THEN
    v_xmlfromqry := v_xmlfromqry || ') ' || v_xmlalias;
  END IF;

  --ADD SORTING
  IF (v_sort IS NULL) THEN
    v_orderBy := '';
  ELSE
    IF (v_data_type_sort = 'integer') THEN
      v_orderBy := ' order by to_number(' || v_sort || ') ' || v_dir;
    ELSIF (v_data_type_sort = 'date' AND v_date_format_sort IS NOT NULL) THEN
      v_orderBy := ' order by to_date(' || v_sort || ', ''' || v_date_format_sort || ''') ' || v_dir;
    ELSE
      v_orderBy := ' order by ' || v_sort || ' ' || v_dir;
    END IF;
  END IF;

  --FINALIZE QUERY BUILD
  v_countquery := 'select count(*)' || v_fromqry || v_xmlfromqry || v_whereqry;
  if v_orderby is not null then
    v_whereqry := v_whereqry || v_orderby;
  end if;
  if v_limit_row is not null and v_whereqry is null then
    v_whereqry := ') tbl2' || ' where rownum <= ' || (v_star_row + v_limit_row);
  elsif v_limit_row is not null and v_whereqry is not null then
    v_whereqry := v_whereqry || ') tbl2' || ' where rownum <= ' || (v_star_row + v_limit_row);
  end if;
  v_query := v_srchqry || v_fromqry || v_xmlfromqry || v_whereqry;

  IF (v_limit_row IS NOT NULL) THEN
    v_query := 'select tbl2.*, rownum rn from (' || v_query || ') tbl';
    v_query := 'select tbl.* from (' || v_query || ' where rn > ' || v_star_row;
  END IF;

  --EXECUTE BUILT QUERY AND COUNT QUERY
  BEGIN
    EXECUTE IMMEDIATE v_countquery
      INTO :TotalCount;
  EXCEPTION
    WHEN OTHERS THEN
        --DBMS_OUTPUT.NEW_LINE();
        --DBMS_OUTPUT.PUT_LINE('Count: ' || v_countquery);
        :ErrorCode := SQLCODE;
        :ErrorMessage := SUBSTR('Error in count query' || ': ' || SQLERRM, 1, 200);
  END;
  --DBMS_OUTPUT.NEW_LINE();
  --DBMS_OUTPUT.PUT_LINE(v_query);
  BEGIN
    OPEN :ITEMS FOR v_query;
  EXCEPTION
    WHEN OTHERS THEN
        :ErrorCode := SQLCODE;
        :ErrorMessage := SUBSTR('Error on search query' || ': ' || SQLERRM, 1, 200);
  END;

END;