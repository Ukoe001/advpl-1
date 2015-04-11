/*
Exemplo de utiliza��o da fun��o MPReport 
Revis�o: 03/05/2006
Abrang�ncia
Vers�o 8.11
Para utilizar o exemplo abaixo verifique se o seu reposit�rio est� com Release 4 do Protheus
*/
#include "protheus.ch"

User Function MyReport1()

//Informando o vetor com as ordens utilizadas pelo relat�rio

MPReport("MYREPORT1","SA1","Relacao de Clientes","Este relat�rio ir� imprimir a relacao de clientes",{"Por Codigo","Alfabetica","Por "+RTrim(RetTitle("A1_CGC"))})
Return

User Function MyReport2()

//Informando para fun��o carregar os �ndices do Dicion�rio de �ndices (SIX) da tabela

MPReport("MYREPORT2","SA1","Relacao de Clientes","Este relat�rio ir� imprimir a relacao de clientes",,.T.)
Return
