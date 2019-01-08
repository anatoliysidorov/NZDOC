Select
    t_translations.col_ID as ID,
    t_lang.COL_ID as LANGID,
    t_plurarForm.COL_LANGUAGE as LANGCODE,
    t_lang.COL_LANGUAGECODE as LANGCODE_LOCALE,
    t_key.COL_ID as KEYID,
    t_key.COL_NAME as KEYNAME,
    t_key.COL_NAMESPACEID as NAMESPACEID,
    t_namespace.COL_NAME as NAMESPACENAME,
    nvl(t_key.COL_ISPLURAL, 0) as ISPLURAL,
    nvl(t_translations.COL_PLURALFORM, 0) as PLURALFORM,
    t_key.COL_CONTEXT as CONTEXT,
    t_translations.COL_VALUE as VALUE,
    nvl(t_plurarForm.COL_PLURALFORMS,0) as PLURALFORMCOUNT
From TBL_LOC_LANGUAGES t_lang
    inner join TBL_LOC_PLURALFORM t_plurarForm ON t_lang.COL_PLURALFORMID = t_plurarForm.col_id
    left join TBL_LOC_KEY t_key on 1 = 1
    left join TBL_LOC_TRANSLATION t_translations ON (t_key.COL_ID = t_translations.COL_KEYID and t_translations.COL_LANGID = t_lang.COL_ID)
    left join TBL_LOC_NAMESPACE t_namespace ON t_namespace.col_id = t_key.COL_NAMESPACEID
Where nvl(t_translations.COL_ISDRAFT, 0) = 0
    and nvl(t_key.COL_ISDELETED, 0) = 0
    and (:NamespaceID is null or t_namespace.col_id = :NamespaceID)
    and (:NamespaceName is null or t_namespace.col_name = :NamespaceName)
    and (:LanguageID is null or t_lang.COL_ID = :LanguageID)
    and t_key.COL_NAMESPACEID is not null
Order By t_lang.COL_ID, t_namespace.COL_NAME