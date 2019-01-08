<%= TemplateEngine:DotLiquid %>

{% if Database.IsOracle %}

DECLARE 

BEGIN
INSERT INTO TBL_LOG
(
	COL_DATA1,
	COL_DATA2
)
VALUES 
(
	:Data1,
	:Data2
)
RETURNING col_ID INTO :recordid;
END;

{% else %}

DECLARE 

BEGIN
INSERT INTO TBL_LOG
(
	COL_DATA1,
	COL_DATA2
)
VALUES 
(
	@Data1,
	@Data2
)
SET @recordid = @@IDENTITY;
END;

{% endif %}