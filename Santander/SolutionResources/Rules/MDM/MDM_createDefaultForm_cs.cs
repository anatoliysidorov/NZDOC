var token = HttpUtility.UrlDecode(request.AsString("token"));
var domain = request.AsString("domain");
var formName = request.AsString("FormName");
var formCode = request.AsString("FormCode");
var caseTypeId = int.Parse(request.AsString("CaseTypeId"));
var bo_Name = request.AsString("BO_Name");
var bo_Id = int.Parse(request.AsString("BO_Id"));
var connectionString = request.AsString("CONNECTION_STRING");

try
{
	var parameters = new ASF.Framework.Service.Parameters.ParameterCollection();
	parameters.Add(new ASF.Framework.Service.Parameters.Parameter()
	{
		Name = "FormName",
		Value = formName 
	});

	parameters.Add(new ASF.Framework.Service.Parameters.Parameter()
	{
		Name = "FormCode",
		Value = formCode 
	});

	parameters.Add(new ASF.Framework.Service.Parameters.Parameter()
	{
		Name = "CaseTypeId",
		Value = caseTypeId 
	});

	parameters.Add(new ASF.Framework.Service.Parameters.Parameter()
	{
		Name = "BO_Name",
		Value = bo_Name 
	});

	parameters.Add(new ASF.Framework.Service.Parameters.Parameter()
	{
		Name = "BO_Id",
		Value = bo_Id 
	});

	parameters.Add(new ASF.Framework.Service.Parameters.Parameter()
	{
		Name = "token",
		Value = token 
	});

	parameters.Add(new ASF.Framework.Service.Parameters.Parameter()
	{
		Name = "domain",
		Value = domain 
	});

	var execResponse = DCM.Process.RuleHelper.AutoGenerateForm(new ASF.BDS.Rules.Common.RuleRequest()
	{
		Parameters = parameters
	});

	string errMsg = execResponse["ERRORMESSAGE"].ToString();
	if (!string.IsNullOrEmpty(errMsg)) 
	{	
		if(errMsg.Length > 252)
		{
			errMsg = errMsg.Substring(0, 252) + "...";
		}
		response["ERRORMESSAGE"] = errMsg;
		response["ERRORCODE"] = 102;
	}
	else 
	{
		response["ERRORMESSAGE"] = "";
		response["ERRORCODE"] = 0;
	}
        // for debug
        /*
        response["XML"] = execResponse["XML"];
        response["ERRORCODETEXT"] = execResponse["ERRORCODETEXT"];
        response["FORMID"] = execResponse["FORMID"];
        */
}
catch (Exception e)
{
	response["ERRORMESSAGE"] = e.ToString();
	response["ERRORCODE"] = 101;
}