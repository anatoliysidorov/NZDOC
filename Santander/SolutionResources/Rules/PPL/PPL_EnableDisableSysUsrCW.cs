var token = HttpUtility.UrlDecode((string)request["token"]);
var sysdomain = (string)request["TOKEN_SYSTEMDOMAIN"];
var appDomain = (string)request["domain"];


var userId = (string)request["USERID"];
var status = (string)request["Status"];


const string updateAppBaseUserRule = "root_PPL_EnableDisableSysUser";
const string updateCaseWorkerRule  = "root_PPL_EnableDisableCW";

string errorMessage = null;

if(string.IsNullOrEmpty(token)) { errorMessage = "Validation: parameter 'token' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(sysdomain)) { errorMessage = "Validation: parameter 'TOKEN_SYSTEMDOMAIN' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(appDomain)) { errorMessage = "Validation: parameter 'application domain' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(userId)) { errorMessage = "Validation: 'user login' is required field"; goto Validation; }
if(string.IsNullOrEmpty(status)) { errorMessage = "Validation: 'Status' is required field"; goto Validation; }

try{
//Call create or modify AppBase User rule first
var userIdInput = 0;
var isProceed = false;
using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
	{
		var userCreateParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "UserId", Value = userId  });
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Status", Value = status  });
		var userCreateResult = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
									{
										DataCommand = updateAppBaseUserRule, 
										Domain = appDomain, 
										Parameters = userCreateParameters, 
										Token = token
									});
			
		  var resParams1 = userCreateResult.Data.GetParameters();
         
		 if(!string.IsNullOrEmpty((string)resParams1["ErrorMessage"].Value)) {
   			response["ErrorCode"] = resParams1["ErrorCode"].Value;
            response["ErrorMessage"] = resParams1["ErrorMessage"].Value;
          }
		 else {
         	isProceed = true;
         }	
		
	}
	//Call create or modify Caseworker rule
    if( isProceed == true){
		using (var client2 = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
		{
			var caseworkerCreateParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
			caseworkerCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "UserId", Value = userId });
			caseworkerCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Status", Value = status });
			var caseworkerCreateResult = client2.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
										{
											DataCommand = updateCaseWorkerRule, 
											Domain = appDomain, 
											Parameters = caseworkerCreateParameters, 
											Token = token
										});
				var ResultJson2= caseworkerCreateResult.Data.GetParameters();
				response["ErrorCode"]  	  = ResultJson2["ErrorCode"].Value;
				response["ErrorMessage"]  = ResultJson2["ErrorMessage"].Value;
				
			
		}
    }

}
catch (Exception ex)
{
	response["ErrorCode"] = 123;
    response["ErrorMessage"] = "Unfortunately an error occurred: " + ex.ToString();
}
	
Validation: 
	if(!string.IsNullOrEmpty(errorMessage))
    
	{
		response["ErrorCode"] = 122;
        response["ErrorMessage"] = errorMessage;
	}