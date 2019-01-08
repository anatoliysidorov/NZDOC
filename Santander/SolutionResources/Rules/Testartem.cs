var token = request.AsString("token");
var domain =  request.AsString("domain");
var service = new DCM.DataManagement.DataManagementService(token, domain);
service.AutoGenerateFormByAPIs("root_CDM_TestErnesto");
response["asd"] = "Done";