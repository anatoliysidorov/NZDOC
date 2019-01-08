string errorMessage = null;

var token = HttpUtility.UrlDecode((string)request["token"]);
var sysdomain = (string)request["TOKEN_SYSTEMDOMAIN"];
var appDomain = (string)request["domain"];
var adminServiceUrl = ConfigurationManager.AppSettings["AdministrationServiceRest"];

var userId = request["UserId"] == null ? 0 : Convert.ToInt32(request["UserId"]);
string userLogin = (string)request["UserLogin"];
var firstName = (string)request["Firstname"];
var lastName = (string)request["Lastname"];
var email = (string)request["EMail"];
var password = System.Web.Security.Membership.GeneratePassword(8, 0);
//var confirmPassword = "12345";//(string)request["confirmPassword"];

var roles = (string)request["SecurityRoles"];
var groups = (string)request["SecurityGroups"];
var phone = (string)request["Phone"];
var cellPhone = (string)request["Cellphone"];
var title = (string)request["Title"];
var birthday = (string)request["Birthday"];
var fax = (string)request["Fax"];
var country = (string)request["Country"];
var street = (string)request["Street"];
var city = (string)request["City"];
var zip = (string)request["Zip"];
var state = (string)request["State"];
var locale = (string)request["Locale"];
var language = (string)request["Language"];
var timeZone = (string)request["Timezone"];
string grantGroups = string.Empty;
string revokeGroups = string.Empty;
string grantAdGroups = string.Empty;

const string fromEmail = "DCM_Team_noreply@eccentex.com";
const string subjectEmail = "Your AppBase User was created";
const string signatureEmail = "DCM Team";
const string resolveRule = "root_PPL_getUserIdByCode";
const string resolveOppositeRule = "root_PPL_getCodeByUserId";
const string getConfigValueRule = "root_UTIL_getConfigs";

if (string.IsNullOrEmpty(token)) { errorMessage = "Validation: parameter 'token' could not be found"; goto Validation; }
if (string.IsNullOrEmpty(sysdomain)) { errorMessage = "Validation: parameter 'TOKEN_SYSTEMDOMAIN' could not be found"; goto Validation; }
if (string.IsNullOrEmpty(appDomain)) { errorMessage = "Validation: parameter 'application domain' could not be found"; goto Validation; }
if (string.IsNullOrEmpty(adminServiceUrl)) { errorMessage = "'AdministrationServiceRest' url could not be found in AppSettings"; goto Validation; }
if (string.IsNullOrEmpty(userLogin) && (userId == 0)) { errorMessage = "Validation: 'user login' is required field"; goto Validation; }
if (string.IsNullOrEmpty(firstName)) { errorMessage = "Validation: 'firstName' is required field"; goto Validation; }
if (string.IsNullOrEmpty(lastName)) { errorMessage = "Validation: 'lastName' is required field"; goto Validation; }
if (string.IsNullOrEmpty(email)) { errorMessage = "Validation: 'email' is required field"; goto Validation; }
//if (string.IsNullOrEmpty(password)) { errorMessage = "Validation: 'password' is required field"; goto Validation; }
if (string.IsNullOrEmpty(country)) { country = "0"; }
if (string.IsNullOrEmpty(locale)) { locale = "0"; }
if (string.IsNullOrEmpty(language)) { language = "0"; }
if (string.IsNullOrEmpty(timeZone)) { timeZone = "0"; }

try
{
	System.Uri uri = new System.Uri(adminServiceUrl);
	var siteRootUri = uri.Scheme + Uri.SchemeDelimiter + uri.Host + ":" + uri.Port + "/Ecx.Web";
	string userCode = "";
	List<string> grantListRoles = new List<string>() { sysdomain + "_allow_my_workspace" };
	List<string> revokeListRoles = new List<string>();

	if (!string.IsNullOrEmpty(roles))
	{
		if (roles.Contains("|||"))
		{
			var arrayOfRoles = roles.Split(new string[] { "|||" }, StringSplitOptions.RemoveEmptyEntries);
			for (var i = 0; i < arrayOfRoles.Length; i++)
			{
				grantListRoles.Add(appDomain + "_" + arrayOfRoles[i]);
			}
		}
		else
		{
			grantListRoles.Add(appDomain + "_" + roles);
		}
	}

	var userProfile = new ASF.Security.Common.Domain.UserProfileInfo
	{
		FirstName = firstName,
		LastName = lastName,
		Email = email,
		CellPhone = cellPhone,
		Phone = phone,
		Title = title,
		BirthdayText = birthday,
		Fax = fax,
		Country = Convert.ToInt64(country),
		Street = street,
		City = city,
		Zip = zip,
		State = state,
		Timezone = Convert.ToInt64(timeZone)
	};

	var propertyLocaleCode = userProfile.GetType().GetProperty("LocaleCode");
	if (propertyLocaleCode != null)
	{
		propertyLocaleCode.SetValue(userProfile, locale, null);
	}

	var propertyLocale = userProfile.GetType().GetProperty("Locale");
	if (propertyLocale != null)
	{
		propertyLocale.SetValue(userProfile, ASF.Framework.Util.ConvertHelper.SafeStringToLong(locale), null);
	}

	var propertyLanguageCode = userProfile.GetType().GetProperty("LanguageCode");
	if (propertyLanguageCode != null)
	{
		propertyLanguageCode.SetValue(userProfile, language, null);
	}
	var propertyLanguage = userProfile.GetType().GetProperty("Language");
	if (propertyLanguage != null)
	{
		propertyLanguage.SetValue(userProfile, ASF.Framework.Util.ConvertHelper.SafeStringToLong(language), null);
	}

	// =================================================
	// Create/Modify User
	if (userId == 0)
	{

		//Get New User Creation Email Body from Configuration
		var emailBodyFromConfig = "";
		var configParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
		configParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "name", Value = "NEWUSER_EMAIL_BODY" });
		var configParamsResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = getConfigValueRule,
			Domain = appDomain,
			Parameters = configParameters,
			Token = token
		});
		var ResultJson = configParamsResult.Data.ToJson();
		Newtonsoft.Json.Linq.JObject jObject = Newtonsoft.Json.Linq.JObject.Parse(ResultJson);
		var item = jObject["DATA"][getConfigValueRule]["ITEMS"][0]["VALUE"];
		emailBodyFromConfig = item.ToString().Replace("\"", string.Empty).Replace("\\r", string.Empty).Replace("\\t", string.Empty).Replace("\\n", string.Empty);
		//response["VALUE"]  = emailBodyFromConfig;

		var createUserRequest = new ASF.Security.Service.Common.Messages.CreateUser2Request
		{
			Domain = sysdomain,
			Token = token,
			AuthUser = new ASF.Security.Common.Domain.AuthUserInfo
			{
				UserInfo = new ASF.Security.Common.Domain.UserInfo
				{
					Name = firstName + " " + lastName,
					Login = userLogin,
					FirstName = firstName,
					LastName = lastName /*,
					WorkPhone = Phone */
				},
				AuthInfo = new ASF.Security.Common.Domain.AuthInfo
				{
					Username = userLogin,
					Password = password,
					Email = email,
					PasswordQuestion = "NONE",
					PasswordAnswer = "NONE",
					LoginType = ASF.Security.Common.Domain.LoginType.MEMBERSHIP
				}
			},
			Profile = userProfile,
			//Roles = grantListRoles.ToArray(),
			Subject = subjectEmail,
			Body = emailBodyFromConfig,
			From = fromEmail,
			IsBodyHtml = true,
			ResolvedPlaceholders = new ASF.Framework.Util.SerializableDictionary<string, string> { { "ACCOUNTURL", siteRootUri }, { "TEAM", signatureEmail } }
		};

		using (var svc = new ASF.Security.Service.Proxy.AdministrationServiceSvc.AdministrationServiceClient())
		{
			//create user
			try
			{
				var userResp = svc.CreateUser2(createUserRequest);
				userCode = userResp.Code;
				if (!string.IsNullOrEmpty(userCode))
				{
					var userParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
					userParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "UCode", Value = userCode });
					var createUserResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
					{
						DataCommand = resolveRule,
						Domain = appDomain,
						Parameters = userParameters,
						Token = token
					});
					var resParams1 = createUserResult.Data.GetParameters();
					response["UserId"] = resParams1["USERID"].Value;
					userId = int.Parse(resParams1["USERID"].Value.ToString());
				}
			}
			catch (Exception ex)
			{
				errorMessage = "Exception: " + ex.Message;
				goto Validation;
			}
		}
	}
	else
	{
 		//Get Active Directory groups
		var adGroupParams = new ASF.Framework.Service.Parameters.ParameterCollection();
		adGroupParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "USERID", Value = userId });
		var getAdGroupRes = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = "root_PPL_getAdGroups",
			Domain = appDomain,
			Parameters = adGroupParams,
			Token = token
		});
		var adGroupsOutParams = getAdGroupRes.Data.GetParameters();
		if (!adGroupsOutParams["GRANTLIST"].IsEmpty())
		{
			grantAdGroups = adGroupsOutParams["GRANTLIST"].Value.ToString();
		}

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

		userCode = resParams1["UCODE"].Value.ToString();

		if (string.IsNullOrEmpty(userLogin))
		{
			userLogin = resParams1["ULOGIN"].Value.ToString();
		}

		// get grantListRoles
		string temp_roles = null;
		if(resParams1["UROLES"].Value != null){
			temp_roles = resParams1["UROLES"].Value.ToString();
		}

		if (!string.IsNullOrEmpty(temp_roles))
		{
			if (temp_roles.Contains("|||"))
			{
				var arrayOfRoles = temp_roles.Split(new string[] { "|||" }, StringSplitOptions.RemoveEmptyEntries);
				for (var i = 0; i < arrayOfRoles.Length; i++)
				{
					if (!arrayOfRoles[i].Contains(appDomain))
					{
						if (!grantListRoles.Contains(arrayOfRoles[i]))
						{
							grantListRoles.Add(arrayOfRoles[i]);
						}
					} else
					{
						if (!grantListRoles.Contains(arrayOfRoles[i]))
						{
							revokeListRoles.Add(arrayOfRoles[i]);
						}
					}
				}
			}
			else
			{
				if (!grantListRoles.Contains(temp_roles))
				{
					grantListRoles.Add(temp_roles);
				}
			}
		}

		if(resParams1["ERRORMESSAGE"].Value != null){
			errorMessage = resParams1["ERRORMESSAGE"].Value.ToString();
		}

		if (!string.IsNullOrEmpty(userCode))
		{
			var updateUserRequest = new ASF.Security.Service.Common.Messages.UpdateUser2Request
			{
				Domain = sysdomain,
				Token = token,
				Code = userCode,
				Profile = userProfile,
				//Roles = grantListRoles.ToArray(),
				User = new ASF.Security.Common.Domain.UserInfo
				{
					Login = userLogin,
					//UserLogin = userLogin,
					//DiplayName = userLogin,
					Name = firstName + " " + lastName
				}

			};
			using (var svc = new ASF.Security.Service.Proxy.AdministrationServiceSvc.AdministrationServiceClient())
			{
				//Update user
				errorMessage = svc.UpdateUser2(updateUserRequest).ErrorMessage;
			}
		}
		else
		{
			errorMessage = resolveOppositeRule + ": " + errorMessage;
		}
		if (!string.IsNullOrEmpty(errorMessage))
		{
			goto Validation;
		}
	}

	// =================================================
	//Grand and Revoke Security Roles
	if ((revokeListRoles.Count != 0) || (grantListRoles.Count != 0))
	{
		ASF.Security.Common.Domain.RoleLinkItemDomain[] grantArray = new ASF.Security.Common.Domain.RoleLinkItemDomain[grantListRoles.Count];
		ASF.Security.Common.Domain.RoleLinkItemDomain[] revokeArray = new ASF.Security.Common.Domain.RoleLinkItemDomain[revokeListRoles.Count];
		if (grantListRoles.Count > 0)
		{
			int i = 0;
			foreach (string x in grantListRoles)
			{
				grantArray[i++] = new ASF.Security.Common.Domain.RoleLinkItemDomain {Code = x, Domain = "" };
			}
		}
		if (revokeListRoles.Count > 0)
		{
			int i = 0;
			foreach (string x in revokeListRoles)
			{
				revokeArray[i++] = new ASF.Security.Common.Domain.RoleLinkItemDomain { Code = x, Domain = "" };
			}
		}
		// Update security roles for a user
		var updateUserRoles = new ASF.Security.Service.Common.Messages.UpdateUserRolesRequest
		{
			Domain = sysdomain,
			Token = token,
			Code = userCode,
			Data = new ASF.Security.Service.Common.Messages.UpdateUserRolesInfo
			{
				GrantList = grantArray,
				RevokeList = revokeArray
			}
		};

		using (var svc = new ASF.Security.Service.Proxy.AdministrationServiceSvc.AdministrationServiceClient())
		{
			errorMessage = svc.UpdateUserRoles(updateUserRoles).ErrorMessage;
		}
	}

	if (!string.IsNullOrEmpty(errorMessage))
	{
		goto Validation;
	}

	// =================================================
	//Call the rule get revoke and grand groups
	var param = new ASF.Framework.Service.Parameters.ParameterCollection();
	param.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "GROUPS", Value = groups });
	param.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "USERID", Value = userId });
	var getGroupsResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = "root_PPL_getSecurityGroupsCW",
		Domain = appDomain,
		Parameters = param,
		Token = token
	});
	var outParameters = getGroupsResult.Data.GetParameters();
	if (!outParameters["GRANTLIST"].IsEmpty())
	{
		grantGroups = outParameters["GRANTLIST"].Value.ToString();
	}
	if (!outParameters["REVOKELIST"].IsEmpty())
	{
		revokeGroups = outParameters["REVOKELIST"].Value.ToString();
	}

 	// Merge active directory groups with appbase groups
	if (!string.IsNullOrEmpty(grantAdGroups))
	{
		if (string.IsNullOrEmpty(grantGroups))
		{
			grantGroups = grantAdGroups;
		}
		else {
			grantGroups += "|||" + grantAdGroups;
		}
	}


	//Grand and Revoke Security Groups
	if ((!string.IsNullOrEmpty(grantGroups)) || (!string.IsNullOrEmpty(revokeGroups)))
	{
		// init grant list
		List<string> grantGroupsList = new List<string>();
		if (!string.IsNullOrEmpty(grantGroups))
		{
			if (grantGroups.Contains("|||"))
			{
				var arrayOfGrantGroup = grantGroups.Split(new string[] { "|||" }, StringSplitOptions.RemoveEmptyEntries);
				for (var i = 0; i < arrayOfGrantGroup.Length; i++)
				{
					grantGroupsList.Add(arrayOfGrantGroup[i]);
				}
			}
			else
			{
				grantGroupsList.Add(grantGroups);
			}
		}

		// init revoke list
		List<string> revokeGroupsList = new List<string>();
		if (!string.IsNullOrEmpty(revokeGroups))
		{
			if (revokeGroups.Contains("|||"))
			{
				var arrayOfRevokeGroup = revokeGroups.Split(new string[] { "|||" }, StringSplitOptions.RemoveEmptyEntries);
				for (var i = 0; i < arrayOfRevokeGroup.Length; i++)
				{
					revokeGroupsList.Add(arrayOfRevokeGroup[i]);
				}
			}
			else
			{
				revokeGroupsList.Add(revokeGroups);
			}
		}

		string[] grantList = { };
		string[] revokeList = { };
		if (grantGroupsList != null)
		{
			if (grantGroupsList.Count > 0)
			{
				grantList = grantGroupsList.ToArray();
			}
		}
		if (revokeGroupsList != null)
		{
			if (revokeGroupsList.Count > 0)
			{
				revokeList = revokeGroupsList.ToArray();
			}
		}
		// Update security groups for a user
		var updateUserGroups = new ASF.Security.Service.Common.Messages.UpdateUserGroupsRequest
		{
			Domain = sysdomain,
			Token = token,
			Code = userCode,
			Data = new ASF.Security.Service.Common.Messages.UpdateUserGroupsInfo
			{
				GrantList = grantList,
				RevokeList = revokeList
			}
		};

		using (var svc = new ASF.Security.Service.Proxy.AdministrationServiceSvc.AdministrationServiceClient())
		{
			errorMessage = svc.UpdateUserGroups(updateUserGroups).ErrorMessage;
		}
	}
}
catch (Exception ex)
{
	errorMessage = "Exception: " + ex.ToString();
}
Validation:
	if (!string.IsNullOrEmpty(errorMessage))
	{
		response["ErrorCode"] = 122;
		response["ErrorMessage"] = errorMessage;
	}
	else
	{
		response["ErrorCode"] = 0;
		response["ErrorMessage"] = string.Empty;
	}