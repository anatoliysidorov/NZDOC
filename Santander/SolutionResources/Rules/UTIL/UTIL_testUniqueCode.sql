DECLARE
res nvarchar2(255);
BEGIN

res := f_UTIL_calcUniqueCode(BaseCode => :BaseCode, TableName => :TableName);
:Output := res;

END;