SELECT cw.col_id   AS ID, 
       cw.col_code AS CODE, 
       cw.col_name AS NAME ,
       cw.col_isDeleted AS ISDELETED
FROM   tbl_dict_customcategory cc 
       inner join tbl_dict_customword cw 
               ON cw.col_wordcategory = cc.col_id 
START WITH cc.col_code IN (SELECT * 
                           FROM   TABLE(Asf_splitclob(:CategoryPath, '/'))) 
CONNECT BY PRIOR cc.col_id = cc.col_categorycategory 
<%=Sort("@SORT@","@DIR@")%>