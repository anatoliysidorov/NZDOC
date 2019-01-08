DECLARE
v_cnt             PLS_INTEGER;
v_cnt_all         PLS_INTEGER :=0;
BEGIN
/******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM
    tbl_procedure
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
      UPDATE tbl_procedure
      SET col_code = sys_guid()
      WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_dict_casesystype
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
          UPDATE tbl_dict_casesystype
          SET col_code = sys_guid()
          WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_dict_stateconfig
    WHERE col_code IS NULL;
        
    IF v_cnt > 0 THEN
        UPDATE tbl_dict_stateconfig
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_dict_casestate
    WHERE col_code IS NULL;
        
    IF v_cnt > 0 THEN
        UPDATE tbl_dict_casestate
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_dict_casetransition
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dict_casetransition
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_map_casestateinitiation
    WHERE col_code IS NULL
        AND col_casestateinit_casesystype IS NOT NULL;
        
    IF v_cnt > 0 THEN
        UPDATE tbl_map_casestateinitiation
        SET col_code = sys_guid()
        WHERE col_code IS NULL
        AND col_casestateinit_casesystype IS NOT NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM TBL_STP_RESOLUTIONCODE
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_STP_RESOLUTIONCODE
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM Tbl_Dict_Tasksystype
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE Tbl_Dict_Tasksystype
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_dict_taskstate
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dict_taskstate
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_tasktemplate
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN

        UPDATE tbl_tasktemplate
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_map_taskstateinitiation
    WHERE col_code IS NULL
        AND col_map_taskstateinittasktmpl IS NOT NULL;
        
    IF v_cnt > 0 THEN
        UPDATE tbl_map_taskstateinitiation
        SET col_code = sys_guid()
        WHERE col_code IS NULL
        AND col_map_taskstateinittasktmpl IS NOT NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_taskevent
    WHERE col_code IS NULL
     AND col_taskeventtaskstateinit IN (SELECT col_id FROM tbl_map_taskstateinitiation WHERE col_map_taskstateinittasktmpl IS NOT NULL );
        
    IF v_cnt > 0 THEN
        UPDATE tbl_taskevent
        SET col_code = sys_guid()
        WHERE col_code IS NULL
        AND col_taskeventtaskstateinit IN (SELECT col_id FROM tbl_map_taskstateinitiation WHERE col_map_taskstateinittasktmpl IS NOT NULL );

      v_cnt_all := v_cnt_all + v_cnt;
      
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_taskdependency
    WHERE col_code IS NULL
        AND col_tskdpndprnttskstateinit IN (SELECT col_id FROM tbl_map_taskstateinitiation WHERE col_map_taskstateinittasktmpl IS NOT NULL )
        OR col_tskdpndchldtskstateinit  IN (SELECT col_id FROM tbl_map_taskstateinitiation WHERE col_map_taskstateinittasktmpl IS NOT NULL );
        
    IF v_cnt > 0 THEN
      
        UPDATE tbl_taskdependency
        SET col_code = sys_guid()
        WHERE col_code IS NULL
        AND col_tskdpndprnttskstateinit IN (SELECT col_id FROM tbl_map_taskstateinitiation WHERE col_map_taskstateinittasktmpl IS NOT NULL )
        OR col_tskdpndchldtskstateinit  IN (SELECT col_id FROM tbl_map_taskstateinitiation WHERE col_map_taskstateinittasktmpl IS NOT NULL );

      v_cnt_all := v_cnt_all + v_cnt;
      
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM TBL_AUTORULEPARAMETER
    WHERE col_code IS NULL
    AND col_autoruleparamtaskdep IN (SELECT td.col_id
                                           FROM tbl_taskdependency td
                                           JOIN tbl_map_taskstateinitiation sti
                                         ON td.col_tskdpndprnttskstateinit = sti.col_id
                                         AND sti.col_map_taskstateinittasktmpl IS NOT NULL );
                                         
    IF v_cnt > 0 THEN
        UPDATE TBL_AUTORULEPARAMETER
        SET col_code = sys_guid()
        WHERE col_code IS NULL
        AND col_autoruleparamtaskdep IN (SELECT td.col_id
                                           FROM tbl_taskdependency td
                                           JOIN tbl_map_taskstateinitiation sti
                                         ON td.col_tskdpndprnttskstateinit = sti.col_id
                                         AND sti.col_map_taskstateinittasktmpl IS NOT NULL );
                                     
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_stp_availableadhoc
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_stp_availableadhoc
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_dict_slaeventtype
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dict_slaeventtype
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_dict_slaeventlevel
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dict_slaeventlevel
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/

    --tbl_slaevent
    --tbl_slaaction
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_dict_tasktransition
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dict_tasktransition
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_fom_form
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_fom_form
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM TBL_FOM_UIELEMENTTYPE
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_FOM_UIELEMENTTYPE
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_fom_uielement
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_fom_uielement
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_FOM_CodedPage
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_FOM_CodedPage
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_ac_accessobjecttype
    WHERE col_code IS NULL; 
    
    IF v_cnt > 0 THEN
        UPDATE tbl_ac_accessobjecttype
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_AC_ACCESSOBJECT
    WHERE col_code IS NULL; 
    
    IF v_cnt > 0 THEN
        UPDATE tbl_AC_ACCESSOBJECT
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM  tbl_AC_PERMISSION
    WHERE col_code IS NULL;
        
    IF v_cnt > 0 THEN
        UPDATE tbl_AC_PERMISSION
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_STP_PRIORITY
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE tbl_STP_PRIORITY
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_dict_participanttype
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE tbl_dict_participanttype
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_DICT_ASSOCPAGETYPE
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE tbl_DICT_ASSOCPAGETYPE
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/    
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_dict_partytype
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE tbl_dict_partytype
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/      
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_ASSOCPAGE
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE tbl_ASSOCPAGE
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/     
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_dict_workbaskettype
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE tbl_dict_workbaskettype
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt
    FROM TBL_AC_ACCESSSUBJECT
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE TBL_AC_ACCESSSUBJECT
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt
    FROM Tbl_Ppl_Team
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE Tbl_Ppl_Team
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/     
    SELECT COUNT(*)
    INTO v_cnt
    FROM Tbl_Ppl_Businessrole
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE Tbl_Ppl_Businessrole
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_ppl_caseworker
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE tbl_ppl_caseworker
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/     
    SELECT COUNT(*)
    INTO v_cnt
    FROM TBL_PPL_WORKBASKET
    WHERE col_ucode IS NULL;

    IF v_cnt > 0 THEN
        UPDATE TBL_PPL_WORKBASKET
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_externalparty
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE tbl_externalparty
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_DICT_CUSTOMCATEGORY
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE tbl_DICT_CUSTOMCATEGORY
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_DICT_CUSTOMWORD
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE tbl_DICT_CUSTOMWORD
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_DICT_DATEEVENTTYPE
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE tbl_DICT_DATEEVENTTYPE
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_dict_CASESTATESETUP
    WHERE col_code IS NULL OR col_ucode IS NULL;

    IF v_cnt > 0 THEN
        UPDATE tbl_dict_CASESTATESETUP
        SET col_code = sys_guid()
        WHERE col_code IS NULL;
        
        UPDATE tbl_dict_CASESTATESETUP
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;        

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt
    FROM tbl_DICT_TASKSTATESETUP
    WHERE col_code IS NULL OR col_ucode IS NULL;

    IF v_cnt > 0 THEN
        UPDATE tbl_DICT_TASKSTATESETUP
        SET col_code = sys_guid()
        WHERE col_code IS NULL;
        
        UPDATE tbl_DICT_TASKSTATESETUP
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;        

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt
    FROM TBL_DICT_INITMETHOD
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE TBL_DICT_INITMETHOD
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt
    FROM TBL_DICT_TASKEVENTTYPE
    WHERE col_code IS NULL;

    IF v_cnt > 0 THEN
        UPDATE TBL_DICT_TASKEVENTTYPE
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;
    /******************************************************/    
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_fom_page
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_fom_page
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_fom_attribute
    WHERE col_code IS NULL or col_ucode is null;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_fom_attribute
        SET col_code = sys_guid()
        WHERE col_code IS NULL;
        
        UPDATE tbl_fom_attribute
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;        
        

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/   
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_fom_path
    WHERE col_code IS NULL OR col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_fom_path
        SET col_code = sys_guid()
        WHERE col_code IS NULL;
        
        UPDATE tbl_fom_path
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;        

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/                                                     
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_fom_path
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_fom_path
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_fom_relationship
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_fom_relationship
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/                                              
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_participant
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_participant
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/                                                  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM Tbl_Fom_Dashboard
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE Tbl_Fom_Dashboard
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/                                                      
 /******************************************************/                                                      
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_loc_key
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_loc_key
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_LOC_Namespace
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_LOC_Namespace
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_loc_pluralform
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_loc_pluralform
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/          
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_LOC_Languages 
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_LOC_Languages 
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_LOC_Translation  
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_LOC_Translation  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_DOM_ModelCache  
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_DOM_ModelCache  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_DOM_Model  
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_DOM_Model  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_dom_object  
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dom_object  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/   
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_dom_relationship  
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dom_relationship  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_DOM_Attribute  
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_DOM_Attribute  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_dom_config  
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dom_config  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_DOM_InsertAttr  
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_DOM_InsertAttr  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_dom_cache  
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dom_cache  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;    
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_LOC_KeySources  
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_LOC_KeySources  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    
    /******************************************************/  
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM Tbl_Int_Integtarget
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE Tbl_Int_Integtarget  
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/      
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_dict_caserole
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dict_caserole  
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DICT_DCMTYPE
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DICT_DCMTYPE  
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_dict_state
    WHERE col_ucode IS NULL
		OR col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dict_state  
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

        UPDATE tbl_dict_state  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_dict_stateconfigtype
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dict_stateconfigtype  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_dict_tagobject
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dict_tagobject  
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_dict_tagtotagobject
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dict_tagtotagobject  
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DICT_TRANSITION
    WHERE col_ucode IS NULL
		OR col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DICT_TRANSITION  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;

        UPDATE TBL_DICT_TRANSITION  
        SET col_code = sys_guid()
        WHERE col_code IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_COMMONEVENTTMPL
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_COMMONEVENTTMPL  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_COMMONEVENT
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_COMMONEVENT  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_SOM_ATTRIBUTE
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_SOM_ATTRIBUTE  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_SOM_Model
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_SOM_Model  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_SOM_Object
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_SOM_Object  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_som_relationship
    WHERE col_code IS NULL
    OR col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_som_relationship  
        SET col_code = sys_guid()
        WHERE col_code IS NULL;

        UPDATE tbl_som_relationship  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
        				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;       
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt  
    FROM Tbl_Fom_Object
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE Tbl_Fom_Object  
        SET col_code = sys_guid()
        WHERE col_code IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_mdm_form
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_mdm_form  
        SET col_code = sys_guid()
        WHERE col_code IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_mdm_searchpage
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_mdm_searchpage  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_mdm_model
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_mdm_model  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_MDM_MODELVERSION
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_MDM_MODELVERSION  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;  
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_SOM_MODEL
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_SOM_MODEL  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;     
    /******************************************************/ 
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_som_resultattr
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_som_resultattr  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_som_searchattr
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_som_searchattr  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/      
    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DICT_DCMTYPE
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DICT_DCMTYPE  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;        
    /******************************************************/      
    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_dom_referenceobject
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_dom_referenceobject  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
    /******************************************************/      
    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DOM_REFERENCEATTR
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DOM_REFERENCEATTR  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
        
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DOM_MODELJOURNAL
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DOM_MODELJOURNAL  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
        
    /******************************************************/  
    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_MDM_MODELVERSION
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_MDM_MODELVERSION  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
        
    /******************************************************/       
    /******************************************************/ 
	    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DOM_RENDERATTR
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DOM_RENDERATTR  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
        
    /******************************************************/ 	
		    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DICT_STATEEVENT
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DICT_STATEEVENT  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
        
    /******************************************************/ 		
		    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DOM_RENDEROBJECT
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DOM_RENDEROBJECT  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
        
    /******************************************************/ 			
		    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DOM_RENDERCONTROL
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DOM_RENDERCONTROL  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
        
    /******************************************************/ 				      
		    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DOM_RENDERTYPE
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DOM_RENDERTYPE  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
        
    /******************************************************/ 	
		    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DICT_DATATYPE
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DICT_DATATYPE  
        SET col_code = sys_guid()
        WHERE col_code IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
        
    /******************************************************/ 		
		    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DICT_STATESLAACTION
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DICT_STATESLAACTION  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
        
    /******************************************************/ 			
		    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DICT_STATESLAEVENT
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DICT_STATESLAEVENT  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
        
    /******************************************************/ 	
		    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_DICT_ContainerType
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_DICT_ContainerType  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
        
    /******************************************************/   
		    SELECT COUNT(*)
    INTO v_cnt  
    FROM Tbl_Dict_Systemtype
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE Tbl_Dict_Systemtype  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;
    END IF;            
        
    /******************************************************/    
		    SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_DOM_UpdateAttr
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_DOM_UpdateAttr  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;   
    END IF;    
    
    /******************************************************/ 
		    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_PPL_ORGCHART
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_PPL_ORGCHART  
        SET col_code = sys_guid()
        WHERE col_code IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;   
    END IF;    
     /******************************************************/       
		    SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_AC_PERMISSION
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_AC_PERMISSION  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
				
      v_cnt_all := v_cnt_all + v_cnt;   
    END IF;    
     /******************************************************/  
   SELECT COUNT(*)
    INTO v_cnt  
    FROM Tbl_Doc_Doccasetype
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DOC_DOCCASETYPE  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
        
      v_cnt_all := v_cnt_all + v_cnt;   
    END IF;    
     /******************************************************/  
   SELECT COUNT(*)
    INTO v_cnt  
    FROM Tbl_Doc_Document
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DOC_DOCUMENT  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
        
      v_cnt_all := v_cnt_all + v_cnt;   
    END IF;    
     /******************************************************/
   SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_CASELINKTMPL
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_CASELINKTMPL  
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
        
      v_cnt_all := v_cnt_all + v_cnt;   
    END IF;    
     /******************************************************/
   SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DICT_LinkDirection
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DICT_LinkDirection
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
        
      v_cnt_all := v_cnt_all + v_cnt;   
    END IF;    
     /******************************************************/     
   SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_TASKSYSTYPERESOLUTIONCODE
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_TASKSYSTYPERESOLUTIONCODE
        SET col_code = sys_guid()
        WHERE col_code IS NULL;
        
      v_cnt_all := v_cnt_all + v_cnt;   
    END IF;    
     /******************************************************/     
   SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_DICT_CustomWord
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_DICT_CustomWord
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
        
      v_cnt_all := v_cnt_all + v_cnt;   
    END IF;    
     /******************************************************/          
   SELECT COUNT(*)
    INTO v_cnt  
    FROM tbl_DICT_CommonEventType
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE tbl_DICT_CommonEventType
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
        
      v_cnt_all := v_cnt_all + v_cnt;   
    END IF;    
     /******************************************************/
   SELECT COUNT(*)
    INTO v_cnt  
    FROM Tbl_DICT_BlackList
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE Tbl_DICT_BlackList
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
        
      v_cnt_all := v_cnt_all + v_cnt;   
    END IF;    
     /******************************************************/
   SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_THREADSETTING
    WHERE col_ucode IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_THREADSETTING
        SET col_ucode = sys_guid()
        WHERE col_ucode IS NULL;
        
      v_cnt_all := v_cnt_all + v_cnt;   
    END IF;    
     /******************************************************/
   SELECT COUNT(*)
    INTO v_cnt  
    FROM TBL_SLAEVENTTMPL
    WHERE col_code IS NULL;
    
    IF v_cnt > 0 THEN
        UPDATE TBL_SLAEVENTTMPL
        SET col_code = sys_guid()
        WHERE col_code IS NULL;
        
      v_cnt_all := v_cnt_all + v_cnt;   
    END IF;    
     /******************************************************/


IF v_cnt_all >0 THEN
      COMMIT;
    END IF;

END;
