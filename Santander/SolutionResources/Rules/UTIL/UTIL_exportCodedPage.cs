var token = HttpUtility.UrlDecode((string)request["token"]);
var sysdomain = (string)request["TOKEN_SYSTEMDOMAIN"];
var domain = (string)request["domain"];

string ruleCodedPage = "root_FOM_getCodedPages";
string sys_BINARY_RESPONSE = String.Empty;
byte[] byteArray;
var resourceServiceClient = new ASF.Config.WebService.Proxy.ResourceServiceSvc.ResourceServiceClient();
string folderPath = "res://tenant/solutions2/cache/";

Func<Newtonsoft.Json.Linq.JToken, string, string> getValue = (x, n) =>
{
	var el = x.Value<string>(n);
	return !string.IsNullOrEmpty(el) ? el : String.Empty;
};

try
{
    //Call the rule to getting a record of specific Coded Page (code = DCM_GLOBAL_JS)
    var param = new ASF.Framework.Service.Parameters.ParameterCollection();
    param.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "CodedPage_Code", Value = "DCM_GLOBAL_JS"});
    var importDataToDB = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
    {
        DataCommand = ruleCodedPage,
        Domain = domain,
        Parameters = param,
        Token = token
    });
    var outParameters = importDataToDB.Data.GetParameters();
    if (outParameters["ERRORMESSAGE"].Value != null)
    {
        throw new Exception(outParameters["ERRORMESSAGE"].Value.ToString());
    }

    var responseRuleResult = importDataToDB.Data.ToJson();
    Newtonsoft.Json.Linq.JObject jObject = Newtonsoft.Json.Linq.JObject.Parse(responseRuleResult);
    foreach (var data in jObject["DATA"][ruleCodedPage]["ITEMS"])
    {
        sys_BINARY_RESPONSE += System.Web.HttpUtility.HtmlDecode(getValue(data, "PAGEMARKUP"));
    }

    if (!String.IsNullOrEmpty(sys_BINARY_RESPONSE))
    {
        byteArray = System.Text.Encoding.UTF8.GetBytes(sys_BINARY_RESPONSE);
        resourceServiceClient.DeleteItem(token, folderPath + "dcm-global.js", new ASF.Framework.Service.Domain.ResourcePathResolveInfo { Domain = domain, SolutionCode = string.Empty, VersionCode = string.Empty });
        resourceServiceClient.PutFile(token, folderPath, "dcm-global.js", "dcm-global.js", "application/javascript", byteArray, new ASF.Framework.Service.Domain.ResourcePathResolveInfo() { Domain = domain });
    }

	response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = string.Empty });
	response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = "The Injections File for the Coded Page with code = DCM_GLOBAL_JS generated." });
	response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = 0 });
}
catch (Exception ex)
{
	var errorMessage = ex.Message;
	response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = errorMessage });
	response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = string.Empty });
	response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = 101 });
}
