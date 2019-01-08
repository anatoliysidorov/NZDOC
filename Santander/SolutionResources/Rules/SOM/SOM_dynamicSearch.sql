DECLARE
    v_configid           INTEGER;
    v_input              NCLOB;
    v_star_row           INTEGER;
    v_limit_row          INTEGER;
    v_sort               NVARCHAR2(255);
    v_defSort            NVARCHAR2(255);
    v_dir                VARCHAR2(10);
    v_result             number;
    
    v_items              sys_refcursor;
    v_errorcode          INTEGER;
    v_totalcount         INTEGER;
    v_Errormessage       NVARCHAR2(255);
    
BEGIN
    v_configid  := :ConfigId;
    v_input     := NVL(:Input,'<CustomData><Attributes></Attributes></CustomData>');
    v_star_row  := NVL(:FIRST, 0);
    v_limit_row := :LIMIT;
    v_sort      := :SORT;
    v_dir       := NVL(:DIR, 'ASC');
    v_errorcode := 0;
    v_result := f_som_dynamicsearchfn(  accesssubjectcode => sys_context('CLIENTCONTEXT', 'AccessSubject'),
                                        configid          => v_configid,
                                        dir               => v_dir,
                                        errorcode         => v_errorcode,
                                        errormessage      => v_errormessage,
                                        first             => v_star_row,
                                        input             => v_input,
                                        items             => v_items,
                                        limit             => v_limit_row,
                                        sort              => v_sort,
                                        totalcount        => v_totalcount);

    IF NVL(v_errorcode,0) = 0 then
        :items := v_items;
    end if;
    :errorcode    := v_errorcode;
    :errormessage := v_errormessage;
    :totalcount   := v_totalcount;
    
    --DBMS_OUTPUT.PUT_LINE(v_errorCode);
    --DBMS_OUTPUT.PUT_LINE(v_errorMessage);

END;