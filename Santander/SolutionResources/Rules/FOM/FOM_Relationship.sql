SELECT 
  r.relationid as COL_ID,
  r.name AS Name,
  r.code      AS Code,
  'col_'
  || r.localcode AS ColumnName,
  r.SOURCECARDINALITYTYPE AS SourceType,
  'tbl_'
  || bo_src.localcode AS SourceBO,
  r.TARGETCARDINALITYTYPE AS TargetType,
  'tbl_'
  || bo_tgt.localcode AS TargetBO
FROM @TOKEN_SYSTEMDOMAINUSER@.conf_borelation r
LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_boobject bo_src
ON (bo_src.objectid = R.Sourceobjectid)
LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_boobject bo_tgt
ON (bo_tgt.objectid = R.Targetobjectid)
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_version vrs
ON r.componentid = vrs.componentid
INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_environment env
ON vrs.versionid = env.depversionid
WHERE env.code   = '@TOKEN_DOMAIN@'