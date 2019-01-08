SELECT ff.col_id AS id,
       ff.col_code AS code,
       ff.col_name AS NAME,
       dbms_xmlgen.CONVERT(ff.col_formmarkup) AS FORMMARKUP,
       ff.col_description AS DESCRIPTION,
       ff.col_isdeleted AS isdeleted,
       'FORM' AS RAWTYPE,
       -------------------------------------------
       t_viewable AS ISVISIBLE,
       t_enable   AS ISENABLE,
       t_title    AS FORMTITLE
  FROM tbl_fom_form ff
  JOIN (
	SELECT lower(regexp_substr(v_FORMCODES, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS form_code,
         regexp_substr(v_ISENABLES, '[[:' || 'alnum:]_]+', 1, LEVEL) t_enable,
         regexp_substr(v_ISVIEWABLES, '[[:' || 'alnum:]_]+', 1, LEVEL) t_viewable,
         regexp_substr(v_FORMTITLES, '[[:' || 'alnum:]_]+', 1, LEVEL) t_title,
         LEVEL AS rn_code
    FROM (SELECT :FORMCODES AS v_FORMCODES,
         nvl(:ISENABLES, 1) AS v_ISENABLES,
         nvl(:ISVIEWABLES, 1) AS v_ISVIEWABLES,
         :FORMTITLES AS v_FORMTITLES
    FROM dual)
  CONNECT BY regexp_substr(v_FORMCODES, '[[:' || 'alnum:]_]+', 1, LEVEL) IS NOT NULL
	) t 
    ON LOWER(ff.col_code) = form_code
 ORDER BY rn_code
