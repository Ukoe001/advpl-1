#include "fileio.ch"
#Include "protheus.ch"
#Include "folder.ch"
#Include "tbiconn.ch"
#Include "topconn.ch"


/*
����������������������������������������������������������������������������������
����������������������������������������������������������������������������������
������������������������������������������������������������������������������ͻ��
���Metodo    RHIMP19Cracha   �Autor  �Edna Dalfovo� Data � 21/02/2013 ���
������������������������������������������������������������������������������͹��
���Desc.     �Responsavel em Processar a Importacao das funcoes para a tabela  ���
���          �SPE.			                                                    ���
������������������������������������������������������������������������������͹��
���Uso       �Integracao do Modulo de RH dos Sistemas Logix X Protheus.        ���
������������������������������������������������������������������������������͹��
���Parametros�fName - Nome do Arquivo 	   				                   	 ���
������������������������������������������������������������������������������͹��
���Retorno   �                                                                 ���
������������������������������������������������������������������������������ͼ��
����������������������������������������������������������������������������������
����������������������������������������������������������������������������������
*/
USER Function RHIMP19Cracha(fName)
 Local cBuffer       := ""
 LOCAL lIncluiu 		   := .F.
 Local nPosIni       := 0
 Local nPosFim       := 0
 Local nPosFimFilial := 0
 Local nCount        := 0
 Local nlidos        := 0
 Local cEmpresaArq   := ""
 LOCAL cFilialArq    := ""
 LOCAL cEmpOrigem    := "00"
 LOCAL cFilialOrigem := "00"
 LOCAL cPE_Matprov   := ""
 LOCAL cPE_Mat       := ""
 LOCAL dPE_DataIni   := CtoD("//")
 PRIVATE aErro       := {}


 nCount := U_RIM01Line(fName)

 //���������������������������������������������������������������������Ŀ
 //� Numero de registros a importar                                      �
 //�����������������������������������������������������������������������
 ProcRegua(nCount)

 FT_FUSE(fName)
 FT_FGOTOP()

 lExiste:= .T.
 While !FT_FEOF()
    IncProc()
    cBuffer := FT_FREADLN()

	   nPosFimFilial := At("|", cBuffer)
	   cEmpresaArq      := Substr(cBuffer, 1, nPosFimFilial - 1)

    nPosIni := nPosFimFilial
    cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
    nPosFim := At("|", cBuffer)

	   cFilialArq := Substr(cBuffer, nPosIni + 1, nPosFim - (nPosIni + 1))
	   If Empty(cFilialArq)
	      cFilialArq := "  "
    EndIf

    IF cEmpresaArq <> cEmpOrigem .OR. cFilialArq <> cFilialOrigem
       lExiste:= .F.
    	  dbSelectArea("SM0")
       dbGoTop()

       RpcClearEnv()
       OpenSm0Excl()
       While ! Eof()
          lEmpresa:= SM0->M0_CODIGO
          lFilial := SM0->M0_CODFIL

          IF lEmpresa =  cEmpresaArq .AND. (Empty(cFilialArq) .OR. cFilialArq = lFilial)
             lExiste = .T.
             SM0->(dbSkip())
             EXIT
          ENDIF
          SM0->(dbSkip())
       ENDDO
       IF lExiste == .T.
          RpcSetType(3)
          PREPARE ENVIRONMENT EMPRESA (lEmpresa) FILIAL (lFilial) MODULO "PON" USER "ADMIN" FUNNAME "PONA120"

       ELSE
          lIncluiu := .F.
          cDescErro := "Crach�s Provis�rios cujo c�digo da empresa igual a " + AllTrim(cEmpresaArq)+'/'+ AllTrim(cFilialArq)+" n�o foram importados."
			       //U_RIM01ERR(cDescErro)
			       aAdd(aErro,cDescErro)
       ENDIF

   ENDIF

    IF lExiste == .T.

       //���������������������������������������������������������������������Ŀ
	      //� Incrementa a regua                                                  �
		     //�����������������������������������������������������������������������
	      nlidos += 1
       lIncluiu := .T.

       nPosIni := At("|", cBuffer)
       cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
       nPosFim := At("|", cBuffer)

       If (nPosIni + 1) == nPosFim
	         	cPE_Matprov := ""
	      ELSE
           cPE_Matprov := Substr(cBuffer, nPosIni + 1, nPosFim - (nPosIni + 1))
       ENDIF

       nPosIni := At("|", cBuffer)
	      cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
	      nPosFim := At("|", cBuffer)

	      If (nPosIni + 1) == nPosFim
	         	cPE_Mat := ""
	      ELSE
	         	cPE_Mat := Substr(cBuffer, nPosIni + 1, nPosFim  - (nPosIni + 1))
	      EndIf

	      nPosIni := At("|", cBuffer)
	      cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
	      nPosFim := At("|", cBuffer)

       IF (nPosIni + 1) == nPosFim
	         	dPE_DataIni :=  CtoD('//')
	      ELSE
	         	dPE_DataIni := CtoD(Substr(cBuffer, nPosIni + 1, nPosFim  - (nPosIni + 1)))
	      ENDIF

	      DbSelectArea("SRA")
  		   DbSetOrder(1)

       IF 	(DbSeek(cFilialArq + cPE_Mat + Space(TamSX3("RA_MAT")[1] - Len(cPE_Mat)))) .OR. Empty(cPE_Mat)

	           DbSelectArea("SPE")
		          DbSetOrder(3)

	           IF 	!DbSeek((cFilialArq) + (cPE_Matprov + Space(TamSX3("PE_MATPROV")[1] - Len(cPE_Matprov))) + (cPE_Mat + Space(TamSX3("PE_MAT")[1] - Len(cPE_Mat)))+ (DtoS(dPE_DataIni) + Space(TamSX3("PE_DATAINI")[1] - Len(DtoS(dPE_DataIni)))))
	              	RecLock("SPE", .T.)

  		            If 1 == nPosFimFilial
                     PE_FILIAL := ""
	               ELSE
                   		PE_FILIAL := cFilialArq
		              EndIf

	               IF (nPosIni + 1) == nPosFim
	              	     PE_MATPROV := ""
	               ELSE
	                    PE_MATPROV := cPE_Matprov
	               ENDIF

  	             PE_MAT := cPE_Mat
                PE_DATAINI :=  dPE_DataIni
	           ELSE
	              	RecLock("SPE", .F.)
	           ENDIF

	           nPosIni := At("|", cBuffer)
	           cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
	           nPosFim := At("|", cBuffer)

	           If (nPosIni + 1) == nPosFim
	              	PE_DATAFIM := CtoD("2100/12/31")
	           ELSE
	              	PE_DATAFIM := CtoD(Substr(cBuffer, nPosIni + 1, nPosFim  - (nPosIni + 1)))
	           ENDIF
	      ELSE
	          cDescErro := "Crach� Provis�rio: "+AllTrim(cEmpresaArq)+'/'+AllTrim(cFilialArq)+'/'+alltrim(cPE_Mat)+" - Funcion�rio n�o encontrado. Registros de Crach� Provis�rio n�o foram importados."
			        //U_RIM01ERR(cDescErro)
			        aAdd(aErro,cDescErro)
	      ENDIF

       MSUnLock()

       IncProc()

    ENDIF

    IF ((cEmpOrigem <> cEmpresaArq) .OR. (cFilialOrigem <> cFilialArq))  .AND. lIncluiu == .F.
	   	    cDescErro := "Crach�s Provis�ros cujo c�digo da empresa/filial igual a " + alltrim(cEmpresaArq)+'/'+alltrim(cFilialArq)+" n�o foram importados."
	   	    //U_RIM01ERR(cDescErro)
	   	    aAdd(aErro,cDescErro)
	   ENDIF

    FT_FSKIP()

    cEmpOrigem := cEmpresaArq
    cFilialOrigem  := cFilialArq
 ENDDO
  U_RIM01ERA(aErro)
 //���������������������������������������������������������������������Ŀ
 //� Libera o arquivo                                                    �
 //�����������������������������������������������������������������������
 FT_FUSE()

RETURN

