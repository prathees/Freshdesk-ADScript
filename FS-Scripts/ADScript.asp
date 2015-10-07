<!--#include file="Constants.asp"-->
<%
	' VERSION 1.0.0
	' Simple SSO based on Classic ASP hosted on IIS.
	'----------------------------------------------------------------
	' VERSION 1.0.1
	' Debugging information added.
	'----------------------------------------------------------------
	' VERSION 1.0.2
	' Pass through functionality added.
	'----------------------------------------------------------------
	' VERSION 2.0.1
	' UTF8 characters support added. 
	' Basic script revamp
	' Credentials library added to the Constants file.
	' Version details included.
	'----------------------------------------------------------------
	' Current Version: 2.0.1        
	
    ' Credentials for a domain user for LDAP access
    
    on error resume next

    sError = ""

    ' Retrieve authenticated user
    strUsername = split(Request.ServerVariables("LOGON_USER"),"\")(1)
    Debug Request.ServerVariables("LOGON_USER") & " - should be of the form DOMAIN\username - if blank, your IIS probably allows anonymous access to this file."
    
    Set rootDSE = GetObject("LDAP://RootDSE")
    Set oConn = CreateObject("ADODB.Connection")

    sDomainContainer = rootDSE.Get("defaultNamingContext")
    Debug "DomainContainer: " & sDomainContainer

    oConn.Provider = "ADSDSOObject"
	oConn.properties("user id") = sLdapReaderUsername
	oConn.properties("password") = sLdapReaderPassword
    oConn.Open "ADs Provider"

    sQuery = "<LDAP://" & sDomainContainer & ">;(sAMAccountName=" & strUsername & ");adspath,mail,displayName;subtree"
    Set userRS = oConn.Execute(sQuery)

    If Not userRS.EOF and not err then
        sFullName =  userRS("displayName")
        sEmail = userRS("mail")
        sExternalID = ""
        
        Debug "Full name: " & sFullname
        Debug "Email: " & sEmail
        
        if sEmail > "" then
            sMessage = sFullName & sEmail & sToken 
            Debug "Message: " & sMessage
            sDigest = MD5Hash(sMessage)
            
            sURL = sReturnURL & _
                "?name=" & Server.URLEncode(userRS("displayName")) & _
                "&email=" & Server.URLEncode(sEmail) & _
                "&hash=" & sDigest
            
            Debug "Redirecting to: " & sURL
            if request.QueryString("Debug") = "1" then
                response.end
            end if
            
            if err.Description = "" then
                Response.redirect(sURL)
            end if
        else
            Debug "Error: No email"
            sError = "Account '" & Request.ServerVariables("LOGON_USER") & "' doesn't have an e-mail address."
        end if
    
    else
        Debug "Error: Account not found"
        sError = "Account '" & Request.ServerVariables("LOGON_USER") & "' not found."
    end if
    
    Response.Write(sNoLogin)

    if err then
        sError = Err.Description & vbCrLf & sError
    end if

    response.Write(vbCrLf & vbCrLf & "<!---" & vbCrLf & sError & vbCrlf & "--->")
    
    userRS.Close
    oConn.Close

    response.end

function Debug(st)
    if request.QueryString("debug") = "1" then
        response.Write("DEBUG: " & st & "<br/>")
    end if
end function

Function MD5Hash(sMessage)
    Set UTF8 = CreateObject("System.Text.UTF8Encoding")
	Set MD5 = CreateObject("System.Security.Cryptography.MD5CryptoServiceProvider")
    md5Bytes = MD5.ComputeHash_2( (UTF8.GetBytes_4(sMessage)) )
	Dim hexStr, x, bytesToHex
    For x=1 to lenb(md5Bytes)
        hexStr= hex(ascb(midb( (md5Bytes),x,1)))
        if len(hexStr)=1 then hexStr="0" & hexStr
        bytesToHex=bytesToHex & hexStr
    Next
	MD5Hash = LCase(bytesToHex)
End Function

%>