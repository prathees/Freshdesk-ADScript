<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>

<% 
    Response.Charset = "UTF-8"


    ' Shared secret from the remote authentication page 
    sToken     = "SECRET_SSO_TOKEN_FROM_FRESHDESK"


    sDomainName = "SIMPLE_DOMAIN_NAME" 'Provide the Simple Domain Name - eg: FRESHDESK
    sDomainController = "DOMAIN_CONTROLLER" 'IP Address or FQDN of ActiveDirectory Server - eg: ad-server01.freshdesk.com
    sAdminLogin = "DOMAIN_LOGIN_WITH_READ_ACCESS_IN_AD" 
    sAdminPassword = "PASSWORD_OF_ABOVE_LOGIN"


    '------------------------------------------------
    sErrorMessage = ""    

    sReturnURL = "http://" & Request.Querystring("host_url") & "/login/sso"
    Debug  "sReturnURL : " & sReturnURL

   
    Const BITS_TO_A_BYTE = 8
    Const BYTES_TO_A_WORD = 4
    Const BITS_TO_A_WORD = 32

    Dim m_lOnBits(30)
    Dim m_l2Power(30)

    Call Init()

    on error resume next

    'Retrieve authenticated user from 
    authenticatedUser =  Request.ServerVariables("LOGON_USER")
    if authenticatedUser = "" then
        authenticatedUser =  Request.ServerVariables("AUTH_USER") 
    end if

    if authenticatedUser = "" then
        sErrorMessage = sErrorMessage & "ERROR: Your IIS probably allows anonymous access to this file."
    else
	    strSplitUsername = split(authenticatedUser,"\")
        strUsername = strSplitUsername(UBound(strSplitUsername)) 
        Debug "Current Logged User : " & strUsername

        Set rootDSE = GetObject("LDAP://" & sDomainController & "/RootDSE")
        sDomainContainer = rootDSE.Get("defaultNamingContext")
        Debug "DomainContainer : " & sDomainContainer

        Set objConnection = CreateObject("ADODB.Connection")
        Set objCommand =   CreateObject("ADODB.Command")
        objConnection.Provider = "ADsDSOObject"
        objConnection.Properties("User ID") = sAdminLogin
        objConnection.Properties("Password") = sAdminPassword
        objConnection.Properties("Encrypt Password") = TRUE
        objConnection.Open "Active Directory Provider"

        Set objCommand.ActiveConnection = objConnection
        objCommand.Properties("Page Size") = 1000

        objCommand.CommandText = "SELECT sAMAccountName, displayName, mail FROM 'LDAP://" & sDomainController & "/" & sDomainContainer  & "' WHERE objectCategory='person' AND objectClass='user' AND sAMAccountName='" & strUsername & "'"

        Debug "Query : " & objCommand.CommandText

        Set objRecordSet = objCommand.Execute

        if Err then
            Debug "***Query Execute Failed : " & Err.Description
        else
            Do Until objRecordSet.EOF
                sFullName = GetFieldDataFromRecordSet(objRecordSet, "displayName")
                sEmail = GetFieldDataFromRecordSet(objRecordSet, "mail")
                Debug "Display Name : " & sFullname
                Debug "Email : " & sEmail
                objRecordSet.MoveNext
            Loop


            if sEmail > "" then
                sMessage = sFullName & sEmail & sToken 
                Debug "Message: " & sMessage
                sDigest = MD5(sMessage)
                
                sURL = sReturnURL & _
                    "?name=" & Server.URLEncode(sFullName) & _
                    "&email=" & Server.URLEncode(sEmail) & _
                    "&hash=" & sDigest
                
                Debug "sURL: " & sURL

                if request.QueryString("Debug") = "1" then
                    response.end
                else
                    if Err.Number = 0  then
                        Response.redirect(sURL)
                    end if
                end if
                

            else
                Debug "Error: No email. " & "Account '" & authenticatedUser & "' doesn't have an e-mail address."
                Err.Raise -1
            end if


        end if

    End If


    if Err then
        sErrorDescription = Err.Description
        if Err.Number = -1 then
            sErrorDescription = "Account '" & authenticatedUser & "' doesn't have an e-mail address."     
        end if
        sErrorMessage = "Couldn't login to Freshdesk. Please contact your administrator </br></br> Error Message : " & sErrorDescription & "<br/><br/>Debug:" & sErrorMessage
    end if

    response.Write sErrorMessage 
    
    objConnection.Close

    response.end

function Debug(st)
    sErrorMessage = sErrorMessage & "<br/>" & st
    if request.QueryString("debug") = "1" then
        response.Write("DEBUG: " & st & "<br/>")
    end if
end function

'
' DON'T CHANGE ANYTHING BELOW HERE. FOR REAL.
'

Function Init()     
    m_lOnBits(0) = CLng(1)
    m_lOnBits(1) = CLng(3)
    m_lOnBits(2) = CLng(7)
    m_lOnBits(3) = CLng(15)
    m_lOnBits(4) = CLng(31)
    m_lOnBits(5) = CLng(63)
    m_lOnBits(6) = CLng(127)
    m_lOnBits(7) = CLng(255)
    m_lOnBits(8) = CLng(511)
    m_lOnBits(9) = CLng(1023)
    m_lOnBits(10) = CLng(2047)
    m_lOnBits(11) = CLng(4095)
    m_lOnBits(12) = CLng(8191)
    m_lOnBits(13) = CLng(16383)
    m_lOnBits(14) = CLng(32767)
    m_lOnBits(15) = CLng(65535)
    m_lOnBits(16) = CLng(131071)
    m_lOnBits(17) = CLng(262143)
    m_lOnBits(18) = CLng(524287)
    m_lOnBits(19) = CLng(1048575)
    m_lOnBits(20) = CLng(2097151)
    m_lOnBits(21) = CLng(4194303)
    m_lOnBits(22) = CLng(8388607)
    m_lOnBits(23) = CLng(16777215)
    m_lOnBits(24) = CLng(33554431)
    m_lOnBits(25) = CLng(67108863)
    m_lOnBits(26) = CLng(134217727)
    m_lOnBits(27) = CLng(268435455)
    m_lOnBits(28) = CLng(536870911)
    m_lOnBits(29) = CLng(1073741823)
    m_lOnBits(30) = CLng(2147483647)
    
    m_l2Power(0) = CLng(1)
    m_l2Power(1) = CLng(2)
    m_l2Power(2) = CLng(4)
    m_l2Power(3) = CLng(8)
    m_l2Power(4) = CLng(16)
    m_l2Power(5) = CLng(32)
    m_l2Power(6) = CLng(64)
    m_l2Power(7) = CLng(128)
    m_l2Power(8) = CLng(256)
    m_l2Power(9) = CLng(512)
    m_l2Power(10) = CLng(1024)
    m_l2Power(11) = CLng(2048)
    m_l2Power(12) = CLng(4096)
    m_l2Power(13) = CLng(8192)
    m_l2Power(14) = CLng(16384)
    m_l2Power(15) = CLng(32768)
    m_l2Power(16) = CLng(65536)
    m_l2Power(17) = CLng(131072)
    m_l2Power(18) = CLng(262144)
    m_l2Power(19) = CLng(524288)
    m_l2Power(20) = CLng(1048576)
    m_l2Power(21) = CLng(2097152)
    m_l2Power(22) = CLng(4194304)
    m_l2Power(23) = CLng(8388608)
    m_l2Power(24) = CLng(16777216)
    m_l2Power(25) = CLng(33554432)
    m_l2Power(26) = CLng(67108864)
    m_l2Power(27) = CLng(134217728)
    m_l2Power(28) = CLng(268435456)
    m_l2Power(29) = CLng(536870912)
    m_l2Power(30) = CLng(1073741824)
End Function

Function LShift(lValue, iShiftBits)
    If iShiftBits = 0 Then
        LShift = lValue
        Exit Function
    ElseIf iShiftBits = 31 Then
        If lValue And 1 Then
            LShift = &H80000000
        Else
            LShift = 0
        End If
        Exit Function
    ElseIf iShiftBits < 0 Or iShiftBits > 31 Then
        Err.Raise 6
    End If
    
    If (lValue And m_l2Power(31 - iShiftBits)) Then
        LShift = ((lValue And m_lOnBits(31 - (iShiftBits + 1))) * m_l2Power(iShiftBits)) Or &H80000000
    Else
        LShift = ((lValue And m_lOnBits(31 - iShiftBits)) * m_l2Power(iShiftBits))
    End If
End Function

Function RShift(lValue, iShiftBits)
    If iShiftBits = 0 Then
        RShift = lValue
        Exit Function
    ElseIf iShiftBits = 31 Then
        If lValue And &H80000000 Then
            RShift = 1
        Else
            RShift = 0
        End If
        Exit Function
    ElseIf iShiftBits < 0 Or iShiftBits > 31 Then
        Err.Raise 6
    End If
    
    RShift = (lValue And &H7FFFFFFE) \ m_l2Power(iShiftBits)

    If (lValue And &H80000000) Then
        RShift = (RShift Or (&H40000000 \ m_l2Power(iShiftBits - 1)))
    End If
End Function

Function RotateLeft(lValue, iShiftBits)
    RotateLeft = LShift(lValue, iShiftBits) Or RShift(lValue, (32 - iShiftBits))
End Function

Function AddUnsigned(lX, lY)
    Dim lX4
    Dim lY4
    Dim lX8
    Dim lY8
    Dim lResult
 
    lX8 = lX And &H80000000
    lY8 = lY And &H80000000
    lX4 = lX And &H40000000
    lY4 = lY And &H40000000
 
    lResult = (lX And &H3FFFFFFF) + (lY And &H3FFFFFFF)
 
    If lX4 And lY4 Then
        lResult = lResult Xor &H80000000 Xor lX8 Xor lY8
    ElseIf lX4 Or lY4 Then
        If lResult And &H40000000 Then
            lResult = lResult Xor &HC0000000 Xor lX8 Xor lY8
        Else
            lResult = lResult Xor &H40000000 Xor lX8 Xor lY8
        End If
    Else
        lResult = lResult Xor lX8 Xor lY8
    End If
 
    AddUnsigned = lResult
End Function

Function F(x, y, z)
    F = (x And y) Or ((Not x) And z)
End Function

Function G(x, y, z)
    G = (x And z) Or (y And (Not z))
End Function

Function H(x, y, z)
    H = (x Xor y Xor z)
End Function

Function I(x, y, z)
    I = (y Xor (x Or (Not z)))
End Function

Sub FF(a, b, c, d, x, s, ac)
    a = AddUnsigned(a, AddUnsigned(AddUnsigned(F(b, c, d), x), ac))
    a = RotateLeft(a, s)
    a = AddUnsigned(a, b)
End Sub

Sub GG(a, b, c, d, x, s, ac)
    a = AddUnsigned(a, AddUnsigned(AddUnsigned(G(b, c, d), x), ac))
    a = RotateLeft(a, s)
    a = AddUnsigned(a, b)
End Sub

Sub HH(a, b, c, d, x, s, ac)
    a = AddUnsigned(a, AddUnsigned(AddUnsigned(H(b, c, d), x), ac))
    a = RotateLeft(a, s)
    a = AddUnsigned(a, b)
End Sub

Sub II(a, b, c, d, x, s, ac)
    a = AddUnsigned(a, AddUnsigned(AddUnsigned(I(b, c, d), x), ac))
    a = RotateLeft(a, s)
    a = AddUnsigned(a, b)
End Sub

Function ConvertToWordArray(sMessage)
    Dim lMessageLength
    Dim lNumberOfWords
    Dim lWordArray()
    Dim lBytePosition
    Dim lByteCount
    Dim lWordCount
    
    Const MODULUS_BITS = 512
    Const CONGRUENT_BITS = 448
    
    lMessageLength = Len(sMessage)
    
    lNumberOfWords = (((lMessageLength + ((MODULUS_BITS - CONGRUENT_BITS) \ BITS_TO_A_BYTE)) \ (MODULUS_BITS \ BITS_TO_A_BYTE)) + 1) * (MODULUS_BITS \ BITS_TO_A_WORD)
    ReDim lWordArray(lNumberOfWords - 1)
    
    lBytePosition = 0
    lByteCount = 0
    Do Until lByteCount >= lMessageLength
        lWordCount = lByteCount \ BYTES_TO_A_WORD
        lBytePosition = (lByteCount Mod BYTES_TO_A_WORD) * BITS_TO_A_BYTE
        lWordArray(lWordCount) = lWordArray(lWordCount) Or LShift(Asc(Mid(sMessage, lByteCount + 1, 1)), lBytePosition)
        lByteCount = lByteCount + 1
    Loop

    lWordCount = lByteCount \ BYTES_TO_A_WORD
    lBytePosition = (lByteCount Mod BYTES_TO_A_WORD) * BITS_TO_A_BYTE

    lWordArray(lWordCount) = lWordArray(lWordCount) Or LShift(&H80, lBytePosition)

    lWordArray(lNumberOfWords - 2) = LShift(lMessageLength, 3)
    lWordArray(lNumberOfWords - 1) = RShift(lMessageLength, 29)
    
    ConvertToWordArray = lWordArray
End Function

Function WordToHex(lValue)
    Dim lByte
    Dim lCount
    
    For lCount = 0 To 3
        lByte = RShift(lValue, lCount * BITS_TO_A_BYTE) And m_lOnBits(BITS_TO_A_BYTE - 1)
        WordToHex = WordToHex & Right("0" & Hex(lByte), 2)
    Next
End Function

Function MD5(sMessage)
    Dim x
    Dim k
    Dim AA
    Dim BB
    Dim CC
    Dim DD
    Dim a
    Dim b
    Dim c
    Dim d
    
    Const S11 = 7
    Const S12 = 12
    Const S13 = 17
    Const S14 = 22
    Const S21 = 5
    Const S22 = 9
    Const S23 = 14
    Const S24 = 20
    Const S31 = 4
    Const S32 = 11
    Const S33 = 16
    Const S34 = 23
    Const S41 = 6
    Const S42 = 10
    Const S43 = 15
    Const S44 = 21

    x = ConvertToWordArray(sMessage)
    
    a = &H67452301
    b = &HEFCDAB89
    c = &H98BADCFE
    d = &H10325476

    For k = 0 To UBound(x) Step 16
        AA = a
        BB = b
        CC = c
        DD = d
    
        FF a, b, c, d, x(k + 0), S11, &HD76AA478
        FF d, a, b, c, x(k + 1), S12, &HE8C7B756
        FF c, d, a, b, x(k + 2), S13, &H242070DB
        FF b, c, d, a, x(k + 3), S14, &HC1BDCEEE
        FF a, b, c, d, x(k + 4), S11, &HF57C0FAF
        FF d, a, b, c, x(k + 5), S12, &H4787C62A
        FF c, d, a, b, x(k + 6), S13, &HA8304613
        FF b, c, d, a, x(k + 7), S14, &HFD469501
        FF a, b, c, d, x(k + 8), S11, &H698098D8
        FF d, a, b, c, x(k + 9), S12, &H8B44F7AF
        FF c, d, a, b, x(k + 10), S13, &HFFFF5BB1
        FF b, c, d, a, x(k + 11), S14, &H895CD7BE
        FF a, b, c, d, x(k + 12), S11, &H6B901122
        FF d, a, b, c, x(k + 13), S12, &HFD987193
        FF c, d, a, b, x(k + 14), S13, &HA679438E
        FF b, c, d, a, x(k + 15), S14, &H49B40821
    
        GG a, b, c, d, x(k + 1), S21, &HF61E2562
        GG d, a, b, c, x(k + 6), S22, &HC040B340
        GG c, d, a, b, x(k + 11), S23, &H265E5A51
        GG b, c, d, a, x(k + 0), S24, &HE9B6C7AA
        GG a, b, c, d, x(k + 5), S21, &HD62F105D
        GG d, a, b, c, x(k + 10), S22, &H2441453
        GG c, d, a, b, x(k + 15), S23, &HD8A1E681
        GG b, c, d, a, x(k + 4), S24, &HE7D3FBC8
        GG a, b, c, d, x(k + 9), S21, &H21E1CDE6
        GG d, a, b, c, x(k + 14), S22, &HC33707D6
        GG c, d, a, b, x(k + 3), S23, &HF4D50D87
        GG b, c, d, a, x(k + 8), S24, &H455A14ED
        GG a, b, c, d, x(k + 13), S21, &HA9E3E905
        GG d, a, b, c, x(k + 2), S22, &HFCEFA3F8
        GG c, d, a, b, x(k + 7), S23, &H676F02D9
        GG b, c, d, a, x(k + 12), S24, &H8D2A4C8A
            
        HH a, b, c, d, x(k + 5), S31, &HFFFA3942
        HH d, a, b, c, x(k + 8), S32, &H8771F681
        HH c, d, a, b, x(k + 11), S33, &H6D9D6122
        HH b, c, d, a, x(k + 14), S34, &HFDE5380C
        HH a, b, c, d, x(k + 1), S31, &HA4BEEA44
        HH d, a, b, c, x(k + 4), S32, &H4BDECFA9
        HH c, d, a, b, x(k + 7), S33, &HF6BB4B60
        HH b, c, d, a, x(k + 10), S34, &HBEBFBC70
        HH a, b, c, d, x(k + 13), S31, &H289B7EC6
        HH d, a, b, c, x(k + 0), S32, &HEAA127FA
        HH c, d, a, b, x(k + 3), S33, &HD4EF3085
        HH b, c, d, a, x(k + 6), S34, &H4881D05
        HH a, b, c, d, x(k + 9), S31, &HD9D4D039
        HH d, a, b, c, x(k + 12), S32, &HE6DB99E5
        HH c, d, a, b, x(k + 15), S33, &H1FA27CF8
        HH b, c, d, a, x(k + 2), S34, &HC4AC5665
    
        II a, b, c, d, x(k + 0), S41, &HF4292244
        II d, a, b, c, x(k + 7), S42, &H432AFF97
        II c, d, a, b, x(k + 14), S43, &HAB9423A7
        II b, c, d, a, x(k + 5), S44, &HFC93A039
        II a, b, c, d, x(k + 12), S41, &H655B59C3
        II d, a, b, c, x(k + 3), S42, &H8F0CCC92
        II c, d, a, b, x(k + 10), S43, &HFFEFF47D
        II b, c, d, a, x(k + 1), S44, &H85845DD1
        II a, b, c, d, x(k + 8), S41, &H6FA87E4F
        II d, a, b, c, x(k + 15), S42, &HFE2CE6E0
        II c, d, a, b, x(k + 6), S43, &HA3014314
        II b, c, d, a, x(k + 13), S44, &H4E0811A1
        II a, b, c, d, x(k + 4), S41, &HF7537E82
        II d, a, b, c, x(k + 11), S42, &HBD3AF235
        II c, d, a, b, x(k + 2), S43, &H2AD7D2BB
        II b, c, d, a, x(k + 9), S44, &HEB86D391
    
        a = AddUnsigned(a, AA)
        b = AddUnsigned(b, BB)
        c = AddUnsigned(c, CC)
        d = AddUnsigned(d, DD)
    Next
    
    MD5 = LCase(WordToHex(a) & WordToHex(b) & WordToHex(c) & WordToHex(d))
End Function



Function GetFieldDataFromRecordSet(objRecordSet, field)
  fieldData = ""
  If("objectGUID" = field) Then
    fieldData = GuidToString(objRecordSet.Fields("objectGUID").Value)
  Else
    fieldData = objRecordSet.Fields(field).Value
  End If

  If IsNull(fieldData) Then
    fieldData = ""
  End If
  GetFieldDataFromRecordSet = fieldData
End Function




Function normalize_str(strRemove)
    ' Multidimensional array: http://camie.dyndns.org/technical/vbscript-arrays/
    Dim arrWrapper(1)
    Dim arrReplace(94)
    Dim arrReplaceWith(94)
    
    arrWrapper(0) = arrReplace
    arrWrapper(1) = arrReplace
    
    ' Replace
    arrWrapper(0)(0) = "Š"
    arrWrapper(0)(1) = "š"
    arrWrapper(0)(2) = "Ð"
    arrWrapper(0)(3) = "d"
    arrWrapper(0)(4) = "Ž"
    arrWrapper(0)(5) = "ž"
    arrWrapper(0)(6) = "C"
    arrWrapper(0)(7) = "c"
    arrWrapper(0)(8) = "C"
    arrWrapper(0)(9) = "c"
    arrWrapper(0)(10) = "À"
    arrWrapper(0)(11) = "Á"
    arrWrapper(0)(12) = "Â"
    arrWrapper(0)(13) = "Ã"
    arrWrapper(0)(14) = "Ä"
    arrWrapper(0)(15) = "Å"
    arrWrapper(0)(16) = "Æ"
    arrWrapper(0)(17) = "Ç"
    arrWrapper(0)(18) = "È"
    arrWrapper(0)(19) = "É"
    arrWrapper(0)(20) = "Ê"
    arrWrapper(0)(21) = "Ë"
    arrWrapper(0)(22) = "Ì"
    arrWrapper(0)(23) = "Í"
    arrWrapper(0)(24) = "Î"
    arrWrapper(0)(25) = "Ï"
    arrWrapper(0)(26) = "Ñ"
    arrWrapper(0)(27) = "Ò"
    arrWrapper(0)(28) = "Ó"
    arrWrapper(0)(29) = "Ô"
    arrWrapper(0)(30) = "Õ"
    arrWrapper(0)(31) = "Ö"
    arrWrapper(0)(32) = "Ø"
    arrWrapper(0)(33) = "Ù"
    arrWrapper(0)(34) = "Ú"
    arrWrapper(0)(35) = "Û"
    arrWrapper(0)(36) = "Ü"
    arrWrapper(0)(37) = "Ý"
    arrWrapper(0)(38) = "Þ"
    arrWrapper(0)(39) = "ß"
    arrWrapper(0)(40) = "à"
    arrWrapper(0)(41) = "á"
    arrWrapper(0)(42) = "â"
    arrWrapper(0)(43) = "ã"
    arrWrapper(0)(44) = "ä"
    arrWrapper(0)(45) = "å"
    arrWrapper(0)(46) = "æ"
    arrWrapper(0)(47) = "ª"
    arrWrapper(0)(48) = "ç"
    arrWrapper(0)(49) = "è"
    arrWrapper(0)(50) = "é"
    arrWrapper(0)(51) = "ê"
    arrWrapper(0)(52) = "ë"
    arrWrapper(0)(53) = "ì"
    arrWrapper(0)(54) = "í"
    arrWrapper(0)(55) = "î"
    arrWrapper(0)(56) = "ï"
    arrWrapper(0)(57) = "ð"
    arrWrapper(0)(58) = "ñ"
    arrWrapper(0)(59) = "ò"
    arrWrapper(0)(60) = "ó"
    arrWrapper(0)(61) = "ô"
    arrWrapper(0)(62) = "õ"
    arrWrapper(0)(63) = "ö"
    arrWrapper(0)(64) = "ø"
    arrWrapper(0)(65) = "ù"
    arrWrapper(0)(66) = "ú"
    arrWrapper(0)(67) = "û"
    arrWrapper(0)(68) = "ü"
    arrWrapper(0)(69) = "ý"
    arrWrapper(0)(70) = "ý"
    arrWrapper(0)(71) = "þ"
    arrWrapper(0)(72) = "ÿ"
    arrWrapper(0)(73) = "R"
    arrWrapper(0)(74) = "r"
    arrWrapper(0)(75) = "`"
    arrWrapper(0)(76) = "´"
    arrWrapper(0)(77) = "„"
    arrWrapper(0)(78) = "`"
    arrWrapper(0)(79) = "´"
    arrWrapper(0)(80) = "€"
    arrWrapper(0)(81) = "™"
    arrWrapper(0)(82) = "{"
    arrWrapper(0)(83) = "}"
    arrWrapper(0)(84) = "~"
    arrWrapper(0)(85) = "’"
    arrWrapper(0)(86) = "'"
    arrWrapper(0)(87) = "¶"
    arrWrapper(0)(88) = "¼"
    arrWrapper(0)(89) = "µ"
    arrWrapper(0)(90) = "®"
    arrWrapper(0)(91) = "/" 
    arrWrapper(0)(92) = "|"
    arrWrapper(0)(93) = "º"
    arrWrapper(0)(94) = "&"
     
     ' With
    arrWrapper(1)(0) = "S"
    arrWrapper(1)(1) = "s"
    arrWrapper(1)(2) = "Dj"
    arrWrapper(1)(3) = "d"
    arrWrapper(1)(4) = "Z"
    arrWrapper(1)(5) = "z"
    arrWrapper(1)(6) = "C"
    arrWrapper(1)(7) = "c"
    arrWrapper(1)(8) = "C"
    arrWrapper(1)(9) = "c"
    arrWrapper(1)(10) = "A"
    arrWrapper(1)(11) = "A"
    arrWrapper(1)(12) = "A"
    arrWrapper(1)(13) = "A"
    arrWrapper(1)(14) = "A"
    arrWrapper(1)(15) = "A"
    arrWrapper(1)(16) = "A"
    arrWrapper(1)(17) = "C"
    arrWrapper(1)(18) = "E"
    arrWrapper(1)(19) = "E"
    arrWrapper(1)(20) = "E"
    arrWrapper(1)(21) = "E"
    arrWrapper(1)(22) = "I"
    arrWrapper(1)(23) = "I"
    arrWrapper(1)(24) = "I"
    arrWrapper(1)(25) = "I"
    arrWrapper(1)(26) = "N"
    arrWrapper(1)(27) = "O"
    arrWrapper(1)(28) = "O"
    arrWrapper(1)(29) = "O"
    arrWrapper(1)(30) = "O"
    arrWrapper(1)(31) = "O"
    arrWrapper(1)(32) = "O"
    arrWrapper(1)(33) = "U"
    arrWrapper(1)(34) = "U"
    arrWrapper(1)(35) = "U"
    arrWrapper(1)(36) = "U"
    arrWrapper(1)(37) = "Y"
    arrWrapper(1)(38) = "B"
    arrWrapper(1)(39) = "Ss"
    arrWrapper(1)(40) = "a"
    arrWrapper(1)(41) = "a"
    arrWrapper(1)(42) = "a"
    arrWrapper(1)(43) = "a"
    arrWrapper(1)(44) = "a"
    arrWrapper(1)(45) = "a"
    arrWrapper(1)(46) = "a"
    arrWrapper(1)(47) = "a"
    arrWrapper(1)(48) = "c"
    arrWrapper(1)(49) = "e"
    arrWrapper(1)(50) = "e"
    arrWrapper(1)(51) = "e"
    arrWrapper(1)(52) = "e"
    arrWrapper(1)(53) = "i"
    arrWrapper(1)(54) = "i"
    arrWrapper(1)(55) = "i"
    arrWrapper(1)(56) = "i"
    arrWrapper(1)(57) = "o"
    arrWrapper(1)(58) = "n"
    arrWrapper(1)(59) = "o"
    arrWrapper(1)(60) = "o"
    arrWrapper(1)(61) = "o"
    arrWrapper(1)(62) = "o"
    arrWrapper(1)(63) = "o"
    arrWrapper(1)(64) = "o"
    arrWrapper(1)(65) = "u"
    arrWrapper(1)(66) = "u"
    arrWrapper(1)(67) = "u"
    arrWrapper(1)(68) = "u"
    arrWrapper(1)(69) = "y"
    arrWrapper(1)(70) = "y"
    arrWrapper(1)(71) = "b"
    arrWrapper(1)(72) = "y"
    arrWrapper(1)(73) = "R"
    arrWrapper(1)(74) = "r"
    arrWrapper(1)(75) = ""
    arrWrapper(1)(76) = ""
    arrWrapper(1)(77) = ","
    arrWrapper(1)(78) = ""
    arrWrapper(1)(79) = ""
    arrWrapper(1)(80) = ""
    arrWrapper(1)(81) = ""
    arrWrapper(1)(82) = ""
    arrWrapper(1)(83) = ""
    arrWrapper(1)(84) = ""
    arrWrapper(1)(85) = ""
    arrWrapper(1)(86) = ""
    arrWrapper(1)(87) = ""
    arrWrapper(1)(88) = ""
    arrWrapper(1)(89) = "u"
    arrWrapper(1)(90) = ""
    arrWrapper(1)(91) = "." 
    arrWrapper(1)(92) = "-"
    arrWrapper(1)(93) = ""
    arrWrapper(1)(94) = "e"

    
    'WScript.Echo "Remove str: " & strRemove
    For N = 0 To 94
        'WScript.Echo "Replace " & arrWrapper(0)(N) & " with " & arrWrapper(1)(N)
        ' http://www.w3schools.com/vbscript/func_replace.asp
        ' 1: Start find from 1st character
        ' -1: Find until string does not End
        ' 0: binary comparision. Respect uppercase from lowercase.
        strRemove = Replace(strRemove, arrWrapper(0)(N), arrWrapper(1)(N), 1, -1, 0)
    Next
    
    normalize_str = strRemove
End Function


%>