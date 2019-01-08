var token = HttpUtility.UrlDecode(request["token"] == null ? string.Empty : (string)request["token"]);
var appDomain = request["domain"] == null ? string.Empty : (string)request["domain"];
string errorMessage = string.Empty;
const string setSysVarRule = "root_UTIL_setSystemVariable";
var typeLargeText = ASF.Framework.Service.Parameters.ParameterType.LargeText();
var sysVarName = request["SYSVAR_NAME"] == null ? string.Empty : (string)request["SYSVAR_NAME"];
var sysVarValue = request["SYSVAR_VALUE"] == null ? string.Empty : (string)request["SYSVAR_VALUE"];
int numVal = 0;

//Action<string> logDebug = m => Ecx.Rule.Helpers.BDSHelper.LogDebug(m, null);
//logDebug("IL_DEBUG_UTIL_setSystemVariable_c");
try
{
    if (sysVarName == "UI_DATA_CACHE_VERSION")
    {
        sysVarValue = (string)request["UI_DATA_CACHE_VERSION"];
        try
        {
            numVal = Convert.ToInt32(sysVarValue);
        }
        catch
        {
        }

        if (numVal == Int32.MaxValue)
        {
            numVal = 0;
        }
        numVal += 1;
        sysVarValue = numVal.ToString();
    }

    var paramsSetSysVar = new ASF.Framework.Service.Parameters.ParameterCollection();
    paramsSetSysVar.AddParameter(new Parameter { Type = typeLargeText, Name = "SYSVAR_NAME", Value = sysVarName });
    paramsSetSysVar.AddParameter(new Parameter { Type = typeLargeText, Name = "SYSVAR_VALUE", Value = sysVarValue });

    var ruleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
    {
        DataCommand = setSysVarRule,
        Domain = appDomain,
        Parameters = paramsSetSysVar,
        Token = token
    });
    var resultJson = ruleResult.Data.GetParameters();

    if (resultJson["ERRORMESSAGE"].Value != null && !string.IsNullOrEmpty(resultJson["ERRORMESSAGE"].Value.ToString()))
    {
        errorMessage = resultJson["ERRORMESSAGE"].Value.ToString();
        goto Validation;
    }

    try
    {
        var managementSvc = new ASF.Management.WebService.Core.BaseManagementService();
        managementSvc.UpdateEnvironmentContextInternal(token, appDomain);
    }
    catch
    {
    }
}
catch (Exception ex)
{
    errorMessage = "Exception: " + ex.Message;
}

Validation:
if (!string.IsNullOrEmpty(errorMessage))
{
    response["ErrorCode"] = "101";
    response["ErrorMessage"] = errorMessage;
}