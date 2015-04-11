#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWEBSRV.CH"

/* ===============================================================================
WSDL Location    http://localhost:888/ws/XMOSTRASALDO.apw?WSDL
Gerado em        04/11/15 15:47:23
Observa��es      C�digo-Fonte gerado por ADVPL WSDL Client 1.120703
                 Altera��es neste arquivo podem causar funcionamento incorreto
                 e ser�o perdidas caso o c�digo-fonte seja gerado novamente.
=============================================================================== */

User Function _AOGSDSI ; Return  // "dummy" function - Internal Use 

/* -------------------------------------------------------------------------------
WSDL Service WSXMOSTRASALDO
------------------------------------------------------------------------------- */

WSCLIENT WSXMOSTRASALDO

	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD RESET
	WSMETHOD CLONE
	WSMETHOD MOSTRASALDO

	WSDATA   _URL                      AS String
	WSDATA   _HEADOUT                  AS Array of String
	WSDATA   _COOKIES                  AS Array of String
	WSDATA   cPRODUTO                  AS string
	WSDATA   nMOSTRASALDORESULT        AS float

ENDWSCLIENT

WSMETHOD NEW WSCLIENT WSXMOSTRASALDO
::Init()
If !FindFunction("XMLCHILDEX")
	UserException("O C�digo-Fonte Client atual requer os execut�veis do Protheus Build [7.00.121227P-20131106] ou superior. Atualize o Protheus ou gere o C�digo-Fonte novamente utilizando o Build atual.")
EndIf
Return Self

WSMETHOD INIT WSCLIENT WSXMOSTRASALDO
Return

WSMETHOD RESET WSCLIENT WSXMOSTRASALDO
	::cPRODUTO           := NIL 
	::nMOSTRASALDORESULT := NIL 
	::Init()
Return

WSMETHOD CLONE WSCLIENT WSXMOSTRASALDO
Local oClone := WSXMOSTRASALDO():New()
	oClone:_URL          := ::_URL 
	oClone:cPRODUTO      := ::cPRODUTO
	oClone:nMOSTRASALDORESULT := ::nMOSTRASALDORESULT
Return oClone

// WSDL Method MOSTRASALDO of Service WSXMOSTRASALDO

WSMETHOD MOSTRASALDO WSSEND cPRODUTO WSRECEIVE nMOSTRASALDORESULT WSCLIENT WSXMOSTRASALDO
Local cSoap := "" , oXmlRet

BEGIN WSMETHOD

cSoap += '<MOSTRASALDO xmlns="http://localhost:888/">'
cSoap += WSSoapValue("PRODUTO", ::cPRODUTO, cPRODUTO , "string", .T. , .F., 0 , NIL, .F.) 
cSoap += "</MOSTRASALDO>"

oXmlRet := SvcSoapCall(	Self,cSoap,; 
	"http://localhost:888/MOSTRASALDO",; 
	"DOCUMENT","http://localhost:888/",,"1.031217",; 
	"http://localhost:888/ws/XMOSTRASALDO.apw")

::Init()
::nMOSTRASALDORESULT :=  WSAdvValue( oXmlRet,"_MOSTRASALDORESPONSE:_MOSTRASALDORESULT:TEXT","float",NIL,NIL,NIL,NIL,NIL,NIL) 

END WSMETHOD

oXmlRet := NIL
Return .T.



