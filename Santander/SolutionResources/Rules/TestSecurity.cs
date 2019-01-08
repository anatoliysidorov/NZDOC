var token = HttpUtility.UrlDecode(request["token"] == null?string.Empty:(string)request["token"]);
var sysdomain = request["TOKEN_SYSTEMDOMAIN"] == null?string.Empty:(string)request["TOKEN_SYSTEMDOMAIN"];
var appDomain = request["domain"] == null?string.Empty:(string)request["domain"];
    
//Auxilliaruy parameters
string errorMessage = null;
const string createAppBaseUserRule = "root_PPL_CreateModifySysUser";

try{
	
	//Call create or modify AppBase User rule first
	var userIdInput = 0;
	var userId = 19931;
	using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
	{
		var userCreateParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "EMail", Value = "il1@gm.com" });
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Firstname", Value = "il99" });
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Lastname", Value = "il99" });
		
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "UserLogin", Value = "il1" });
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "UserId", Value = "19931"});

		
		var userCreateResult = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = createAppBaseUserRule,
			Domain = appDomain,
			Parameters = userCreateParameters,
			Token = token
		});
	}

}
catch (Exception ex)
{
	response["ErrorCode"]    = "102";
	response["ErrorMessage"] =  "Exception: "+ex.Message;
}
