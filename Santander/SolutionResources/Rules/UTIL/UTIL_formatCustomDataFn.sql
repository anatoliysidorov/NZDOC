BEGIN
	RETURN NVL(:INPUT, '<CustomData><Attributes></Attributes></CustomData>');
END;