var token = HttpUtility.UrlDecode((string)request["token"]);
var sysdomain = (string)request["TOKEN_SYSTEMDOMAIN"];
var appDomain = (string)request["domain"];

var userId = (string)request["UserId"];

string errorMessage = null;
const string resolveOppositeRule = "root_PPL_getCodeByUserId";

/*if(string.IsNullOrEmpty(token)) { errorMessage = "Validation: parameter 'token' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(sysdomain)) { errorMessage = "Validation: parameter 'TOKEN_SYSTEMDOMAIN' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(appDomain)) { errorMessage = "Validation: parameter 'application domain' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(userId)) { errorMessage = "Validation: 'User id' is required field"; goto Validation; }

try{

var userCode ="";
var outPut ="";
using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
		{
			var userParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
			userParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "UserId", Value = userId });
			var deleteUserResult = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
										{
											DataCommand = resolveOppositeRule, 
											Domain = appDomain, 
											Parameters = userParameters, 
											Token = token
										});
			var resParams1 = deleteUserResult.Data.GetParameters();
			//response["UCode"]  = resParams1["UCODE"].Value;
			userCode = (string)resParams1["UCODE"].Value;
			outPut = (string)resParams1["ERRORMESSAGE"].Value;
			
		}
if (!string.IsNullOrEmpty(userCode)) {		
var deleteUserRequest = new ASF.Security.Service.Common.Messages.DeleteUserRequest
{
	Domain = sysdomain,
	Token = token,
	Code = userCode,
	
	
};
	using (var svc = new ASF.Security.Service.Proxy.AdministrationServiceSvc.AdministrationServiceClient())
{
	//Update user
	var userCode2 = svc.DeleteUser(deleteUserRequest).ErrorCode;
	response["ErrocCode"] = userCode2;
	//response["ErrorMessage"] = 
	//response["Login"] = userLogin;

}
}
else {
	response["ErrorCode"] = 123;
	response["ErrorMessage"] = outPut;
}

}
catch (Exception ex)
{
	response["ErrorCode"] = 122;
    response["ErrorMessage"] = "Unfortunately an error occurred: " + ex.ToString();
}
	
Validation: 
	if(!string.IsNullOrEmpty(errorMessage))
    
	{
		
        response["ErrorCode"] = 121;
        response["ErrorMessage"] = errorMessage;
	}*/