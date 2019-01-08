SELECT 
	dc.CODE 				as CODE,
	dc.NAME 				as NAME,
    dc.DESCRIPTION 			as DESCRIPTION,
    dc.EMAIL_SMTP_ENCODING 	as EMAIL_SMTP_ENCODING,
    dc.EMAIL_SMTP_PASSWORD 	as EMAIL_SMTP_PASSWORD,
    dc.EMAIL_SMTP_SERVER 	as EMAIL_SMTP_SERVER,
    dc.EMAIL_SMTP_USERNAME 	as EMAIL_SMTP_USERNAME,
    dc.EMAIL_SMTP_USE_SSL 	as EMAIL_SMTP_USE_SSL,
    dc.MAIL_FROM 			as MAIL_FROM,
    dc.MAIL_TO 				as MAIL_TO,
    dc.SUBJECT 				as SUBJECT
FROM @TOKEN_SYSTEMDOMAINUSER@.conf_environment e 
    inner join @TOKEN_SYSTEMDOMAINUSER@.conf_version v ON v.versionid = e.depversionid 
    inner join @TOKEN_SYSTEMDOMAINUSER@.conf_distribchannel dc ON dc.componentid = v.componentid 
WHERE e.code = '@TOKEN_DOMAIN@' and dc.CHANNELTYPE = 0