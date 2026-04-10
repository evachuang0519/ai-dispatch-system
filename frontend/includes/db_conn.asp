<%
' Classic ASP 不直連資料庫，所有操作透過 FastAPI
' 此檔案提供共用的 HTTP 呼叫函式

Dim API_BASE
API_BASE = "http://localhost:8000"

Function CallAPI(method, path, jsonBody)
    Dim http
    Set http = Server.CreateObject("MSXML2.XMLHTTP")
    http.Open method, API_BASE & path, False
    http.setRequestHeader "Content-Type", "application/json"
    http.setRequestHeader "Accept", "application/json"
    If jsonBody <> "" Then
        http.Send jsonBody
    Else
        http.Send
    End If
    If http.status >= 200 And http.status < 300 Then
        CallAPI = http.responseText
    Else
        CallAPI = "{""error"":""" & http.status & " " & http.statusText & """}"
    End If
    Set http = Nothing
End Function

Function GetAPI(path)
    GetAPI = CallAPI("GET", path, "")
End Function

Function PostAPI(path, jsonBody)
    PostAPI = CallAPI("POST", path, jsonBody)
End Function

Function PutAPI(path, jsonBody)
    PutAPI = CallAPI("PUT", path, jsonBody)
End Function

Function PatchAPI(path)
    PatchAPI = CallAPI("PATCH", path, "")
End Function

Function DeleteAPI(path)
    DeleteAPI = CallAPI("DELETE", path, "")
End Function
%>
