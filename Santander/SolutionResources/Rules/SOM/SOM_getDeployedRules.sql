SELECT cont.ID AS ID,
       cont.CODE AS CODE,
       cont.NAME AS NAME
  FROM VW_EXP_APPBASECONTENT cont
 WHERE UPPER(cont.TYPE) = 'RULE'
<%=Sort("@SORT@","@DIR@")%>