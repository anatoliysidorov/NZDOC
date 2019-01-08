DECLARE
    v_count          INTEGER;
    v_recId          INTEGER;
    v_Parent         INTEGER;
    v_Child          INTEGER;
    v_data_type_id   INTEGER;
    v_data_type_name NVARCHAR2(255);
    v_rec_data_type  NVARCHAR2(255);
    
BEGIN
  /*
   * List of business objects that are associated with FOM_OBJECT
   * recObg Loop for processing each record FOM_OBJECT
   */
    FOR recObg IN (SELECT DISTINCT fObj.COL_ID AS ID, fObj.COL_CODE AS CODE,
                            deployBO.BOLOCALCODE AS BOLOCALCODE,
                            deployBO.BONAME AS BONAME,
                            deployBO.BOTABLENAME AS TABLENAMEBO
                    FROM TBL_FOM_OBJECT fObj
                    LEFT JOIN VW_UTIL_DEPLOYEDBO deployBO
                            ON LOWER(deployBO.BOTABLENAME) = LOWER(fObj.COL_TABLENAME)
                    WHERE fObj.COL_TABLENAME IS NOT NULL)
    LOOP
        --Set curent COL_ID from FOM_OBJECT into variable v_recId
        v_recId := recObg.ID;
        IF (recObg.TABLENAMEBO IS NULL) THEN
            ---- Delete from SOM
            --Delete all records from SOM_RESULTATTR, that refer to non-existent configuration
            DELETE FROM TBL_SOM_RESULTATTR
            WHERE COL_ID IN (
                SELECT sRes.COL_ID
                FROM TBL_SOM_RESULTATTR sRes
                LEFT JOIN TBL_SOM_CONFIG sConf 
                        ON sConf.COL_ID = sRes.COL_SOM_RESULTATTRSOM_CONFIG
                WHERE sConf.COL_ID IS NULL
                    OR sConf.COL_SOM_CONFIGFOM_OBJECT = v_recId);

            --Delete all records from SOM_SEARCHATTR, that refer to non-existent configuration
            DELETE FROM TBL_SOM_SEARCHATTR
            WHERE COL_ID IN (
                SELECT sSerch.COL_ID
                FROM TBL_SOM_SEARCHATTR sSerch
                LEFT JOIN TBL_SOM_CONFIG sConf 
                        ON sConf.COL_ID = sSerch.COL_SOM_SEARCHATTRSOM_CONFIG
                WHERE sConf.COL_ID IS NULL
                    OR sConf.COL_SOM_CONFIGFOM_OBJECT = v_recId);

            --Remove all associated configuration
            DELETE FROM TBL_SOM_CONFIG
            WHERE COL_SOM_CONFIGFOM_OBJECT = v_recId;

            ---Delete from FOM
            DELETE FROM TBL_FOM_ATTRIBUTE
            WHERE COL_FOM_ATTRIBUTEFOM_OBJECT = v_recId;
  
            DELETE FROM TBL_FOM_RELATIONSHIP
            WHERE COL_CHILDFOM_RELFOM_OBJECT  = v_recId
                OR COL_PARENTFOM_RELFOM_OBJECT = v_recId;

            DELETE FROM TBL_FOM_OBJECT
            WHERE COL_ID = v_recId;
  
            --TBD DELETE FROM PATH
        ELSE
            UPDATE TBL_FOM_OBJECT SET
              COL_ALIAS = SUBSTR('t_' || recObg.BONAME, 1, 30),
              COL_XMLALIAS = SUBSTR('xml_' || recObg.BONAME, 1, 30)
            WHERE COL_ID = v_recId;

            FOR recAttr IN (SELECT fa.COL_ID AS ID,
                                UPPER(BALOCALCODE) AS CODE,
                                BANAME AS Name,
                                BACOLUMNNAME AS ColumnName,
                                LOWER(BATYPECODE) AS TypeCode,
                                BATYPENAME AS TypeName
                            FROM VW_UTIL_DEPLOYEDBO dbo
                            LEFT JOIN TBL_FOM_ATTRIBUTE fa 
                                ON (LOWER(fa.COL_COLUMNNAME) = LOWER(dbo.BACOLUMNNAME)
                                AND fa.COL_FOM_ATTRIBUTEFOM_OBJECT = v_recId)
                            WHERE dbo.BOTABLENAME = recObg.TABLENAMEBO)
            LOOP
                v_rec_data_type := recAttr.TypeCode;

                IF (v_rec_data_type = 'type_xmltype')
                THEN CONTINUE; --Next record if current column have XML type 

                ELSIF (v_rec_data_type = 'type_checkbox' OR 
                    v_rec_data_type = 'type_integer'  OR 
                    v_rec_data_type = 'type_number')
                THEN v_data_type_name := 'integer';
  
                ELSIF (v_rec_data_type = 'type_date' OR v_rec_data_type = 'type_time')
                THEN v_data_type_name := 'date';
  
                ELSE v_data_type_name := 'text';
                END IF;

                --Get col_id of type from TBL_DICT_DATATYPE
                BEGIN
                    SELECT COL_ID INTO v_data_type_id
                    FROM TBL_DICT_DATATYPE
                    WHERE LOWER(COL_CODE) = v_data_type_name;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN v_data_type_id := NULL;
                END;
                ------

                IF (recAttr.ID IS NULL) THEN
                    --Add attribute
                    INSERT INTO TBL_FOM_ATTRIBUTE (
                        COL_FOM_ATTRIBUTEFOM_OBJECT,
                        COL_CODE,
                        COL_NAME,
                        COL_COLUMNNAME,
                        COL_STORAGETYPE,
                        COL_ALIAS,
                        COL_FOM_ATTRIBUTEDATATYPE
                    ) VALUES (
                        v_recId,
                        SUBSTR(recObg.CODE || '_' || recAttr.CODE, 1, 30),
                        recAttr.NAME,
                        recAttr.COLUMNNAME,
                        'SIMPLE',
                        SUBSTR(recObg.CODE || '_' || recAttr.NAME, 1, 30),
                        v_data_type_id
                    );
                ELSE
                    -- Update attribute
                    UPDATE TBL_FOM_ATTRIBUTE SET
                           COL_CODE = SUBSTR(recObg.CODE || '_' || recAttr.CODE, 1, 30),
                           COL_NAME = recAttr.NAME,
                           COL_COLUMNNAME = recAttr.COLUMNNAME,
                           COL_STORAGETYPE = 'SIMPLE',
                           COL_ALIAS = SUBSTR(recObg.CODE || '_' || recAttr.NAME, 1, 30),
                           COL_FOM_ATTRIBUTEDATATYPE = v_data_type_id
                     WHERE COL_ID = recAttr.ID;
                END IF;
            END LOOP; --recAttr

            ---- Removing non-existent attributes
        DELETE FROM TBL_FOM_ATTRIBUTE
        WHERE COL_ID IN (
            SELECT fa.COL_ID
              FROM TBL_FOM_ATTRIBUTE fa
              LEFT JOIN VW_UTIL_DEPLOYEDBO dbo 
                ON LOWER(fa.COL_COLUMNNAME) = LOWER(dbo.BACOLUMNNAME)
               AND dbo.BOTABLENAME = recObg.TABLENAMEBO
             WHERE fa.COL_FOM_ATTRIBUTEFOM_OBJECT = v_recId
               AND BACOLUMNNAME IS NULL);
      ----
      FOR recRellation IN (SELECT DISTINCT
                                  rel.NAME AS NameRel,
                                  rel.ColumnName AS ColumnName,
                                  rel.SOURCEBO AS Source,
                                  rel.SOURCETYPE AS SourceType,
                                  fObjS.COL_ID AS Source_id_obj,
                                  rel.TARGETBO AS Target,
                                  rel.TARGETTYPE AS TargetType,
                                  fObjT.COL_ID AS Target_id_obj,
                                  fRel.COL_ID AS Rel_ID,
                                  fRel.COL_FOREIGNKEYNAME
          FROM VW_FOM_RELATIONSHIP rel
          LEFT JOIN TBL_FOM_RELATIONSHIP fRel
              ON LOWER(rel.ColumnName) = LOWER(fRel.COL_FOREIGNKEYNAME)
          LEFT JOIN TBL_FOM_OBJECT fObjS
              ON LOWER(fObjS.COL_TABLENAME) = LOWER(rel.SOURCEBO)
          LEFT JOIN TBL_FOM_OBJECT fObjT
              ON LOWER(fObjT.COL_TABLENAME) = LOWER(rel.TARGETBO)
          WHERE fObjT.COL_ID IS NOT NULL
            AND fObjS.COL_ID IS NOT NULL
            AND (rel.SOURCEBO = recObg.TABLENAMEBO
             OR  rel.TARGETBO = recObg.TABLENAMEBO))
      LOOP
        IF (recRellation.SourceType = 1 AND recRellation.TargetType = 2) 
        THEN
          v_Parent := recRellation.Source_id_obj;
          v_Child  := recRellation.Target_id_obj;
        ELSIF (recRellation.SourceType = 2 AND recRellation.TargetType = 1)
        THEN
          v_Parent := recRellation.Target_id_obj;
          v_Child  := recRellation.Source_id_obj;
        ELSE
          CONTINUE;
        END IF;
        
        IF (recRellation.Rel_ID IS NULL) THEN
            INSERT INTO TBL_FOM_RELATIONSHIP (
              COL_CHILDFOM_RELFOM_OBJECT,
              COL_PARENTFOM_RELFOM_OBJECT,
              COL_CODE,
              COL_NAME,
              COL_FOREIGNKEYNAME
            ) VALUES (
              v_Child, 
              v_Parent, 
              UPPER(recRellation.NameRel), 
              recRellation.NameRel, 
              recRellation.COLUMNNAME
             );
        ELSE
          UPDATE TBL_FOM_RELATIONSHIP SET 
            COL_CHILDFOM_RELFOM_OBJECT = v_Child,
            COL_PARENTFOM_RELFOM_OBJECT = v_Parent,
            COL_CODE = UPPER(recRellation.NameRel), 
            COL_NAME = recRellation.NameRel, 
            COL_FOREIGNKEYNAME = recRellation.COLUMNNAME
          WHERE COL_ID = recRellation.rel_id;
        END IF;
      END LOOP;--recRellation

      ----Removing non-existent rellations
        DELETE FROM TBL_FOM_RELATIONSHIP
        WHERE COL_ID IN (
          SELECT fRel.COL_ID
          FROM TBL_FOM_RELATIONSHIP fRel
          LEFT JOIN VW_FOM_RELATIONSHIP relS ON LOWER(relS.COLUMNNAME) = LOWER(fRel.COL_FOREIGNKEYNAME)
                AND relS.SOURCEBO = recObg.TABLENAMEBO
          LEFT JOIN VW_FOM_RELATIONSHIP relT ON LOWER(relT.COLUMNNAME) = LOWER(fRel.COL_FOREIGNKEYNAME)
                AND relT.TARGETBO = recObg.TABLENAMEBO
          LEFT JOIN TBL_FOM_OBJECT fObjCh ON fObjCh.COL_ID = fRel.COL_CHILDFOM_RELFOM_OBJECT
          LEFT JOIN TBL_FOM_OBJECT fObjPa ON fObjPa.COL_ID = fRel.COL_PARENTFOM_RELFOM_OBJECT
          WHERE (fRel.COL_CHILDFOM_RELFOM_OBJECT = v_recId
            OR fRel.COL_PARENTFOM_RELFOM_OBJECT  = v_recId)
            AND ((relS.COLUMNNAME IS NULL AND relT.COLUMNNAME IS NULL) OR -- If not exist relation
                 (fObjCh.COL_ID IS NULL OR fObjPa.COL_ID IS NULL))); -- If not exist any object
      ----
    END IF;
  END LOOP; ---recObg
  ----Removing attributr with not-existent object
  DELETE FROM TBL_FOM_ATTRIBUTE
   WHERE COL_ID IN (
    SELECT fAttr.COL_ID
      FROM TBL_FOM_ATTRIBUTE fAttr
      LEFT JOIN TBL_FOM_OBJECT fObj
        ON fObj.COL_ID = fAttr.COL_FOM_ATTRIBUTEFOM_OBJECT
     WHERE fObj.COL_ID IS NULL);
  ----
END;