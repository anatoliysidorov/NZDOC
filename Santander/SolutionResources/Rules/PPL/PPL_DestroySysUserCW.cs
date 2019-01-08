var token = HttpUtility.UrlDecode((string)request["token"]);
var sysdomain = (string)request["TOKEN_SYSTEMDOMAIN"];
var appDomain = (string)request["domain"];


var userId = (string)request["USERID"];


const string deleteAppBaseUserRule = "root_PPL_DestroySysUser";
const string deleteCaseWorkerRule  = "root_PPL_DestroyCW";

string errorMessage = null;

if(string.IsNullOrEmpty(token)) { errorMessage = "Validation: parameter 'token' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(sysdomain)) { errorMessage = "Validation: parameter 'TOKEN_SYSTEMDOMAIN' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(appDomain)) { errorMessage = "Validation: parameter 'application domain' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(userId)) { errorMessage = "Validation: 'user login' is required field"; goto Validation; }

try{
//Call delete AppBase User rule first
var userIdInput = 0;
var isProceed = false;
using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
	{
		var userDeleteParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
		userDeleteParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "UserId", Value = userId  });
		var userDeleteResult = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
									{
										DataCommand = deleteAppBaseUserRule, 
										Domain = appDomain, 
										Parameters = userDeleteParameters, 
										Token = token
									});
			
		  var resParams1 = userDeleteResult.Data.GetParameters();
         
		 if(!string.IsNullOrEmpty((string)resParams1["ErrorMessage"].Value)) {
   			response["ErrorCode"] = resParams1["ErrorCode"].Value;
            response["ErrorMessage"] = resParams1["ErrorMessage"].Value;
          }
		 else {
         	isProceed = true;
         }	
		
	}
	//Call Delete or modify Caseworker rule
    if( isProceed == true){
		using (var client2 = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
		{
			var caseworkerDeleteParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
			caseworkerDeleteParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "UserId", Value = userId });
			var caseworkerDeleteResult = client2.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
										{
											DataCommand = deleteCaseWorkerRule, 
											Domain = appDomain, 
											Parameters = caseworkerDeleteParameters, 
											Token = token
										});
				var ResultJson2= caseworkerDeleteResult.Data.GetParameters();
				response["ErrorCode"]  	  = ResultJson2["ErrorCode"].Value;
				response["ErrorMessage"]  = ResultJson2["ErrorMessage"].Value;
				
			
		}
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
		response["ErrorCode"] = 123;
        response["ErrorMessage"] = errorMessage;
	}