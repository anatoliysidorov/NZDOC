BEGIN
    RETURN '<' ||:NodeTag || '>' || :msg || '</' || :NodeTag || '>';
END;