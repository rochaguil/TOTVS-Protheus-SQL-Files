USE PUOBH2

SELECT Nome' as Empresa, CTT_DESC01 "Centro Custo", CTD_DESC01 Linha, C7_FILIAL Filial, A2_NOME "Razao Social", A2_NREDUZ "N Fantasia", B1_COD Produto, B1_DESC Descricao, C7_QUANT Quantidade, C7_QUJE "Quantidade Entregue",C7_PRECO "Prc Unitario",
IIF(C7_PO_EIC = '', C7_NUM, C7_PO_EIC) "Numero PC",
IIF(C7_RESIDUO = 'S', C7_QUJE,C7_QUANT) * C7_PRECO "Vlr.Total", SUBSTRING(C7_EMISSAO, 7,2) + '/' + SUBSTRING(C7_EMISSAO , 5,2) + '/' + SUBSTRING(C7_EMISSAO ,1,4) AS "DT Emissao"
,SUBSTRING(D1_DTDIGIT, 7,2) + '/' + SUBSTRING(D1_DTDIGIT , 5,2) + '/' + SUBSTRING(D1_DTDIGIT ,1,4) AS "DT Entrada"
,CASE
	WHEN C7_ENCER = 'E' THEN 'Encerrado'
	WHEN C7_ENCER = '' THEN 'Em aberto'
	ELSE C7_ENCER END "Ped. Encerr."
,C7_RESIDUO Resíduo,
CASE
 WHEN C7_MOEDA = 2 THEN 'USD'
 WHEN C7_MOEDA = 4 THEN 'EUR' END Moeda,
 CASE
	WHEN B1_TIPO = 'PA' THEN 'Revenda'
	WHEN B1_TIPO = 'MC' THEN 'Consumo'
	ELSE B1_TIPO END Tipo
,A2_EST Estado
FROM SC7010
LEFT JOIN (SELECT * FROM SB1010 WHERE SB1010.D_E_L_E_T_ <> '*') SB1010 ON
SC7010.C7_PRODUTO = SB1010.B1_COD
LEFT JOIN (SELECT * FROM CTD010 WHERE CTD010.D_E_L_E_T_ <> '*') CTD010 ON
CTD010.CTD_ITEM = SB1010.B1_ITEMCC
LEFT JOIN (SELECT * FROM SA2010 WHERE SA2010.D_E_L_E_T_ <> '*') SA2 ON
SA2.A2_COD = C7_FORNECE AND SA2.A2_LOJA = C7_LOJA
LEFT JOIN (SELECT * FROM CTT010 WHERE CTT010.D_E_L_E_T_ <> '*') CTT010 ON
CTT010.CTT_CUSTO = SB1010.B1_CC
LEFT JOIN (
SELECT TOP 1 WITH TIES D1_FILIAL, D1_PEDIDO, D1_DTDIGIT
FROM SD1010
WHERE D_E_L_E_T_ <> '*' AND D1_PEDIDO <> ''
ORDER BY
ROW_NUMBER() OVER(PARTITION BY D1_FILIAL, D1_PEDIDO ORDER BY D1_FILIAL, D1_PEDIDO )) SD1 ON
D1_PEDIDO = C7_NUM AND D1_FILIAL = C7_FILIAL
WHERE SC7010.D_E_L_E_T_ <> '*'
AND A2_EST = 'EX'
ORDER BY [DT Emissao] DESC

