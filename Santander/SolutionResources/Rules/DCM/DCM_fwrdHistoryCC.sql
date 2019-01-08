DECLARE 
    v_maxid     INTEGER; 
    v_seqid     INTEGER; 
    v_nextseqid INTEGER; 
BEGIN 
    SELECT Max(col_id) 
    INTO   v_maxid 
    FROM   tbl_historycc; 

    SELECT gen_tbl_historycc.NEXTVAL 
    INTO   v_seqid 
    FROM   dual; 

    IF v_seqid < v_maxid THEN 
      v_nextseqid := v_seqid;
      WHILE v_nextseqid < v_maxid LOOP 
          SELECT gen_tbl_historycc.NEXTVAL 
          INTO   v_nextseqid 
          FROM   dual; 
      END LOOP; 
    END IF; 
END; 