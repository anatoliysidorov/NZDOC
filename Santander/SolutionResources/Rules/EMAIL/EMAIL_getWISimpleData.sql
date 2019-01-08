SELECT  wi.COL_ID                                           AS Id,
    (CASE
        WHEN INSTR(wi.COL_NAME, TO_NCHAR('Re:')) = 0
        THEN TO_NCHAR('Re: ') || wi.COL_NAME ||
          (
            CASE WHEN REGEXP_INSTR(wi.COL_NAME, '^.+\s+#DOC-20\d\d-\d+\s*$', 1) = 0
            THEN TO_NCHAR(' #') || wi.COL_TITLE
            END
          )
        ELSE wi.COL_NAME
    END)                                                    AS SUBJECT,
    '@EMAIL_SENDER@'                                        AS EMAIL_SENDER,
    extractValue(c.COL_CUSTOMDATA, '/CONTENT/FROM')         AS SOURCEFROM,
    extractValue(c.COL_CUSTOMDATA, '/CONTENT/TO')           AS SOURCETO,
    extractValue(c.COL_CUSTOMDATA, '/CONTENT/HEADER_From')  AS SOURCENAMEFROM
FROM tbl_pi_workitem wi
    LEFT JOIN TBL_EMAIL_WORKITEM_EXT wi_ext ON wi.COL_ID = wi_ext.COL_EMAIL_WI_PI_WORKITEM
    LEFT JOIN TBL_DOC_DOCUMENT pdoc on pdoc.COL_ISPRIMARY = 1 AND pdoc.COL_DOC_DOCUMENTPI_WORKITEM = wi.COL_ID
    LEFT JOIN TBL_CONTAINER c on pdoc.COL_DOC_DOCUMENTCONTAINER = c.COL_ID
WHERE wi.COL_ID = :ID
