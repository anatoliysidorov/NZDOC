var Logger = Common.Logging.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
				try
				{						
					var token =  request.AsString("Token");
					var solDomain =  request.AsString("domain");					
					var importUrl = request.AsString("ResFileImportURL");
					
					ASF.Framework.Util.ValidationHelper.ValidateNotNullString(token, "token");
					ASF.Framework.Util.ValidationHelper.ValidateNotNullString(solDomain, "solDomain");
					ASF.Framework.Util.ValidationHelper.ValidateNotNullString(importUrl, "importUrl");
					
					string ruleCode = "root_UTIL_importDCMDataFileSync";
                    Logger.Debug("Import data request parameters:");
					
					Logger.Debug("importUrl:" + importUrl);
					foreach (var v in request.Parameters)
					{
						Logger.Debug("Parameter: " + v.Name + " Value:" + v.Value);
					}					
					
					ASF.Framework.Service.Parameters.ParameterCollection ruleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
					//add custom parameter
					ruleParams.AddParameter(new Parameter("ImportURL", ParameterType.btype_text, ParameterDirection.Input, importUrl));										
					//add all parameters from request 
					ruleParams.AddRange(request.Parameters);			
									
					var dataRuleResp = new ASF.BDS.WebService.Messages.ExecuteResponse();										
					
					var importDataRuleRequest = new ASF.BDS.WebService.Messages.ExecuteRequest()
					{
						Parameters = ruleParams,
						Domain = solDomain,
						Token = token,
						DataCommand = ruleCode,
						VersionCode = null
					};	
					
					Logger.Debug("Execute rule start:" + ruleCode);
					dataRuleResp = ASF.CoreLib.APIHelper.BDSExecute(importDataRuleRequest);					
					Logger.Debug("Execute rule finish:" + ruleCode);
					
					if (!string.IsNullOrEmpty(dataRuleResp.ErrorMessage))
					{
						Logger.Error("Execute rule:" + ruleCode + " error:" + dataRuleResp.ErrorMessage + " Error Code:" + dataRuleResp.ErrorCode);
						throw new InvalidOperationException(ruleCode + " dataRuleResp.ErrorMessage" + dataRuleResp.ErrorMessage);
					}else
					{
						//process response here
					}										
					
					response.Result.AddParameter(new Parameter { Name = "InitData", Value = "Success" });										
				}
				catch (Exception e)
				{
					response["ErrorMessage"] = e.ToString();					
				}