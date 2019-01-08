var Logger = Common.Logging.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
var token = HttpUtility.UrlDecode((string)request["token"]);
var appDomain = (string)request["domain"];
var CaseType_CMS_URL = (string)request["ImportURL"];
var rule_importCaseTypeXML = "root_UTIL_importDCMDataXML";
string xmlBody = "";
string xml_id = "";
try
{
	  Logger.Debug("Download start for :" + CaseType_CMS_URL);
       var t = ASF.Framework.Security.SecurityToken.GetSecurityTokenFromString(token);

       var svc = new ASF.Config.WebService.Core.BaseResourceService();

       var pathInfo = ASF.Config.Common.ResourceHelper.TryParseFilePath(CaseType_CMS_URL, rt => svc.GetRuntimeSolutionInfo(rt, t, t.Tenant, new ASF.Framework.Service.Domain.ResourcePathResolveInfo { Domain = appDomain }));
       ASF.Framework.Util.ValidationHelper.ValidateNotNullObject(pathInfo, "pathInfo");

       var result = svc.GetFileInternal(t, pathInfo);
	Logger.Debug("Download succeded for:" + CaseType_CMS_URL);
       xmlBody = System.Text.Encoding.UTF8.GetString(result);
    
	Logger.Debug("XmlBody :" + xmlBody);

	// insert a xml data into InsertXML table and return the new ID
	var dsClient0 = ASF.CoreLib.APIHelper.GetDataService(appDomain);
	var reqParam2 = new ASF.Framework.Service.Parameters.ParameterCollection();
	
	reqParam2.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.LargeText(), Name = "inputXML", Value  = xmlBody });
	var response_XMLID = dsClient0.Execute(
		ASF.Framework.Security.SecurityToken.GetSecurityTokenFromString(token),
		appDomain,
		string.Empty,
		"root_UTIL_insertXML", 
		reqParam2 
	);
	var resParams = response_XMLID.GetParameters();
	xml_id = resParams["newId"].Value == null? string.Empty:resParams["newId"].Value.ToString();

	// insert into QQ Evet
	var reqParam1 = new ASF.Framework.Service.Parameters.ParameterCollection();	
	
	reqParam1.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "XMLdata", Value  = xmlBody });
	reqParam1.AddParameter(new Parameter("XmlId", ParameterType.btype_number, ParameterDirection.Input, xml_id));
	
	Logger.Debug("Execute Import XML Start");
	
	var response1 = dsClient0.Execute(
		ASF.Framework.Security.SecurityToken.GetSecurityTokenFromString(token),
		appDomain,
		string.Empty,
		rule_importCaseTypeXML, 
		reqParam1 
	);
	Logger.Debug("Execute Import XML finish");
	
	var resParams1 = response1.GetParameters();
	response["ErrorCode"]       = resParams1["ERRORCODE"].Value      == null? string.Empty:resParams1["ERRORCODE"].Value.ToString();
	response["ErrorMessage"]    = resParams1["ERRORMESSAGE"].Value   == null? string.Empty:resParams1["ERRORMESSAGE"].Value.ToString();
	response["SuccessMessage"]  = resParams1["SUCCESSMESSAGE"].Value == null? string.Empty:resParams1["SUCCESSMESSAGE"].Value.ToString();
}
catch (Exception ex)
{
	var errorMessage = ex.ToString();
	response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = errorMessage });
	response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = "101" });
}