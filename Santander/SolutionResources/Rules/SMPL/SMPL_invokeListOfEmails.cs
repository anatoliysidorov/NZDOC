	var token = HttpUtility.UrlDecode((string)request["token"]);
	var sysdomain = (string)request["TOKEN_SYSTEMDOMAIN"];
	var appDomain = (string)request["domain"];
	//var TaskId = (string)request["TaskId"];

	//task event invoker name 
	const string taskEventInvokerRule = "root_EVN_invokeTaskEventCalc";
	
	//system info
	string errorMessage = null;
	var errorCode = 0;
	
	//call invoker
	try{
		var inputParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
			
		inputParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "TaskId", Value = 777 });
		inputParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(),   Name = "ProcessorCode", Value = "f_SMPL_getListOfEmails"});
		
		var invokerResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
									{
										DataCommand = taskEventInvokerRule, 
										Domain = appDomain, 
										Parameters = inputParameters, 
										Token = token
									});
		var invokerOutputParams = invokerResult.Data.GetParameters();

		response["Result"]		 = invokerOutputParams["RESULT"].Value == null?string.Empty:invokerOutputParams["RESULT"].Value.ToString(); 
		response["ErrorCode"] 	 = invokerOutputParams["ERRORCODE"].Value == null?string.Empty:invokerOutputParams["ERRORCODE"].Value.ToString();
		response["ErrorMessage"] = invokerOutputParams["ERRORMESSAGE"].Value == null?string.Empty:invokerOutputParams["ERRORMESSAGE"].Value.ToString();
	}
	catch (Exception ex){
		response["ErrorMessage"] = ex.ToString();
	}
		