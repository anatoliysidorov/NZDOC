DECLARE 
    v_finalreport           NCLOB; 
    v_caseworkersreport     NCLOB; 
    v_externalpartiesreport NCLOB; 
    v_count                 NUMBER; 
    v_res                   NUMBER; 
    v_accessssubjectid      NUMBER; 
    v_workbasketid          NUMBER; 
BEGIN 
    v_accessssubjectid := 0; 
    v_workbasketid := 0; 
    v_finalreport := NULL;
    v_caseworkersreport := NULL; 
    v_externalpartiesreport := NULL; 

    FOR rec IN (SELECT Nvl(cw.col_name, 'DELETED')    CaseworkerName, 
                       cw.col_id                      CaseworkerId, 
                       Cw.col_caseworkeraccesssubject CWAccessSubjectId, 
                       acs.col_id                     AccessSubjectId 
                FROM   tbl_ppl_caseworker cw 
                       left join tbl_ac_accesssubject acs 
                              ON Cw.col_caseworkeraccesssubject = acs.col_id 
                WHERE  Cw.col_caseworkeraccesssubject IS NULL 
                        OR acs.col_id IS NULL 
                ORDER  BY cw.col_id) LOOP 
        IF rec.accesssubjectid IS NULL THEN 
          INSERT INTO tbl_ac_accesssubject 
                      (col_type, 
                       col_name, 
                       col_code) 
          VALUES      ('CASEWORKER', 
                       rec.caseworkername, 
                       'CASEWORKER_' 
                       ||rec.caseworkerid) 
          returning col_id INTO v_accessssubjectid; 

          UPDATE tbl_ppl_caseworker 
          SET    col_caseworkeraccesssubject = v_accessssubjectid 
          WHERE  col_id = rec.caseworkerid; 

          v_caseworkersreport := v_caseworkersreport || '<li>Created Access Subject record for Case Worker ' ||rec.caseworkername ||'(#' ||rec.caseworkerid ||')</li>'; 
        END IF; 
    END LOOP; 

    FOR rec IN (SELECT cw.col_id                   CaseworkerId, 
                       Nvl(cw.col_name, 'Deleted') CaseworkerName, 
                       Wb.col_id                   WorkbasketId 
                FROM   tbl_ppl_caseworker cw 
						left join vw_ppl_simpleworkbasket wb 
                              ON Wb.caseworker_id = cw.col_id AND lower(Wb.workbaskettype_code) = 'personal'
                WHERE  Wb.col_id IS NULL 
                ORDER  BY cw.col_id) LOOP 
        IF rec.workbasketid IS NULL THEN 
          INSERT INTO tbl_ppl_workbasket 
                      (col_code, 
                       col_name, 
                       col_workbasketworkbaskettype, 
                       col_ucode, 
                       col_caseworkerworkbasket, 
                       col_isdefault, 
                       col_isprivate) 
          VALUES      ('PRIMARY', 
                       'Main', 
                       1, 
                       Sys_guid(), 
                       rec.caseworkerid, 
                       1, 
                       0); 

          v_caseworkersreport := v_caseworkersreport || '<li>Created personal workbasket for Case Worker ' ||rec.caseworkername ||'(#' ||rec.caseworkerid ||')</li>'; 
        END IF; 
    END LOOP; 

    IF v_caseworkersreport IS NOT NULL THEN 
      v_finalreport := '<br><b>Caseworkers Fix:</b>' ||v_caseworkersreport; 
    END IF; 

    FOR rec IN (SELECT Nvl(ex.col_name, 'DELETED')  ExternalPartyName, 
                       ex.col_id                    ExternalPartyId, 
                       Ex.col_extpartyaccesssubject EXAccessSubjectId, 
                       acs.col_id                   AccessSubjectId 
                FROM   tbl_externalparty ex 
                       left join tbl_ac_accesssubject acs 
                              ON ex.col_extpartyaccesssubject = acs.col_id 
                WHERE  ex.col_extpartyaccesssubject IS NULL 
                        OR acs.col_id IS NULL 
                ORDER  BY ex.col_id) LOOP 
        IF rec.accesssubjectid IS NULL THEN 
          INSERT INTO tbl_ac_accesssubject 
                      (col_type, 
                       col_name, 
                       col_code) 
          VALUES      ('EXTERNALPARTY', 
                       rec.externalpartyname, 
                       'EXTERNALPARTY_' 
                       ||rec.externalpartyid) 
          returning col_id INTO v_accessssubjectid; 

          UPDATE tbl_externalparty 
          SET    col_extpartyaccesssubject = v_accessssubjectid 
          WHERE  col_id = rec.externalpartyid; 

          v_externalpartiesreport := v_externalpartiesreport || '<li>Created Access Subject record for External Party ' ||rec.externalpartyname ||'(#' ||rec.externalpartyid ||')</li>'; 
        END IF; 
    END LOOP; 

    FOR rec IN (SELECT ex.col_id                   ExternalPartyId, 
                       Nvl(ex.col_name, 'DELETED') ExternalPartyName, 
                       wb.col_id                   WorkbasketId 
                FROM   tbl_externalparty ex 
                       left join (SELECT col_id, 
                                         col_workbasketexternalparty 
                                  FROM   tbl_ppl_workbasket 
                                  WHERE  col_workbasketexternalparty IS NOT NULL 
                                 ) wb 
                              ON ex.col_id = wb.col_workbasketexternalparty 
                WHERE  wb.col_id IS NULL 
                ORDER  BY ex.col_id) LOOP 
        INSERT INTO tbl_ppl_workbasket 
                    (col_code, 
                     col_name, 
                     col_workbasketworkbaskettype, 
                     col_ucode, 
                     col_workbasketexternalparty, 
                     col_isdefault, 
                     col_isprivate) 
        VALUES      ('PRIMARY', 
                     'Main', 
                     1, 
                     Sys_guid(), 
                     rec.externalpartyid, 
                     1, 
                     0); 

        v_externalpartiesreport := v_externalpartiesreport || '<li>Created personal workbasket for External Party ' ||rec.externalpartyname ||'(#' ||rec.externalpartyid ||')</li>'; 
    END LOOP; 

    IF v_externalpartiesreport IS NOT NULL THEN 
      v_finalreport := v_finalreport ||'<br><b>External Parties Fix:</b>' ||v_externalpartiesreport; 
    END IF; 

    :Report := Nvl(v_finalreport, 'No Fixed Needed'); 
END; 