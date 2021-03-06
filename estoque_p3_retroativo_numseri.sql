USE PUOBH2

IF OBJECT_ID('tempdb..#SD2_NFS') IS NOT NULL DROP TABLE #SD2_NFS

SELECT * INTO #SD2_NFS FROM (
SELECT DISTINCT D2_DOC, D2_FILIAL, D2_SERIE, D2_TIPO, F4_ESTOQUE
, ISNULL(A2_COD,A1_COD) CLIFOR_COD, ISNULL(A2_LOJA,A1_LOJA) CLIFOR_LOJA, ISNULL(A2_NREDUZ + '  ',A1_NREDUZ) CLIFOR_NREDUZ, ISNULL(A2_NOME,A1_NOME) CLIFOR_NOME
FROM SD2010 SD2
LEFT JOIN SF4010 SF4 ON F4_CODIGO = D2_TES AND SF4.D_E_L_E_T_ <> '*'
LEFT JOIN SA1010 SA1 ON A1_COD = D2_CLIENTE AND A1_LOJA = D2_LOJA AND SA1.D_E_L_E_T_ <> '*' AND NOT D2_TIPO IN ('B','D')
LEFT JOIN SA2010 SA2 ON A2_COD = D2_CLIENTE AND A2_LOJA = D2_LOJA AND SA2.D_E_L_E_T_ <> '*' AND D2_TIPO IN ('B','D')
WHERE SD2.D_E_L_E_T_ <> '*') t

IF OBJECT_ID('tempdb..#SD1_NFS') IS NOT NULL DROP TABLE #SD1_NFS
SELECT * INTO #SD1_NFS FROM (
SELECT TOP 1 WITH TIES D1_DOC, D1_FILIAL, D1_SERIE, D1_TIPO, F4_ESTOQUE
, ISNULL(A2_COD,A1_COD) CLIFOR_COD, ISNULL(A2_LOJA,A1_LOJA) CLIFOR_LOJA, ISNULL(A2_NREDUZ + '  ', A1_NREDUZ) CLIFOR_NREDUZ, ISNULL(A2_NOME,A1_NOME) CLIFOR_NOME
FROM SD1010 SD1
LEFT JOIN SF4010 SF4 ON F4_CODIGO = D1_TES AND SF4.D_E_L_E_T_ <> '*'
LEFT JOIN SA2010 SA2 ON A2_COD = D1_FORNECE AND A2_LOJA = D1_LOJA AND SA2.D_E_L_E_T_ <> '*' AND NOT D1_TIPO IN ('B','D')
LEFT JOIN SA1010 SA1 ON A1_COD = D1_FORNECE AND A1_LOJA = D1_LOJA AND SA1.D_E_L_E_T_ <> '*' AND D1_TIPO IN ('B','D')
WHERE SD1.D_E_L_E_T_ <> '*'
ORDER BY ROW_NUMBER() OVER(PARTITION BY D1_DOC, D1_FILIAL, A2_COD, A1_COD, A2_LOJA, A1_LOJA ORDER BY D1_DOC, D1_FILIAL, D1_SERIE, D1_TIPO, A2_LOJA, A1_LOJA )) u

IF OBJECT_ID('tempdb..#ult_preco') IS NOT NULL DROP TABLE #ult_preco

SELECT * INTO #ult_preco FROM(
SELECT TOP 1 WITH TIES CTD_DESC01 LINHA,D2_EMISSAO,B1_COD PRODUTO, D2_PRCVEN, D2_CUSTO1/NULLIF(D2_QUANT,0) CUSTO_UNIT FROM SD2010 SD2
LEFT JOIN SF4010 SF4 ON
F4_CODIGO = D2_TES AND SF4.D_E_L_E_T_ <> '*'
LEFT JOIN SB1010 SB1 ON
B1_COD = D2_COD AND SB1.D_E_L_E_T_ <> '*'
LEFT JOIN CTD010 CTD ON
CTD_ITEM = B1_ITEMCC AND CTD.D_E_L_E_T_ <> '*'
WHERE SD2.D_E_L_E_T_ <> '*' AND F4_DUPLIC = 'S' AND D2_TIPO IN ('C','P','N','I')
AND D2_EMISSAO <= (SELECT TOP 1 B9_DATA FROM SB9010 WHERE D_E_L_E_T_ <> '*' AND B9_FILIAL = D2_FILIAL ORDER BY 1 DESC)
--AND B1_COD LIKE '%5MAX%'
ORDER BY ROW_NUMBER() OVER (PARTITION BY D2_COD ORDER BY D2_COD, D2_EMISSAO DESC)
)t

IF OBJECT_ID('tempdb..#ult_custo') IS NOT NULL DROP TABLE #ult_custo

SELECT * INTO #ult_custo FROM(

SELECT TOP 1 WITH TIES B1_COD PRODUTO, D1_DTDIGIT,D1_CUSTO / NULLIF(D1_QUANT,0) CUSTO_UNIT  FROM SD1010 SD1
LEFT JOIN SF4010 SF4 ON
F4_CODIGO = D1_TES AND SF4.D_E_L_E_T_ <> '*'
LEFT JOIN SB1010 SB1 ON
B1_COD = D1_COD AND SB1.D_E_L_E_T_ <> '*'
WHERE SD1.D_E_L_E_T_ <> '*' AND F4_TEXTO LIKE '%COMPRA%'
ORDER BY ROW_NUMBER() OVER (PARTITION BY B1_COD ORDER BY D1_DTDIGIT DESC)
) t

IF OBJECT_ID('tempdb..#Z08S') IS NOT NULL DROP TABLE #Z08S

SELECT * INTO #Z08S FROM (
SELECT
	  'SER' AS TABELA
	, Z08_FILORI
	, Z08_LOCAL
	, B1_COD, B1_DESC, CTD_DESC01
	,Z08_DATA
	, SUBSTRING(Z08_DATA,7,2) + '/' + SUBSTRING(Z08_DATA,5,2) + '/' + SUBSTRING(Z08_DATA,1,4) DT
	, TRIM(Z07_LOTE) LOTE, SUBSTRING(Z08_NF,1,9) NF, SUBSTRING(Z08_NF,10,3) SERIE
	, 'TES' AS TES
	, Z08_ACT
	, 'CF' AS CF
	, CASE
		WHEN Z08_TIPO IN ('D', 'J') THEN 'E'
		WHEN Z08_TIPO IN ('M', 'S') THEN 'S'
	ELSE
		''
	END TIPO
	, CASE
		WHEN Z08_TIPO IN ('D', 'J') THEN 1
		WHEN Z08_TIPO IN ('M', 'S') THEN -1
	END QUANT
	, Z08_IDENT
	, 'PEDIDO' AS PEDIDO
	, Z08_ID
	, D2_TIPO
	, F4_ESTOQUE
	, SD2.CLIFOR_COD
	, SD2.CLIFOR_LOJA
	, SD2.CLIFOR_NREDUZ
	, SD2.CLIFOR_NOME
	, Z08_USER
FROM Z08010 
LEFT JOIN Z07010 ON
Z07_ID = Z08_ID AND Z07010.D_E_L_E_T_ <> '*'
LEFT JOIN SB1010 SB1 ON
SB1.D_E_L_E_T_ <> '*' AND B1_COD = Z07_PROD
LEFT JOIN CTD010 CTD ON
CTD_ITEM = SB1.B1_ITEMCC AND CTD.D_E_L_E_T_ <> '*'
LEFT JOIN #SD2_NFS SD2 ON
Z08_FILORI = D2_FILIAL AND SUBSTRING(Z08_NF,1,9) = D2_DOC AND SUBSTRING(Z08_NF,10,3) = D2_SERIE
AND SUBSTRING(Z08_CLIFOR,1,6) = SD2.CLIFOR_COD AND SUBSTRING(Z08_CLIFOR,7,2) = SD2.CLIFOR_LOJA
LEFT JOIN (
	SELECT B6_IDENT, B6_PRODUTO, B6_PODER3, SUM(B6_SALDO) SALDO, B6_DOC, B6_SERIE,B6_FILIAL FROM SB6010 WHERE D_E_L_E_T_ <> '*'  GROUP BY B6_IDENT, B6_PRODUTO, B6_PODER3,B6_DOC,B6_FILIAL,B6_SERIE) SB6 ON
	B6_IDENT = Z08_IDENT AND B6_PRODUTO = B1_COD AND B6_PODER3 = 'R' AND B6_FILIAL = Z08_FILORI
WHERE Z08010.D_E_L_E_T_ <> '*' AND Z08_TIPO IN ('M', 'S')
AND Z08_ACT LIKE '%REM%'
--AND SALDO >0
--AND Z08_IDENT = '521333'
) t;

IF OBJECT_ID('tempdb..#Z08E') IS NOT NULL DROP TABLE #Z08E

SELECT * INTO #Z08E FROM (
SELECT * FROM (
SELECT
	  'SER' AS TABELA
	, Z08_USER
	, Z08_FILORI
	, Z08_LOCAL
	, B1_COD, B1_DESC, CTD_DESC01
	, Z08_DATA
	, SUBSTRING(Z08_DATA,7,2) + '/' + SUBSTRING(Z08_DATA,5,2) + '/' + SUBSTRING(Z08_DATA,1,4) DT
	, TRIM(Z07_LOTE) LOTE, SUBSTRING(Z08_NF,1,9) NF, SUBSTRING(Z08_NF,10,3) SERIE
	, F3_OBSERV
	, 'TES' AS TES
	, Z08_ACT
	, 'CF' AS CF
	, CASE
		WHEN Z08_TIPO IN ('D', 'J', 'I') THEN 'E'
		WHEN Z08_TIPO IN ('M', 'S') THEN 'S'
	ELSE
		''
	END TIPO
	, CASE
		WHEN Z08_TIPO IN ('D', 'J', 'I') THEN 1
		WHEN Z08_TIPO IN ('M', 'S') THEN -1
	END QUANT
	, Z08_IDENT
	, 'PEDIDO' AS PEDIDO
	, Z08_ID
	, D1_TIPO
	, F4_ESTOQUE
	, ISNULL(SD1.CLIFOR_COD, Z08_CLIFOR) CLIFOR_COD
	, ISNULL(SD1.CLIFOR_LOJA, '01') CLIFOR_LOJA
	, ISNULL(SD1.CLIFOR_NREDUZ, Z08_NOMECF) CLIFOR_NREDUZ
	, ISNULL(SD1.CLIFOR_NOME, Z08_NOMECF) CLIFOR_NOME
	, ISNULL(B6_DOC, SUBSTRING(F3_OBSERV, 12, 9)) NF_ORIG
	, ISNULL(B6_SERIE, SUBSTRING(F3_OBSERV, 22, 3)) SERIE_ORIG
FROM Z08010 
LEFT JOIN Z07010 ON
Z07_ID = Z08_ID AND Z07010.D_E_L_E_T_ <> '*'
LEFT JOIN SB1010 SB1 ON
SB1.D_E_L_E_T_ <> '*' AND B1_COD = Z07_PROD
LEFT JOIN CTD010 CTD ON
CTD_ITEM = SB1.B1_ITEMCC AND CTD.D_E_L_E_T_ <> '*'
LEFT JOIN #SD1_NFS SD1 ON
Z08_FILORI = D1_FILIAL AND SUBSTRING(Z08_NF,1,9) = D1_DOC AND SUBSTRING(Z08_NF,10,3) = D1_SERIE
AND SUBSTRING(Z08_CLIFOR,1,6) = SD1.CLIFOR_COD AND SUBSTRING(Z08_CLIFOR,7,2) = SD1.CLIFOR_LOJA
LEFT JOIN (SELECT DISTINCT F3_NFISCAL, F3_FILIAL, F3_OBSERV FROM SF3010 WHERE D_E_L_E_T_ <> '*') SFE ON
F3_NFISCAL = SUBSTRING(Z08_NF,1,9) AND F3_FILIAL = Z08_FILORI
LEFT JOIN (
	SELECT B6_IDENT, B6_PRODUTO, B6_PODER3, SUM(B6_SALDO) SALDO, B6_DOC, B6_SERIE,B6_FILIAL FROM SB6010 WHERE D_E_L_E_T_ <> '*'  GROUP BY B6_IDENT, B6_PRODUTO, B6_PODER3,B6_DOC,B6_FILIAL,B6_SERIE) SB6 ON
	B6_IDENT = Z08_IDENT AND B6_PRODUTO = B1_COD AND B6_PODER3 = 'R' AND B6_FILIAL = Z08_FILORI
WHERE Z08010.D_E_L_E_T_ <> '*' AND Z08_TIPO IN ('D', 'J')
AND (Z08_ACT LIKE '%REM%' OR Z08_ACT LIKE '%RETORNO DEM%')
--AND Z08_IDENT = '521766'
--AND Z08_NF LIKE '%000105226%'
--AND Z08_NF LIKE '%000080524%'
--AND Z08_ID LIKE '%00000000000000036014%'
) u
LEFT JOIN (SELECT DISTINCT F2_DOC, F2_SERIE, F2_FILIAL FROM SF2010 WHERE D_E_L_E_T_ <> '*') SF2 ON
F2_DOC = NF_ORIG AND F2_SERIE = SERIE_ORIG AND F2_FILIAL = Z08_FILORI
) v

/*SELECT * FROM #Z08E
LEFT JOIN (
	SELECT B6_IDENT, B6_PRODUTO, B6_PODER3, SUM(B6_SALDO) SALDO FROM SB6010 WHERE D_E_L_E_T_ <> '*'  GROUP BY B6_IDENT, B6_PRODUTO, B6_PODER3) SB6 ON
	B6_IDENT = Z08_IDENT AND B6_PRODUTO = B1_COD AND B6_PODER3 = 'R'
where Z08_ID LIKE '%010649%'
WHERE F2_DOC IS NULL*/

IF OBJECT_ID('tempdb..#Z08V') IS NOT NULL DROP TABLE #Z08V

SELECT * INTO #Z08V FROM (
SELECT
  --TOP 2 WITH TIES 
  Z08_ID
, count(Z08_ORDEM) COUNT_ORDEM
, Z08_DATA
, CLIFOR_COD
, CLIFOR_LOJA
, B1_COD
FROM Z08010 
LEFT JOIN Z07010 ON
Z07_ID = Z08_ID AND Z07010.D_E_L_E_T_ <> '*'
LEFT JOIN SB1010 SB1 ON
SB1.D_E_L_E_T_ <> '*' AND B1_COD = Z07_PROD
LEFT JOIN CTD010 CTD ON
CTD_ITEM = SB1.B1_ITEMCC AND CTD.D_E_L_E_T_ <> '*'
LEFT JOIN #SD2_NFS SD2 ON
Z08_FILORI = D2_FILIAL AND SUBSTRING(Z08_NF,1,9) = D2_DOC AND SUBSTRING(Z08_NF,10,3) = D2_SERIE
AND SUBSTRING(Z08_CLIFOR,1,6) = SD2.CLIFOR_COD AND SUBSTRING(Z08_CLIFOR,7,2) = SD2.CLIFOR_LOJA
WHERE Z08010.D_E_L_E_T_ <> '*' AND Z08_TIPO IN ('M', 'S')
AND Z08_ACT LIKE '%VEND%' --AND Z08_ID = '00000000000000035050'
GROUP BY Z08_ID, Z08_DATA
, CLIFOR_COD
, CLIFOR_LOJA
, B1_COD
--ORDER BY 2 DESC
--ORDER BY ROW_NUMBER() OVER (PARTITION BY Z08_ID ORDER BY Z08_ORDEM DESC)
) s

IF OBJECT_ID('tempdb..#Z08D') IS NOT NULL DROP TABLE #Z08D

SELECT * INTO #Z08D FROM (
SELECT
  --TOP 1 WITH TIES 
  Z08_ID
, COUNT(Z08_ORDEM) COUNT_ORDEM
, Z08_DATA
, SUBSTRING(Z08_CLIFOR,1,6) CLIFOR_COD
, SUBSTRING(Z08_CLIFOR,7,2) CLIFOR_LOJA
, B1_COD
FROM Z08010 
LEFT JOIN Z07010 ON
Z07_ID = Z08_ID AND Z07010.D_E_L_E_T_ <> '*'
LEFT JOIN SB1010 SB1 ON
SB1.D_E_L_E_T_ <> '*' AND B1_COD = Z07_PROD
LEFT JOIN CTD010 CTD ON
CTD_ITEM = SB1.B1_ITEMCC AND CTD.D_E_L_E_T_ <> '*'
LEFT JOIN #SD1_NFS SD1 ON
Z08_FILORI = D1_FILIAL AND SUBSTRING(Z08_NF,1,9) = D1_DOC AND SUBSTRING(Z08_NF,10,3) = D1_SERIE
AND SUBSTRING(Z08_CLIFOR,1,6) = SD1.CLIFOR_COD AND SUBSTRING(Z08_CLIFOR,7,2) = SD1.CLIFOR_LOJA
WHERE Z08010.D_E_L_E_T_ <> '*' AND Z08_TIPO IN ('D')
AND Z08_ACT LIKE '%DEV%VEND%' 
AND Z08_ID = '00000000000000013007'
--ORDER BY ROW_NUMBER() OVER (PARTITION BY Z08_ID ORDER BY Z08_ORDEM DESC)
GROUP BY Z08_ID, Z08_DATA
, Z08_CLIFOR
, B1_COD
--ORDER BY 2 DESC
) d 

IF OBJECT_ID('tempdb..#Z08DV') IS NOT NULL DROP TABLE #Z08DV

SELECT * INTO #Z08DV FROM (
	SELECT #Z08V.Z08_ID,
	right(#Z08V.Z08_ID,6) Z08_ID_6,
	#Z08V.COUNT_ORDEM - ISNULL(#Z08D.COUNT_ORDEM,0) FATURADO	
	FROM #Z08V
	LEFT JOIN #Z08D ON
	#Z08V.Z08_ID = #Z08D.Z08_ID
	--WHERE #Z08D.Z08_ID IS NULL
	where (#Z08V.COUNT_ORDEM - ISNULL(#Z08D.COUNT_ORDEM,0)) > 0
	--ORDER BY 2 DESC
	) t

--SELECT DISTINCT Z08_ID FROM Z08010 WHERE D_E_L_E_T_ <> '*' AND Z08_ACT LIKE '%VEND%' AND Z08_TIPO = 'S'

/*SELECT
  TOP 1 WITH TIES 
  Z08_ID
, Z08_ORDEM
FROM Z08010 WHERE Z08_ACT LIKE '%VEND%' AND D_E_L_E_T_ <> '*' AND Z08_TIPO = 'S'
ORDER BY ROW_NUMBER() OVER (PARTITION BY Z08_ID ORDER BY Z08_ORDEM DESC)

SELECT * FROM Z08010 WHERE Z08_ID = '00000000000000027380'*/

IF OBJECT_ID('tempdb..#Z08FINAL') IS NOT NULL DROP TABLE #Z08FINAL

SELECT * INTO #Z08FINAL FROM (
select 
	'SER' AS TABELA
	, #Z08S.Z08_USER S_USER
	, #Z08E.Z08_USER E_USER
	, #Z08S.Z08_FILORI
	, #Z08S.Z08_LOCAL
	, #Z08S.B1_COD
	, #Z08S.B1_DESC
	, #Z08S.CTD_DESC01
	, #Z08S.DT
	, #Z08S.LOTE
	, #Z08S.NF
	, #Z08S.SERIE
	, 'TES' AS TES
	, #Z08S.Z08_ACT
	, 'CF' AS CF
	, #Z08S.TIPO
	, #Z08S.QUANT S_QUANT
	, IIF(ISNULL(#Z08DV.Z08_ID, ISNULL(#Z08E.QUANT,0)) = #Z08S.Z08_ID, 1,
		ISNULL(#Z08DV.Z08_ID, ISNULL(#Z08E.QUANT,0))) E_QUANT
	, #Z08S.Z08_IDENT
	, #Z08S.Z08_ID
	, #Z08S.D2_TIPO
	, #Z08S.F4_ESTOQUE
	, #Z08S.CLIFOR_COD
	, #Z08S.CLIFOR_LOJA
	, #Z08S.CLIFOR_NREDUZ
	, #Z08S.CLIFOR_NOME
	
FROM #Z08S
LEFT JOIN #Z08E ON
	#Z08S.Z08_IDENT = #Z08E.Z08_IDENT
AND #Z08S.Z08_ID = #Z08E.Z08_ID
AND #Z08S.B1_COD = #Z08E.B1_COD
and #Z08S.CLIFOR_COD = #Z08E.CLIFOR_COD
AND #Z08S.NF = #Z08E.F2_DOC
AND #Z08S.SERIE = #Z08E.F2_SERIE
LEFT JOIN #Z08DV ON
#Z08DV.Z08_ID = #Z08S.Z08_ID
WHERE
	#Z08S.Z08_ID <> ''
AND #Z08S.Z08_IDENT <> ''
--AND #Z08S.Z08_IDENT = '496175'
--AND #Z08S.Z08_ID = '00000000000000038597'
--and #Z08S.NF = '000021080'
--and t.B1_COD = 'SQUID18        '
) f

SELECT B6_EMISSAO, D2_NUMSERI, B6_CLIFOR,B6_LOJA, B6_PRODUTO,B6_QUANT, D2_LOTECTL
--, iif(FATURADO IS NULL, 'N', 'S') FATURADO
FROM(

SELECT B6_EMISSAO, D2_NUMSERI, B6_CLIFOR,B6_LOJA, B6_PRODUTO,B6_QUANT, D2_LOTECTL FROM(
select
B6_EMISSAO
,B6_FILIAL
,B6_LOCAL
,sum(B6_QUANT * -1) B6_QUANT
,B6_PRODUTO
,B6_IDENT
, D2_NUMSERI
, B6_CLIFOR, B6_LOJA
, D2_LOTECTL
FROM SB6010 SB6
LEFT JOIN SD2010 SD2 ON
( D2_FILIAL = B6_FILIAL AND D2_IDENTB6 = B6_IDENT AND B6_LOCAL = D2_LOCAL AND SD2.D_E_L_E_T_ <> '*' AND D2_DOC = B6_DOC)  	
WHERE SB6.D_E_L_E_T_ <> '*' AND B6_PODER3 = 'R' AND B6_EMISSAO < (select MIN(Z08_DATA) FROM Z08010 WHERE D_E_L_E_T_ <> '*')
group by B6_PRODUTO, B6_IDENT,B6_DOC,B6_FILIAL,B6_LOCAL,B6_EMISSAO,D2_NUMSERI, B6_CLIFOR, B6_LOJA, D2_LOTECTL

UNION ALL

select
B6_EMISSAO
,B6_FILIAL
,B6_LOCAL
,sum(B6_QUANT) quant
, B6_PRODUTO
, B6_IDENT
, D1_XSERIAL
, B6_CLIFOR, B6_LOJA
, D1_LOTECTL
FROM SB6010 SB6
LEFT JOIN SD1010 SD1 ON
( D1_FILIAL = B6_FILIAL AND D1_IDENTB6 = B6_IDENT AND B6_LOCAL = D1_LOCAL AND SD1.D_E_L_E_T_ <> '*' AND D1_DOC = B6_DOC )  	
WHERE SB6.D_E_L_E_T_ <> '*' AND B6_PODER3 = 'D' AND B6_EMISSAO < (select MIN(Z08_DATA) FROM Z08010 WHERE D_E_L_E_T_ <> '*')
group by B6_PRODUTO, B6_IDENT,B6_DOC,B6_FILIAL,B6_LOCAL,B6_EMISSAO,D1_XSERIAL, B6_CLIFOR, B6_LOJA, D1_LOTECTL
) t
--WHERE D2_NUMSERI LIKE '%048600%'

UNION ALL

SELECT * FROM(
select 
Z08_DATA
,RIGHT(Z08_ID,6)Z08_ID
, CLIFOR_COD
, CLIFOR_LOJA
, B1_COD
, QUANT
, LOTE
FROM #Z08S
UNION ALL
select 
Z08_DATA
,RIGHT(Z08_ID,6)Z08_ID
, CLIFOR_COD
, CLIFOR_LOJA
, B1_COD
, QUANT
, LOTE
FROM #Z08E) t
--WHERE Z08_ID LIKE '%048600%'

UNION ALL

SELECT B6_EMISSAO, D2_NUMSERI, B6_CLIFOR,B6_LOJA, B6_PRODUTO,B6_QUANT, D2_LOTECTL FROM(
select
B6_EMISSAO
,B6_FILIAL
,B6_LOCAL
,sum(B6_QUANT * -1) B6_QUANT
,B6_PRODUTO
,B6_IDENT
, D2_NUMSERI
, B6_CLIFOR
, B6_LOJA
, D2_LOTECTL
FROM SB6010 SB6
LEFT JOIN SD2010 SD2 ON
( D2_FILIAL = B6_FILIAL AND D2_IDENTB6 = B6_IDENT AND B6_LOCAL = D2_LOCAL AND SD2.D_E_L_E_T_ <> '*' AND D2_DOC = B6_DOC )  	
WHERE SB6.D_E_L_E_T_ <> '*' AND B6_PODER3 = 'R' AND B6_EMISSAO >= '20211206'
group by B6_PRODUTO, B6_IDENT,B6_DOC,B6_FILIAL,B6_LOCAL,B6_EMISSAO,D2_NUMSERI, B6_CLIFOR, B6_LOJA, D2_LOTECTL
UNION ALL
select
B6_EMISSAO
,B6_FILIAL
,B6_LOCAL
,sum(B6_QUANT) quant
, B6_PRODUTO
, B6_IDENT
, D1_XSERIAL
, B6_CLIFOR
, B6_LOJA
, D1_LOTECTL
FROM SB6010 SB6
LEFT JOIN SD1010 SD1 ON
( D1_FILIAL = B6_FILIAL AND D1_IDENTB6 = B6_IDENT AND B6_LOCAL = D1_LOCAL AND SD1.D_E_L_E_T_ <> '*' AND D1_DOC = B6_DOC )  	
WHERE SB6.D_E_L_E_T_ <> '*' AND B6_PODER3 = 'D' AND B6_EMISSAO >= '20211206'
--AND D1_XSERIAL = '048600'
--AND B6_DOC = '000107098'
group by B6_PRODUTO, B6_IDENT,B6_DOC,B6_FILIAL,B6_LOCAL,B6_EMISSAO,D1_XSERIAL, B6_CLIFOR, B6_LOJA, B6_PRODUTO, D1_LOTECTL
) t


--WHERE D2_NUMSERI LIKE '%044232%'
/*
UNION ALL

SELECT
Z08_DATA, RIGHT(Z08_ID,6),CLIFOR_COD,CLIFOR_LOJA, B1_COD,
SUM(
	CASE WHEN TAB = 'V' THEN COUNT_ORDEM ELSE -COUNT_ORDEM END) QUANT
FROM(
SELECT
'V' AS TAB,Z08_DATA, Z08_ID,CLIFOR_COD,CLIFOR_LOJA, B1_COD, COUNT_ORDEM
FROM #Z08V

UNION ALL

SELECT
'D' AS TAB,Z08_DATA, Z08_ID,CLIFOR_COD,CLIFOR_LOJA, B1_COD, COUNT_ORDEM
FROM #Z08D)
Z08VD
GROUP BY Z08_DATA, Z08_ID,CLIFOR_COD,CLIFOR_LOJA, B1_COD
*/
) u
--LEFT JOIN #Z08DV ON
--Z08_ID_6 = D2_NUMSERI
--WHERE D2_NUMSERI LIKE '%048600%'
--AND FATURADO IS NULL
ORDER BY 1
