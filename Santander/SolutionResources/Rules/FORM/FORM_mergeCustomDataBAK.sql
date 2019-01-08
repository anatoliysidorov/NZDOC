declare
  v_input      xmltype;
  v_input2     xmltype;
  v_input3     xmltype;
  v_paramname  nvarchar2(255);
  v_paramvalue nvarchar2(255);
  v_formname   nvarchar2(255);
  v_formname2  nvarchar2(255);
  v_param      nvarchar2(255);
  v_result     varchar2(32000);
  v_result2    varchar2(32000);
  v_result3    varchar2(32000);
  v_count      Integer;
  v_count1     Integer;
  v_count2     Integer;
  v_count3     Integer;
  doc          DBMS_XMLDOM.DOMDocument;
  doc2         DBMS_XMLDOM.DOMDocument;
  doc3         DBMS_XMLDOM.DOMDocument;
  ndoc         DBMS_XMLDOM.DOMNode;
  ndoc2        DBMS_XMLDOM.DOMNode;
  ndoc3        DBMS_XMLDOM.DOMNode;
  docelem      DBMS_XMLDOM.DOMElement;
  docelem2     DBMS_XMLDOM.DOMElement;
  node         DBMS_XMLDOM.DOMNode;
  node2        DBMS_XMLDOM.DOMNode;
  node3        DBMS_XMLDOM.DOMNode;
  childnode3   DBMS_XMLDOM.DOMNode;
  newnode3     DBMS_XMLDOM.DOMNode;
  childnode    DBMS_XMLDOM.DOMNode;
  nodelist     DBMS_XMLDOM.DOMNodelist;
  nodelist2    DBMS_XMLDOM.DOMNodelist;
  nodemap      DBMS_XMLDOM.DOMNamedNodeMap;
  nodemap2     DBMS_XMLDOM.DOMNamedNodeMap;
  attrnode     DBMS_XMLDOM.DOMNode;
  attrnode2    DBMS_XMLDOM.DOMNode;
  attr         DBMS_XMLDOM.DOMAttr;
  attr2        DBMS_XMLDOM.DOMAttr;
  attrname     nvarchar2(255);
  attrname2    nvarchar2(255);
  attrvalue    nvarchar2(255);
  attrvalue2   nvarchar2(255);
  buf          nvarchar2(8000);
  buf2         nvarchar2(8000);
  v_exists     boolean;
begin
  v_result := :Input;
  v_result2 := :Input2;
  if v_result is null then
    v_result := '<CustomData><Attributes></Attributes></CustomData>';
  end if;
  if v_result2 is null then
    v_result2 := '<CustomData><Attributes></Attributes></CustomData>';
  end if;

  v_result3 := '<CustomData><Attributes></Attributes></CustomData>';

  v_result := replace(v_result, '&', '&amp;');
  v_result := replace(v_result, '''', '&apos;');

  v_result2 := replace(v_result2, '&', '&amp;');
  v_result2 := replace(v_result2, '''', '&apos;');
  
  v_input3 := XMLType(v_result3);
  doc3 := DBMS_XMLDOM.newDOMDocument(v_input3);
  ndoc3 := DBMS_XMLDOM.makeNode(doc3);
  DBMS_XMLDOM.writeToBuffer(ndoc3, buf);
  node3 := DBMS_XMLDOM.getFirstChild(ndoc3);
  childnode3 := DBMS_XMLDOM.getFirstChild(node3);
  DBMS_XMLDOM.writeToBuffer(node3, buf);
  DBMS_XMLDOM.writeToBuffer(node3, buf);

  -----------------------------------------------------------------------------------
  v_input := XMLType(v_result);
  doc := DBMS_XMLDOM.newDOMDocument(v_input);
  ndoc := DBMS_XMLDOM.makeNode(doc);
  node := DBMS_XMLDOM.getFirstChild(ndoc);
  docelem := DBMS_XMLDOM.getDocumentElement(doc);
  nodelist := DBMS_XMLDOM.getElementsByTagName(docelem, 'Form');
  if DBMS_XMLDOM.getLength(nodelist) > 0 then
    v_count := 0;
    while (true)
    loop
      node := DBMS_XMLDOM.item(nodelist, v_count);
      DBMS_XMLDOM.writeToBuffer(node, buf);
      if buf is null then
        exit;
      end if;
      nodemap := DBMS_XMLDOM.getAttributes(node);
      v_count1 := 0;
      buf2 := null;
      while (true)
      loop
        attrnode := DBMS_XMLDOM.Item(nodemap, v_count1);
        attr := DBMS_XMLDOM.makeAttr(attrnode);
        attrname := DBMS_XMLDOM.getName(attr);
        attrvalue := DBMS_XMLDOM.getValue(attr);
        v_formname := attrvalue;
        if attrname is null then
          exit;
        end if;
        --PARSE THE SECOND XML DOCUMENT
        v_input2 := XMLType(v_result2);
        doc2 := DBMS_XMLDOM.newDOMDocument(v_input2);
        ndoc2 := DBMS_XMLDOM.makeNode(doc2);
        node2 := DBMS_XMLDOM.getFirstChild(ndoc2);
        docelem2 := DBMS_XMLDOM.getDocumentElement(doc2);
        nodelist2 := DBMS_XMLDOM.getElementsByTagName(docelem2, 'Form');
        if DBMS_XMLDOM.getLength(nodelist2) > 0 then
          v_count2 := 0;
          while (true)
          loop
            node2 := DBMS_XMLDOM.item(nodelist2, v_count2);
            DBMS_XMLDOM.writeToBuffer(node2, buf2);
            if buf2 is null then
              exit;
            end if;
            nodemap2 := DBMS_XMLDOM.getAttributes(node2);
            v_count3 := 0;
            while (true)
            loop
              attrnode2 := DBMS_XMLDOM.Item(nodemap2, v_count3);
              attr2 := DBMS_XMLDOM.makeAttr(attrnode2);
              attrname2 := DBMS_XMLDOM.getName(attr2);
              attrvalue2 := DBMS_XMLDOM.getValue(attr2);
              v_formname2 := attrvalue2;
              if v_formname2 = v_formname then
                node := node2;
              end if;
              if attrname2 is null then
                exit;
              end if;
              v_count3 := v_count3 + 1;
            end loop;
            if buf2 is null then
              exit;
            end if;
            v_count2 := v_count2 + 1;
          end loop;
          newnode3 := DBMS_XMLDOM.appendChild(childnode3, DBMS_XMLDOM.adoptNode(doc3, node));
        else
          newnode3 := DBMS_XMLDOM.appendChild(childnode3, DBMS_XMLDOM.adoptNode(doc3, node));
        end if;
        v_count1 := v_count1 + 1;
      end loop;
      if buf is null then
        exit;
      end if;
      v_count := v_count + 1;
    end loop;
  else
    DBMS_XMLDOM.freeDocument(doc2);
    DBMS_XMLDOM.freeDocument(doc);
    DBMS_XMLDOM.freeDocument(doc3);
    return v_result2;
  end if;
  ----------------------------------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------------------------------

  DBMS_XMLDOM.freeDocument(doc2);
  DBMS_XMLDOM.freeDocument(doc);

  ----------------------------------------------------------------------------------------------------------
  --------------------- ADD MISSING NODES FROM THE SECOND XML ----------------------------------------------
  ----------------------------------------------------------------------------------------------------------
  v_input2 := XMLType(v_result2);
  doc := DBMS_XMLDOM.newDOMDocument(v_input2);
  ndoc := DBMS_XMLDOM.makeNode(doc);
  node := DBMS_XMLDOM.getFirstChild(ndoc);
  docelem := DBMS_XMLDOM.getDocumentElement(doc);
  nodelist := DBMS_XMLDOM.getElementsByTagName(docelem, 'Form');
  if DBMS_XMLDOM.getLength(nodelist) > 0 then
    v_count := 0;
    while (true)
    loop
      node := DBMS_XMLDOM.item(nodelist, v_count);
      DBMS_XMLDOM.writeToBuffer(node, buf);
      if buf is null then
        exit;
      end if;
      nodemap := DBMS_XMLDOM.getAttributes(node);
      v_count1 := 0;
      buf2 := null;
      while (true)
      loop
        attrnode := DBMS_XMLDOM.Item(nodemap, v_count1);
        attr := DBMS_XMLDOM.makeAttr(attrnode);
        attrname := DBMS_XMLDOM.getName(attr);
        attrvalue := DBMS_XMLDOM.getValue(attr);
        v_formname := attrvalue;
        if attrname is null then
          exit;
        end if;
        --PARSE THE SECOND XML DOCUMENT
        v_input := XMLType(v_result);
        doc2 := DBMS_XMLDOM.newDOMDocument(v_input);
        ndoc2 := DBMS_XMLDOM.makeNode(doc2);
        node2 := DBMS_XMLDOM.getFirstChild(ndoc2);
        docelem2 := DBMS_XMLDOM.getDocumentElement(doc2);
        nodelist2 := DBMS_XMLDOM.getElementsByTagName(docelem2, 'Form');
        v_exists := false;
        if DBMS_XMLDOM.getLength(nodelist2) > 0 then
          v_count2 := 0;
          while (true)
          loop
            node2 := DBMS_XMLDOM.item(nodelist2, v_count2);
            DBMS_XMLDOM.writeToBuffer(node2, buf2);
            if buf2 is null then
              exit;
            end if;
            nodemap2 := DBMS_XMLDOM.getAttributes(node2);
            v_count3 := 0;
            while (true)
            loop
              attrnode2 := DBMS_XMLDOM.Item(nodemap2, v_count3);
              attr2 := DBMS_XMLDOM.makeAttr(attrnode2);
              attrname2 := DBMS_XMLDOM.getName(attr2);
              attrvalue2 := DBMS_XMLDOM.getValue(attr2);
              v_formname2 := attrvalue2;
              if v_formname2 = v_formname then
                v_exists := true;
                exit;
              end if;
              if attrname2 is null then
                exit;
              end if;
              v_count3 := v_count3 + 1;
            end loop;
            if v_exists then
              exit;
            end if;
            if buf2 is null then
              exit;
            end if;
            v_count2 := v_count2 + 1;
          end loop;
          if v_exists then
            exit;
          end if;
        end if;
        v_count1 := v_count1 + 1;
      end loop;
      if buf is null then
        exit;
      end if;
      if not v_exists then
        newnode3 := DBMS_XMLDOM.appendChild(childnode3, DBMS_XMLDOM.adoptNode(doc3, node));
      end if;
      v_count := v_count + 1;
    end loop;
  end if;
  ----------------------------------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------------------------------

  DBMS_XMLDOM.writeToBuffer(node3, buf);
  DBMS_XMLDOM.freeDocument(doc2);
  DBMS_XMLDOM.freeDocument(doc);

  ------------------- FREE TARGET XML DOCUMENT --------------------------------------------------------------
  DBMS_XMLDOM.freeDocument(doc3);

  dbms_output.put_line(buf);
  return buf;

end;