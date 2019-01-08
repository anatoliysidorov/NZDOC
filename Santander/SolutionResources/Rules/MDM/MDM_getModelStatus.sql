DECLARE
    --INTERNAL
    v_environmentCode NVARCHAR2(50);
    v_solutionID INT;
    v_devComponentID INT;
    v_DomModelID INT;
BEGIN
    --CHECK
	IF NVL(:MDMMODELID, 0) = 0 THEN
		RETURN;
	END IF;
	
	--GET SOLUTION ID
    SELECT     v.SOLUTIONID
    INTO		v_solutionID
    FROM       @TOKEN_SYSTEMDOMAINUSER@.CONF_ENVIRONMENT e
    INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_VERSION v ON v.VERSIONID = e.DEPVERSIONID
    WHERE      e.CODE = '@TOKEN_DOMAIN@';
    
    --GET LATEST COMPONENT ID FOR SOLUTION
    SELECT COMPONENTID
    INTO	v_devComponentID
    FROM   @TOKEN_SYSTEMDOMAINUSER@.CONF_VERSION
    WHERE  SOLUTIONID = v_solutionID
           AND TYPE = 1;
    
    --GET DOM MODEL ID FROM MDM MODEL
    SELECT COL_ID
    INTO   v_DomModelID
    FROM   TBL_DOM_MODEL
    WHERE  COL_DOM_MODELMDM_MODEL = :MDMMODELID;
    
    --GET DOM BUSINESS OBJECTS AND THEIR STATUS
    OPEN :CUR_BUSINESSOBJECTS FOR
    SELECT     
               fo.col_apicode AS FOMOBJECT_APICODE,
               fo.col_tablename AS FOMOBJECT_TABLENAME,
               do.col_id AS DOMOBJECT_ID,
			   do.col_code AS DOMOBJECT_CODE,
               do.col_name AS DOMOBJECT_NAME,
               bo.objectid AS AppBaseBO_ID,
               ut.STATUS AS ORACLE_STATUS,
			   ut.table_name AS ORACLE_NAME,
			   f_MDM_getObjectPath(FOMObjectId => fo.col_id) as OBJECTPATH
    FROM       tbl_dom_object do
    LEFT JOIN tbl_fom_object fo            ON fo.col_id = do.col_dom_objectfom_object
    LEFT JOIN  @TOKEN_SYSTEMDOMAINUSER@.conf_boobject bo ON bo.code = fo.col_apicode
    LEFT JOIN  user_tables ut               on table_name = upper(fo.col_tablename)
    WHERE      do.col_dom_objectdom_model = v_dommodelid
               AND(LOWER(do.col_type) = LOWER('businessobject')
               OR LOWER(do.col_type) = 'rootbusinessobject')
               AND bo.componentid = v_devcomponentid
   ORDER BY lower(do.col_name);
			   
	--GET DOM ATTRIBUTES FOR THE BUSINESS OBJECTS
	OPEN :CUR_ATTRIBUTES FOR
	SELECT 
		fa.COL_APICODE as FOMATTRIBUTE_APICODE,
		fa.COL_COLUMNNAME as FOMATTRIBUTE_COLUMNNAME,
		do.COL_ID as DOMOBJECT_ID,
		da.COL_ID as DOMATTRIBUTE_ID,
		da.COL_CODE as DOMATTRIBUTE_CODE,
		da.COL_NAME as DOMATTRIBUTE_NAME,
		dda.col_code as DATATYPE_CODE,
		ba.OBJECTID as AppBaseBA_ID,
		uc.COLUMN_ID as ORACLE_COLUMNID,
		uc.DATA_TYPE as ORACLE_DATATYPE,
		uc.CHAR_LENGTH as ORACLE_CHARLENGTH,
		uc.DATA_PRECISION as ORACLE_DATAPRECISION,
		uc.DATA_SCALE as ORACLE_DATASCALE
	FROM TBL_DOM_ATTRIBUTE da
	LEFT JOIN TBL_FOM_ATTRIBUTE fa ON fa.col_id = da.COL_DOM_ATTRFOM_ATTR
	LEFT JOIN TBL_DOM_OBJECT do ON do.col_id = da.COL_DOM_ATTRIBUTEDOM_OBJECT
	LEFT JOIN TBL_FOM_OBJECT fo ON fo.col_id = do.COL_DOM_OBJECTFOM_OBJECT
	LEFT JOIN TBL_DICT_DATATYPE dda ON dda.col_id = fa.COL_FOM_ATTRIBUTEDATATYPE
	LEFT JOIN TBL_DOM_REFERENCEATTR ra ON ra.COL_DOM_REFATTRFOM_ATTR = fa.col_id
	LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_boattribute ba ON ba.code = fa.col_apicode
	LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_boobject bo ON bo.objectid = ba.objectid
	LEFT JOIN user_tab_cols uc ON uc.TABLE_NAME = upper(fo.col_tablename) AND uc.COLUMN_NAME = upper(fa.COL_COLUMNNAME)
	WHERE 	do.COL_DOM_OBJECTDOM_MODEL = v_dommodelid
			AND ra.col_id IS NULL --do not want foreign elements
			AND bo.componentid = v_devcomponentid;
	

	--GET DOM RELATIONSHIPS FOR THE BUSINESS OBJECT
	OPEN :CUR_RELATIONSHIPS FOR
	SELECT 
		dr.col_id as DOMRELATIONSHIP_ID,
		fr.COL_APICODE as FOMRELATION_APICODE,
		dr.COL_NAME as DOMRELATIONSHIP_NAME,
		fr.COL_FOREIGNKEYNAME as FOMRELATION_FOREIGNKEYNAME,
		doChild.col_id as DOCHILD_ID,
		doChild.col_name as DOCHILD_NAME,
		doChild.col_code as DOCHILD_CODE,
		foChild.col_name as FOCHILD_NAME,
		foChild.col_code as FOCHILD_CODE,
		doParent.col_id as DOPARENT_ID,
		doParent.col_name as DOPARENT_NAME,
		doParent.col_code as DOPARENT_CODE,
		foParent.col_name as FOPARENT_NAME,
		foParent.col_code as FOPARENT_CODE,
		br.RELATIONID as AppBaseBR_ID,
		ucChild.COLUMN_ID as ORACLE_COLUMNID,
		ucChild.DATA_TYPE as ORACLE_DATATYPE
	FROM TBL_DOM_RELATIONSHIP dr
	LEFT JOIN TBL_FOM_RELATIONSHIP fr ON fr.col_id = dr.COL_DOM_RELFOM_REL
	LEFT JOIN TBL_DOM_OBJECT doParent ON doParent.col_id = dr.COL_PARENTDOM_RELDOM_OBJECT
	LEFT JOIN TBL_FOM_OBJECT foParent ON foParent.col_id = doParent.COL_DOM_OBJECTFOM_OBJECT
	LEFT JOIN TBL_DOM_OBJECT doChild ON doChild.col_id = dr.COL_CHILDDOM_RELDOM_OBJECT
	LEFT JOIN TBL_FOM_OBJECT foChild ON foChild.col_id = doChild.COL_DOM_OBJECTFOM_OBJECT
	LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_boobject boChild ON boChild.code = foChild.col_apicode
	LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_borelation br ON br.code = fr.col_apicode
	LEFT JOIN user_tab_cols ucChild ON ucChild.TABLE_NAME = upper(foChild.col_tablename) AND ucChild.COLUMN_NAME = upper(fr.COL_FOREIGNKEYNAME)
	WHERE (doParent.COL_DOM_OBJECTDOM_MODEL = v_dommodelid OR doChild.COL_DOM_OBJECTDOM_MODEL = v_dommodelid)
	AND boChild.componentid = v_devcomponentid AND br.componentid = v_devcomponentid;	

END;