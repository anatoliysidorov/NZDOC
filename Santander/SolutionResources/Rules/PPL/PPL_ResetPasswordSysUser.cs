var token = HttpUtility.UrlDecode((string)request["token"]);
var sysdomain = (string)request["TOKEN_SYSTEMDOMAIN"];
var appDomain = (string)request["domain"];
var adminServiceUrl = ConfigurationManager.AppSettings["AdministrationServiceRest"];

var userId = (string)request["UserId"];

const string resolveOppositeRule = "root_PPL_getCodeByUserId";

string errorMessage = null;

if(string.IsNullOrEmpty(token)) { errorMessage = "Validation: parameter 'token' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(sysdomain)) { errorMessage = "Validation: parameter 'TOKEN_SYSTEMDOMAIN' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(appDomain)) { errorMessage = "Validation: parameter 'application domain' could not be found"; goto Validation; }
if(string.IsNullOrEmpty(adminServiceUrl)) { errorMessage = "'AdministrationServiceRest' url could not be found in AppSettings"; goto Validation; }
if(string.IsNullOrEmpty(userId)||userId == "0") { errorMessage = "Validation: 'User id' is required field"; goto Validation; }
string userCode ="";

try{

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
		userCode = (string)resParams1["UCODE"].Value;
	}

	if(resParams1["ERRORMESSAGE"].Value != null){
		errorMessage = (string)resParams1["ERRORMESSAGE"].Value;
	}

	if (!string.IsNullOrEmpty(userCode) && userCode != "null") {
		
		var dataServiceUri = new System.Uri(adminServiceUrl);
		var wu = dataServiceUri + "reset/"  + sysdomain +"/"+userCode+"?t=" + token;
		
		var _req = (System.Net.HttpWebRequest)System.Net.WebRequest.Create(wu);
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
				}
			}
		}
	}	
	else {
		response["ErrorCode"] = 123;
		response["ErrorMessage"] = errorMessage;
	}

	response["ErrorCode"] = 0;
	response["ErrorMessage"] = "";
	response["SuccessResponse"] = "Password was reseted";
	

}
catch (Exception ex)
{
	response["ErrorCode"] = 121;
	response["ErrorMessage"] = "Exception: " + ex.ToString();
}
	
Validation: 
	if(!string.IsNullOrEmpty(errorMessage) && errorMessage != "null"){
		response["ErrorCode"] = 122;
		response["ErrorMessage"] = errorMessage;
	}
	else {
		response["ErrorCode"] = 0;
		response["ErrorMessage"] = string.Empty;
	}