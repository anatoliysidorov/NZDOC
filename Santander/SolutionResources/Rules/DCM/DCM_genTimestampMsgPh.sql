BEGIN 
    :PlaceholderResult :='<b>' || to_char(systimestamp, 'HH24:MI:SS.FF6') || '</b>';
END;