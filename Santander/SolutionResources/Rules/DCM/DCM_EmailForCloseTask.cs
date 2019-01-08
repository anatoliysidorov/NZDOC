int errorCode = 0;
string errorMessage = string.Empty;
string successResponse = string.Empty;

string taskId = request.AsString("taskid");
string domain = request.AsString("domain");
string token = request.AsString("token");
string dataServiceRest = ConfigurationManager.AppSettings["DataServiceRest"];

if (string.IsNullOrEmpty(taskId)) 
{
    errorCode = 5;
    errorMessage = "Task id is required for this operation";
    goto Validation;
}

string htmlEmail = "<html><head></head><body><div style=\"color:rgb(0,0,0);font-family:tahoma,arial,helvetica,sans-serif;font-size:medium;\">Dear, NAME,</div><div style=\"font-family:helvetica; font-size: 14px\">You may close task with id TASKID by this <a href=\"DATA_SERVICE_REST/get.bin/DOMAIN/root_DCM_closeTaskByLink?taskId=TASKID&t=TOKEN\">link</a>.</div><img src=\"http://www.waterlinedata.com//logos/logo-waterlinedata-580x110.jpg\" style=\"padding: 20px; width: 250px\"/><div style=\"font-family:helvetica; font-size: 14px\"><b>Connection the right people to the right data</b></div></body></html>";
try
{
    using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
    {
        var taskInfoParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
        taskInfoParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "taskId", Value = taskId });

        var taskInfoRequest = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
        {
            DataCommand = "root_DCM_taskInfoForEmail",
            Domain = domain,
            Parameters = taskInfoParameters,
            Token = token
        });
        var taskInfoResponse = taskInfoRequest.Data.ToXml();

        XmlDocument doc = new XmlDocument();
        doc.LoadXml(taskInfoResponse.ToString());

        var items = doc.SelectNodes("//DATA/root_DCM_taskInfoForEmail/ITEMS");

        if (items.Count == 0)
        {
            errorCode = 2;
            errorMessage = string.Format("Can not find info about task {0}", taskId);
            goto Validation;
        }

        var emailNode = items[0].SelectSingleNode("EMAIL");
        var fullNameNode = items[0].SelectSingleNode("FULLNAME");

        if (emailNode == null)
        {
            errorCode = 3;
            errorMessage = string.Format("Can not find info about email recipient for task {0}", taskId);
            goto Validation;
        }

        string email = emailNode.InnerXml;
        string name = string.IsNullOrEmpty(fullNameNode.InnerXml) ? "Recipient" : fullNameNode.InnerXml;

        htmlEmail = htmlEmail.Replace("TOKEN", token).Replace("TASKID", taskId).Replace("DOMAIN", domain).Replace("NAME", name).Replace("DATA_SERVICE_REST", dataServiceRest);

        var emailSendParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
        emailSendParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "to", Value = email });
        emailSendParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "subject", Value = "Confirmation" });
        emailSendParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "html", Value = htmlEmail });

        var emailSendRequest = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
        {
            DataCommand = "root_LTR_sendEmail",
            Domain = domain,
            Parameters = emailSendParameters,
            Token = token
        });

        var emailSendResponse = emailSendRequest.Data.GetParameters();

        if (!string.IsNullOrEmpty(emailSendResponse["errorMessage"].Value.ToString()))
        {
            errorCode = 4;
            errorMessage = emailSendResponse["errorMessage"].Value.ToString();
            goto Validation;
        }

        successResponse = emailSendResponse["successResponse"].Value.ToString();
    }

}
catch (Exception e)
{
    errorCode = 1;
    errorMessage = e.ToString();
    goto Validation;
}

Validation:
    response["errorCode"] = errorCode;
    response["errorMessage"] = errorMessage;
    response["successResponse"] = successResponse;