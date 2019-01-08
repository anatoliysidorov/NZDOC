// create logger
Ecx.Rule.Helpers.BDSHelper.LogDebug("Starting DICT_importCustomWords", null);

try
{
	// Get input parameters
	var token = request.AsString("Token");
	var domain = request.AsString("domain");
	var systemDomain = request.AsString("TOKEN_SYSTEMDOMAIN");
	
	var docUrl = (string)request["DocUrl"];
	var parentId = (string)request["ParentId"];
	// Const
	var ruleImportCode = "root_DICT_CreateCustomItem";
	string debugMsg="";
	
	// define delegate for BDS service
	Func<string, ParameterCollection, ParameterCollection> CallBusinessRule = new Func<string, ParameterCollection, ParameterCollection>((rule_name, params_) =>
	{
		var r_par = new ASF.BDS.WebService.Messages.ExecuteResponse();
		var r = new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			Parameters = params_,
			Domain = domain,
			Token = token,
			DataCommand = rule_name,
			VersionCode = null
		};

		r_par = ASF.CoreLib.APIHelper.BDSExecute(r);
		return  r_par.Data.GetParameters();
	});
	
	//const string ruleDocumentCalculateStoragePath = "root_Document_CalculateStoragePath";
	
	try{
	// Validation
	if(string.IsNullOrEmpty(token)) { throw new ApplicationException("Validation: Parameter 'Token' could not be found"); }
	if(string.IsNullOrEmpty(domain)) { throw new ApplicationException("Validation: parameter 'application domain' could not be found"); }
	if(string.IsNullOrEmpty(systemDomain)) { throw new ApplicationException("Validation: Parameter 'TOKEN_SYSTEMDOMAIN' could not be found"); }
	
	if(string.IsNullOrEmpty(docUrl)) { throw new ApplicationException("Validation: parameter 'DocUrl' could not be found"); }
	if(string.IsNullOrEmpty(parentId)) { throw new ApplicationException("Validation: parameter 'ParentId' could not be found"); }
	
	
	
	uint[] builtInDateTimeNumberFormatIDs = new uint[] { 14, 15, 16, 17, 18, 19, 20, 21, 22, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 45, 46, 47, 50, 51, 52, 53, 54, 55, 56, 57, 58 };
	Dictionary<uint, DocumentFormat.OpenXml.Spreadsheet.NumberingFormat> builtInDateTimeNumberFormats = builtInDateTimeNumberFormatIDs.ToDictionary(id => id, id => new DocumentFormat.OpenXml.Spreadsheet.NumberingFormat { NumberFormatId = id });
	System.Text.RegularExpressions.Regex dateTimeFormatRegex = new System.Text.RegularExpressions.Regex(@"((?=([^[]*\[[^[\]]*\])*([^[]*[ymdhs]+[^\]]*))|.*\[(h|mm|ss)\].*)", System.Text.RegularExpressions.RegexOptions.Compiled);
	System.Text.RegularExpressions.Regex normalizeColumnNameRegex = new System.Text.RegularExpressions.Regex(@"[^A-Za-z0-9_]");

	// Global Variables
	DocumentFormat.OpenXml.Packaging.SpreadsheetDocument document = null;
	Dictionary<uint, DocumentFormat.OpenXml.Spreadsheet.NumberingFormat> dateTimeCellFormats = new Dictionary<uint, DocumentFormat.OpenXml.Spreadsheet.NumberingFormat>();

	// Global variables for import
	Dictionary<string, string> columnNamesByLetter = new Dictionary<string, string>();
	Dictionary<string, string> ruleParamsByColumnName = new Dictionary<string, string>();
	
	
	
	string docFullPath = String.Empty;
		
	//-------------------------------------------------------
	//      Get document full path from cms by docUrl
	//-------------------------------------------------------
	using (var client = new ASF.CMS.WebService.Proxy.CMSServiceSvc.CMSServiceClient())
	{
		try
		{
			var cmsRequest = new ASF.CMS.WebService.Messages.GetResourceRequest()
			{ 
				Token = token, 
				Domain = domain, 
				Url = docUrl 
			};
			
			ASF.CMS.WebService.Messages.GetResourceResponse cmsResponse = client.GetResource(cmsRequest);
			
			if (cmsResponse.Resource != null)
			{
				if (cmsResponse.Resource.Length > 0)
				{ 
					docFullPath = cmsResponse.Resource.FullFileSystemPath;
				}
			}
		}
		catch (Exception e)
		{ 
			throw new ApplicationException(e.Message);
		}
	}
	
	
	
	// if document path is not empty, process it
                    if (!string.IsNullOrEmpty(docFullPath))
                    {
                        //-----------------------------
                        //      define delegates
                        //-----------------------------

                        //--- GetColumnAddress ---
                        Func<string, string> GetColumnAddress = (cellReference) =>
                        {
                            //Create a regular expression to get column address letters.
                            System.Text.RegularExpressions.Regex regex = new System.Text.RegularExpressions.Regex("[A-Za-z]+");
                            System.Text.RegularExpressions.Match match = regex.Match(cellReference);
                            return match.Value;
                        };

                        //--- NormalizeColumnName ---
                        Func<string, string> NormalizeColumnName = (s) =>
                        {
                            //return normalizeColumnNameRegex.Replace(s.ToString(), "").ToLower();
                            return normalizeColumnNameRegex.Replace(s.ToString(), "");
                        };

                        //--- IsDateTimeCell ---
                        Func<DocumentFormat.OpenXml.Spreadsheet.Cell, bool> IsDateTimeCell = (cell) =>
                        {
                            if (cell.StyleIndex == null)
                                return false;

                            return dateTimeCellFormats.ContainsKey(cell.StyleIndex);
                        };

                        //--- Get cell value ---
                        Func<DocumentFormat.OpenXml.Spreadsheet.Cell, object> GetCellValue = (cell) =>
                        {
                            if (cell == null) return null;

                            string value = cell.InnerText;

                            //Process values particularly for those data types.
                            if (cell.DataType == null)
                            {
                                if (IsDateTimeCell(cell))
                                {
                                    return DateTime.FromOADate(Double.Parse(value));
                                }
                            }
                            else
                            {
                                switch (cell.DataType.Value)
                                {
                                    //Obtain values from shared string table.
                                    case DocumentFormat.OpenXml.Spreadsheet.CellValues.SharedString:
                                        var sstPart = document.WorkbookPart.GetPartsOfType<DocumentFormat.OpenXml.Packaging.SharedStringTablePart>().FirstOrDefault();
                                        return sstPart.SharedStringTable.ChildElements[Int32.Parse(value)].InnerText;

                                    //Optional boolean conversion.
                                    case DocumentFormat.OpenXml.Spreadsheet.CellValues.Boolean:
                                        //var booleanToBit = ConfigurationManager.AppSettings["BooleanToBit"];
                                        //if (booleanToBit != "Y")
                                        var booleanToBit = true;
                                        if (booleanToBit)
                                        {
                                            value = value == "0" ? "FALSE" : "TRUE";
                                        }

                                        return value;
                                }
                            }

                            return value;
                        };

                        // GetDateTimeCellFormats
                        Func<DocumentFormat.OpenXml.Packaging.WorkbookPart, Dictionary<uint, DocumentFormat.OpenXml.Spreadsheet.NumberingFormat>> GetDateTimeCellFormats = (workbookPart) =>
                        {
                            var dateNumberFormats = new Dictionary<uint, DocumentFormat.OpenXml.Spreadsheet.NumberingFormat>();
                            if (workbookPart.WorkbookStylesPart.Stylesheet.NumberingFormats != null)
                            {

                                dateNumberFormats = workbookPart.WorkbookStylesPart.Stylesheet.NumberingFormats
                                    .Descendants<DocumentFormat.OpenXml.Spreadsheet.NumberingFormat>()
                                    .Where(nf => dateTimeFormatRegex.Match(nf.FormatCode.Value).Success)
                                    .ToDictionary(nf => nf.NumberFormatId.Value);

                            }
                            var cellFormats = workbookPart.WorkbookStylesPart.Stylesheet.CellFormats
                                .Descendants<DocumentFormat.OpenXml.Spreadsheet.CellFormat>();

                            var dateCellFormats = new Dictionary<uint, DocumentFormat.OpenXml.Spreadsheet.NumberingFormat>();
                            uint styleIndex = 0;
                            foreach (var cellFormat in cellFormats)
                            {
                                if (cellFormat.ApplyNumberFormat != null && cellFormat.ApplyNumberFormat.Value)
                                {
                                    if (dateNumberFormats.ContainsKey(cellFormat.NumberFormatId.Value))
                                    {
                                        dateCellFormats.Add(styleIndex, dateNumberFormats[cellFormat.NumberFormatId.Value]);
                                    }
                                    else if (builtInDateTimeNumberFormats.ContainsKey(cellFormat.NumberFormatId.Value))
                                    {
                                        dateCellFormats.Add(styleIndex,
                                            builtInDateTimeNumberFormats[cellFormat.NumberFormatId.Value]);
                                    }
                                }

                                styleIndex++;
                            }

                            return dateCellFormats;
                        };


                        //--- check that cell collumn allowed as rule parameter ---
                        Func<DocumentFormat.OpenXml.Spreadsheet.Cell, string> GetRuleParameterNameForCell = (cell) =>
                        {
                            if (cell == null) return string.Empty;
                            var cellLetter = GetColumnAddress(cell.CellReference);

                            // check if column with letter (A,B,C...) is exists in document
                            if (!columnNamesByLetter.ContainsKey(cellLetter)) return string.Empty;
                            var columnName = columnNamesByLetter[cellLetter];

                            return ruleParamsByColumnName.ContainsKey(columnName)
                                ? ruleParamsByColumnName[columnName]
                                : string.Empty;
                        };

						
                        //---   execute import ---
                        Func<List<Dictionary<string, string>>, bool> ImportRecords = (ruleParamsList) =>
                        {
                            var commands = new List<ASF.BDS.Common.Domain.Batch.DataCommandRequest>();
                            

                            // For each line form rule command
                            foreach (var ruleParams in ruleParamsList)
                            {
                                var prms = new ParameterCollection();
                                foreach (var ruleParam in ruleParams)
                                {
                                    prms.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = ruleParam.Key, Value = ruleParam.Value });
                                }

                                //prms.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "status", Value = "READYTOAPPLY" });

                                var dataCommand = new ASF.BDS.Common.Domain.Batch.DataCommandRequest() { DataCommand = ruleImportCode,Parameters = prms};
                                commands.Add(dataCommand);
                            }

                            var req = new ASF.BDS.WebService.Messages.ExecuteBatchRequest()
                            {
                                Domain = domain,
                                VersionCode = null,
                                Token = token,
                                Requests = commands.ToArray()
                            };
							
                            using (var x = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
                            {
                                var res = x.ExecuteBatch(req);
                            }
                            
                            return true;
                        };

						
						System.Text.RegularExpressions.Regex dateFormatRegex = new System.Text.RegularExpressions.Regex(@"^(\d{2})/(\d{2})/(\d{4})$", System.Text.RegularExpressions.RegexOptions.Compiled);
                        //System.Text.RegularExpressions.Regex timeFormatRegex = new System.Text.RegularExpressions.Regex(@"^(\d{2}):(\d{2})$", System.Text.RegularExpressions.RegexOptions.Compiled);
						System.Text.RegularExpressions.Regex timeFormatRegex = new System.Text.RegularExpressions.Regex(@"^\d+(:[0-5]\d){1,2}$", System.Text.RegularExpressions.RegexOptions.Compiled);
						
						
                        System.Text.RegularExpressions.Regex onlyDigitalFormatRegex = new System.Text.RegularExpressions.Regex(@"^[0-9]*$", System.Text.RegularExpressions.RegexOptions.Compiled);
						
						
                        //-----------------------------
                        //          main actions
                        //-----------------------------
                        document = DocumentFormat.OpenXml.Packaging.SpreadsheetDocument.Open(docFullPath, false);



                        DocumentFormat.OpenXml.Packaging.WorkbookPart wbPart = document.WorkbookPart;

                        DocumentFormat.OpenXml.Spreadsheet.Sheet sheet = null;
                        DocumentFormat.OpenXml.Packaging.WorksheetPart wsPart = null;

                        sheet = wbPart.Workbook.Descendants<DocumentFormat.OpenXml.Spreadsheet.Sheet>().FirstOrDefault();
                        if (sheet != null)
                        {
                            // Retrieve a reference to the worksheet part.
                            wsPart = (DocumentFormat.OpenXml.Packaging.WorksheetPart)(wbPart.GetPartById(sheet.Id));
                        }

                        if (wsPart == null)
                        {
                            throw new Exception("No worksheet.");
                        }

                        dateTimeCellFormats = GetDateTimeCellFormats(wbPart);

                        //Iterate cells of custom header row.
                        foreach (DocumentFormat.OpenXml.Spreadsheet.Cell cell in wsPart.Worksheet.Descendants<DocumentFormat.OpenXml.Spreadsheet.Row>().ElementAt(0))
                        {
                            //Get custom column names.
                            //Remove spaces, symbols (except underscore), and make lower cases and for all values in columnNames list.                    
                            var x = GetCellValue(cell);
                            if (x != null)
                            {
                                //columnNames.Add(NormalizeColumnName(x.ToString()));

                                //Get built-in column names by extracting letters from cell references.
                                //columnLetters.Add(GetColumnAddress(cell.CellReference));
                                var columnName = NormalizeColumnName(x.ToString());
                                var columnLetter = GetColumnAddress(cell.CellReference);

                                columnNamesByLetter.Add(columnLetter, columnName);
                            }
                        }

						// form mapping column<>rule parameter
                        ruleParamsByColumnName.Add("Name", "Name");
                        ruleParamsByColumnName.Add("Code", "pCode");
                        ruleParamsByColumnName.Add("Value", "pValue");
                        ruleParamsByColumnName.Add("Remarks", "Description");
                        ruleParamsByColumnName.Add("IsDisabled", "IsDeleted");
                        ruleParamsByColumnName.Add("Style", "pStyle");
                        ruleParamsByColumnName.Add("Row Style", "pRowStyle");


                        // read data from file
                        int RowIndex = 1;
                        bool hasValue = false;

                        // dictionary that contain information for one line in the file
                        Dictionary<string, string> ruleParamsWithValues = new Dictionary<string, string>();
                        
                        List<Dictionary<string, string>> batchList = new List<Dictionary<string, string>>();


                        var ws = wsPart.Worksheet;
                        while (RowIndex < ws.Descendants<DocumentFormat.OpenXml.Spreadsheet.Row>().Count())
                        {
							ruleParamsWithValues = new Dictionary<string, string>();
                            try
                            {
                                var row = ws.Descendants<DocumentFormat.OpenXml.Spreadsheet.Row>().ElementAt(RowIndex);
                                // clear rule parameters with values
                                
                                foreach (var cell in row.Descendants<DocumentFormat.OpenXml.Spreadsheet.Cell>())
                                {
                                    // if value is string.Empty, this column not allowed and we skip it
                                    var ruleParameterName = GetRuleParameterNameForCell(cell);
                                    //if (ruleParameterName == string.Empty) continue;
									if(!string.IsNullOrEmpty(ruleParameterName)) 
									{
										try
										{
											var cellValue = GetCellValue(cell);
											if(!string.IsNullOrEmpty((string)cellValue)) 
											{
												ruleParamsWithValues.Add(ruleParameterName, (string)cellValue);
											}
										}
										catch (Exception ex){}
									}
                                }
                            }
                            catch (Exception ex)
                            {
                                // In this place need to be saving of an exception to journal.
                            }
							
							// check if row is empty
							var rowIsNotEmpty = ruleParamsWithValues.Count > 0;
							
							//response.Result.AddParameter(new Parameter() { Name = "Row"+RowIndex, Value = ruleParamsWithValues.Count });
							
							if(rowIsNotEmpty)
							{
								ruleParamsWithValues.Add("ParentCategoryId", parentId.ToString());
								ruleParamsWithValues.Add("RawType", "WORD");
								
								//	validation	
		
								if ((ruleParamsWithValues.ContainsKey("Name")) && !string.IsNullOrEmpty(ruleParamsWithValues["Name"]) && ruleParamsWithValues["Name"].Length > 255)
								{
									ruleParamsWithValues["Name"] = ruleParamsWithValues["Name"].Substring(0, 254);
								}
								if ((ruleParamsWithValues.ContainsKey("pCode")) && !string.IsNullOrEmpty(ruleParamsWithValues["pCode"]) && ruleParamsWithValues["pCode"].Length > 255)
								{
									ruleParamsWithValues["pCode"] = ruleParamsWithValues["pCode"].Substring(0, 254);
								}
								if ((ruleParamsWithValues.ContainsKey("pValue")) && !string.IsNullOrEmpty(ruleParamsWithValues["pValue"]) && ruleParamsWithValues["pValue"].Length > 255)
								{
									ruleParamsWithValues["pValue"] = ruleParamsWithValues["pValue"].Substring(0, 254);
								}
								if ((ruleParamsWithValues.ContainsKey("pStyle")) && !string.IsNullOrEmpty(ruleParamsWithValues["pStyle"]) && ruleParamsWithValues["pStyle"].Length > 255)
								{
									ruleParamsWithValues["pStyle"] = ruleParamsWithValues["pStyle"].Substring(0, 254);
								}
								if ((ruleParamsWithValues.ContainsKey("pRowStyle")) && !string.IsNullOrEmpty(ruleParamsWithValues["pRowStyle"]) && ruleParamsWithValues["pRowStyle"].Length > 255)
								{
									ruleParamsWithValues["pRowStyle"] = ruleParamsWithValues["pRowStyle"].Substring(0, 254);
								}
								
								// Check whether value IsDisabled is in allowed range.
								if ((ruleParamsWithValues.ContainsKey("IsDeleted")) && !string.IsNullOrEmpty(ruleParamsWithValues["IsDeleted"])){
									if(ruleParamsWithValues["IsDeleted"] != "1"){
										ruleParamsWithValues["IsDeleted"] = "";
									}
								}
								// add set of parameters in batch list
								batchList.Add(ruleParamsWithValues);
							}
							RowIndex++;
                        }


						// Import Records
						response.Result.AddParameter(new Parameter() { Name = "StartImportRecords", Value = batchList.Count });
						ImportRecords(batchList);
						response.Result.AddParameter(new Parameter() { Name = "StopImportRecords", Value = batchList.Count });
						
						
						// Delete file
						//Ecx.Rule.Helpers.Utils.TryToDeleteFile(docUrl);
/*						try
						{
							var cmsRequest = new ASF.CMS.WebService.Messages.DeleteResourceRequest()
							{
								Token = token,
								Domain = domain,
								Url = docUrl		
							};
							
							using (var cmsClient = new ASF.CMS.WebService.Proxy.CMSServiceSvc.CMSServiceClient())
							{
								var res = cmsClient.DeleteResource(cmsRequest);
								response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = res.ErrorCode });
								response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = res.ErrorMessage });
							}
								
						}
						catch (Exception ex)
						{
							var errorMessage = "Unfortunately an error occurred deleting file from CMS ---- " + ex.ToString();
							response.Result.AddParameter(new Parameter() { Name = "Error", Value = errorMessage });
Ecx.Rule.Helpers.BDSHelper.LogDebug("errorMessage on Delete: "+ errorMessage, null);
						}
*/						
                    }
	
	}catch(Exception ex){
		response.Result.AddParameter(new Parameter() { Name = "ExceptionLev1", Value = ex.ToString() });
		
		try{
				// Update log
				Ecx.Rule.Helpers.BDSHelper.LogDebug("Exception while Parsing the File. DICT_importCustomWords rule => Exception block. ErrorMessage: "+ex.ToString(), null);
				
				// Update status
		
		}catch(Exception exp){
			Ecx.Rule.Helpers.BDSHelper.LogDebug("Exception  while updating Status from inside FileParsing rule => Exception block. ErrorMessage: "+ exp.ToString(), null);
			response.Result.AddParameter(new Parameter() { Name = "ExceptionLev2", Value = exp.ToString() });
		}
		throw ex;
	}


}
catch (Exception e)
{
	response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = e.ToString() });
	Ecx.Rule.Helpers.BDSHelper.LogDebug("Exception in DICT_importCustomWords. ErrorMessage: "+ e.ToString(), null);
	response.Result.AddParameter(new Parameter() { Name = "ExceptionLev3", Value = e.ToString() });
	Ecx.Rule.Helpers.BDSHelper.LogDebug("End catch rule DICT_importCustomWords", null);
	
}
Ecx.Rule.Helpers.BDSHelper.LogDebug("End rule DICT_importCustomWords", null);
