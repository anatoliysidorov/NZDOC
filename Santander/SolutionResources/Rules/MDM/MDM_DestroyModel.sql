DECLARE
  V_ID         number;
  V_IDS        nvarchar2(32767);
  V_RESULT     number;
  v_casetypeid number;
  localhash    ecxtypes.params_hash;
  v_createdby  nvarchar2(255);
  v_domain nvarchar2(255);
  v_count number;
  v_message nclob;
  v_modelName NVARCHAR2(255);

BEGIN

  :ERRORCODE       := 0;
  :ERRORMESSAGE    := '';
  :ExecutionLog := '';
  :AFFECTEDROWS    := 0;
  V_IDS            := :IDS;
  V_ID             := :ID;
  :SUCCESSRESPONSE := EMPTY_CLOB();
  v_createdby := '@TOKEN_USERACCESSSUBJECT@';
  v_domain    := '@TOKEN_DOMAIN@';
  v_message := '';

  IF (V_ID IS NULL AND V_IDS IS NULL) THEN
    :ERRORMESSAGE := 'Id can not be empty';
    :ERRORCODE    := 101;
    RETURN;
  END IF;

  IF (V_ID IS NOT NULL) THEN
    V_IDS := TO_CHAR(V_ID);
  END IF;

  FOR mRec IN (SELECT COLUMN_VALUE AS id FROM TABLE(ASF_SPLIT(v_Ids, ','))) LOOP

    -- Check if CaseType is linked with DataModel
    select count(*) into v_count
    from tbl_dict_casesystype
    where col_casesystypemodel = mRec.id;  

    if(v_count > 0) THEN
      begin
        select col_name into v_modelName 
        from tbl_mdm_model 
        where col_id = mRec.id; 
      exception
        when no_data_found then
          v_modelName := null;
      end; 

      if(v_modelName is not null) then
        v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'Case Type is linked with data model (Name of Data Model: ' || v_modelName || ')');
      end if;

      continue;
    end if; 

    select count(*) into v_count 
    from tbl_mdm_model 
    where col_id = mRec.id;  
    
    if(v_count = 0) then
      v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'Model is not found (ModelId: ' || mRec.id || ')');
      continue;
    end if;

    UPDATE TBL_MDM_MODEL SET
        COL_ISDELETED = 1
    WHERE COL_ID = mRec.id;

    -- delete MDM Model
    localhash('ModelId') := mRec.id;
    localhash('UseRest') := 'true';
    v_result := QUEUE_addWithHash(
                                v_code            => sys_guid(),
                                v_domain          => v_domain,
                                v_createddate     => sysdate,
                                v_createdby       => v_createdby,
                                v_owner           => v_createdby,
                                v_scheduleddate   => sysdate,
                                v_objecttype      => 1,
                                v_processedstatus => 1,
                                v_processeddate   => sysdate,
                                v_errorstatus     => 0,
                                v_parameters      => localhash,
                                v_priority        => 0,
                                v_objectcode      => 'root_DOM_deleteModelBOs_cs',
                                v_error           => '');

  
    :AFFECTEDROWS := :AFFECTEDROWS + 1;
  END LOOP;

  if(v_message is not null) then
    :ERRORMESSAGE := 'There are an error on destory data model. (Deleted ' ||  :AFFECTEDROWS || ' models)';    
    :ERRORCODE    := 101;
    :ExecutionLog := v_message;
  else 
      V_RESULT := LOC_I18N(MESSAGETEXT   => 'Deleted {{MESS_COUNT}} models',
                       MESSAGERESULT => :SUCCESSRESPONSE,
                       MESSAGEPARAMS => NES_TABLE(KEY_VALUE('MESS_COUNT', :AFFECTEDROWS)));
  end if;



END;