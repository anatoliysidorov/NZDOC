var token = HttpUtility.UrlDecode((string)request["token"]);
var appDomain = (string)request["domain"];

var CaseType_Id = (string)request["ExportCaseTypeId"];
var CaseType_Code = string.Empty;
var ExportDictionaries = (string)request["ExportDictionaries"];
var CustomBOTags = (string)request["CustomBOTags"];
var rule_exportCaseTypeXML = "root_UTIL_exportDCMDataXML";
var rule_getCaseTypeInfo = "root_STP_getCaseTypes";

string cmsFileName = "GlobalDictionaries_";
string cmsUri = "";
string caseTypeXML = "";
int errorCode = 0;

try
{
	if (!string.IsNullOrEmpty(CaseType_Id) && CaseType_Id!="0") {
		var reqParamCode = new ParameterCollection();
		reqParamCode.AddParameter(new Parameter("CaseType_Id", ParameterType.Number(), ParameterDirection.Input, CaseType_Id));
		var requestCode = new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = rule_getCaseTypeInfo, Domain = appDomain, Token = token, Parameters = reqParamCode,
		};
		var responseCode = ASF.CoreLib.APIHelper.BDSExecute(requestCode);
		var ResultJson = responseCode.Data.ToJson();
		Newtonsoft.Json.Linq.JObject jObject = Newtonsoft.Json.Linq.JObject.Parse(ResultJson );
		var item = jObject["DATA"][rule_getCaseTypeInfo ]["ITEMS"][0]["CODE"];
		var resParamsCode = responseCode.Data.GetParameters();
		CaseType_Code = item.ToString().Replace("\"", string.Empty);

		cmsFileName = cmsFileName+"CaseType_"+CaseType_Code+"_";
	}

	cmsFileName = cmsFileName+DateTime.Now.ToString("yyyy-MMM-dd-HH-mm-ss")+".xml";
	cmsUri = "cms:///" + cmsFileName;

	var reqParam1 = new ParameterCollection();
	reqParam1.AddParameter(new Parameter("ExportCaseTypeId", ParameterType.Number(), ParameterDirection.Input, CaseType_Id));
	reqParam1.AddParameter(new Parameter("ExportDictionaries", ParameterType.Number(), ParameterDirection.Input, ExportDictionaries));
	reqParam1.AddParameter(new Parameter("CustomBOTags", ParameterType.LargeText(), ParameterDirection.Input, CustomBOTags));
	var request1 = new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = rule_exportCaseTypeXML, Domain = appDomain, Token = token, Parameters = reqParam1,
	};
	var response1 = ASF.CoreLib.APIHelper.BDSExecute(request1);
	var resParams1 = response1.Data.GetParameters();
	Int32.TryParse(resParams1["ErrorCode"].Value.ToString(), out errorCode);

	response["ErrorCode"] = errorCode;
	response["ErrorMessage"] = resParams1["ErrorMessage"].Value;
	response["SuccessMessage"] = resParams1["SuccessMessage"].Value;
	caseTypeXML = (string) resParams1["XMLdata"].Value;
	
	if (errorCode == 0) {
		var fileContent = caseTypeXML;
		using (var cmsClient = new ASF.CMS.WebService.Proxy.CMSServiceSvc.CMSServiceClient())
		{
			var cmsRequest = new ASF.CMS.WebService.Messages.CreateResourceRequest()
			{
				Token = token,
				Domain = appDomain,
				Url = cmsUri,
				Resource = new ASF.CMS.Common.Domain.Resource()
				{
					Buffer = System.Text.Encoding.UTF8.GetBytes(fileContent),
					ContentType = "text/plain",
					Length = fileContent.Length,
					OriginalFileName = cmsFileName
				}
			};

			var res = cmsClient.CreateResource(cmsRequest);
			string resultUrl  = res.Url;
			response.Result.AddParameter(new Parameter() { Name = "ExportURL", Value = resultUrl });
		}
	}

}
catch (Exception ex)
{
	var errorMessage = ex.ToString();
	response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = errorMessage });
	response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = "101" });
}