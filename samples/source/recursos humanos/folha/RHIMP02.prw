#include "fileio.ch"
#Include "protheus.ch"
#Include "folder.ch"
#Include "tbiconn.ch"
#Include "topconn.ch"

/*
����������������������������������������������������������������������������������
����������������������������������������������������������������������������������
������������������������������������������������������������������������������ͻ��
���Metodo    RHIMP02Funcao   �Autor  �Rafael Luis da Silva� Data � 23/02/2010 ���
������������������������������������������������������������������������������͹��
���Desc.     �Responsavel em Processar a Importacao das funcoes para a tabela  ���
���          �SRJ.			                                                    ���
������������������������������������������������������������������������������͹��
���Uso       �Integracao do Modulo de RH dos Sistemas Logix X Protheus.        ���
������������������������������������������������������������������������������͹��
���Parametros�fName  - Nome do Arquivo 	   				                   	 ���
������������������������������������������������������������������������������͹��
���Retorno   �                                                                 ���
������������������������������������������������������������������������������ͼ��
����������������������������������������������������������������������������������
����������������������������������������������������������������������������������
*/
USER Function RHIMP02Funcao(fName)
 Local cBuffer       := ""
 LOCAL lIncluiu 		   := .F.
 Local nPosIni       := 0
 Local nPosFim       := 0
 Local nPosFimFilial := 0
 Local nCount        := 0
 Local nlidos        := 0
 Local lEmpresaArq   := ""
 LOCAL lFilialArq    := ""
 LOCAL lEmpOrigem    := "00"
 LOCAL lFilialOrigem := "00"
 Local aCampos       := {}
 LOCAL cRJ_funcao		  := ""
 LOCAL cDescErro		   := ""

 PRIVATE aErro := {}

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
	   lEmpresaArq      := Substr(cBuffer, 1, nPosFimFilial - 1)

    nPosIni := nPosFimFilial
    cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
    nPosFim := At("|", cBuffer)

	   lFilialArq := Substr(cBuffer, nPosIni + 1, nPosFim - (nPosIni + 1))
	   If Empty(lFilialArq)
	      lFilialArq := "  "
    EndIf

    IF lEmpresaArq <> lEmpOrigem .OR. lFilialArq <> lFilialOrigem
       lExiste:= .F.
    	  dbSelectArea("SM0")
       dbGoTop()

       RpcClearEnv()
       OpenSm0Excl()
       While ! Eof()
          lEmpresa:= SM0->M0_CODIGO
          lFilial := SM0->M0_CODFIL

          IF lEmpresa =  lEmpresaArq .AND. (Empty(lFilialArq) .OR. lFilialArq = lFilial)
             lExiste = .T.
             SM0->(dbSkip())
             EXIT
          ENDIF
          SM0->(dbSkip())
       ENDDO
       IF lExiste == .T.
          RpcSetType(3)
          PREPARE ENVIRONMENT EMPRESA (lEmpresa) FILIAL (lFilial) MODULO "GPE" USER "ADMIN" FUNNAME "GPEA030"
          CHKFILE("SRJ")
          CHKFILE("RCC")
       ELSE
          lIncluiu := .F.
          cDescErro := "Fun��es cujo c�digo da empresa igual a " + AllTrim(lEmpresaArq)+'/'+ AllTrim(lFilialArq)+" n�o foram importados."
			       //U_RIM01ERR(cDescErro)
			       aAdd(aErro,cDescErro)
       ENDIF

   ENDIF

    IF lExiste == .T.

       aCampos := {}

       //���������������������������������������������������������������������Ŀ
	    	 //� Incrementa a regua                                                  �
		     //�����������������������������������������������������������������������
	    	 nlidos += 1
       lIncluiu := .T.

       aCampos := {}

   	   nPosIni := At("|", cBuffer)
   	   cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
   	   nPosFim := At("|", cBuffer)

   	   cRJ_funcao := Substr(cBuffer, nPosIni + 1, nPosFim - (nPosIni + 1))

	      If 1 == nPosFimFilial
   	      aAdd(aCampos,{'RJ_FILIAL',''})
	      ELSE
 	        aAdd(aCampos,{'RJ_FILIAL',lFilialArq})
	      EndIf

	   	  If (nPosIni + 1) == nPosFim
	         aAdd(aCampos,{'RJ_FUNCAO',""})
	      Else
	         aAdd(aCampos,{'RJ_FUNCAO',cRJ_funcao})
	      EndIf

	   	  nPosIni := At("|", cBuffer)
	   	  cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
	   	  nPosFim := At("|", cBuffer)

	   	  If (nPosIni + 1) == nPosFim
	         	aAdd(aCampos,{'RJ_DESC',""})
	   	  ELSE
	          aAdd(aCampos,{'RJ_DESC',Substr(cBuffer, nPosIni + 1, nPosFim  - (nPosIni + 1))})
	   	  ENDIF

       nPosIni := At("|", cBuffer)
	   	  cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
	   	  nPosFim := At("|", cBuffer)

       If (nPosIni + 1) == nPosFim
          aAdd(aCampos,{'RJ_CODCBO',""})
       Else
          aAdd(aCampos,{'RJ_CODCBO',Substr(cBuffer, nPosIni + 1, nPosFim - (nPosIni + 1))})
       ENDIF

    ENDIF

    IF lIncluiu == .T.
       cDescErro := 'Cargo: '+AllTrim(lEmpresaArq)+'/'+AllTrim(lFilialArq)+'/'+AllTrim(cRJ_funcao)
       If !U_RIM01MVC( 'SRJ', aCampos,'GPEA030',cDescErro,cRJ_funcao,'GPEA030_SRJ')
          lIncluiu := .F.
       ENDIF
    ENDIF

    lEmpOrigem := lEmpresaArq
    lFilialOrigem := lFilialArq
    MSUnLock()
	   IncProc()

    FT_FSKIP()
 ENDDO
 U_RIM01ERA(aErro)

 //���������������������������������������������������������������������Ŀ
 //� Libera o arquivo                                                    �
 //�����������������������������������������������������������������������
 FT_FUSE()
RETURN

