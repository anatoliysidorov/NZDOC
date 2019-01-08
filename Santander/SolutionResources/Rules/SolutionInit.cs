var Logger = Common.Logging.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
				try
				{						
					var token =  request.AsString("Token");
					var solDomain =  request.AsString("domain");
					var tenantDomain =  request.AsString("TenantDomain");
					
					string securityInitRule = "root_SolutionInitSecurity";
					string initDataRule = "root_SolutionInitData";
					string resFileUrl = @"res://tenant/solutions2/lib/BaseConfig.xml";

					
					Logger.Debug("Imput request parameters:");
					foreach (var v in request.Parameters)
					{
						Logger.Debug("Parameter: " + v.Name + " Value:" + v.Value);
					}
					
					var assignedRoleCode = solDomain + "_root_Administrator"+","+solDomain + "_root_CaseWorker";
					Logger.Debug("Role to assign:" + assignedRoleCode);
					
					ASF.Framework.Service.Parameters.ParameterCollection securityParms = new ASF.Framework.Service.Parameters.ParameterCollection();
					//add custom parameter
					securityParms.AddParameter(new Parameter("Roles", ParameterType.btype_text, ParameterDirection.Input, assignedRoleCode));										
					//add all parameters from request 
					securityParms.AddRange(request.Parameters);					
					
					ASF.Framework.Service.Parameters.ParameterCollection initDataParms = new ASF.Framework.Service.Parameters.ParameterCollection();
					//add custom parameter
					initDataParms.AddParameter(new Parameter("ResFileImportURL", ParameterType.btype_text, ParameterDirection.Input, resFileUrl));					
					//add all parameters from request 
					initDataParms.AddRange(request.Parameters);					
					
									
					var securityRuleResp = new ASF.BDS.WebService.Messages.ExecuteResponse();					
					var dataRuleResp = new ASF.BDS.WebService.Messages.ExecuteResponse();
					
					var initSecurityRequest = new ASF.BDS.WebService.Messages.ExecuteRequest()
					{
						Parameters = securityParms,
						Domain = solDomain,
						Token = token,
						DataCommand = securityInitRule,
						VersionCode = null
					};
					
					var initDataRequest = new ASF.BDS.WebService.Messages.ExecuteRequest()
					{
						Parameters = initDataParms,
						Domain = solDomain,
						Token = token,
						DataCommand = initDataRule,
						VersionCode = null
					};					
					
					
					Logger.Debug("Execute rule start:" + securityInitRule);
					securityRuleResp = ASF.CoreLib.APIHelper.BDSExecute(initSecurityRequest);					
					Logger.Debug("Execute rule finish:" + securityInitRule);
					
					if (!string.IsNullOrEmpty(securityRuleResp.ErrorMessage))
					{
						Logger.Error("Execute rule:" + securityInitRule + " error:" + securityRuleResp.ErrorMessage + " Error Code:" + securityRuleResp.ErrorCode);
						throw new InvalidOperationException(securityInitRule + " securityRuleResp.ErrorMessage" + securityRuleResp.ErrorMessage);
					}else
					{
						//process response here
					}										
					
					Logger.Debug("Execute rule start:" + initDataRule);
					dataRuleResp = ASF.CoreLib.APIHelper.BDSExecute(initDataRequest);									
					Logger.Debug("Execute rule finish:" + initDataRule);
					
					if (!string.IsNullOrEmpty(dataRuleResp.ErrorMessage))
					{
						Logger.Error("Execute rule:" + initDataRule + " error:" + dataRuleResp.ErrorMessage + " Error Code:" + dataRuleResp.ErrorCode);
						throw new InvalidOperationException(initDataRule + " dataRuleResp.ErrorMessage" + dataRuleResp.ErrorMessage);
					}else
					{
						//process response here
					}										
					
					response.Result.AddParameter(new Parameter { Name = "InitSecurity", Value = "Success" });					
					response.Result.AddParameter(new Parameter { Name = "InitData", Value = "Success" });
				}
				catch (Exception e)
				{
					response["ErrorMessage"] = e.ToString();					
				}