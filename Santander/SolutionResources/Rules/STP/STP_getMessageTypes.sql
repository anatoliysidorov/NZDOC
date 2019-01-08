SELECT 
    COL_ID AS ID,
    COL_NAME AS NAME,
    COL_CODE AS CODE
FROM tbl_DICT_MessageType
<%=Sort("@SORT@","@DIR@")%>