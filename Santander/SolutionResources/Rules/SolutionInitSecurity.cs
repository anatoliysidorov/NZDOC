var Logger = Common.Logging.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
try
{						
	var token =  request.AsString("Token");
	var domain =  request.AsString("TenantDomain");
	var roleCodes =  request.AsString("Roles");
	var userCode =  request.AsString("User");	

    ASF.Framework.Util.ValidationHelper.ValidateNotNullString(token, "token");	
	ASF.Framework.Util.ValidationHelper.ValidateNotNullString(domain, "domain");
	//ASF.Framework.Util.ValidationHelper.ValidateNotNullString(roleCodes, "roleCodes");
	//ASF.Framework.Util.ValidationHelper.ValidateNotNullString(userCode, "userCode");
	
	Logger.Debug("Domain:" + domain);
	Logger.Debug("Roles:" + roleCodes);
	Logger.Debug("User:" + userCode);
	
	string[] roles = roleCodes.Split(new string[]{";", ","}, StringSplitOptions.RemoveEmptyEntries)
	   .Select(s => s.Trim())
	   .Where(s => s != String.Empty)
	   .ToArray();
	var st = ASF.Framework.Security.SecurityToken.GetSecurityTokenFromString(token);
	try
	{
		var adminSvc = new ASF.Security.Service.Core.BaseAdministrationService();
		
		foreach (var role in roles)
		{	
			if (!string.IsNullOrEmpty(role))
			{
				Logger.Debug("Grant role:" + role +" to:" + userCode);
				adminSvc.GrantRoleToUserInternal(st,  domain, userCode, role);			
				Logger.Debug("Role" + role + " granted");
			}
		}
	}
	catch (Exception e)
	{
		Logger.Error("Unhandled Error:" + e);
		response["ErrorMessage"] = e.ToString();
		throw;
	}			
				
	response.Result.AddParameter(new Parameter { Name = "Status", Value = "Success" });						
}
catch (Exception e)
{
	response["ErrorMessage"] = e.ToString();
}