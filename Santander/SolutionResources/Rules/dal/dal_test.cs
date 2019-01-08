var token = request.AsString("Token");
                    var domain = request.AsString("Domain");
                    var versionCode = "DCM_CATS_v2_1.0_2394";
                    var BOCode = request.AsString("BO_Code");

                    ASF.Persistence.Common.Domain.DALModel DALModel = ASF.CoreLib.APIHelper.GetDALModel(token, domain, versionCode);
                    if (DALModel != null)
                        if (DALModel.DataModel != null)
                            if (DALModel.DataModel.DataObjects != null)
                            {
                                //Get DB Table Name by BO Code
                                if (!string.IsNullOrEmpty(BOCode))
                                {
                                    var EntityObject = DALModel.MappingModel.EntitySetMappings.FirstOrDefault(x => x.EntityObject.Code == BOCode);
                                    if (EntityObject != null)
                                    {
                                        var tblName = EntityObject.EntityTypeMapping.DataObject.Name.ToString();
                                        response.Result.AddParameter(new Parameter { Name = "BO_Table_Name", Value = tblName });
                                    }
                                    else
                                    {
                                        response["ErrorMessage"] = "Link to DB Table not found";
                                        response["ErrorCode"] = 200;
                                    }
                                }
                            }

                    return response;