DECLARE
  TYPE t_attribute IS RECORD(
    attr_name  NVARCHAR2(255),
    attr_value NVARCHAR2(255));
  TYPE t_attributes IS TABLE OF t_attribute INDEX BY BINARY_INTEGER;

  v_source_doc   DBMS_XMLDOM.DOMDocument;
  v_target_doc   DBMS_XMLDOM.DOMDocument;
  v_source_attrs NVARCHAR2(4000);
  v_target_attrs NVARCHAR2(4000);
  v_source_arr   t_attributes;
  v_target_arr   t_attributes;
  v_output_arr   t_attributes;
  v_output_xml   NVARCHAR2(4000);
  j              INT;
  p              INT;

  PROCEDURE getAttributes(p_node IN DBMS_XMLDOM.DOMNode, ind IN INT, xmltype IN NVARCHAR2) IS
    v_nlist     DBMS_XMLDOM.DOMNodeList;
    v_node      DBMS_XMLDOM.DOMNode;
    v_attr_type INT;
  BEGIN
  
    IF (ind > 1) THEN
      v_attr_type := DBMS_XMLDOM.getNodeType(p_node);
      -- Attr
      IF (v_attr_type = 1) THEN
        CASE
          WHEN xmltype = 'source' THEN
            v_source_arr(ind - 1).attr_name := DBMS_XMLDOM.getNodeName(p_node);
          WHEN xmltype = 'target' THEN
            v_target_arr(ind - 1).attr_name := DBMS_XMLDOM.getNodeName(p_node);
        END CASE;
      ELSE
        -- Text
        IF (v_attr_type = 3) THEN
          CASE
            WHEN xmltype = 'source' THEN
              v_source_arr(ind - 2).attr_value := DBMS_XMLDOM.getNodeValue(p_node);
            WHEN xmltype = 'target' THEN
              v_target_arr(ind - 2).attr_value := DBMS_XMLDOM.getNodeValue(p_node);
          END CASE;
        END IF;
      END IF;
    END IF;
  
    -- get Child Nodes
    v_nlist := DBMS_XMLDOM.getchildnodes(p_node);
  
    -- recursive call
    IF NOT DBMS_XMLDOM.isNull(v_nlist) THEN
      FOR i IN 0 .. DBMS_XMLDOM.getLength(v_nlist) - 1 LOOP
        v_node := DBMS_XMLDOM.item(v_nlist, i);
        j      := j + 1;
        getAttributes(v_node, j, xmltype);
      END LOOP;
    END IF;
  END;

  FUNCTION normalizeArray(p_array IN t_attributes) RETURN t_attributes IS
    out_array t_attributes;
    j         INT;
    p         INT;
    i         INT;
  BEGIN
    p := 0;
    j := 1;
    i := 1;
  
    WHILE p_array.COUNT + p >= i LOOP
      BEGIN
        out_array(j).attr_name := p_array(i).attr_name;
        out_array(j).attr_value := p_array(i).attr_value;
        j := j + 1;
        i := i + 1;
      EXCEPTION
        WHEN no_data_found THEN
          p := p + 1;
          i := i + 1;
      END;
    END LOOP;
  
    RETURN out_array;
  END;

  -- Copy array
  PROCEDURE copyArray(p_array_from IN t_attributes, p_ind_from IN INT, p_array_to IN OUT t_attributes, p_ind_to IN INT) IS
  BEGIN
    p_array_to(p_ind_to).attr_name := p_array_from(p_ind_from).attr_name;
    p_array_to(p_ind_to).attr_value := p_array_from(p_ind_from).attr_value;
  END;

  -- Compare record
  FUNCTION compareRecord(p_array_from IN t_attributes, p_ind_from IN INT, p_array_in IN t_attributes) RETURN NUMBER IS
    isAttr NUMBER;
  BEGIN
    isAttr := 0;
    FOR i IN 1 .. p_array_in.COUNT LOOP
      IF (p_array_from(p_ind_from).attr_name = p_array_in(i).attr_name) THEN
        isAttr := 1;
        EXIT;
      END IF;
    END LOOP;
    RETURN isAttr;
  END;
BEGIN
  -- Get Source Array from XML
  IF (SourceXML IS NOT NULL) THEN
    BEGIN
      SELECT d.extract('/attributes').getstringval()
        INTO v_source_attrs
        FROM TABLE(XMLSequence(SourceXML.extract('CustomData/attributes'))) d;
      -- Initilize document
      v_source_doc := DBMS_XMLDOM.newdomdocument(XMLType(v_source_attrs));
      -- Get array from DOM
      j := 0; p := 1;
      getAttributes(DBMS_XMLDOM.makeNode(v_source_doc), j, 'source');
      -- Normalize array
      v_source_arr := normalizeArray(v_source_arr);
    
    EXCEPTION
      WHEN OTHERS THEN
        GOTO cleanup;
    END;
  END IF;

  -- Get Target Array from XML
  IF (TargetXML IS NOT NULL) THEN
    BEGIN
      SELECT d.extract('/attributes').getstringval()
        INTO v_target_attrs
        FROM TABLE(XMLSequence(TargetXML.extract('CustomData/attributes'))) d;
      -- Initilize document
      v_target_doc := DBMS_XMLDOM.newdomdocument(XMLType(v_target_attrs));
      -- Get array from DOM
      j := 0; p := 1;
      getAttributes(DBMS_XMLDOM.makeNode(v_target_doc), j, 'target');
      -- Normalize array
      v_target_arr := normalizeArray(v_target_arr);
    
    EXCEPTION
      WHEN OTHERS THEN
        GOTO cleanup;
    END;
  END IF;

  -- Compare arraies
  IF (v_target_arr.COUNT > 0) THEN
    FOR i IN 1 .. v_target_arr.COUNT LOOP
      copyArray(p_array_from => v_target_arr, p_ind_from => i, p_array_to => v_output_arr, p_ind_to => i);
    END LOOP;
  
    IF (v_source_arr.COUNT > 0) THEN
      j := v_output_arr.COUNT;
      FOR i IN 1 .. v_source_arr.COUNT LOOP
        p := compareRecord(p_array_from => v_source_arr, p_ind_from => i, p_array_in => v_output_arr);
        IF (p = 0) THEN
          j := j + 1;
          copyArray(p_array_from => v_source_arr, p_ind_from => i, p_array_to => v_output_arr, p_ind_to => j);
        END IF;
      END LOOP;
    END IF;
  
  ELSE
    IF (v_source_arr.COUNT > 0) THEN
      FOR i IN 1 .. v_source_arr.COUNT LOOP
        copyArray(p_array_from => v_source_arr, p_ind_from => i, p_array_to => v_output_arr, p_ind_to => i);
      END LOOP;
    END IF;
  END IF;

  v_output_xml := '<CustomData><attributes>';
  FOR i IN 1 .. v_output_arr.COUNT LOOP
    v_output_xml := v_output_xml || '<' || v_output_arr(i).attr_name || '>' || v_output_arr(i).attr_value || '</' || v_output_arr(i).attr_name || '>';
  END LOOP;
  v_output_xml := v_output_xml || '</attributes></CustomData>';

  <<cleanup>>
  ResultXML := XMLType(v_output_xml);
END;