var token = request.AsString("token");
var domain =  request.AsString("domain");
var version= string.Empty;
var componentCode = "root";
string relationCodes =  request.AsString("relationCodes");
string objectCodes = request.AsString("objectCodes");
string getWithoutParameter = request.AsString("getWithoutParameter");


Func<ASF.BDS.WebService.Messages.ExecuteResponse, string, string, string> getValueFromResponse = (resp, ruleName, paramName) =>
{
	string result = "";
	System.Xml.XmlNode nodeEl = null;

	try
	{
		ParameterCollection respParams = resp.Data.GetParameters();

		if (respParams != null && respParams.Count > 0)
		{
			Object obj = respParams[paramName].Value;

			if (obj != null)
			{
				result = obj.ToString();
			}
		}
		else
		{
			var xmlResp = resp.Data.ToXml();

			System.Xml.XmlDocument xmlDocTemp = new System.Xml.XmlDocument();
			xmlDocTemp.LoadXml(xmlResp.ToString());

			if (xmlDocTemp != null)
			{
				nodeEl = xmlDocTemp.SelectSingleNode(string.Format("//DATA/{0}/ITEMS/{1}", ruleName, paramName));

				if (nodeEl != null)
				{
					result = nodeEl.InnerText;
				}
			}
		}

	}
	catch (Exception exp)
	{
		throw new Exception(string.Format("Exception on get value from rule {0} response", ruleName), exp);
	}

	return result;
};

Func<string, string, System.Xml.Linq.XElement> CreateParameter = delegate (string name, string value)
{
    var parameter = new XElement("Parameter", "");
    parameter.SetAttributeValue("name", name);
    parameter.SetAttributeValue("value", value);
    return parameter;
};

Func<ASF.Config.Common.Domain.BusinessData.BusinessRelationInfo, string> CreateXmlByRelation = delegate (ASF.Config.Common.Domain.BusinessData.BusinessRelationInfo relation)
{
    System.Xml.Linq.XDocument objectDocument = new XDocument(
            new XElement("Relation",
                    CreateParameter("Name", relation.Name),
                    CreateParameter("Code", relation.Code),
                    CreateParameter("TargetObjectCode", relation.TargetObjectCode),
                    CreateParameter("SourceObjectName", relation.SourceObjectName)

                )
        );
    return objectDocument.ToString();
};

Func<ASF.Config.Common.Domain.BusinessData.BusinessObjectAttributeInfo[], System.Xml.Linq.XElement> CreateXmlByDataObjectColumns = delegate (ASF.Config.Common.Domain.BusinessData.BusinessObjectAttributeInfo[] columns)
{
    System.Xml.Linq.XElement objectDocument = new XElement("Columns");

    foreach (var column in columns)
    {

        XElement columnXml = new XElement("Column",
                CreateParameter("Name", column.Name),
                CreateParameter("Code", column.Code),
                CreateParameter("Description", column.Description),
                CreateParameter("TypeCode", column.TypeCode),
                CreateParameter("TypeName", column.TypeName)
            );

        objectDocument.Add(columnXml);

    }
    return objectDocument;
};

Func<ASF.Config.Common.Domain.BusinessData.BusinessObjectInfo, string> CreateXmlByDataObject = delegate (ASF.Config.Common.Domain.BusinessData.BusinessObjectInfo busObject)
{
    var columns = ASF.CoreLib.APIHelper.GetBusinessObjectAttributes(token, version, componentCode, busObject.Code);
    System.Xml.Linq.XDocument objectDocument = new XDocument(
            new XElement("BusinessObject",
                    CreateParameter("Name", busObject.Name),
                    CreateParameter("Code", busObject.Code),
                    CreateParameter("Description", busObject.Description),
                    CreateXmlByDataObjectColumns(columns)
                )
        );
    return objectDocument.ToString();
};

Func<string, ASF.Config.Common.Domain.BusinessData.BusinessObjectInfo[]> GetBusinessObjects = delegate (string busObjectsCodes)
{
    string[] codes = busObjectsCodes.Split(new string[] { "|||" }, StringSplitOptions.None);

    List<ASF.Config.Common.Domain.BusinessData.BusinessObjectInfo> bos = new List<ASF.Config.Common.Domain.BusinessData.BusinessObjectInfo>();
    try
    {
        foreach (string code in codes)
        {
            var bo = ASF.CoreLib.APIHelper.GetBusinessObject(token, version, componentCode, code);
            ASF.Config.Common.Domain.BusinessData.BusinessObjectInfo info = new ASF.Config.Common.Domain.BusinessData.BusinessObjectInfo()
            {
                Name = bo.Name,
                Code = bo.Code,
                Description = bo.Description
            };
            bos.Add(info);
        }
    }
    catch
    {
    }

    return bos.ToArray();
};

Func<string, ASF.Config.Common.Domain.BusinessData.BusinessRelationInfo[]> GetBusinessRelations = delegate (string busRelationsCodes)
{
    string[] codes = busRelationsCodes.Split(new string[] { "|||" }, StringSplitOptions.None);

    List<ASF.Config.Common.Domain.BusinessData.BusinessRelationInfo> relations = new List<ASF.Config.Common.Domain.BusinessData.BusinessRelationInfo>();
    try
    {
        foreach (string code in codes)
        {
            var relation = ASF.CoreLib.APIHelper.GetBusinessRelation(token, version, componentCode, code);
            ASF.Config.Common.Domain.BusinessData.BusinessRelationInfo info = new ASF.Config.Common.Domain.BusinessData.BusinessRelationInfo()
            {
                Name = relation.Name,
                Code = relation.Code,
                SourceObjectCode = relation.SourceObjectCode,
                TargetObjectCode = relation.TargetObjectCode
            };
            relations.Add(info);
        }
    }
    catch
    {
    }
    return relations.ToArray();
};



try
{

    //Get Version Id		
    var reqGetConfVersionId = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
    {
        DataCommand = "root_UTIL_getConfVersionId",
        Domain = domain,
        Parameters = null,
        Token = token
    });

    version = getValueFromResponse(reqGetConfVersionId, "root_UTIL_getConfVersionId", "CODE");

    if (String.IsNullOrEmpty(version))
    {
        throw new Exception("Version Id is not found");
    }

    var bosArr = string.IsNullOrEmpty(objectCodes) && getWithoutParameter == "true" ? ASF.CoreLib.APIHelper.GetBusinessObjects(token, version, componentCode) : GetBusinessObjects(objectCodes);

    string objectsXml = "<Objects>";
    foreach (var bo in bosArr)
    {
        objectsXml += CreateXmlByDataObject(bo);
    }
    objectsXml += "</Objects>";

    var relArr = string.IsNullOrEmpty(relationCodes) && getWithoutParameter == "true" ? ASF.CoreLib.APIHelper.GetBusinessRelations(token, version, componentCode) : GetBusinessRelations(relationCodes);

    string relationsXml = "<Relations>";
    foreach (var relation in relArr)
    {
        relationsXml += CreateXmlByRelation(relation);
    }
    relationsXml += "</Relations>";

    response["MODEL"] = string.Format("<MODEL>{0}{1}</MODEL>", objectsXml, relationsXml); ;
    response["ERRORMESSAGE"] = string.Empty;
    response["ERRORCODE"] = 0;

}
catch (Exception exc)
{

    response["MODEL"] = string.Empty;
    response["ERRORMESSAGE"] = exc.ToString();
    response["ERRORCODE"] = 101;

}