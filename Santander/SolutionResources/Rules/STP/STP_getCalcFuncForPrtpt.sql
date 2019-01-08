select RulesData.* from 
(SELECT 
    deployed_rule.ID as Id,
    deployed_rule.NAME as Name,
    deployed_rule.CODE as Code,
    deployed_rule.ISNEEDDEPLOYFUNCTION as isFinction,
    rule_parameters.InputParameters as InputParameters,
    rule_parameters.OutputParameters as OutputParameters 
FROM VW_UTIL_DEPLOYEDRULE deployed_rule
LEFT JOIN
    (SELECT 
        rule_parameter.RULEID AS RULEID, 
        LISTAGG(case when rule_parameter.behaviortype = 1 then to_char(rule_parameter.CODE)end, ',') WITHIN GROUP (ORDER BY rule_parameter.CODE) as InputParameters,
        LISTAGG(case when rule_parameter.behaviortype = 2 then to_char(rule_parameter.CODE)end, ',') WITHIN GROUP (ORDER BY rule_parameter.CODE) as OutputParameters,
        LISTAGG(case when rule_parameter.behaviortype = 3 then to_char(rule_parameter.CODE)end, ',') WITHIN GROUP (ORDER BY rule_parameter.CODE) as Placeholders,
        LISTAGG(case when rule_parameter.behaviortype = 4 then to_char(rule_parameter.CODE)end, ',') WITHIN GROUP (ORDER BY rule_parameter.CODE) as ReturnValue
    FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_RULEPARAMETER rule_parameter
    INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_RULE rule ON rule.RULEID = rule_parameter.RULEID
    INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_VERSION version ON rule.COMPONENTID = version.COMPONENTID
    INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.CONF_ENVIRONMENT enviroment ON version.VERSIONID = enviroment.DEPVERSIONID
    WHERE enviroment.code = '@TOKEN_DOMAIN@' 
    GROUP BY rule_parameter.RULEID) rule_parameters on rule_parameters.RULEID = deployed_rule.ID
    ) RulesData
WHERE 
    RulesData.isFinction = 1 
    and
   --get input parameters
    (SELECT count(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(RulesData.InputParameters, ','))) = 2
    and 
    exists(
        SELECT LOWER(COLUMN_VALUE) FROM TABLE(ASF_SPLIT('CaseId', ','))
        INTERSECT
        SELECT LOWER(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(RulesData.InputParameters, ','))
    )
    and 
    exists(
        SELECT LOWER(COLUMN_VALUE) FROM TABLE(ASF_SPLIT('CasePartyId', ','))
        INTERSECT
        SELECT LOWER(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(RulesData.InputParameters, ','))
    )

    and (:Id is null or RulesData.Id= :Id)
    <%=Sort("@SORT@","@DIR@")%>
