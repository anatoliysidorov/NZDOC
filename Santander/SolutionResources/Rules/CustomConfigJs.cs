var token = HttpUtility.UrlDecode((string)request["token"]);
var domain = (string)request["domain"];
string languageCode = (string)request["LANGUAGE_LOCAL"];
string ruleNameLanguageData = "root_LOC_getLanguages";
string ruleNameExportData = "root_LOC_getExportData";
string ruleCodedPage = "root_FOM_getCodedPages";
string sys_BINARY_RESPONSE = "Boot().currentLanguageData = @@CURENT_LANGUAGE_DATA@@;";
string curent_LANGUAGE_DATA = String.Empty;
string jsCode = String.Empty;
string separatorIsPlurar = " #:"; // the value for isPlurar must be getting like true if separator is present
string separatorContext = " %:";  // the value for context must be getting like suffix
string langID = String.Empty;
string useDCM_GLOBAL_JS = (string)request["useDCM_GLOBAL_JS"];
ParameterCollection param = null;
ParameterCollection outParameters = null;
string responseRuleResult = string.Empty;
Newtonsoft.Json.Linq.JObject jObject = null;

Func<Newtonsoft.Json.Linq.JToken, string, string> getValue = (x, n) =>
{
    //var el = x[n].ToString().Replace("\"", string.Empty);
    var el = x.Value<string>(n);
    return !string.IsNullOrEmpty(el) ? el : String.Empty;
};

try
{
    if (string.IsNullOrEmpty(languageCode)) { throw new Exception("The Language code can not be empty"); }

    //Call the rule to getting a record of language data
    param = new ASF.Framework.Service.Parameters.ParameterCollection();
    param.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "LANGUAGECODE", Value = languageCode });
    var getLangResp = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
    {
        DataCommand = ruleNameLanguageData,
        Domain = domain,
        Parameters = param,
        Token = token,
        VersionCode = null
    });
    outParameters = getLangResp.Data.GetParameters();
    if (outParameters["ERRORMESSAGE"].Value != null)
    {
        throw new Exception(outParameters["ERRORMESSAGE"].Value.ToString());
    }

    responseRuleResult = getLangResp.Data.ToJson();
    jObject = Newtonsoft.Json.Linq.JObject.Parse(responseRuleResult);
    foreach (var data in jObject["DATA"][ruleNameLanguageData]["ITEMS"])
    {
        curent_LANGUAGE_DATA += data.ToString();
        langID = getValue(data, "ID");
    }

    if ((String.IsNullOrEmpty(langID)) || (langID == "null"))
    {
        //Call the rule for get a default record of laguage data
        param = new ASF.Framework.Service.Parameters.ParameterCollection();
        param.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "ISDEFAULT", Value = "1" });
        var getLangResp2 = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
        {
            DataCommand = ruleNameLanguageData,
            Domain = domain,
            Parameters = param,
            Token = token,
            VersionCode = null
        });
        var outParameters2 = getLangResp2.Data.GetParameters();
        if (outParameters2["ERRORMESSAGE"].Value != null)
        {
            throw new Exception(outParameters2["ERRORMESSAGE"].Value.ToString());
        }

        responseRuleResult = getLangResp2.Data.ToJson();
        jObject = Newtonsoft.Json.Linq.JObject.Parse(responseRuleResult);
        foreach (var data in jObject["DATA"][ruleNameLanguageData]["ITEMS"])
        {
            curent_LANGUAGE_DATA += data.ToString();
            langID = getValue(data, "ID");
        }
        sys_BINARY_RESPONSE = sys_BINARY_RESPONSE.Replace("@@CURENT_LANGUAGE_DATA@@", curent_LANGUAGE_DATA);
    }
    else
    {
        sys_BINARY_RESPONSE = sys_BINARY_RESPONSE.Replace("@@CURENT_LANGUAGE_DATA@@", curent_LANGUAGE_DATA);
    }

    if ((String.IsNullOrEmpty(langID)) || (langID == "null"))
    {
        throw new Exception("The Language ID not defined");
    }

    //Call the rule to getting an export data
    param = new ASF.Framework.Service.Parameters.ParameterCollection();
    param.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "LanguageID", Value = langID });
    var expDataResp = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
    {
        DataCommand = ruleNameExportData,
        Domain = domain,
        Parameters = param,
        Token = token,
        VersionCode = null
    });
    outParameters = expDataResp.Data.GetParameters();
    if (outParameters["ERRORMESSAGE"].Value != null)
    {
        throw new Exception(outParameters["ERRORMESSAGE"].Value.ToString());
    }

    responseRuleResult = expDataResp.Data.ToJson();

    string namespaceName = String.Empty;
    string import_string = String.Empty;
    string lang_local = String.Empty;
    string fileContent = @"Ext.ns('i18n.resources.@@lang_local@@');
i18n.resources['@@lang_local@@'].@@NAMESPACENAME@@ = @@import_string@@;";
    Dictionary<string, string> dictJSON = new Dictionary<string, string>();

    jObject = Newtonsoft.Json.Linq.JObject.Parse(responseRuleResult);
    foreach (var data in jObject["DATA"][ruleNameExportData]["ITEMS"])
    {
        if (namespaceName != getValue(data, "NAMESPACENAME"))
        {
            if (!string.IsNullOrEmpty(namespaceName))
            {
                import_string = Newtonsoft.Json.JsonConvert.SerializeObject(dictJSON, Newtonsoft.Json.Formatting.Indented);
                sys_BINARY_RESPONSE += fileContent.Replace("@@lang_local@@", lang_local).Replace("@@NAMESPACENAME@@", namespaceName).Replace("@@import_string@@", import_string);

                //and get new parameters
                import_string = "";
                dictJSON.Clear();
            }
            namespaceName = getValue(data, "NAMESPACENAME");
        }
        lang_local = getValue(data, "LANGCODE");
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

    if (dictJSON.Count > 0)
    {
        import_string = Newtonsoft.Json.JsonConvert.SerializeObject(dictJSON, Newtonsoft.Json.Formatting.Indented);
        sys_BINARY_RESPONSE += fileContent.Replace("@@lang_local@@", lang_local).Replace("@@NAMESPACENAME@@", namespaceName).Replace("@@import_string@@", import_string);
    }

    if (useDCM_GLOBAL_JS == "1")
    {
        //Call the rule to getting a record of specific Coded Page (code = DCM_GLOBAL_JS)
        param = new ASF.Framework.Service.Parameters.ParameterCollection();
        param.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "CodedPage_Code", Value = "DCM_GLOBAL_JS" });
        var codedPageResp = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
        {
            DataCommand = ruleCodedPage,
            Domain = domain,
            Parameters = param,
            Token = token,
            VersionCode = null
        });
        outParameters = codedPageResp.Data.GetParameters();
        if (outParameters["ERRORMESSAGE"].Value != null)
        {
            throw new Exception(outParameters["ERRORMESSAGE"].Value.ToString());
        }

        responseRuleResult = codedPageResp.Data.ToJson();
        jObject = Newtonsoft.Json.Linq.JObject.Parse(responseRuleResult);
        foreach (var data in jObject["DATA"][ruleCodedPage]["ITEMS"])
        {
            jsCode += getValue(data, "PAGEMARKUP");
            jsCode = System.Web.HttpUtility.HtmlDecode(jsCode);
        }

        if (!String.IsNullOrEmpty(jsCode))
        {
            sys_BINARY_RESPONSE += jsCode;
        }
    }

    // return the main data
    response["SYS_BINARY_RESPONSE"] = sys_BINARY_RESPONSE;
    response["SYS_BINARY_CONTENT_TYPE"] = "application/javascript";
}
catch (Exception ex)
{
    var errorMessage = ex.Message;
    response["SYS_BINARY_RESPONSE"] = "Boot().currentLanguageData = null;";
    response["SYS_BINARY_CONTENT_TYPE"] = "application/javascript";
}
