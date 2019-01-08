var token = HttpUtility.UrlDecode((string)request["token"]);
var sysdomain = (string)request["TOKEN_SYSTEMDOMAIN"];
var domain = (string)request["domain"];
string ruleNameExportData = "root_LOC_getExportData";
string ruleNameLanguageData = "root_LOC_getLanguages";
string separatorIsPlurar = " #:"; // the value for isPlurar must be getting like true if separator is present
string separatorContext = " %:";  // the value for context must be getting like suffix
string sys_BINARY_RESPONSE = String.Empty;
byte[] byteArray;
var resourceServiceClient = new ASF.Config.WebService.Proxy.ResourceServiceSvc.ResourceServiceClient();
string folderPath = "res://tenant/solutions2/cache/translations/";

Func<Newtonsoft.Json.Linq.JToken, string, string> getValue = (x, n) =>
{
	var el = x.Value<string>(n);
	return !string.IsNullOrEmpty(el) ? el : String.Empty;
};

try
{
	//Call the rule to getting an export data
	
	var param = new ASF.Framework.Service.Parameters.ParameterCollection();
	//param.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "LanguageID", Value = "502" });
	var importDataToDB = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = ruleNameExportData,
		Domain = domain,
		Parameters = param,
		Token = token
	});
	var outParameters = importDataToDB.Data.GetParameters();
	if (outParameters["ERRORMESSAGE"].Value != null)
	{
		throw new Exception(outParameters["ERRORMESSAGE"].Value.ToString());
	}

	var responseRuleResult = importDataToDB.Data.ToJson();

	string namespaceName = String.Empty;
	string import_string = String.Empty;
	string lang_local = String.Empty;
	string lang_code = String.Empty;
	string fileHeader = @"Boot().currentLanguageData = @@CURENT_LANGUAGE_DATA@@; Ext.ns('i18n.resources.@@lang_local@@');";
	string fileContent = @"i18n.resources['@@lang_local@@'].@@NAMESPACENAME@@ = @@import_string@@;";
	Dictionary<string, string> dictJSON = new Dictionary<string, string>();
	string i18n_content = System.Text.Encoding.UTF8.GetString(resourceServiceClient.GetFileBody(token, "res://tenant/solutions2/lib/i18next/init.js", new ASF.Framework.Service.Domain.ResourcePathResolveInfo { Domain = domain, SolutionCode = string.Empty, VersionCode = string.Empty }).Body);
	string langData = String.Empty;
	string moment_local = String.Empty;
	string moment_content = String.Empty;
	string ext_local = String.Empty;
	string ext_content = String.Empty;

	Newtonsoft.Json.Linq.JObject jObject = Newtonsoft.Json.Linq.JObject.Parse(responseRuleResult);
	foreach (var data in jObject["DATA"][ruleNameExportData]["ITEMS"])
	{
		if (lang_local != getValue(data, "LANGCODE_LOCALE"))
		{
			// save a File
			if (!string.IsNullOrEmpty(sys_BINARY_RESPONSE))
			{
				if (!string.IsNullOrEmpty(moment_local) && moment_local != "null")
				{
					moment_content += System.Text.Encoding.UTF8.GetString(resourceServiceClient.GetFileBody(token, "res://tenant/solutions2/lib/moment-locale/" + moment_local + ".js", new ASF.Framework.Service.Domain.ResourcePathResolveInfo { Domain = domain, SolutionCode = string.Empty, VersionCode = string.Empty }).Body);
				}
				if (!string.IsNullOrEmpty(ext_local) && ext_local != "null")
				{
					ext_content += System.Text.Encoding.UTF8.GetString(resourceServiceClient.GetFileBody(token, "res://tenant/solutions2/lib/ext-locale/ext-locale-" + ext_local + ".js", new ASF.Framework.Service.Domain.ResourcePathResolveInfo { Domain = domain, SolutionCode = string.Empty, VersionCode = string.Empty }).Body);
				}
				import_string = Newtonsoft.Json.JsonConvert.SerializeObject(dictJSON, Newtonsoft.Json.Formatting.Indented);

				sys_BINARY_RESPONSE += fileContent.Replace("@@lang_local@@", lang_code).Replace("@@NAMESPACENAME@@", namespaceName).Replace("@@import_string@@", import_string);
				sys_BINARY_RESPONSE += ext_content;
				sys_BINARY_RESPONSE += moment_content;
				sys_BINARY_RESPONSE += i18n_content;
				byteArray = System.Text.Encoding.UTF8.GetBytes(sys_BINARY_RESPONSE);
				resourceServiceClient.PutFileOverride(token, folderPath, lang_local + ".js", lang_local + ".js", "application/javascript", byteArray, true, new ASF.Framework.Service.Domain.ResourcePathResolveInfo() { Domain = domain });

				sys_BINARY_RESPONSE = String.Empty;
				import_string = String.Empty;
				moment_content = String.Empty;
				moment_local = String.Empty;
				ext_local = String.Empty;
				ext_content = String.Empty;
				dictJSON.Clear();
			}
			lang_local = getValue(data, "LANGCODE_LOCALE");

			//Call the rule to getting a record of language data
			var param2 = new ASF.Framework.Service.Parameters.ParameterCollection();
			param2.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "LANGUAGECODE", Value = lang_local });
			var importDataToDB2 = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
			{
				DataCommand = ruleNameLanguageData,
				Domain = domain,
				Parameters = param2,
				Token = token
			});
			var outParameters2 = importDataToDB2.Data.GetParameters();
			if (outParameters2["ERRORMESSAGE"].Value != null)
			{
				throw new Exception(outParameters2["ERRORMESSAGE"].Value.ToString());
			}

			var responseRuleResult2 = importDataToDB2.Data.ToJson();
			Newtonsoft.Json.Linq.JObject jObject2 = Newtonsoft.Json.Linq.JObject.Parse(responseRuleResult2);
			foreach (var data2 in jObject2["DATA"][ruleNameLanguageData]["ITEMS"])
			{
				langData = data2.ToString();
				moment_local = getValue(data2, "MOMENTCODE");
				ext_local = getValue(data2, "EXTCODE");
				lang_code = getValue(data2, "PLURALCODE");
			}

			sys_BINARY_RESPONSE += fileHeader.Replace("@@CURENT_LANGUAGE_DATA@@", langData).Replace("@@lang_local@@", lang_code);
		}

		if (namespaceName != getValue(data, "NAMESPACENAME"))
		{
			if (!string.IsNullOrEmpty(namespaceName))
			{
				import_string = Newtonsoft.Json.JsonConvert.SerializeObject(dictJSON, Newtonsoft.Json.Formatting.Indented);
				sys_BINARY_RESPONSE += fileContent.Replace("@@lang_local@@", lang_code).Replace("@@NAMESPACENAME@@", namespaceName).Replace("@@import_string@@", import_string);
				import_string = String.Empty;
				dictJSON.Clear();
			}
			namespaceName = getValue(data, "NAMESPACENAME");
		}

		string keyName = getValue(data, "KEYNAME");
		string _context = getValue(data, "CONTEXT");
		string isPlurar = getValue(data, "ISPLURAL");
		string plurarForm = getValue(data, "PLURALFORM");
		string translateValue = getValue(data, "VALUE");
		string plurarFormCount = getValue(data, "PLURALFORMCOUNT");
		string _key = "";
		if ((string.IsNullOrEmpty(translateValue)) || (translateValue == "null"))
		{
			continue;
		}

		_key += keyName;
		if ((isPlurar == "1") && (plurarFormCount == "2"))
		{
			if (plurarForm == "1")
			{
				_key += (separatorIsPlurar + "plural");
			}
		}
		else if (isPlurar == "1")
		{
			_key += (separatorIsPlurar + plurarForm);
		}

		if (!string.IsNullOrEmpty(_context) && (_context != "null"))
		{
			_key += (separatorContext + _context);
		}

		if (!dictJSON.ContainsKey(_key))
		{
			dictJSON.Add(_key, HttpUtility.HtmlDecode(translateValue));
		}
	}

	// save a File
	if (!string.IsNullOrEmpty(sys_BINARY_RESPONSE))
	{
		import_string = Newtonsoft.Json.JsonConvert.SerializeObject(dictJSON, Newtonsoft.Json.Formatting.Indented);
		sys_BINARY_RESPONSE += fileContent.Replace("@@lang_local@@", lang_code).Replace("@@NAMESPACENAME@@", namespaceName).Replace("@@import_string@@", import_string);
		sys_BINARY_RESPONSE += ext_content;
		sys_BINARY_RESPONSE += moment_content;
		sys_BINARY_RESPONSE += i18n_content;

		byteArray = System.Text.Encoding.UTF8.GetBytes(sys_BINARY_RESPONSE);
		resourceServiceClient.PutFileOverride(token, folderPath, lang_local + ".js", lang_local + ".js", "application/javascript", byteArray, true, new ASF.Framework.Service.Domain.ResourcePathResolveInfo() { Domain = domain });
	}

	response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = string.Empty });
	response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = "The Translation Files generated." });
	response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = 0 });
}
catch (Exception ex)
{
	var errorMessage = ex.Message;
	response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = errorMessage });
	response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = string.Empty });
	response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = 101 });
}
