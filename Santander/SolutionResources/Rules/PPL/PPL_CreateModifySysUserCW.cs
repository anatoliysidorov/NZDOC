var token = HttpUtility.UrlDecode(request["token"] == null ? string.Empty : (string)request["token"]);
var appDomain = request["domain"] == null ? string.Empty : (string)request["domain"];
var adminServiceUrl = ConfigurationManager.AppSettings["AdministrationServiceRest"];
var typeLargeText = ASF.Framework.Service.Parameters.ParameterType.LargeText();
var typeText = ASF.Framework.Service.Parameters.ParameterType.Text();
var typeNumber = ASF.Framework.Service.Parameters.ParameterType.Number();
var typeInteger = ASF.Framework.Service.Parameters.ParameterType.Integer();

//Auxilliaruy parameters
string errorMessage = string.Empty;
string successResponse = string.Empty;
ASF.Framework.Service.Parameters.Parameter inputParam;
bool result = false;

result = request.TryGetParameterByName("USERID", out inputParam);
var userId = 0;
if (result && !inputParam.IsEmpty())
{
	result = Int32.TryParse(inputParam.Value.ToString(), out userId);
	if (!result)
	{
		userId = 0;
	}
}
result = request.TryGetParameterByName("EXTERNALID", out inputParam);
var externalId = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("USERLOGIN", out inputParam);
var userLogin = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("NEED_MODIFY_EXTID", out inputParam);
var needModifyExternalId = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("FIRSTNAME", out inputParam);
var firstName = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("LASTNAME", out inputParam);
var lastName = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("EMAIL", out inputParam);
var email = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("SECURITYROLES_WOUT_GROUPS", out inputParam);
var roles = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("SECURITYGROUPS", out inputParam);
var groups = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;

//AppBase user additional params
result = request.TryGetParameterByName("PHONE", out inputParam);
var phone = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("CELLPHONE", out inputParam);
var cellphone = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("TITLE", out inputParam);
var title = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("BIRTHDAY", out inputParam);
var birthday = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("FAX", out inputParam);
var fax = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("COUNTRY", out inputParam);
var country = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : null;
result = request.TryGetParameterByName("STREET", out inputParam);
var street = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("CITY", out inputParam);
var city = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("ZIP", out inputParam);
var zip = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("STATE", out inputParam);
var state = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : string.Empty;
result = request.TryGetParameterByName("LOCALE", out inputParam);
var locale = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : null;
result = request.TryGetParameterByName("LANGUAGE", out inputParam);
var language = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : null;
result = request.TryGetParameterByName("TIMEZONE", out inputParam);
var timezone = !inputParam.IsEmpty() && result ? inputParam.Value.ToString() : null;

const string createAppBaseUserRule = "root_PPL_CreateModifySysUser";
const string createCaseWorkerRule = "root_PPL_CreateModifyCW";

if (string.IsNullOrEmpty(token)) { errorMessage = "Validation: parameter 'token' could not be found"; goto Validation; }
if (string.IsNullOrEmpty(appDomain)) { errorMessage = "Validation: parameter 'application domain' could not be found"; goto Validation; }
if (string.IsNullOrEmpty(adminServiceUrl)) { errorMessage = "Validation: 'AdministrationServiceRest' url could not be found in AppSettings"; goto Validation; }
if (string.IsNullOrEmpty(userLogin) && userId == 0) { errorMessage = "Validation: 'user login' is required field"; goto Validation; }
if (string.IsNullOrEmpty(firstName)) { errorMessage = "Validation: 'firstName' is required field"; goto Validation; }
if (string.IsNullOrEmpty(lastName)) { errorMessage = "Validation: 'lastName' is required field"; goto Validation; }
if (string.IsNullOrEmpty(email)) { errorMessage = "Validation: 'email' is required field"; goto Validation; }

try
{
	//Call the rule for checked a case worker is exists
	if ((needModifyExternalId == "1" || userId == 0) && (!string.IsNullOrEmpty(externalId)))
	{
		var existsParam = new ASF.Framework.Service.Parameters.ParameterCollection();

		existsParam.AddParameter(new Parameter { Type = typeText, Name = "ExternalId", Value = externalId });

		var caseWorkerExistResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = "root_PPL_checkExternalIDfn",
			Domain = appDomain,
			Parameters = existsParam,
			Token = token
		});
		var outParameters = caseWorkerExistResult.Data.GetParameters();
		var isCaseWorkerExist = outParameters["CaseWorkerExist"].Value;
		if (isCaseWorkerExist.ToString() == "1")
		{
			// get error message for response
			errorMessage = "Error: Case Worker with External Id: {{MESS_EXTERNALID}} already exists";
			object objMessageParams = new { MESS_EXTERNALID = externalId.ToString() };
			var jsonParams = Newtonsoft.Json.JsonConvert.SerializeObject(objMessageParams);
			var i18NParams = new ASF.Framework.Service.Parameters.ParameterCollection();
			i18NParams.AddParameter(new Parameter { Type = typeLargeText, Name = "MessageText", Value = errorMessage });
			i18NParams.AddParameter(new Parameter { Type = typeLargeText, Name = "MessageParams", Value = jsonParams });
			var i18NResponse = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
			{
				DataCommand = "root_LOC_i18n_invocation",
				Domain = appDomain,
				Parameters = i18NParams,
				Token = token
			});
			var resultI18N = i18NResponse.Data.GetParameters();
			errorMessage = resultI18N["MessageResult"].Value.ToString();
			goto Validation;
		}
	}

	//Call create or modify AppBase User rule first
	var userIdInput = 0;
	var userCreateParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "EMail", Value = email });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "Firstname", Value = firstName });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "Lastname", Value = lastName });

	userCreateParameters.AddParameter(new Parameter { Type = typeLargeText, Name = "SecurityGroups", Value = groups });
	userCreateParameters.AddParameter(new Parameter { Type = typeLargeText, Name = "SecurityRoles", Value = roles });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "UserLogin", Value = userLogin });
	userCreateParameters.AddParameter(new Parameter { Type = typeNumber, Name = "UserId", Value = userId });

	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "Phone", Value = phone });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "Cellphone", Value = cellphone });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "Title", Value = title });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "Birthday", Value = birthday });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "Fax", Value = fax });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "Country", Value = country });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "Street", Value = street });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "City", Value = city });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "Zip", Value = zip });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "State", Value = state });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "Locale", Value = locale });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "Language", Value = language });
	userCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "Timezone", Value = timezone });

	var userCreateResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = createAppBaseUserRule,
		Domain = appDomain,
		Parameters = userCreateParameters,
		Token = token
	});
	var resultJson = userCreateResult.Data.GetParameters();

	//Exit if AppBase User create funtion returns an error message
	if (!string.IsNullOrEmpty(resultJson["ErrorMessage"].Value.ToString()))
	{
		errorMessage = resultJson["ErrorMessage"].Value.ToString();
		goto Validation;
	}
	if (userId == 0)
	{
		response["UserId"] = resultJson["UserId"].Value == null ? "No Id" : resultJson["UserId"].Value.ToString();
		userIdInput = resultJson["UserId"].Value == null ? 0 : int.Parse(resultJson["UserId"].Value.ToString());
	}
	else
	{
		userIdInput = userId;
	}

	//Call create or modify CaseWorker rule
	var caseworkerCreateParameters = new ASF.Framework.Service.Parameters.ParameterCollection();

	caseworkerCreateParameters.AddParameter(new Parameter { Type = typeInteger, Name = "USERID", Value = userIdInput });
	caseworkerCreateParameters.AddParameter(new Parameter { Type = typeText, Name = "ExternalId", Value = externalId });

	var caseWorkerCreateResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = createCaseWorkerRule,
		Domain = appDomain,
		Parameters = caseworkerCreateParameters,
		Token = token
	});
	var resultJson2 = caseWorkerCreateResult.Data.GetParameters();

	if (resultJson2["ERRORCODE"].Value != null)
	{
		response["ErrorCode"] = resultJson2["ERRORCODE"].Value.ToString();
	}
	if (resultJson2["RECORDID"].Value != null)
	{
		response["RECORDID"] = resultJson2["RECORDID"].Value.ToString();
	}
	if (resultJson2["ERRORMESSAGE"].Value != null)
	{
		errorMessage = resultJson2["ERRORMESSAGE"].Value.ToString();
		goto Validation;
	}

	// The success response through the localization
	successResponse = userId != 0 ? "Updated {{MESS_NAME}} caseworker" : "Created {{MESS_NAME}} caseworker";
	object objMessageParams1 = new { MESS_NAME = firstName + " " + lastName };
	var jsonParams1 = Newtonsoft.Json.JsonConvert.SerializeObject(objMessageParams1);
	var i18NParams1 = new ASF.Framework.Service.Parameters.ParameterCollection();
	i18NParams1.AddParameter(new Parameter { Type = typeLargeText, Name = "MessageText", Value = successResponse });
	i18NParams1.AddParameter(new Parameter { Type = typeLargeText, Name = "MessageParams", Value = jsonParams1 });
	var i18NResponse1 = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = "root_LOC_i18n_invocation",
		Domain = appDomain,
		Parameters = i18NParams1,
		Token = token
	});
	var resultI18N1 = i18NResponse1.Data.GetParameters();
	response["SuccessResponse"] = resultI18N1["MessageResult"].Value.ToString();
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