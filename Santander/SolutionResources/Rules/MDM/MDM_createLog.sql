BEGIN

	INSERT INTO TBL_MDM_LOG(
		COL_MESSAGE,
		COL_MDM_LOGMDM_MODEL
	) VALUES
	( 
		:MESSAGE,
		:MODELID
	);

END;