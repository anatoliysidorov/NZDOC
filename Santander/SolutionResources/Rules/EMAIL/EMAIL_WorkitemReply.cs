var Logger = Common.Logging.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
Ecx.Rule.Helpers.BDSHelper.LogRequestParams("EMAIL_WorkitemReply", request);
Func<string, bool, string> getParam = (n, r) => Ecx.Rule.Helpers.BDSHelper.GetParameterAsString(request, n, r);
var token = getParam("TOKEN", true);
var domain = getParam("DOMAIN", true);
string xmlData = getParam("DataXML", true);
string body = getParam("BODY", true);

var tmpHtmlFilePath = Ecx.Rule.Helpers.Utils.GetTempFileName(domain, "tmp.html");
System.IO.File.WriteAllText(tmpHtmlFilePath, body);
var createResponse = AppBaseHelpers.CmsHelper.CreateResource(token, domain, tmpHtmlFilePath);

response.Result.AddParameter(new Parameter { Name = "XMLDATA", Value = xmlData });
response.Result.AddParameter(new Parameter { Name = "HTMLURL", Value = createResponse.FileUrl });

// Create a Workitem after reply
ASF.Framework.Service.Parameters.ParameterCollection dataParms = new ASF.Framework.Service.Parameters.ParameterCollection();
dataParms.AddRange(request.Parameters);
dataParms.GetParameterByName("DataXML").Value = xmlData;
dataParms.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "HTMLURL", Value = createResponse.FileUrl });
var dataRuleResp = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest
{
    Parameters = dataParms,
    Domain = domain,
    Token = token,
    DataCommand = "root_EMAIL_CreateWorkitemReply",
    VersionCode = null
});
if (!string.IsNullOrEmpty(dataRuleResp.ErrorMessage))
{
    Logger.Error("Execute rule:EMAIL_WorkitemReply error:" + dataRuleResp.ErrorMessage + " Error Code:" + dataRuleResp.ErrorCode);
    throw new InvalidOperationException("EMAIL_WorkitemReply dataRuleResp.ErrorMessage" + dataRuleResp.ErrorMessage);
}