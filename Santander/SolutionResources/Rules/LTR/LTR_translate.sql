DECLARE

    v_Message varchar2(4000) ;
    v_Parameters varchar2(4000);
    v_Context varchar2(300);

    v_tmp number;
    v_userLang varchar2(200);
    v_sql varchar2(8000);

    v_pName varchar2(255);
    v_pValue varchar2(2000);
    v_pPos number;
    v_l10n varchar2(255);

    v_result nvarchar2(2000);

BEGIN

    v_Message    := :p_Message;
    v_Parameters := :p_Parameters;
    v_Context    := :p_Context;
    
    begin

        if ('' is not null) then

            v_sql := 'select .f_l10n_translate(p_Message => :'||'v_Message, p_Context => :'||'v_Context, p_Parameters => :'||'v_Parameters) from dual';
            execute immediate v_sql into v_result using v_Message, v_Context, v_Parameters;

        else

            -- check if exists translations

            select count(*) into v_tmp from user_tables where table_name = 'TBL_LOC_TRANSLATION';

            if (v_tmp > 0) then

                -- get translation

                v_sql := 'select DBMS_LOB.SUBSTR(t.COL_VALUE, 2000, 1)'||
                ' from tbl_loc_key k'||
                ' inner join tbl_loc_translation t on t.col_keyid = k.col_id'||
                ' inner join tbl_loc_languages l on l.col_id = t.col_langid'||
                ' inner join tbl_loc_namespace n on n.col_id = k.COL_NAMESPACEID and upper(n.col_name) = ''RULE'''||
                ' inner join (select '||
                '               ul.CULTURECODE as CODE, '||
                '               ul.LANGUAGEID as ID'||
                '           from conf_6tenant41.ASF_USER u '||
                '           inner join conf_6tenant41.user_profile up on u.USERID = up.USERID'||
                '           inner join conf_6tenant41.DICT_LANGUAGE ul on up.LANGUAGE = ul.LANGUAGEID'||
                '           INNER JOIN conf_6tenant41.ASF_ACCESSSUBJECT acc ON u.accesssubjectid = acc.accesssubjectid'||
                '           where acc.code = SYS_CONTEXT(''CLIENTCONTEXT'', ''AccessSubject'')'||
                '           ) usr on usr.ID = l.COL_APPBASELANGID or usr.code = l.COL_LANGUAGECODE'||
                ' where nvl(k.col_isdeleted, 0) = 0 and nvl(t.COL_PLURALFORM, 0) = 0'||
                ' and nvl(k.col_context, ''_NULL_'') = nvl(:'||'v_Context, ''_NULL_'')'||
                ' and k.COL_NAME = :'||'v_Message'||
                ' and rownum < 2';
                execute immediate v_sql into v_result using v_Context, v_Message;

            end if;

        end if;

        -- return result

        v_result := nvl(v_result, v_Message);

    exception when others then 

        v_result := v_Message;

    end;

    -- apply parameters

    if (v_Parameters is not null and '' is null) then

        for rec in (SELECT COLUMN_VALUE as VAL FROM TABLE(ASF_SPLITCLOB(v_Parameters, '|'))) loop

            v_pPos := instr(rec.VAL, '=');

            if (v_pPos > 0) then

                v_pName := substr(rec.VAL, 1, v_pPos-1);
                v_pValue := substr(rec.VAL, v_pPos+1);
                v_result := replace(v_result, '{'||'{'||v_pName||'}'||'}', v_pValue);

            end if;

        end loop;

    end if;

    return UTL_I18N.UNESCAPE_REFERENCE(v_result);
    --DBMS_OUTPUT.PUT_LINE(UTL_I18N.UNESCAPE_REFERENCE(v_result));

END;