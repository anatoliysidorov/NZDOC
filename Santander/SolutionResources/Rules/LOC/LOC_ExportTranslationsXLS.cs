var token = HttpUtility.UrlDecode((string)request["token"]);
var sysdomain = (string)request["TOKEN_SYSTEMDOMAIN"];
var appDomain = (string)request["domain"];
string tmpFolder = String.Empty;
string tmpZIPFolder = String.Empty;
string tmpFolderAttach = String.Empty;
string uniqSeparator = "(o)(o)";

Dictionary<string, string> colDict = new Dictionary<string, string>();
//colDict.Add("ID", "ID");
//colDict.Add("LANGID", "LANGID");
colDict.Add("LANGCODE", "LANGCODE");
//colDict.Add("KEYID", "KEYID");
colDict.Add("KEYNAME", "KEYNAME");
//colDict.Add("NAMESPACEID", "NAMESPACEID");
colDict.Add("NAMESPACENAME", "NAMESPACENAME");
colDict.Add("ISPLURAL", "ISPLURAL");
colDict.Add("PLURALFORM", "PLURALFORM");
colDict.Add("CONTEXT", "CONTEXT");
colDict.Add("VALUE", "VALUE");

string ruleNameExportData = "root_LOC_getExportData";

Func<Newtonsoft.Json.Linq.JToken, string, string> getValue = (x, n) => 
{
	//var el = x[n].ToString().Replace("\"", string.Empty);
	var el = x.Value<string>(n);
	return !string.IsNullOrEmpty(el) ? el : String.Empty;
};
Func<string, DocumentFormat.OpenXml.Spreadsheet.CellValues, DocumentFormat.OpenXml.Spreadsheet.Cell> ConstructCell = (x, n) => 
{
	return new DocumentFormat.OpenXml.Spreadsheet.Cell()
	{
		CellValue = new DocumentFormat.OpenXml.Spreadsheet.CellValue(x),
		DataType = new DocumentFormat.OpenXml.EnumValue<DocumentFormat.OpenXml.Spreadsheet.CellValues>(n)
	};
};
Func<string, string, string> CreateXLS = (_tmpFolderAttach, langID) => 
{
	string tmpFileAttach = System.IO.Path.Combine(_tmpFolderAttach, langID + ".xlsx");
	using (var document = DocumentFormat.OpenXml.Packaging.SpreadsheetDocument.Create(tmpFileAttach, DocumentFormat.OpenXml.SpreadsheetDocumentType.Workbook))
	{
		var workbookPart = document.AddWorkbookPart();
		workbookPart.Workbook = new DocumentFormat.OpenXml.Spreadsheet.Workbook();
		workbookPart.Workbook.Save();
		document.Close();
	}
	return tmpFileAttach;
};
Func<string, uint, string, SortedList<string, object>, Dictionary<string, string>, int, bool> AddSheet = (tmpFileAttach, sheetID, sheetName, listData, dictionaryColumn, countPluralForms) =>
{
	List<string> arrayPluralForms = new List<string>();
	for (int i = 0; i <= countPluralForms - 1; i++)
	{
		arrayPluralForms.Add(i.ToString());
	}
	List<string> readyData = new List<string>();

	// add a sheet into the XLS file
	using (var document = DocumentFormat.OpenXml.Packaging.SpreadsheetDocument.Open(tmpFileAttach, true))
	{
		// Add a blank WorksheetPart.
		var worksheetPart = document.WorkbookPart.AddNewPart<DocumentFormat.OpenXml.Packaging.WorksheetPart>();
		worksheetPart.Worksheet = new DocumentFormat.OpenXml.Spreadsheet.Worksheet();
		var sheets = document.WorkbookPart.Workbook.GetFirstChild<DocumentFormat.OpenXml.Spreadsheet.Sheets>();
		if (sheets == null)
		{
			sheets = document.WorkbookPart.Workbook.AppendChild(new DocumentFormat.OpenXml.Spreadsheet.Sheets());
		}

		// Append the new worksheet and associate it with the workbook.
		var sheet = new DocumentFormat.OpenXml.Spreadsheet.Sheet() { Id = document.WorkbookPart.GetIdOfPart(worksheetPart), SheetId = sheetID, Name = sheetName };
		sheets.Append(sheet);
		document.WorkbookPart.Workbook.Save();

		var sheetData = worksheetPart.Worksheet.AppendChild(new DocumentFormat.OpenXml.Spreadsheet.SheetData());

		// Constructing header
		var row = new DocumentFormat.OpenXml.Spreadsheet.Row();
		foreach (KeyValuePair<string, string> item in colDict)
		{
			row.Append(ConstructCell(item.Value, DocumentFormat.OpenXml.Spreadsheet.CellValues.String));
		}
		sheetData.AppendChild(row);

		// Constructing content
		foreach (var data in listData)
		{

			string isPlural = data.Value.GetType().GetProperty("ISPLURAL").GetValue(data.Value, null).ToString();
			string _context = data.Value.GetType().GetProperty("CONTEXT").GetValue(data.Value, null).ToString();
			string keyID = data.Value.GetType().GetProperty("KEYID").GetValue(data.Value, null).ToString();
			string pluralForm = data.Value.GetType().GetProperty("PLURALFORM").GetValue(data.Value, null).ToString();

			if (readyData.Contains(keyID + uniqSeparator + _context))
			{
				continue;
			}

			if (isPlural == "0")
			{
				var contentRow = new DocumentFormat.OpenXml.Spreadsheet.Row();
				foreach (KeyValuePair<string, string> dict in colDict)
				{
					var value = data.Value.GetType().GetProperty(dict.Key).GetValue(data.Value, null).ToString();
					contentRow.Append(ConstructCell(value, DocumentFormat.OpenXml.Spreadsheet.CellValues.String));
				}
				sheetData.AppendChild(contentRow);
			}
			else
			{
				Dictionary<string, object> tempDict = new Dictionary<string, object>();
				for (var i = 0; i < listData.Count; i++)
				{
					var obj = listData.Values[i];
					string context2 = obj.GetType().GetProperty("CONTEXT").GetValue(obj, null).ToString();
					string keyID2 = obj.GetType().GetProperty("KEYID").GetValue(obj, null).ToString();
					string pluralForm2 = obj.GetType().GetProperty("PLURALFORM").GetValue(obj, null).ToString();
					if ((context2 == _context) && (keyID2 == keyID))
					{
						tempDict.Add(pluralForm2, obj);
						if (!readyData.Contains(keyID2 + uniqSeparator + context2))
						{
							readyData.Add(keyID2 + uniqSeparator + context2);
						}
					}
				}

				foreach (string item in arrayPluralForms)
				{
					object dataObj = data.Value;
					bool isFound = false;
					if (tempDict.ContainsKey(item))
					{
						dataObj = tempDict[item];
						isFound = true;
					}

					var contentRow = new DocumentFormat.OpenXml.Spreadsheet.Row();
					foreach (KeyValuePair<string, string> dict in colDict)
					{
						string value = dataObj.GetType().GetProperty(dict.Key).GetValue(dataObj, null).ToString();
						if ((dict.Key == "VALUE") && (!isFound))
						{
							value = "";
						}
						else if ((dict.Key == "ID") && (!isFound))
						{
							value = "";
						}
						else if (dict.Key == "PLURALFORM")
						{
							value = item;
						}
						contentRow.Append(ConstructCell(value, DocumentFormat.OpenXml.Spreadsheet.CellValues.String));
					}
					sheetData.AppendChild(contentRow);
				}
			}
		}

		// save an close
		worksheetPart.Worksheet.Save();
		document.Close();
	}
	return true;
};

try
{
	//Temp Folder name
	tmpFolder = Ecx.Rule.Helpers.Utils.GetTempFolder(appDomain);
	tmpZIPFolder = "DOCEXPTOZIP_" + Guid.NewGuid().ToString().Replace("-", "").Substring(0, 10);

	//create a folder
	tmpFolderAttach = System.IO.Path.Combine(tmpFolder, tmpZIPFolder);
	if (!System.IO.Directory.Exists(tmpFolderAttach))
	{
		try
		{
			System.IO.Directory.CreateDirectory(tmpFolderAttach);
		}
		catch (Exception e)
		{
			throw new Exception("Error: Can't create a folder " + tmpFolderAttach + "(" + e.Message + ") Error: {0} ", e);
		}
	}

	// get a export data

	var headerParams = new ASF.Framework.Service.Parameters.ParameterCollection();
	//headerParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "LanguageID", Value = "3" });
	var reqHeader = new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = ruleNameExportData,
		Domain = appDomain,
		Token = token,
		Parameters = headerParams,
	};
	var resHeader = ASF.CoreLib.APIHelper.BDSExecute(reqHeader);
	var responseRuleResult = resHeader.Data.ToJson();
	//Byte[] exelByte = (Byte[])resHeader.Data.ToExcel();

	// JSON to LIST of objects
	SortedList<string, object> langList = new SortedList<string, object>();
	string langCode = String.Empty;
	string namespaceName = String.Empty;
	uint ind = 1;
	string tmpFileAttach = String.Empty;
	int countPluralForm = 1;

	Newtonsoft.Json.Linq.JObject jObject = Newtonsoft.Json.Linq.JObject.Parse(responseRuleResult);
	foreach (var data in jObject["DATA"][ruleNameExportData]["ITEMS"])
	{
		if (langCode != getValue(data, "LANGCODE"))
		{
			if (langList.Count > 0)
			{
				AddSheet(tmpFileAttach, ind, namespaceName, langList, colDict, countPluralForm);
				ind = 1;
				langList.Clear();
			}
			langCode = getValue(data, "LANGCODE");
			// create a XLS doc
			tmpFileAttach = CreateXLS(tmpFolderAttach, langCode);
		}

		if (namespaceName != getValue(data, "NAMESPACENAME"))
		{
			if (langList.Count > 0)
			{
				AddSheet(tmpFileAttach, ind, namespaceName, langList, colDict, countPluralForm);
				ind = ind + 1;
				langList.Clear();
			}
			namespaceName = getValue(data, "NAMESPACENAME");
		}

		countPluralForm = Int32.Parse(getValue(data, "PLURALFORMCOUNT"));

		langList.Add(getValue(data, "KEYID") + uniqSeparator + getValue(data, "CONTEXT") + uniqSeparator + getValue(data, "PLURALFORM"), new
		{
			ID = getValue(data, "ID"),
			LANGID = getValue(data, "LANGID"),
			LANGCODE = langCode,
			KEYID = getValue(data, "KEYID"),
			KEYNAME = getValue(data, "KEYNAME"),
			NAMESPACEID = getValue(data, "NAMESPACEID"),
			NAMESPACENAME = getValue(data, "NAMESPACENAME"),
			ISPLURAL = getValue(data, "ISPLURAL"),
			PLURALFORM = getValue(data, "PLURALFORM"),
			CONTEXT = getValue(data, "CONTEXT"),
			VALUE = HttpUtility.HtmlDecode(getValue(data, "VALUE"))
		});
	}
	if (langList.Count > 0)
	{
		AddSheet(tmpFileAttach, ind, namespaceName, langList, colDict, countPluralForm);
		langList.Clear();
	}

	//Archive the all Folder and define ZIP filename
	string zipFileName = tmpZIPFolder.ToLower() + ".zip";
	var zipf = Ecx.Rule.Helpers.Utils.ZipFolder(appDomain, tmpFolderAttach, zipFileName, null);

	// Save zip to CMS
	using (var client = new ASF.CMS.WebService.Proxy.CMSServiceSvc.CMSServiceClient())
	{
		var createResource = new ASF.CMS.Common.Domain.Resource()
		{
			Buffer = System.IO.File.ReadAllBytes(zipf),
			ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
			Length = zipf.Length,
			OriginalFileName = zipFileName
		};
		var resp = client.CreateResource(new ASF.CMS.WebService.Messages.CreateResourceRequest()
		{
			Token = token,
			Domain = appDomain,
			Url = "/" + zipFileName,
			Resource = createResource
		});
		response["URL_FILE"] = resp.Url;
	}

	// Delete a temp folder and ZIP file
	System.IO.File.Delete(zipf);
	if (System.IO.Directory.Exists(tmpFolderAttach))
	{
		try
		{
			System.IO.Directory.Delete(tmpFolderAttach, true);
		}
		catch (Exception e)
		{
			throw new Exception("Error: Can't delete a folder " + tmpFolderAttach + "(" + e.Message + ") Error: {0} ", e);
		}
	}

	response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = string.Empty });
	response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = "Export to XLS has done" });
	response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = 0 });
}
catch (Exception ex)
{
	var errorMessage = ex.Message;
	response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = errorMessage });
	response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = string.Empty });
	response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = 101 });
}
