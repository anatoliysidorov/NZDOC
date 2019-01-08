var token = HttpUtility.UrlDecode((string)request["token"]);
var sysdomain = (string)request["TOKEN_SYSTEMDOMAIN"];
var appDomain = (string)request["domain"];
var adminServiceUrl = ConfigurationManager.AppSettings["AdministrationServiceRest"];
var userId = (string)request["UserId"];
var status = (string)request["Status"];
string errorMessage = null;
const string resolveOppositeRule = "root_PPL_getCodeByUserId";

if(string.IsNullOrEmpty(token)) { errorMessage = "Validation: parameter 'token' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(sysdomain)) { errorMessage = "Validation: parameter 'TOKEN_SYSTEMDOMAIN' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(appDomain)) { errorMessage = "Validation: parameter 'application domain' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(adminServiceUrl)) { errorMessage = "'AdministrationServiceRest' url could not be found in AppSettings"; goto Validation; }
if(string.IsNullOrEmpty(userId)) { errorMessage = "Validation: 'User id' is required field"; goto Validation; }
if(string.IsNullOrEmpty(status)) { errorMessage = "Validation: 'Status' is required field"; goto Validation; }

try
{
	string userCode = "";
	string userLogin = "";
	var userParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
	userParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "UserId", Value = userId });
	var createUserResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = resolveOppositeRule, 
			Domain = appDomain, 
			Parameters = userParameters, 
			Token = token
		});
	var resParams1 = createUserResult.Data.GetParameters();

	if(resParams1["UCODE"].Value != null){
		userCode = resParams1["UCODE"].Value.ToString();
	}

	if(resParams1["ULOGIN"].Value != null){
		userLogin = resParams1["ULOGIN"].Value.ToString();
	}

	if(resParams1["ERRORMESSAGE"].Value != null){
		errorMessage = resParams1["ERRORMESSAGE"].Value.ToString();
	}

	
	if (!string.IsNullOrEmpty(userCode)) 
	{
		// update users status
		var updateUserRequest = new ASF.Security.Service.Common.Messages.UpdateUserRequest
		{
			Domain = sysdomain,
			Token = token,
			Code = userCode,
			LoginType = ASF.Security.Common.Domain.LoginType.MEMBERSHIP,
			User = new ASF.Security.Common.Domain.UserInfo
			{
				Login = userLogin,
				Status = status=="0"?ASF.Security.Common.Domain.Status.Active:ASF.Security.Common.Domain.Status.Inactive
			}
		};

		using (var svc = new ASF.Security.Service.Proxy.AdministrationServiceSvc.AdministrationServiceClient())
		{
			//Update user
			var userCode2 = svc.UpdateUser(updateUserRequest).ErrorCode;
		}
		
		// update is Locked out status
		if (status == "0")
		{
			var dataServiceUri = new System.Uri(adminServiceUrl);
			var wu = dataServiceUri + "unlock/"  + sysdomain +"/"+userCode+"?t=" + token;
			//response["url"] = wu;
			var _req = (System.Net.HttpWebRequest)System.Net.WebRequest.Create(wu);
			_req.Method = "POST";
			_req.ContentLength = 0;
			string respBody = null;
			using (var resp = (System.Net.HttpWebResponse)_req.GetResponse())
			{
				using (var stream = resp.GetResponseStream())
				{
					using (var reader = new System.IO.StreamReader(stream))
					{
						respBody += reader.ReadToEnd();
						
						Newtonsoft.Json.Linq.JObject jObject = Newtonsoft.Json.Linq.JObject.Parse(respBody .ToString());
						var item = jObject["ErrorMessage"];
						errorMessage = item.ToString().Replace("\"", string.Empty);
						errorMessage = errorMessage == "null" ? null : errorMessage;
					}
				}
			}
		}
	}
	else
	{
		response["ErrorCode"] = 123;
		response["ErrorMessage"] = errorMessage;
	}
	response["ErrorCode"] = 0;
	response["ErrorMessage"] = "";
	response["SuccessResponse"] = "User was updated";
}
catch (Exception ex)
{
	response["ErrorCode"] = 122;
	response["ErrorMessage"] = "Exception: " + ex.ToString();
}
	
Validation: 
	if(!string.IsNullOrEmpty(errorMessage))
	{
		response["ErrorCode"] = 121;
		response["ErrorMessage"] = errorMessage;
	}