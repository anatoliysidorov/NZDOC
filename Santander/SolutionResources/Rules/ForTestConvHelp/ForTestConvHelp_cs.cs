var token = request.AsString("token");
var domain =  request.AsString("domain");

using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
{

var parametersRequest = new ASF.Framework.Service.Parameters.ParameterCollection();
var ruleResponse = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
{
    DataCommand = "root_ForTestConvHelp",
    Domain = domain,
    Parameters = parametersRequest,
    Token = token
});
var parametersResponse = ruleResponse.Data.GetParameters();
    
response["int_variable"] = ASF.Framework.Util.ConvertHelper.SafeObjectToInt(parametersResponse["int_variable"].Value);
response["int_variable_val"] = parametersResponse["int_variable"].Value;
response["string_variable"] = ASF.Framework.Util.ConvertHelper.SafeObjectToInt(parametersResponse["string_variable"].Value);
response["string_variable_val"] = parametersResponse["string_variable"].Value;
}
