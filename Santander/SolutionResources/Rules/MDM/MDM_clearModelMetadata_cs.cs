var token = request.AsString("token");
var domain = request.AsString("domain");
bool useRest = request.AsString("UseRest").ToLower() == "true" ? true : false;
var designtimeConfigurationServiceRest = ConfigurationSettings.AppSettings["DesignConfigService"];
int modelId = 0;
string envVersionId = string.Empty;

string modelConfig = string.Empty;
string modelName = string.Empty;

ParameterCollection inputParameters = null;

var service = new DCM.DataManagement.DataManagementService(AppBaseHelpers.DcmConvertHelper.SafeObjectToString(request["token"]), AppBaseHelpers.DcmConvertHelper.SafeObjectToString(request["domain"]));

Int32.TryParse(request.AsString("ModelId"), out modelId);
if (modelId == 0)
{
    response["ErrorCode"] = 101;
    response["ErrorMessage"] = "Model Id is required field.";
    return response;
}

Func<ASF.BDS.Common.Domain.Result.BaseResult, string, string, string> getValueFromResponse = (resp, ruleName, paramName) =>
{
    string result = string.Empty;
    System.Xml.XmlNode nodeEl = null;

    try
    {
        ParameterCollection respParams = resp.GetParameters();

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
            var xmlResp = resp.ToXml();

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

try
{

    //Get Version Id
    var reqGetConfVersionId = AppBaseHelpers.BdsHelper.ExecuteRequest("root_UTIL_getConfVersionId", new ParameterCollection());

    envVersionId = getValueFromResponse(reqGetConfVersionId, "root_UTIL_getConfVersionId", "CODE");

    if (String.IsNullOrEmpty(envVersionId))
    {
        throw new Exception("Version Id is not found");
    }

    //Get Data Model Data
    inputParameters = new ParameterCollection();
    inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "MODEL_ID", Value = modelId });
    inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "ISCONFIG", Value = "1" });
    var reqGetModelData = AppBaseHelpers.BdsHelper.ExecuteRequest("root_MDM_getModels", inputParameters);

    modelConfig = getValueFromResponse(reqGetModelData, "root_MDM_getModels", "CONFIG");
    modelName = getValueFromResponse(reqGetModelData, "root_MDM_getModels", "NAME");

    if (!String.IsNullOrEmpty(modelConfig))
    {

        var info = service.ApplyMxGraphModelToAppbase(new DCM.DataManagement.Domain.MDMModelCreationConfig(modelConfig, string.Empty)
        {
            UseRest = useRest,
            DesigntimeConfigurationServiceRest = designtimeConfigurationServiceRest,
            VersionId = envVersionId,
            Token = token,
            Domain = domain,
            NewBusinessModelString = string.Empty,
            OldBusinessModelString = modelConfig

        });

        response["Info"] = info.serializeToJSON().ToString();

    }

    //Clean FOM_*, DOM_*, SOM_*, MDM_* data
    inputParameters = new ParameterCollection();
    inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "ModelId", Value = modelId });
    var reqDestroyDOMModel = AppBaseHelpers.BdsHelper.ExecuteRequest("root_MDM_clearModelMetadata", inputParameters);

    response["SuccessResponse"] = string.Format("{0} Data Model metadata was cleaned", modelName);

}
catch (Exception e)
{
    response["ErrorMessage"] = e.ToString();
    response["ErrorCode"] = 99;
}

