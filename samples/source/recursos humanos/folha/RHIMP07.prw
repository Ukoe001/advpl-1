#include "fileio.ch"
#Include "protheus.ch"
#Include "folder.ch"
#Include "tbiconn.ch"
#Include "topconn.ch"

/*
����������������������������������������������������������������������������������
����������������������������������������������������������������������������������
������������������������������������������������������������������������������ͻ��
���Metodo    �RHIMP07Turno    �Autor  �Rafael Luis da Silva� Data � 23/02/2010 ���
������������������������������������������������������������������������������͹��
���Desc.     �Responsavel em Processar a Importacao dos turnos para a tabela   ���
���          �Tabela SR6.                                                      ���
������������������������������������������������������������������������������͹��
���Uso       �Integracao do Modulo de RH dos Sistemas Logix X Protheus.        ���
������������������������������������������������������������������������������͹��
���Parametros�fName - Nome do Arquivo 		 				                   	 ���
������������������������������������������������������������������������������͹��
���Retorno   �                                                                 ���
������������������������������������������������������������������������������ͼ��
����������������������������������������������������������������������������������
����������������������������������������������������������������������������������
*/
USER Function RHIMP07Turno(fName)
  	 Local cBuffer       := ""
    Local lFilialArq    := ""
    Local lIncluiu 		:= .F.
    Local nPosIni       := 0
    Local nPosFim       := 0
    Local nPosFimFilial := 0
    Local nCount        := 0
    Local nlidos        := 0
    Local lEmpresaArq   := ""
    LOCAL lFilialArq    := ""
    LOCAL lEmpOrigem    := "00"
    LOCAL lFilialOrigem := "00"
	   LOCAL cR6_turno 		:= ""
	   LOCAL cDescErro		:= ""
	   PRIVATE aErro    := {}

   nCount := U_RIM01Line(fName)

    //���������������������������������������������������������������������Ŀ
    //� Numero de registros a importar                                      �
    //�����������������������������������������������������������������������
    ProcRegua(nCount)

    FT_FUSE(fName)
    FT_FGOTOP()

    lExiste:= .T.
    While !FT_FEOF()
       	cBuffer := FT_FREADLN()

    	   nPosFimFilial := At("|", cBuffer)
    	   lEmpresaArq      := Substr(cBuffer, 1, nPosFimFilial - 1)

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
           While !Eof()
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
              PREPARE ENVIRONMENT EMPRESA (lEmpresa) FILIAL (lFilial) MODULO "GPE" USER "ADMIN" FUNNAME "GPEA080"
              CHKFILE("SR6")
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

          //���������������������������������������������������������������������Ŀ
	    	    //� Incrementa a regua                                                  �
		        //�����������������������������������������������������������������������
	    	    nlidos += 1
          lIncluiu := .T.

         	nPosIni := At("|", cBuffer)
         	cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
         	nPosFim := At("|", cBuffer)

         	cR6_turno  := Substr(cBuffer, nPosIni + 1, nPosFim - (nPosIni + 1))

    	    	DbSelectArea("SR6")
     		   DbSetOrder(1)

    	    	If 	!DbSeek(lFilialArq + cR6_turno + Space(TamSX3("R6_TURNO")[1] - Len(cR6_turno)))
    	        	RecLock("SR6", .T.)

    		        IF 1 == nPosFimFilial
        	       	R6_FILIAL := ""
    	        	ELSE
      	        		R6_FILIAL := lFilialArq
    		        EndIf

    	    	    If (nPosIni + 1) == nPosFim
    	        	   R6_TURNO  := ""
    	        	Else
    	            R6_TURNO    := cR6_turno
    	        	EndIf
    	    	Else
    	        	RecLock("SR6", .F.)
    	    	EndIf

    	    	nPosIni := At("|", cBuffer)
    	    	cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
    	    	nPosFim := At("|", cBuffer)

    	    	If (nPosIni + 1) == nPosFim
    	        	R6_DESC := ""
    	    	Else
    	        	R6_DESC := Substr(cBuffer, nPosIni + 1, nPosFim  - (nPosIni + 1))
    	    	ENDIF

    	    	nPosIni := At("|", cBuffer)
    	    	cBuffer := Stuff(cBuffer, nPosIni, 1, ";")
    	    	nPosFim := At("|", cBuffer)

    	    	If (nPosIni + 1) == nPosFim
    	        	R6_HRNORMA := 0
    	    	Else
    	        	R6_HRNORMA := Val(Substr(cBuffer, nPosIni + 1, nPosFim  - (nPosIni + 1)))
    	    	ENDIF


    	    	MSUnLock()
    	    	IncProc()
    		EndIf

      IF ((lEmpOrigem <> lEmpresaArq) .OR. (lFilialOrigem <> lFilialArq))  .AND. lIncluiu == .F.
	    	    cDescErro := "Turnos cujo c�digo da empresa/filial igual a " + alltrim(lEmpresaArq)+'/'+alltrim(lFilialArq)+" n�o foram importados."
	    	    //U_RIM01ERR(cDescErro)
	    	    aAdd(aErro,cDescErro)
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
return