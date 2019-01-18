Func<string, bool, string> getParam = (n, r) => Ecx.Rule.Helpers.BDSHelper.GetParameterAsString(request, n, r);
var token = getParam("TOKEN", true);
var domain = getParam("DOMAIN", true);
var taskId = getParam("TaskId", false);
var name = getParam("Name", false);
var ruleCode = "root_ltr_gen_by_code";
var inputParams = request.Parameters.Where(p => p.Name != "t").ToDictionary(p => p.Name, p => p.Value == null ? null : p.Value.ToString());

Func<XDocument, string, string> getValueFromResponse = LTR.Helpers.AppBaseHelper.GetValueFromResponse;
Func<string, Dictionary<string, string>, XDocument> executeRule = (c, p) => LTR.Helpers.AppBaseHelper.ExecuteRuleXml(token, domain, c, p);

// get Case Id
var caseIdRes = executeRule("root_ltr_dcm_task_get_case_id", new Dictionary<string, string> { { "TaskId", taskId } });
var caseId = getValueFromResponse(caseIdRes, "CASEID");
// get Product Type
var caseProdTypeRes = executeRule("root_CUST_getProductType", new Dictionary<string, string> { { "TaskId", taskId } });
var productType = getValueFromResponse(caseProdTypeRes, "PRODUCTTYPE");
var caseName = getValueFromResponse(caseProdTypeRes, "CASENAME");

inputParams["CASE_ID"] = caseId;
inputParams["ObjectId"] = caseId;
inputParams["Name"] = "19-B-"+ caseName + "-" + productType + "-" + name;
inputParams["ObjectType"] = "root_Case";
var ltrGenRes = executeRule(ruleCode, inputParams);

response.Result.AddParameter(new Parameter() { Name = "errorCode", Value = getValueFromResponse(ltrGenRes, "ERRORCODE") });
response.Result.AddParameter(new Parameter() { Name = "errorMessage", Value = getValueFromResponse(ltrGenRes, "ERRORMESSAGE") });