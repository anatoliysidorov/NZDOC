for (int i = 0; i < request.Parameters.Count(); i++)
 {
 	response[request.Parameters[i].Name.ToString()] = request.Parameters[i].Value.ToString();
 }