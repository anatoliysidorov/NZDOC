SELECT 
r.RULEID as Id,
r.RULEID as col_Id,
r.RULEID as RuleId,
r.COMPONENTID as ComponentId,
r.CODE as Code,
r.NAME as Name,
r.RULETYPE as RuleType,
r.BIZTYPE as BizType,
r.ACCESSOBJECTID as AccessObjectId,
r.DESCRIPTION as Description,
r.LOCALCODE as LocalCode,
r.REF_SCHEMAID as Ref_SchemaId,
r.ISNEEDDEPLOYFUNCTION as IsNeedDeployFunction,
r.ISNEEDDEPLOYVIEW as IsNeedDeployView,
r.ISSYSTEM as IsSystem,
r.MODIFIEDDATE as ModifiedDate
FROM   @TOKEN_SYSTEMDOMAINUSER@.conf_environment e
       inner join @TOKEN_SYSTEMDOMAINUSER@.conf_version v 
               ON v.versionid = e.depversionid 
       inner join @TOKEN_SYSTEMDOMAINUSER@.conf_rule r 
               ON r.componentid = v.componentid 
WHERE  e.code = '@TOKEN_DOMAIN@' 
