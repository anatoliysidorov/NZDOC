string taskId = request.AsString("taskid");
string domain = request.AsString("domain");
string token = request.AsString("token");

string RED = "D50000";
string GREEN = "00796B";
string YELLOW = "EF6C00";

string htmlResponse = "<html><head><style> div{background-color: #COLOR;font-weight: 500;font: 200% serif;color:white;border-radius: 50px;  padding: 30px;  }  body{margin: 200px;}</style></head><body><div>MESSAGE</div></body></html>";
           
try{

    var ruleParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
    ruleParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "taskId", Value = taskId });
    ruleParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "ResolutionId", Value = "0" });
    ruleParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Target", Value = "root_TSK_Status_CLOSED_DEFAULT" });

    var taskTransitionManualRequest = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
    {
        DataCommand = "root_DCM_taskTransitionManual",
        Domain = domain,
        Parameters = ruleParameters,
        Token = token,
	    VersionCode = null
    });
    var taskTransitionManualResponse = taskTransitionManualRequest.Data.GetParameters();

    string retval = taskTransitionManualResponse["errorMessage"].Value == null ? string.Format("Task {0} was closed",taskId) : taskTransitionManualResponse["errorMessage"].Value.ToString();
    string color = taskTransitionManualResponse["errorMessage"].Value == null ? GREEN : YELLOW;
    response["SYS_BINARY_RESPONSE"] = htmlResponse.Replace("MESSAGE",retval).Replace("COLOR",color);
    response["SYS_BINARY_CONTENT_TYPE"] = "text/html";

}catch(Exception e){
    response["SYS_BINARY_RESPONSE"] = htmlResponse.Replace("MESSAGE",e.ToString()).Replace("COLOR",RED);
    response["SYS_BINARY_CONTENT_TYPE"] = "text/html";
}