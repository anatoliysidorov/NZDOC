declare
  v_input      xmltype;
  v_paramname  nvarchar2(255);
  v_paramvalue nvarchar2(255);
  v_eventid    Integer;
  v_eventproc  nvarchar2(255);
  v_stateid    Integer;
  v_result     varchar2(32000);
  doc          DBMS_XMLDOM.DOMDocument;
  ndoc         DBMS_XMLDOM.DOMNode;
  buf          NVARCHAR2(32000);

  rootnode          DBMS_XMLDOM.DOMNode;
  newnode           DBMS_XMLDOM.DOMNode;
  newelement        DBMS_XMLDOM.DOMElement;
  newtext           DBMS_XMLDOM.DOMText;
  newtextnode       DBMS_XMLDOM.DOMNode;
  newattr           DBMS_XMLDOM.DOMAttr;
  newattr2          DBMS_XMLDOM.DOMAttr;
  newattr3          DBMS_XMLDOM.DOMAttr;
begin
  v_result := :Input;
  v_input := XMLType(v_result);
  v_paramname := :ParamName;
  v_paramvalue := :ParamValue;
  v_eventid := :EventId;
  v_eventproc := :EventProc;
  v_stateid := :StateId;

  v_paramvalue := replace(v_paramvalue, '&', '&amp;');
  v_paramvalue := replace(v_paramvalue, '''', '&apos;');
  v_paramvalue := replace(v_paramvalue, '"', '&quot;');
  v_paramvalue := replace(v_paramvalue, '>', '&gt;');
  v_paramvalue := replace(v_paramvalue, '<', '&lt;');
  
  -- Create DOMDocument handle
  doc := DBMS_XMLDOM.newDOMDocument(v_input);
  ndoc := DBMS_XMLDOM.makeNode(doc);

  rootnode := DBMS_XMLDOM.getFirstChild(ndoc);
  
  newelement := DBMS_XMLDOM.createElement(doc, v_paramname);

  newnode := DBMS_XMLDOM.appendChild(rootnode, DBMS_XMLDOM.makeNode(newElement));

  newtext := DBMS_XMLDOM.createTextNode(doc, v_paramvalue);

  if v_eventid is not null then
  newattr := DBMS_XMLDOM.createAttribute(doc, 'EventId');
  DBMS_XMLDOM.setValue(newattr, to_char(v_eventid));
  newattr := DBMS_XMLDOM.setAttributeNode(newelement, newattr);
  end if;
  
  if v_eventproc is not null then
  newattr2 := DBMS_XMLDOM.createAttribute(doc, 'ProcessorCode');
  DBMS_XMLDOM.setValue(newattr2, v_eventproc);
  newattr2 := DBMS_XMLDOM.setAttributeNode(newelement, newattr2);
  end if;

  if v_stateid is not null then
  newattr3 := DBMS_XMLDOM.createAttribute(doc, 'StateId');
  DBMS_XMLDOM.setValue(newattr3, to_char(v_stateid));
  newattr3 := DBMS_XMLDOM.setAttributeNode(newelement, newattr3);
  end if;


  newtextnode := DBMS_XMLDOM.appendChild(newnode,DBMS_XMLDOM.makeNode(newtext));

  DBMS_XMLDOM.writeToBuffer(ndoc, buf);
  DBMS_XMLDOM.freeDocument(doc);
  return buf;

end;