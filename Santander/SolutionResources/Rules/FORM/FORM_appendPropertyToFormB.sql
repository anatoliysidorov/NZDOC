declare
  v_input      xmltype;
  v_paramname  nvarchar2(255);
  v_paramvalue nvarchar2(32000);
  v_result     varchar2(32000);
  doc          DBMS_XMLDOM.DOMDocument;
  ndoc         DBMS_XMLDOM.DOMNode;
  node         DBMS_XMLDOM.DOMNode;
  node2        DBMS_XMLDOM.DOMNode;
  childnode    DBMS_XMLDOM.DOMNode;
  docelem      DBMS_XMLDOM.DOMElement;
  buf          nvarchar2(32000);
  buf2         nvarchar2(8000);

  rootnode          DBMS_XMLDOM.DOMNode;
  childrootnode     DBMS_XMLDOM.DOMNode;
  newnode           DBMS_XMLDOM.DOMNode;
  newelement        DBMS_XMLDOM.DOMElement;
  nodelist          DBMS_XMLDOM.DOMNodelist;
  newtext           DBMS_XMLDOM.DOMText;
  newtextnode       DBMS_XMLDOM.DOMNode;

  v_count     Integer;
  v_count1    Integer;
  nodemap     DBMS_XMLDOM.DOMNamedNodeMap;
  attrnode    DBMS_XMLDOM.DOMNode;
  attr        DBMS_XMLDOM.DOMAttr;
  attrname    nvarchar2(255);
  attrvalue   nvarchar2(255);
  v_formname  nvarchar2(255);
begin
  v_result := :Input;
  v_input := XMLType(v_result);
  v_formname := :FormName;
  v_paramname := :ParamName;
  v_paramvalue := :ParamValue;

  v_paramvalue := replace(v_paramvalue, '&', '&amp;');
  v_paramvalue := replace(v_paramvalue, '''', '&apos;');
  v_paramvalue := replace(v_paramvalue, '"', '&quot;');
  v_paramvalue := replace(v_paramvalue, '>', '&gt;');
  v_paramvalue := replace(v_paramvalue, '<', '&lt;');
  
  
  -- Create DOMDocument handle
  doc := DBMS_XMLDOM.newDOMDocument(v_input);
  ndoc := DBMS_XMLDOM.makeNode(doc);
  docelem := DBMS_XMLDOM.getDocumentElement(doc);

  nodelist := DBMS_XMLDOM.getElementsByTagName(docelem, 'Form');
  if DBMS_XMLDOM.getLength(nodelist) > 0 then
    v_count := 0;
    while (true)
    loop
      node := DBMS_XMLDOM.item(nodelist, v_count);
      DBMS_XMLDOM.writeToBuffer(node, buf);
      nodemap := DBMS_XMLDOM.getAttributes(node);
      v_count1 := 0;
      buf2 := null;
      while (true)
      loop
        attrnode := DBMS_XMLDOM.Item(nodemap, v_count1);
        attr := DBMS_XMLDOM.makeAttr(attrnode);
        attrname := DBMS_XMLDOM.getName(attr);
        attrvalue := DBMS_XMLDOM.getValue(attr);
        if attrname is null then
          exit;
        end if;
        if attrname = 'name' and attrValue = v_formname then
          docelem := DBMS_XMLDOM.makeElement(node);
          nodelist := DBMS_XMLDOM.getElementsByTagName(docelem, v_paramName);
          node2 := DBMS_XMLDOM.item(nodelist, 0);
          DBMS_XMLDOM.writeToBuffer(node2, buf2);
          if buf2 is not null then
            newnode := DBMS_XMLDOM.removeChild(ndoc, node2);
          end if;
          newelement := DBMS_XMLDOM.createElement(doc, v_paramname);
          newnode := DBMS_XMLDOM.appendChild(node, DBMS_XMLDOM.makeNode(newElement));
          newtext := DBMS_XMLDOM.createTextNode(doc, v_paramvalue);
          newtextnode := DBMS_XMLDOM.appendChild(newnode,DBMS_XMLDOM.makeNode(newtext));
          DBMS_XMLDOM.writeToBuffer(ndoc, buf2);
          exit;
        end if;
        v_count1 := v_count1 + 1;
      end loop;
      if buf2 is not null then
        buf := buf2;
        exit;
      end if;
      if buf is null then
        exit;
      end if;
      v_count := v_count + 1;
    end loop;
  end if;

  if buf2 is null then
    node := DBMS_XMLDOM.getFirstChild(ndoc);
    node := DBMS_XMLDOM.getFirstChild(node);
    newelement := DBMS_XMLDOM.createElement(doc, 'Form');
    attr := DBMS_XMLDOM.createAttribute(doc, 'name');
    DBMS_XMLDOM.setValue(attr,v_formname);
    attr := DBMS_XMLDOM.setAttributeNode(newelement, attr);
    node := DBMS_XMLDOM.appendChild(node, DBMS_XMLDOM.makeNode(newelement));
    newelement := DBMS_XMLDOM.createElement(doc, v_paramname);
    newnode := DBMS_XMLDOM.appendChild(node, DBMS_XMLDOM.makeNode(newElement));
    newtext := DBMS_XMLDOM.createTextNode(doc, v_paramvalue);
    newtextnode := DBMS_XMLDOM.appendChild(newnode,DBMS_XMLDOM.makeNode(newtext));
    DBMS_XMLDOM.writeToBuffer(ndoc, buf2);
    buf := buf2;
  end if;

  DBMS_XMLDOM.freeDocument(doc);
  --dbms_output.put_line(buf);
  return buf;

end;