var token = HttpUtility.UrlDecode(request["token"] == null?string.Empty:(string)request["token"]);
var sysdomain = request["TOKEN_SYSTEMDOMAIN"] == null?string.Empty:(string)request["TOKEN_SYSTEMDOMAIN"];
var appDomain = request["domain"] == null?string.Empty:(string)request["domain"];
var adminServiceUrl = ConfigurationManager.AppSettings["AdministrationServiceRest"];

var userId 		= request["USERID"] 		== null?0:Convert.ToInt32(request["USERID"]);
var externalId 	= request["EXTERNALID"] 	== null?string.Empty:(string)request["EXTERNALID"];
var userLogin 	= request["USERLOGIN"] 		== null?string.Empty:(string)request["USERLOGIN"];
var firstName 	= request["FIRSTNAME"] 		== null?string.Empty:(string)request["FIRSTNAME"];
var lastName 	= request["LASTNAME"] 		== null?string.Empty:(string)request["LASTNAME"];
var email 		= request["EMAIL"] 		   	== null?string.Empty:(string)request["EMAIL"];
var roles 		= request["SECURITYROLES"] 	== null?"root_PortalRep":(string)request["SECURITYROLES"];
//AppBase user additional params
var phone = request["PHONE"] 		== null?string.Empty:(string)request["PHONE"];


//External Party params
var externalParty_id = request["EXTPARTY_ID"] 		== null?0:Convert.ToInt32(request["EXTPARTY_ID"]);
var partytype_id = request["PARTYTYPE_ID"] 		== null?string.Empty:(string)request["PARTYTYPE_ID"];
var workbasket_id = request["WORKBASKET_ID"] 	== null?string.Empty:(string)request["WORKBASKET_ID"];
var description = request["DESCRIPTION"] 	== null?string.Empty:(string)request["DESCRIPTION"];

const string createAppBaseUserRule = "root_PPL_CreateModifySysUser";
const string createexternalPartyRule  = "root_PPL_CreateModifyExternalParty";

string errorMessage = null;

if(string.IsNullOrEmpty(token)) { errorMessage = "Validation: parameter 'token' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(sysdomain)) { errorMessage = "Validation: parameter 'TOKEN_SYSTEMDOMAIN' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(appDomain)) { errorMessage = "Validation: parameter 'application domain' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(adminServiceUrl)) { errorMessage = "'AdministrationServiceRest' url could not be found in AppSettings"; goto Validation; }
if(string.IsNullOrEmpty(userLogin)&&userId == 0) { errorMessage = "Validation: 'user login' is required field"; goto Validation; }
if(string.IsNullOrEmpty(firstName)) { errorMessage = "Validation: 'firstName' is required field"; goto Validation; }
if(string.IsNullOrEmpty(lastName)) { errorMessage = "Validation: 'lastName' is required field"; goto Validation; }
if(string.IsNullOrEmpty(email)) { errorMessage = "Validation: 'email' is required field"; goto Validation; }
if(string.IsNullOrEmpty(partytype_id)) { errorMessage = "Validation: 'External Part Type Id' is required field"; goto Validation; }

try{
//Call create or modify AppBase User rule first
var userIdInput = 0;

using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
	{
		var userCreateParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "EMail", Value = email });
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Firstname", Value = firstName });
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Lastname", Value = lastName });
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Phone", Value = phone });
		
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "SecurityRoles", Value = roles });
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "UserLogin", Value = userLogin });
		userCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "UserId", Value = userId});
		
		var userCreateResult = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = createAppBaseUserRule, 
			Domain = appDomain, 
			Parameters = userCreateParameters, 
			Token = token
		});
		var ResultJson = userCreateResult.Data.GetParameters();
					
		//Exit if AppBase User create funtion returns an error message
		if(!string.IsNullOrEmpty(ResultJson["ErrorMessage"].Value.ToString())){
			errorMessage = createAppBaseUserRule+": "+ResultJson["ErrorMessage"].Value.ToString();
		   goto Validation;
		}
	
		if(userId == 0){
			response["UserId"]  = ResultJson["UserId"].Value==null?"No Id":ResultJson["UserId"].Value.ToString();
			userIdInput = ResultJson["UserId"].Value==null?0:Convert.ToInt32(ResultJson["UserId"].Value);
		}
		else{
			userIdInput = userId;
		}
		
		
	}
	
	//Call create or modify externalParty rule
	using (var client2 = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
	{
	
   var externalPartyCreateParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
		if(externalParty_id != 0){
			externalPartyCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "ID", Value = externalParty_id });
		}
		externalPartyCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "USERID", Value = userIdInput });
        externalPartyCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "EXTSYSID", Value = externalId });
		externalPartyCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "NAME", Value = firstName+" "+lastName });
		externalPartyCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "EMAIL", Value = email });
		externalPartyCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "PHONE", Value = phone });
		externalPartyCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "DESCRIPTION", Value = description });
		externalPartyCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "PARTYTYPE_ID", Value = partytype_id });		
		externalPartyCreateParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "WORKBASKET_ID", Value = workbasket_id });				

		var externalPartyCreateResult = client2.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
									{
										DataCommand = createexternalPartyRule, 
										Domain = appDomain, 
										Parameters = externalPartyCreateParameters, 
										Token = token
									});
			var ResultJson2= externalPartyCreateResult.Data.GetParameters();
            
			response["RECORDID"]	  = ResultJson2["RECORDID"].Value;
			response["ErrorCode"]  	  = ResultJson2["ERRORCODE"].Value;
			response["ErrorMessage"]  = ResultJson2["ERRORMESSAGE"].Value;
			
		
	}

}
catch (Exception ex)
{
	response["ErrorMessage"] =  "Exception: "+ex.Message;
}
	
Validation: 
	if(!string.IsNullOrEmpty(errorMessage))
    
	{
		response["ErrorMessage"] = "Error: "+errorMessage;
	}