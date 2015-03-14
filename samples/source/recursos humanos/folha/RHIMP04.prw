#include "fileio.ch"
#Include "protheus.ch"
#Include "folder.ch"
#Include "tbiconn.ch"
#Include "topconn.ch"

/*
����������������������������������������������������������������������������������
����������������������������������������������������������������������������������
������������������������������������������������������������������������������ͻ��
���Metodo    �RHIMP04Depto    �Autor  �Rafael Luis da Silva� Data � 22/02/2010 ���
������������������������������������������������������������������������������͹��
���Desc.     �Responsavel em Processar a Importacao dos departamentos para a   ���
���          �Tabela SQB.                                                      ���
������������������������������������������������������������������������������͹��
���Uso       �Integracao do Modulo de RH dos Sistemas Logix X Protheus.        ���
������������������������������������������������������������������������������͹��
���Parametros�fName  - Nome do Arquivo 						                   ���
������������������������������������������������������������������������������͹��
���Retorno   �                                                                 ���
������������������������������������������������������������������������������ͼ��
����������������������������������������������������������������������������������
����������������������������������������������������������������������������������
*/
USER Function RHIMP04Depto(fName)
  	 Local cBuffer       := ""
  	 Local lEmpresaArq   := ""
    Local lFilialArq    := ""
    Local lIncluiu 		   := .F.
    Local nPosIni       := 0
    Local nPosFim       := 0
    Local nPosFimFilial := 0
    Local nCount        := 0
    Local nlidos        := 0
	   LOCAL lEmpOrigem    := "00"
	   LOCAL lFilialOrigem	:= "00"
	   LOCAL cQB_depto	    := ""
	   Local cDescErro		   := ""
	   PRIVATE aErro       := {}

   nCount := U_RIM01Line(fName)

    //���������������������������������������������������������������������Ŀ
    //� Numero de registros a importar                                      �
    //�����������������������������������������������������������������������
    ProcRegua(nCount)

    FT_FUSE(fName)
    FT_FGOTOP()

    While !FT_FEOF()
      	cBuffer := FT_FREADLN()

	     nPosFimFilial := At("|", cBuffer)
	     lEmpresaArq   := Substr(cBuffer, 1, nPosFimFilial - 1)

      nPosIni := nPosFimFilial
      cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
      nPosFim := At("|", cBuffer)

	     lFilialArq := Substr(cBuffer, nPosIni + 1, nPosFim - (nPosIni + 1))
	     If Empty(lFilialArq)
	        lFilialArq := "  "
      ENDIF

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
            PREPARE ENVIRONMENT EMPRESA (lEmpresa) FILIAL (lFilial) MODULO "GPE" USER "ADMIN" FUNNAME "CSAA100"
            CHKFILE("SQB")
            CHKFILE("SIX")
            CHKFILE("SQ3")
            CHKFILE("SQB1")
            CHKFILE("SQB3")
            CHKFILE("SQB4")
         ELSE
            lIncluiu := .F.
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

        	cQB_depto := Substr(cBuffer, nPosIni + 1, nPosFim - (nPosIni + 1))

		       //If lEmpresaArq = cEmpAnt
		       aTam := TAMSX3("QB_DEPTO")
	        IF aTam[1] < length(cQB_depto)
            cDescErro := "Departamento: "+AllTrim(lEmpresaArq)+'/'+AllTrim(lFilialArq)+'/'+alltrim(cQB_depto)+" - N�o foi importado para a tabela. Alterar o tamanho do campo c�digo no Configurador. Tam. Protheus:" + ALLTRIM(AllToChar(aTam[1]))+ " Tam. Sist. Ext:"+ ALLTRIM(AllToChar(length(cQB_depto))) + "."
			         //U_RIM01ERR(cDescErro)
			         aAdd(aErro,cDescErro)
			         lIncluiu := .F.
			      ELSE
		          //���������������������������������������������������������������������Ŀ
	        	  //� Incrementa a regua                                                  �
		          //�����������������������������������������������������������������������
	        	  nlidos += 1
            lIncluiu := .T.

	           DbSelectArea("SQB")
		          DbSetOrder(1)

	           IF 	!DbSeek(lFilialArq + cQB_depto + Space(TamSX3("QB_DEPTO")[1] - Len(cQB_depto)))
	              	RecLock("SQB", .T.)

		            If 1 == nPosFimFilial
                   	QB_FILIAL := ""
	             ELSE
                 		QB_FILIAL := lFilialArq
		            EndIf

	             IF (nPosIni + 1) == nPosFim
	              	   QB_DEPTO := ""
	             ELSE
	                  QB_DEPTO := cQB_depto
	             ENDIF
	           Else
	              	RecLock("SQB", .F.)
	           EndIf

	           nPosIni := At("|", cBuffer)
	           cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
	           nPosFim := At("|", cBuffer)

	           If (nPosIni + 1) == nPosFim
	              	QB_DESCRIC := ""
	           ELSE
	              	QB_DESCRIC := Substr(cBuffer, nPosIni + 1, nPosFim  - (nPosIni + 1))
	           EndIf

	           nPosIni := At("|", cBuffer)
	           cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
	           nPosFim := At("|", cBuffer)

	           IF (nPosIni + 1) == nPosFim
	              	QB_CC := ""
	           Else
                aTam := TAMSX3("QB_CC")
	               IF aTam[1] < length(Substr(cBuffer, nPosIni + 1, nPosFim - (nPosIni + 1)))
                   cDescErro := "Departamento: "+AllTrim(lEmpresaArq)+'/'+AllTrim(lFilialArq)+'/'+alltrim(cQB_depto)+" - N�o foi importado o c�digo do Centro de Custo. Alterar o tamanho do campo no Configurador."
			                //U_RIM01ERR(cDescErro)
			                aAdd(aErro,cDescErro)
			             ELSE
                   QB_CC := Substr(cBuffer, nPosIni + 1, nPosFim - (nPosIni + 1))
                ENDIF
	           EndIf
	           //IncProc()
		       ENDIF
		       MSUnLock()
	        IncProc()

	     ENDIF


      FT_FSKIP()

      lEmpOrigem := lEmpresaArq
      lFilialOrigem  := lFilialArq
    ENDDO

    U_RIM01ERA(aErro)
    //���������������������������������������������������������������������Ŀ
    //� Libera o arquivo                                                    �
    //�����������������������������������������������������������������������
    FT_FUSE()

RETURN
