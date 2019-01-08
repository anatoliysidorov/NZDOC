DECLARE
	v_configId	NUMBER;
BEGIN
	v_configId := :configId;

	--basic information about the SOM
	OPEN :ConfigInfo FOR
	SELECT obj.col_id             AS OBJID, 
		   obj.col_tablename      AS TABLENAME, 
		   obj.col_alias          AS ALIAS, 
		   conf.col_name          AS NAME, 
		   conf.col_code          AS CODE, 
		   conf.col_defsortfield  AS SORTFIELD, 
		   conf.col_sortdirection AS SORTDIRECTION, 
		   conf.col_customconfig  AS CUSTOMCONFIG 
	FROM   tbl_fom_object obj 
		   inner join tbl_som_config conf 
				   ON obj.col_id = conf.col_som_configfom_object 
	WHERE  conf.col_id = v_configid; 

	--search attributes (search fields and pre-defined filters)
	OPEN :SearchAttr FOR	
	SELECT sa.col_id            AS ID, 
		   sa.col_code          AS CODE, 
		   sa.col_name          AS NAME, 
		   uiet.col_code        AS CONTROLTYPE, 
		   sa.col_constant      AS CONSTANT, 
		   sa.col_defaultvalue  AS DEFAULTVALUE, 
		   sa.col_processorcode AS PROCESSORCODE, 
		   sa.col_valuefield    AS VALUEFIELD, 
		   sa.col_displayfield  AS DISPLAYFIELD, 
		   sa.col_customconfig  AS CUSTOMCONFIG, 
		   sa.col_ispredefined  AS ISPREDEFINED 
	FROM   tbl_som_searchattr sa 
		   left join tbl_fom_uielementtype uiet 
				  ON ( sa.col_searchattr_uielementtype = uiet.col_id ) 
	WHERE  sa.col_som_searchattrsom_config = v_configid 
	ORDER BY sa.COL_SORDER;

	--result list (columns)
	OPEN :ResultAttr FOR
	SELECT ra.col_id           AS ID, 
		   ra.col_code         AS CODE, 
		   ra.col_name         AS NAME, 
		   ra.col_idproperty   AS IDPROPERTY, 
		   ra.col_ishidden     AS IsHidden, 
		   ra.col_customconfig AS CUSTOMCONFIG, 
		   fa.col_alias        AS ATTRIBUTE_ALIAS, 
		   dt.col_code         AS DATATYPE_CODE 
	FROM   tbl_som_resultattr ra 
		   left join tbl_fom_attribute fa 
				  ON( ra.col_som_resultattrfom_attr = fa.col_id ) 
		   left join tbl_dict_datatype dt 
				  ON( fa.col_fom_attributedatatype = dt.col_id ) 
	WHERE  ra.col_som_resultattrsom_config = v_configid 
		   AND ra.col_som_resultattrfom_attr IS NOT NULL 
	ORDER  BY ra.col_sorder; 
END;