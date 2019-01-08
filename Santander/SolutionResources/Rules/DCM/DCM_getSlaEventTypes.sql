select col_id as id, col_code as code, col_name as name, col_intervalds , col_intervalym as intervalym
from tbl_dict_slaeventtype
where (col_isdeleted is null or col_isdeleted !=1)