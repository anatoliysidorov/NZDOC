SELECT groups.NAME,
       groups.CODE
  FROM vw_Groups groups
 WHERE --groups.domainid = '@TOKEN_SYSTEMDOMAIN@'
--AND 
 nvl(groups.SOURCE, 0) = 0
<%= IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1") %>
