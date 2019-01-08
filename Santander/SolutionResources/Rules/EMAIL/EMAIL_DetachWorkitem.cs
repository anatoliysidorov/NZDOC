var Logger = Common.Logging.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
Ecx.Rule.Helpers.BDSHelper.LogRequestParams("EMAIL_DetachWorkitem", request);
Func<string, bool, string> getParam = (n, r) => Ecx.Rule.Helpers.BDSHelper.GetParameterAsString(request, n, r);
Func<XDocument, string, string> getValueFromResponse = (r, n) =>
{
    var tmp = r.Descendants(n).SingleOrDefault();
    return (tmp == null) ? "" : (tmp.Value == "null") ? "" : tmp.Value;
};
var token = getParam("TOKEN", true);
var domain = getParam("DOMAIN", true);

ASF.Framework.Service.Parameters.ParameterCollection dataParms = new ASF.Framework.Service.Parameters.ParameterCollection();
dataParms.AddRange(request.Parameters);
var dataRuleResp = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest
{
    Parameters = dataParms,
    Domain = domain,
    Token = token,
    DataCommand = "root_EMAIL_getInboxWorkbasket",
    VersionCode = null
});
if (!string.IsNullOrEmpty(dataRuleResp.ErrorMessage))
{
    Logger.Error("Execute rule:EMAIL_DetachWorkitem error:" + dataRuleResp.ErrorMessage + " Error Code:" + dataRuleResp.ErrorCode);
    throw new InvalidOperationException("EMAIL_DetachWorkitem dataRuleResp.ErrorMessage" + dataRuleResp.ErrorMessage);
}
var workbasketId = getValueFromResponse(dataRuleResp.Data.ToXml(), "WORKBASKETID");
dataParms.GetParameterByName("WorkbasketId").Value = workbasketId;

dataRuleResp = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest
{
    Parameters = dataParms,
    Domain = domain,
    Token = token,
    DataCommand = "root_PI_UnattachDocumentFromCase",
    VersionCode = null
});
if (!string.IsNullOrEmpty(dataRuleResp.ErrorMessage))
{
    Logger.Error("Execute rule:EMAIL_DetachWorkitem error:" + dataRuleResp.ErrorMessage + " Error Code:" + dataRuleResp.ErrorCode);
    throw new InvalidOperationException("EMAIL_DetachWorkitem dataRuleResp.ErrorMessage" + dataRuleResp.ErrorMessage);
}

/*
dataRuleResp = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest
{
    Parameters = dataParms,
    Domain = domain,
    Token = token,
    DataCommand = "root_EMAIL_DetachWorkitemExt",
    VersionCode = null
});
if (!string.IsNullOrEmpty(dataRuleResp.ErrorMessage))
{
    Logger.Error("Execute rule:EMAIL_DetachWorkitem error:" + dataRuleResp.ErrorMessage + " Error Code:" + dataRuleResp.ErrorCode);
    throw new InvalidOperationException("EMAIL_DetachWorkitem dataRuleResp.ErrorMessage" + dataRuleResp.ErrorMessage);
}
*/