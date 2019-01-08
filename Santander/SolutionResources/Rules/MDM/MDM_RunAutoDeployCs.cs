try{
    
    string tenantConfigurationServiceRest = request.AsString("TENANT_CONFIGURATION_SERVICE_REST");
    string token           = request.AsString("token");
    string domain          = request.AsString("domain");
    string sid             = request.AsString("sid");
    string versionCode     = request.AsString("versionCode");
    string environmentCode = request.AsString("environmentCode");
    string action = string.IsNullOrEmpty(request.AsString("action")) ?  "run-auto-deploy" : request.AsString("action");
    int sleep     = string.IsNullOrEmpty(request.AsString("sleep"))  ? 15000              :  int.Parse(request.AsString("sleep"));

    var requestParams = new Dictionary<string, object>();
    requestParams.Add("tenantConfigurationServiceRest", tenantConfigurationServiceRest);
    requestParams.Add("token", token);
    requestParams.Add("sid", sid);
    requestParams.Add("versionCode", versionCode);
    requestParams.Add("environmentCode", environmentCode);
    requestParams.Add("action", action);
    requestParams.Add("sleep", sleep);
    AppBaseHelpers.BdsHelper.Init(token,domain);
    response = DCM.Process.RuleHelper.RunAutoDeploy(new RuleRequest(requestParams));

}catch(Exception e){
    response["ErrorCode"] = 101;
    response["ErrorMessage"] = e.ToString();
}