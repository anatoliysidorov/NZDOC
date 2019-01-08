SELECT rp.code AS Code,
       rp.name AS NAME,
       t.name AS TYPE,
       rp.behaviortype AS Behavior,
       CASE rp.behaviortype
         WHEN 1 THEN
          'Input'
         WHEN 2 THEN
          'Output'
         WHEN 3 THEN
          'Placeholder'
         WHEN 4 THEN
          'ReturnValue'
         ELSE
          'None'
       END AS BehaviorName,
       ROWNUM AS ID
  FROM @TOKEN_SYSTEMDOMAINUSER@.conf_ruleparameter rp
 INNER JOIN vw_util_deployedrule dr
    ON rp.ruleid = dr.ruleid
  LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_type t
    ON rp.ref_type = t.typeid
 WHERE dr.Code = :RuleCode