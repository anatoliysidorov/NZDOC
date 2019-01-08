SELECT 
	   bo.objectid 				AS COL_ID,	
	   bo.NAME || ' | '  || ba.columntitle        AS BADisplayName, 
       ba.attributeid           AS BAId, 
       bo.code                  AS BOCode, 
       bo.localcode             AS BOLocalCode, 
       bo.NAME                  AS BOName, 
       ba.code                  AS BACode, 
       ba.localcode             AS BALocalCode, 
       'tbl_' || bo.localcode          AS BOTableName, 
       'col_' || ba.localcode          AS BAColumnName, 
       tp.code                  AS BATypeCode, 
       tp.NAME                  AS BATypeName, 
       ba.NAME                  AS BAName, 
       ba.description           AS BADescription, 
       ba.columntitle           AS BAColumnTitle, 
       ba.textfield             AS BATextField, 
       ba.contextsensitivehelp  AS BAContextSensitiveHelp, 
       ba.length                AS BALength, 
       ba.scale                 AS BAScale, 
       ba.pattern               AS BAPattern, 
       ba.maxlength             AS BAMaxLength, 
       ba.minlength             AS BAMinLength, 
       ba.defaultvalue          AS BADefaultValue, 
       ba.defaultvaluelargetext AS BADefaultValueLargeText, 
       ba.maxvalue              AS BAMaxValue, 
       ba.minvalue              AS BAMinValue, 
       ba.valuesfield           AS BAValuesField, 
       ba.defaultvalues         AS BADefaultValues, 
       ba.rulename              AS BARuleName, 
       ba.inputparameters       AS BAInputParameters, 
       ba.displayfield          AS BADisplayField, 
       ba.valuefield            AS BAValueField, 
       ba.defaultobject         AS BADefaultObject, 
       ba.lookup_rule_code      AS BALookupRuleCode, 
       ba.lookup_rule_map       AS BALookupRuleMap, 
       ba.lookup_text_field     AS BALookupTextField, 
       ba.lookup_value_field    AS BALookupValueField, 
       ba.useonlist             AS BAUSeOnList, 
       ba.useoncreatemodify     AS BAUseOnCreateModify, 
       ba.useondetail           AS BAUseOnDetail,
       ba.issystem          	AS BAIsSystem 
FROM   @TOKEN_SYSTEMDOMAINUSER@.conf_boattribute ba 
       INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_type tp 
               ON ba.attributetypeid = tp.typeid 
       INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_boobject bo 
               ON ba.objectid = bo.objectid 
       INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_version vrs 
               ON bo.componentid = vrs.componentid 
       INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_environment env 
               ON vrs.versionid = env.depversionid 
WHERE  env.code = '@TOKEN_DOMAIN@'