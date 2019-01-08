SELECT rolelocalcode AS ROLECODE, 
           roleid AS ROLEID,
       TRIM(SUBSTR(rolename, 1, INSTR(rolename,'(', 1,1)-1)) as ROLENAME
FROM   vw_role 
WHERE INSTR(rolelocalcode, 'root') > 0
<%=Sort("@SORT@","@DIR@")%>
