var token = request.AsString("token");
var domain =  request.AsString("domain");
var versionCode = "DCM_CATS_v2_1.0_2394";
try{

    Func<string, string, System.Xml.Linq.XElement> CreateParameter = delegate (string name, string value)
    {
        var parameter = new XElement("Parameter", "");

        parameter.SetAttributeValue("name", name);
        parameter.SetAttributeValue("value", value);

        return parameter;
    };

    Func<ASF.Persistence.Common.Domain.Data.DataAssociation, string> CreateXmlByAssociation = delegate (ASF.Persistence.Common.Domain.Data.DataAssociation assotiation)
    {
        System.Xml.Linq.XDocument objectDocument = new XDocument(
                new XElement("DataAssociation",
                        CreateParameter("LowerApi", string.Format("root_{0}",assotiation.Name.ToLower())),
                        CreateParameter("Name", assotiation.Name),
                        CreateParameter("IsManyToMany", assotiation.IsManyToMany.ToString()),
                        CreateParameter("IsOneToOne", assotiation.IsOneToOne.ToString()),
                        CreateParameter("PrimaryDataObjectName", assotiation.Primary.DataObject.Name),
                        CreateParameter("ForeignDataObjectName", assotiation.Foreign.DataObject.Name),
                        CreateParameter("Description", assotiation.Description)
                    )
            );
        return objectDocument.ToString();

    };

    Func<ASF.Persistence.Common.Domain.Data.DataObject, System.Xml.Linq.XElement> CreateXmlByDataObjectColumns = delegate (ASF.Persistence.Common.Domain.Data.DataObject dataObject)
    {
        System.Xml.Linq.XElement objectDocument = new XElement("Columns");

        foreach (var column in dataObject.Columns)
        {

            XElement columnXml = new XElement("Column",
                CreateParameter("LowerApi", string.Format("{0}_{1}",dataObject.Name.ToLower().Replace("tbl_", "root_"), column.Name.ToLower().Replace("col_",""))),
                CreateParameter("Name", column.Name),
                CreateParameter("IsBlob", column.DbType.IsBlob.ToString()),
                CreateParameter("IsDateTime", column.DbType.IsDateTime.ToString()),
                CreateParameter("IsLargeText", column.DbType.IsLargeText.ToString()),
                CreateParameter("IsNumber", column.DbType.IsNumber.ToString()),
                CreateParameter("IsSysRefCursor", column.DbType.IsSysRefCursor.ToString()),
                CreateParameter("IsText", column.DbType.IsText.ToString()),
                CreateParameter("IsTimestampWithTimezone", column.DbType.IsTimestampWithTimezone.ToString()),
                CreateParameter("IsXmlType", column.DbType.IsXmlType.ToString()),
                CreateParameter("IsTimestampWithTimezone", column.Description)

                );

            objectDocument.Add(columnXml);

        }

        return objectDocument;

    };

    Func<ASF.Persistence.Common.Domain.Data.DataObject, string> CreateXmlByDataObject = delegate (ASF.Persistence.Common.Domain.Data.DataObject dataObject)
    {
        System.Xml.Linq.XDocument objectDocument = new XDocument(
                new XElement("DataObject",
                        CreateParameter("LowerApi", dataObject.Name.ToLower().Replace("tbl_", "root_")),
                        CreateParameter("Name", dataObject.Name),
                        CreateParameter("Description", dataObject.Description),
                        CreateXmlByDataObjectColumns(dataObject)
                    )
            );
        return objectDocument.ToString();

    };

    ASF.Persistence.Common.Domain.DALModel dalModel = ASF.CoreLib.APIHelper.GetDALModel(token, domain, versionCode);

    var assotiations = dalModel.DataModel.DataAssociations;
    string assotiationsXml = "<Assotiations>";
    foreach (var assotiation in assotiations)
    {
        string assotiationXml = CreateXmlByAssociation(assotiation);
        assotiationsXml += assotiationXml;
    }
    assotiationsXml += "</Assotiations>";

    var dataObjects = dalModel.DataModel.DataObjects;
    string dataObjectsXml = "<Objects>";
    foreach (var dataObject in dataObjects)
    {

        if (dataObject.Type == ASF.Persistence.Common.Domain.Data.DataObjectType.Table)
        {
            string dataObjectXml = CreateXmlByDataObject(dataObject);
            dataObjectsXml += dataObjectXml;
        }
    }
    dataObjectsXml += "</Objects>";

    response["DAL_MODEL_XML"] = string.Format("<DAL_MODEL>{0}{1}</DAL_MODEL>", assotiationsXml, dataObjectsXml);
    response["ERRORMESSAGE"] = string.Empty;
    response["ERRORCODE"] = 0;

}
catch (Exception exc)
{

    response["DAL_MODEL_XML"] = string.Empty;
    response["ERRORMESSAGE"] = exc.ToString();
    response["ERRORCODE"] = 101;

}


