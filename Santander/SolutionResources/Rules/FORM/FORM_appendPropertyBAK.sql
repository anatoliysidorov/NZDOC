declare
  v_input      xmltype;
  v_paramname  nvarchar2(255);
  v_paramvalue nvarchar2(32000);
  v_result     varchar2(32000);
  doc          DBMS_XMLDOM.DOMDocument;
  ndoc         DBMS_XMLDOM.DOMNode;
  node         DBMS_XMLDOM.DOMNode;
  docelem      DBMS_XMLDOM.DOMElement;
  buf          NVARCHAR2(32000);

  rootnode          DBMS_XMLDOM.DOMNode;
  childrootnode     DBMS_XMLDOM.DOMNode;
  newnode           DBMS_XMLDOM.DOMNode;
  newelement        DBMS_XMLDOM.DOMElement;
  nodelist          DBMS_XMLDOM.DOMNodelist;
  newtext           DBMS_XMLDOM.DOMText;
  newtextnode       DBMS_XMLDOM.DOMNode;
begin
  v_result := :Input;
  v_input := XMLType(v_result);
  v_paramname := :ParamName;
  v_paramvalue := :ParamValue;
  if instr(v_paramvalue, '![CDATA[') = 0 then
    v_paramvalue := '![CDATA[' || v_paramvalue || ']]';
  end if;

  v_paramvalue := replace(v_paramvalue, '&', '&amp;');
  v_paramvalue := replace(v_paramvalue, '''', '&apos;');
  v_paramvalue := replace(v_paramvalue, '"', '&quot;');
  v_paramvalue := replace(v_paramvalue, '>', '&gt;');
  v_paramvalue := replace(v_paramvalue, '<', '&lt;');
  
  -- Create DOMDocument handle
  doc := DBMS_XMLDOM.newDOMDocument(v_input);
  ndoc := DBMS_XMLDOM.makeNode(doc);

  ---------------------------------------------------------------------------------------------
  ----------------------- REMOVE NODE ---------------------------------------------------------
  ---------------------------------------------------------------------------------------------
  docelem := DBMS_XMLDOM.getDocumentElement(doc);
  nodelist := DBMS_XMLDOM.getElementsByTagName(docelem, v_paramname);
  node := DBMS_XMLDOM.item(nodelist, 0);
  DBMS_XMLDOM.writeToBuffer(node, buf);
  if buf is not null then
    newnode := DBMS_XMLDOM.removeChild(ndoc, node);
  end if;


  ---------------------------------------------------------------------------------------------
  ----------------------- APPEND NODE ---------------------------------------------------------
  ---------------------------------------------------------------------------------------------
  rootnode := DBMS_XMLDOM.getFirstChild(ndoc);
  
  childrootnode := DBMS_XMLDOM.getFirstChild(rootnode);

  newelement := DBMS_XMLDOM.createElement(doc, v_paramname);

  newnode := DBMS_XMLDOM.appendChild(childrootnode, DBMS_XMLDOM.makeNode(newElement));

  newtext := DBMS_XMLDOM.createTextNode(doc, v_paramvalue);

  newtextnode := DBMS_XMLDOM.appendChild(newnode,DBMS_XMLDOM.makeNode(newtext));

  DBMS_XMLDOM.writeToBuffer(ndoc, buf);
  DBMS_XMLDOM.freeDocument(doc);
  return buf;

end;