BEGIN
    RETURN :originalMsg || '<p>' || :newMsg || '</p>';
END;