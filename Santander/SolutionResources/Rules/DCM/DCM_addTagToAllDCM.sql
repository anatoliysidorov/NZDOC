DECLARE

  V_TAG_CODE              VARCHAR2(255);
  v_EnvironmentCode       VARCHAR2(255);
  V_TAG_ID                NUMBER;
  V_SOLUTION_VERSION_CODE VARCHAR2(255);
  V_COMPONENTID           NUMBER;

  V_INSERTEDRECORDS NUMBER := 0;
  V_ERRORMESSAGE    VARCHAR2(255) := '';
  V_ERRORCODE       NUMBER := 0;

BEGIN

  V_TAG_CODE        := 'root_dcm';
  v_EnvironmentCode := '@TOKEN_DOMAIN@';

  BEGIN
    SELECT VERCONF.CODE
      INTO V_SOLUTION_VERSION_CODE
      FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_ENVIRONMENT E
     INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_VERSION VERR
        ON VERR.VERSIONID = E.DEPVERSIONID
     INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_VERSION VERCONF
        ON VERCONF.SOLUTIONID = VERR.SOLUTIONID
       AND VERCONF.TYPE = 1
     WHERE 1 = 1
       AND E.CODE = V_ENVIRONMENTCODE;
  EXCEPTION
    WHEN OTHERS THEN
      V_ERRORMESSAGE := 'SOLUTION VERSION IS NOT FOUND BY ENVIRONMENT.CODE = ' || V_ENVIRONMENTCODE;
      V_ERRORCODE    := 101;
      GOTO DONE;
  END;

  BEGIN
    SELECT COMPONENTID INTO V_COMPONENTID FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_VERSION WHERE CODE = V_SOLUTION_VERSION_CODE;
  EXCEPTION
    WHEN OTHERS THEN
      V_ERRORMESSAGE := 'ERROR WHEN TRY TO GET COMPONENT ID FOR SOLUTION VERSION = ' || V_SOLUTION_VERSION_CODE;
      V_ERRORCODE    := 101;
      GOTO DONE;
  END;

  BEGIN
    SELECT TAGID
      INTO V_TAG_ID
      FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_TAG
     WHERE COMPONENTID = V_COMPONENTID
       AND UPPER(CODE) = UPPER(V_TAG_CODE);
  EXCEPTION
    WHEN OTHERS THEN
      V_ERRORMESSAGE := 'ERROR WHEN TRY TO GET TAG ID FOR TAG CODE = ' || V_TAG_CODE;
      V_ERRORCODE    := 102;
      GOTO DONE;
  END;

  FOR REC IN (SELECT OBJECT_TYPE,
                     OBJECT_ID,
                     OBJECT_NAME,
                     OBJECT_CODE,
                     TAGS,
                     CASE
                       WHEN (SELECT COUNT(*) FROM TABLE(ASF_SPLITCLOB2(TAGS, ',')) WHERE COLUMN_VALUE = V_TAG_CODE) > 0 THEN
                        'TRUE'
                       ELSE
                        'FALSE'
                     END AS TAG_EXIST
                FROM (SELECT APPBASE_OBJECT.OBJECT_TYPE,
                             APPBASE_OBJECT.OBJECT_ID,
                             APPBASE_OBJECT.OBJECT_NAME,
                             APPBASE_OBJECT.OBJECT_CODE,
                             list_collect(CAST(COLLECT(to_char(TAG.CODE) ORDER BY to_char(TAG.CODE)) AS split_tbl), ',', 1) AS TAGS
                        FROM (SELECT 'RULE' AS OBJECT_TYPE,
                                     RULE.RULEID AS OBJECT_ID,
                                     RULE.NAME AS OBJECT_NAME,
                                     RULE.CODE AS OBJECT_CODE,
                                     RULE.COMPONENTID AS COMPONENTID
                                FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_RULE RULE
                               WHERE NVL(RULE.ISSYSTEM, 0) = 0
                              
                              UNION ALL
                              
                              SELECT 'PAGE' AS OBJECT_TYPE,
                                     PAGE.PAGEID AS OBJECT_ID,
                                     PAGE.NAME AS OBJECT_NAME,
                                     PAGE.CODE AS OBJECT_CODE,
                                     PAGE.COMPONENTID AS COMPONENTID
                                FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_NAVPAGE PAGE
                              
                              UNION ALL
                              
                              SELECT 'RELATION' AS OBJECT_TYPE,
                                     RELATION.RELATIONID AS OBJECT_ID,
                                     RELATION.NAME AS OBJECT_NAME,
                                     RELATION.CODE AS OBJECT_CODE,
                                     RELATION.COMPONENTID AS COMPONENTID
                                FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_BORELATION RELATION
                              
                              UNION ALL
                              
                              SELECT 'OBJECT' AS OBJECT_TYPE,
                                     OBJECT.OBJECTID AS OBJECT_ID,
                                     OBJECT.NAME AS OBJECT_NAME,
                                     OBJECT.CODE AS OBJECT_CODE,
                                     OBJECT.COMPONENTID AS COMPONENTID
                                FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_BOOBJECT OBJECT
                              
                              UNION ALL
                              
                              SELECT 'APPLICATION' AS OBJECT_TYPE,
                                     APPLICATION.APPID AS OBJECT_ID,
                                     APPLICATION.NAME AS OBJECT_NAME,
                                     APPLICATION.CODE AS OBJECT_CODE,
                                     APPLICATION.COMPONENTID AS COMPONENTID
                                FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_APPLICATION APPLICATION) APPBASE_OBJECT
                      
                        LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT TAG_OBJECT
                          ON TAG_OBJECT.OBJECTID = APPBASE_OBJECT.OBJECT_ID
                        LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_TAG TAG
                          ON TAG.TAGID = TAG_OBJECT.TAGID
                       WHERE APPBASE_OBJECT.COMPONENTID = V_COMPONENTID
                       GROUP BY APPBASE_OBJECT.OBJECT_TYPE,
                                APPBASE_OBJECT.OBJECT_ID,
                                APPBASE_OBJECT.OBJECT_NAME,
                                APPBASE_OBJECT.OBJECT_CODE)) LOOP
  
    IF (REC.OBJECT_TYPE = 'RULE' AND REC.TAG_EXIST = 'FALSE') THEN
      INSERT INTO @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT (TAGID, OBJECTID, TYPE) VALUES (V_TAG_ID, REC.OBJECT_ID, 7);
      --DBMS_OUTPUT.PUT_LINE('INSERT INTO @TOKEN_SYSTEMDOMAINUSER@.CONF_tagobject(TAGID, OBJECTID, TYPE) VALUES ('||v_TAG_ID||' , '||REC.OBJECT_ID||', 7); --RULE '||REC.OBJECT_CODE);
      V_INSERTEDRECORDS := V_INSERTEDRECORDS + 1;
    ELSIF (REC.OBJECT_TYPE = 'PAGE' AND REC.TAG_EXIST = 'FALSE') THEN
      INSERT INTO @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT (TAGID, OBJECTID, TYPE) VALUES (V_TAG_ID, REC.OBJECT_ID, 12);
      --DBMS_OUTPUT.PUT_LINE('INSERT INTO @TOKEN_SYSTEMDOMAINUSER@.CONF_tagobject(TAGID, OBJECTID, TYPE) VALUES ('||v_TAG_ID||' , '||REC.OBJECT_ID||', 12); --PAGE '||REC.OBJECT_CODE);
      V_INSERTEDRECORDS := V_INSERTEDRECORDS + 1;
    ELSIF (REC.OBJECT_TYPE = 'RELATION' AND REC.TAG_EXIST = 'FALSE') THEN
      INSERT INTO @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT (TAGID, OBJECTID, TYPE) VALUES (V_TAG_ID, REC.OBJECT_ID, 2);
      --DBMS_OUTPUT.PUT_LINE('INSERT INTO @TOKEN_SYSTEMDOMAINUSER@.CONF_tagobject(TAGID, OBJECTID, TYPE) VALUES ('||v_TAG_ID||' , '||REC.OBJECT_ID||', 2); --RELATION '||REC.OBJECT_CODE);
      V_INSERTEDRECORDS := V_INSERTEDRECORDS + 1;
    ELSIF (REC.OBJECT_TYPE = 'OBJECT' AND REC.TAG_EXIST = 'FALSE') THEN
      INSERT INTO @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT (TAGID, OBJECTID, TYPE) VALUES (V_TAG_ID, REC.OBJECT_ID, 8);
      --DBMS_OUTPUT.PUT_LINE('INSERT INTO @TOKEN_SYSTEMDOMAINUSER@.CONF_tagobject(TAGID, OBJECTID, TYPE) VALUES ('||v_TAG_ID||' , '||REC.OBJECT_ID||', 8); --OBJECT '||REC.OBJECT_CODE);
      V_INSERTEDRECORDS := V_INSERTEDRECORDS + 1;
    ELSIF (REC.OBJECT_TYPE = 'APPLICATION' AND REC.TAG_EXIST = 'FALSE') THEN
      INSERT INTO @TOKEN_SYSTEMDOMAINUSER@.CONF_TAGOBJECT (TAGID, OBJECTID, TYPE) VALUES (V_TAG_ID, REC.OBJECT_ID, 34);
      --DBMS_OUTPUT.PUT_LINE('INSERT INTO @TOKEN_SYSTEMDOMAINUSER@.CONF_tagobject(TAGID, OBJECTID, TYPE) VALUES ('||v_TAG_ID||' , '||REC.OBJECT_ID||', 34); --APPLICATION '||REC.OBJECT_CODE); 
      V_INSERTEDRECORDS := V_INSERTEDRECORDS + 1;
    END IF;
  
  --IF(REC.TAG_EXIST = 'TRUE') THEN
  --DBMS_OUTPUT.PUT_LINE('Object with name : '||REC.OBJECT_CODE||' and type '||REC.OBJECT_TYPE||' already exist.'); 
  --END IF;
  
  END LOOP;

  <<DONE>>

  :ERRORCODE       := V_ERRORCODE;
  :ERRORMESSAGE    := V_ERRORMESSAGE;
  :INSERTEDRECORDS := V_INSERTEDRECORDS;

  /*DBMS_OUTPUT.PUT_LINE('Error code = '||V_ERRORCODE);
  DBMS_OUTPUT.PUT_LINE('Error message = '''||V_ERRORMESSAGE||'''');
  DBMS_OUTPUT.PUT_LINE('Inserted records count = '''||V_INSERTEDRECORDS||'''');*/
END;