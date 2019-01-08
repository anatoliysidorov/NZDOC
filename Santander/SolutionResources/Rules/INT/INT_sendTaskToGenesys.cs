const string getTaskDetailRule = "root_DCM_getTaskDetailPage";
const string getCaseDetailRule = "root_DCM_getCaseDetailPage";
const string getInvokerRule = "root_EVN_invokeTaskEventCalc";

var token = request.AsString("token");
var sysDomain = request.AsString("TOKEN_SYSTEMDOMAIN");
var appDomain = request.AsString("domain");
var TaskId = request.AsString("TaskId");
var CaseId = request.AsString("CaseId");

var channel = string.IsNullOrEmpty(request.AsString("Channel")) ? "workitem" : request.AsString("Channel");
var category = string.IsNullOrEmpty(request.AsString("Category")) ? "DCM_WORKITEM" : request.AsString("Category");
var mediatype = string.IsNullOrEmpty(request.AsString("webform")) ? "workitem" : request.AsString("MediaType");

var PageSend1 = request.AsString("PageSend1");
var PageCode1 = string.IsNullOrEmpty(request.AsString("PageCode1")) ? "root_UTIL_BasePage" : request.AsString("PageCode1");
var PageSendParams1 = string.IsNullOrEmpty(request.AsString("PageSendParams1")) ? "<CustomData><Attributes></Attributes></CustomData>" : request.AsString("PageSendParams1");
var PageSendParamsRule1 = string.IsNullOrEmpty(request.AsString("PageSendParamsRule1")) ? "f_SMPL_getFakeCustomData" : request.AsString("PageSendParamsRule1");

var PageSend2 = request.AsString("PageSend2");
var PageCode2 = string.IsNullOrEmpty(request.AsString("PageCode2")) ? "root_UTIL_BasePage" : request.AsString("PageCode2");
var PageSendParams2 = string.IsNullOrEmpty(request.AsString("PageSendParams2")) ? "<CustomData><Attributes></Attributes></CustomData>" : request.AsString("PageSendParams2");
var PageSendParamsRule2 = string.IsNullOrEmpty(request.AsString("PageSendParamsRule2")) ? "f_SMPL_getFakeCustomData" : request.AsString("PageSendParamsRule2");

var CustomDataInputParameter = string.IsNullOrEmpty(request.AsString("CustomData")) ? "<CustomData><Attributes></Attributes></CustomData>" : request.AsString("CustomData");
var CustomDataRule = string.IsNullOrEmpty(request.AsString("CustomDataRule")) ? "f_SMPL_getFakeCustomData" : request.AsString("CustomDataRule");

var errorCode = 0;
var errorMessage = string.Empty;

string getDetailRule = string.Empty;
XmlDocument document;
XmlNode mainNode;
string externalId = string.Empty;

if (string.IsNullOrEmpty(PageSend1)) { PageSend1 = "OTHER"; }
if (string.IsNullOrEmpty(PageSend2)) { PageSend2 = "NONE"; }


//----------------------------Calculate case Id-----------------------------------------------DCM-1721 [1] by Lavrushenko coment
if (string.IsNullOrEmpty(CaseId))
{
    var getCaseInfoParameters = new ASF.Framework.Service.Parameters.ParameterCollection();

    getCaseInfoParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "TaskId", Value = TaskId });

    var caseInfoRquest = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
    {
        DataCommand = "root_CUST_GTel_getCaseInfo",
        Domain = appDomain,
        Parameters = getCaseInfoParameters,
        Token = token
    });

    var caseInfoResponse = caseInfoRquest.Data.GetParameters();
    CaseId = caseInfoResponse["Case_Id"].Value.ToString() != "0" ? caseInfoResponse["Case_Id"].Value.ToString() : null;
}
if (string.IsNullOrEmpty(TaskId) && string.IsNullOrEmpty(CaseId))  { errorMessage = "Task id or case id is required fields for this operation"; goto Validation; }
//----------------------------Get PageSends 1-----------------------------------------------DCM-1721 [2] by Lavrushenko coment


var v_CalcPageParams1 = new ASF.Framework.Service.Parameters.ParameterCollection();
v_CalcPageParams1.AddParameter(new Parameter("appid", ASF.Framework.Service.Parameters.ParameterType.Text(), System.Data.ParameterDirection.Input, "root_CaseManagement"));
v_CalcPageParams1.AddParameter(new Parameter("d", ASF.Framework.Service.Parameters.ParameterType.Text(), System.Data.ParameterDirection.Input, appDomain));
v_CalcPageParams1.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "Task_Id", Value = TaskId });
v_CalcPageParams1.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "Case_Id", Value = CaseId });

if (PageSend1 != "OTHER")
{
    //--get default data--
    var inputDetailRuleParameters1 = new ASF.Framework.Service.Parameters.ParameterCollection();

    inputDetailRuleParameters1.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "Task_Id", Value = TaskId });
    inputDetailRuleParameters1.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "Case_Id", Value = CaseId });

    getDetailRule = PageSend1 == "TASK" ? getTaskDetailRule : getCaseDetailRule;

    var detailRuleRequest1 = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
    {
        DataCommand = getDetailRule,
        Domain = appDomain,
        Parameters = inputDetailRuleParameters1,
        Token = token
    });

    var detailRuleResponse1 = detailRuleRequest1.Data.GetParameters();

    if (detailRuleResponse1["CUR_PARAMS"].Value == null)
    {
        errorMessage = "Page params data is empty";
        goto Validation;
    }
    if (detailRuleResponse1["ERRORMESSAGE"].Value != null)
    {
        errorMessage = string.Format("Error message from rule {0} : {1}", getDetailRule,
            detailRuleResponse1["ERRORMESSAGE"].Value.ToString());
        goto Validation;
    }
    PageCode1 = detailRuleResponse1["PAGECODE"].Value.ToString();

    var curParams1 = (System.Data.DataTable)detailRuleResponse1["CUR_PARAMS"].Value;

    foreach (DataRow row in curParams1.Rows)
    {
        v_CalcPageParams1.AddParameter(new Parameter(row["NAME"].ToString(),
            ASF.Framework.Service.Parameters.ParameterType.Text(), System.Data.ParameterDirection.Input,
            row["VALUE"].ToString()));
    }

    //--get data from invoke--
    var invokePage1Params = new ASF.Framework.Service.Parameters.ParameterCollection();
    invokePage1Params.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "ProcessorCode", Value = PageSendParamsRule1 });
    invokePage1Params.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "TaskId", Value = TaskId });
    invokePage1Params.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "CaseId", Value = CaseId });


    var invokePage1ParamsRequest = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
    {
        DataCommand = getInvokerRule,
        Domain = appDomain,
        Parameters = invokePage1Params,
        Token = token
    });


    var invokePage1ParamsResponse = invokePage1ParamsRequest.Data.GetParameters();
    string xmlPage1Data = invokePage1ParamsResponse["RESULT"].Value != null
        ? invokePage1ParamsResponse["RESULT"].Value.ToString()
        : string.Empty;

    if (string.IsNullOrEmpty(xmlPage1Data))
    {
        errorMessage = "Xml data root_EVN_invokeTaskEventCalc is empty";
        goto Validation;
    }

    document = new XmlDocument();
    document.LoadXml(xmlPage1Data);
    mainNode = document.SelectSingleNode("CustomData/Attributes");

    foreach (XmlNode node in mainNode)
    {
        var nodeName = node.Name;
        var nodeValue = node.InnerText;
        var parameter = new Parameter(nodeName, ASF.Framework.Service.Parameters.ParameterType.Text(), System.Data.ParameterDirection.Input, nodeValue);
        if (v_CalcPageParams1.ContainsKey(nodeName)) { continue; }

        v_CalcPageParams1.AddParameter(parameter);
    }


    //--get data from input parameter--
    document = new XmlDocument();
    document.LoadXml(PageSendParams1);
    mainNode = document.SelectSingleNode("CustomData/Attributes");

    foreach (XmlNode node in mainNode)
    {
        var nodeName = node.Name;
        var nodeValue = node.InnerText;
        var parameter = new Parameter(nodeName, ASF.Framework.Service.Parameters.ParameterType.Text(),
            System.Data.ParameterDirection.Input, nodeValue);
        if (v_CalcPageParams1.ContainsKey(nodeName)) { continue; }
        v_CalcPageParams1.AddParameter(parameter);
    }
}
//----------------------------Get PageSends 2-----------------------------------------------DCM-1721 [3] by Lavrushenko coment

var v_CalcPageParams2 = new ASF.Framework.Service.Parameters.ParameterCollection();
v_CalcPageParams2.AddParameter(new Parameter("appid", ASF.Framework.Service.Parameters.ParameterType.Text(), System.Data.ParameterDirection.Input, "root_CaseManagement"));
v_CalcPageParams2.AddParameter(new Parameter("d", ASF.Framework.Service.Parameters.ParameterType.Text(), System.Data.ParameterDirection.Input, appDomain));
v_CalcPageParams2.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "Task_Id", Value = TaskId });
v_CalcPageParams2.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "Case_Id", Value = CaseId });


if (PageSend2 != "OTHER" && PageSend2 != "NONE")
{
    //--get default data--
    var inputDetailRuleParameters2 = new ASF.Framework.Service.Parameters.ParameterCollection();

    inputDetailRuleParameters2.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "Task_Id", Value = TaskId });
    inputDetailRuleParameters2.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "Case_Id", Value = CaseId });

    getDetailRule = PageSend2 == "TASK" ? getTaskDetailRule : getCaseDetailRule;

    var detailRuleRequest2 = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
    {
        DataCommand = getDetailRule,
        Domain = appDomain,
        Parameters = inputDetailRuleParameters2,
        Token = token
    });

    var detailRuleResponse2 = detailRuleRequest2.Data.GetParameters();

    if (detailRuleResponse2["CUR_PARAMS"].Value == null)
    {
        errorMessage = "Page params data is empty";
        goto Validation;
    }
    if (detailRuleResponse2["ERRORMESSAGE"].Value != null)
    {
        errorMessage = string.Format("Error message from rule {0} : {2}", getDetailRule,
            detailRuleResponse2["ERRORMESSAGE"].Value.ToString());
        goto Validation;
    }
    PageCode2 = detailRuleResponse2["PAGECODE"].Value.ToString();

    var curParams2 = (System.Data.DataTable)detailRuleResponse2["CUR_PARAMS"].Value;

    foreach (DataRow row in curParams2.Rows)
    {
        v_CalcPageParams2.AddParameter(new Parameter(row["NAME"].ToString(),
            ASF.Framework.Service.Parameters.ParameterType.Text(), System.Data.ParameterDirection.Input,
            row["VALUE"].ToString()));
    }

    //--get data from invoke--
    var invokePage2Params = new ASF.Framework.Service.Parameters.ParameterCollection();
    invokePage2Params.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "ProcessorCode", Value = PageSendParamsRule2 });
    invokePage2Params.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "TaskId", Value = TaskId });
    invokePage2Params.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "CaseId", Value = CaseId });


    var invokePage2ParamsRequest = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
    {
        DataCommand = getInvokerRule,
        Domain = appDomain,
        Parameters = invokePage2Params,
        Token = token
    });


    var invokePage2ParamsResponse = invokePage2ParamsRequest.Data.GetParameters();
    string xmlPage2Data = invokePage2ParamsResponse["RESULT"].Value != null
        ? invokePage2ParamsResponse["RESULT"].Value.ToString()
        : string.Empty;

    if (string.IsNullOrEmpty(xmlPage2Data))
    {
        errorMessage = "Xml data root_EVN_invokeTaskEventCalc is empty";
        goto Validation;
    }

    document = new XmlDocument();
    document.LoadXml(xmlPage2Data);
    mainNode = document.SelectSingleNode("CustomData/Attributes");

    foreach (XmlNode node in mainNode)
    {
        var nodeName = node.Name;
        var nodeValue = node.InnerText;
        var parameter = new Parameter(nodeName, ASF.Framework.Service.Parameters.ParameterType.Text(), System.Data.ParameterDirection.Input, nodeValue);
        if (v_CalcPageParams2.ContainsKey(nodeName)) { continue; }

        v_CalcPageParams2.AddParameter(parameter);
    }


    //--get data from input parameter--
    document = new XmlDocument();
    document.LoadXml(PageSendParams2);
    mainNode = document.SelectSingleNode("CustomData/Attributes");

    foreach (XmlNode node in mainNode)
    {
        var nodeName = node.Name;
        var nodeValue = node.InnerText;
        var parameter = new Parameter(nodeName, ASF.Framework.Service.Parameters.ParameterType.Text(),
            System.Data.ParameterDirection.Input, nodeValue);
        if (v_CalcPageParams2.ContainsKey(nodeName)) { continue; }
        v_CalcPageParams2.AddParameter(parameter);
    }
}
//----------------------------Get v_CalcCustomParams-----------------------------------------------DCM-1721 [2] by Lavrushenko coment 
var v_CalcCustomParams = new ASF.Framework.Service.Parameters.ParameterCollection();

var invokeTaskParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
invokeTaskParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "ProcessorCode", Value = CustomDataRule });
invokeTaskParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "TaskId", Value = TaskId });
invokeTaskParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "CaseId", Value = CaseId });

var invokeTaskRequest = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
{
    DataCommand = getInvokerRule,
    Domain = appDomain,
    Parameters = invokeTaskParameters,
    Token = token
});

var invokeTaskResponse = invokeTaskRequest.Data.GetParameters();
string xmlData = invokeTaskResponse["RESULT"].Value != null ? invokeTaskResponse["RESULT"].Value.ToString() : string.Empty;

if (string.IsNullOrEmpty(xmlData)) { errorMessage = "Xml data root_EVN_invokeTaskEventCalc is empty"; goto Validation; }
//------------add to v_CalcCustomParams values from envoke-----------
document = new XmlDocument();
document.LoadXml(xmlData);
mainNode = document.SelectSingleNode("CustomData/Attributes");

foreach (XmlNode node in mainNode)
{
    var nodeName = node.Name;
    var nodeValue = node.InnerText;
    var parameter = new Parameter(nodeName, ASF.Framework.Service.Parameters.ParameterType.Text(), System.Data.ParameterDirection.Input, nodeValue);
    if (v_CalcCustomParams.ContainsKey(nodeName)) { continue; }

    v_CalcCustomParams.AddParameter(parameter);
}
//---get data from input parameter----

document = new XmlDocument();
document.LoadXml(CustomDataInputParameter);
mainNode = document.SelectSingleNode("CustomData/Attributes");

foreach (XmlNode node in mainNode)
{
    var nodeName = node.Name;
    var nodeValue = node.InnerText;
    var parameter = new Parameter(nodeName, ASF.Framework.Service.Parameters.ParameterType.Text(), System.Data.ParameterDirection.Input, nodeValue);
    if (v_CalcCustomParams.ContainsKey(nodeName)) { continue; }

    v_CalcCustomParams.AddParameter(parameter);
}
v_CalcCustomParams.AddParameter(new Parameter("DCM_CATEGORY", ASF.Framework.Service.Parameters.ParameterType.Text(), System.Data.ParameterDirection.Input, "DCM_WORKITEM"));
v_CalcCustomParams.AddParameter(new Parameter("viewname", ASF.Framework.Service.Parameters.ParameterType.Text(), System.Data.ParameterDirection.Input, "DCM Task"));
v_CalcCustomParams.AddParameter(new Parameter("viewname2", ASF.Framework.Service.Parameters.ParameterType.Text(), System.Data.ParameterDirection.Input, "DCM Case"));

//----------------------------Record parameters about to sent to Genesys API----------------- (MGill code on March 23, 2017)
Dictionary<string, string> genParamLog = new Dictionary<string, string>();
genParamLog.Add("Channel", channel);
genParamLog.Add("Category", category);
genParamLog.Add("MediaType", mediatype);
genParamLog.Add("BusinessValue", "100");
genParamLog.Add("Priority", "100");
genParamLog.Add("Parameters", v_CalcCustomParams.SerializeToJsonLight());
genParamLog.Add("PageCode", PageCode1);
genParamLog.Add("PageParameters", v_CalcPageParams1.SerializeToJsonLight());
genParamLog.Add("PageCode2", PageCode2);
genParamLog.Add("PageParameters2", v_CalcPageParams2.SerializeToJsonLight());
XElement el = new XElement("root",genParamLog.Select(kv => new XElement(kv.Key, kv.Value)));
response["genPramLog"] = el.ToString(SaveOptions.DisableFormatting);

//----------------------------Genesys API call-----------------------------------------------DCM-1721 [4] by Lavrushenko coment 
using (var integrationClent = new ASF.Genesys.WebService.Proxy.IntegrationServiceSvc.IntegrationServiceClient())
{
    var createTaskRequest = new ASF.Genesys.WebService.Messages.CreateTaskRequest()
    {
        Code = "testCode",
        Domain = appDomain,
        Token = token,
        Data = new ASF.Genesys.Common.Domain.CreateTaskData()
        {
            CaptureId = Guid.NewGuid().ToString(),
            Channel = channel,
            Category = category,
            MediaType = mediatype,
            CreatedDateTime = null,
            ActivationDateTime = null,
            DueDateTime = null,
            ExpirationDateTime = null,
            BusinessValue = 100,
            Priority = 100,
            ProcessId = null,
            CustomerId = null,
            Hold = null,
            Reason = null,
            Actor = null,
            Parameters = v_CalcCustomParams,
            PageCode = PageCode1,
            PageParameters = v_CalcPageParams1,
            PageCode2 = PageCode2,
            PageParameters2 = v_CalcPageParams2
            /*,viewname  = "DCM1", TODO [2] : no suggestions
                viewname  = "DCM2"   TODO [2] : no suggestions */

        }
    };
    try
    {
        var createTaskResp = integrationClent.CreateTask(createTaskRequest);
        //----------------------------Store custom data-----------------------------------------------DCM-1721 [5] by Lavrushenko coment 
        if (createTaskResp != null)
        {

            if (!string.IsNullOrEmpty(createTaskResp.ErrorMessage))
            {
                errorMessage = "ASF.Genesys.WebService.Proxy.IntegrationServiceSvc: " + createTaskResp.ErrorMessage;
                goto Validation;
            }
            //here your genesys ID
            externalId = createTaskResp.ExternalId; //generated by Genesys iWD
            response["ExternalId"] = externalId;

            var updateTaskIParams = new ASF.Framework.Service.Parameters.ParameterCollection();
            updateTaskIParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "TaskId", Value = TaskId });
            updateTaskIParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "ExternalId", Value = externalId });
            var updateTaskResponse = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
            {
                DataCommand = "root_CUST_GB_storeTaskInfo",
                Domain = appDomain,
                Parameters = updateTaskIParams,
                Token = token
            });
            var updateTaskOParams = updateTaskResponse.Data.GetParameters();
            string error = updateTaskOParams["ErrorMessage"].Value == null ? string.Empty : updateTaskOParams["ErrorMessage"].Value.ToString();
            errorMessage = string.IsNullOrEmpty(error) ? string.Empty : "Store task info rule: " + error;

        }
        else
        {
            errorMessage = "CreateTask Response is null";
            goto Validation;
        }
    }
    catch (Exception ex)
    {
        errorMessage = "ASF.Genesys.WebService.Proxy.IntegrationServiceSvc: " + ex.Message;
        goto Validation;
    }
}

Validation:
if (!string.IsNullOrEmpty(errorMessage))
{
    response["ErrorCode"] = 122;
    response["ErrorMessage"] = errorMessage;
}
else
{
    response["SuccessResponse"] = "Genesys API was called";
}