IF OBJECT_ID('tempdb..#escreenanalysis') IS NOT NULL DROP TABLE #escreenanalysis;

SELECT DISTINCT
		e.practice_id,
		a.acct_id,
		CONVERT(date,e.create_timestamp) as dos,
		count(distinct e.enc_id) as encs
	INTO #escreenanalysis
FROM patient_encounter e
	JOIN vw_enc_balance b on e.enc_id=b.enc_id
	LEFT JOIN accounts a ON e.person_id = a.guar_id
WHERE e.guar_id = '0BD0C5BF-019A-4680-A2AF-EA7BC57D28ED'
	AND a.guar_id IS NULL
	AND b.enc_bal = 0
	AND e.enc_status = 'H'
GROUP BY e.practice_id,
		 a.acct_id,
		 CONVERT(date,e.create_timestamp)
ORDER BY dos DESC, encs DESC

IF OBJECT_ID('tempdb..#wcmissingacct') IS NOT NULL DROP TABLE #wcmissingacct;

SELECT DISTINCT
		e.practice_id,
		a.acct_id,
		CONVERT(date,e.create_timestamp) as dos,
		count(distinct e.enc_id) as encs
	INTO #wcmissingacct
FROM patient_encounter e
	LEFT JOIN accounts a ON a.guar_id = e.guar_id
WHERE a.guar_id IS NULL
GROUP BY e.practice_id,
		 a.acct_id,
		 CONVERT(date,e.create_timestamp)
ORDER BY dos DESC, encs DESC

SELECT DISTINCT TOP 100
		dos,
		SUM(encs) as encs,
		'escreen' as enc_type
FROM #escreenanalysis
GROUP BY dos
ORDER BY dos DESC

--SELECT DISTINCT TOP 10
--		dos,
--		SUM(encs) as encs,
--		'escreen' as enc_type
--FROM #escreenanalysis
--GROUP BY dos
--ORDER BY encs DESC

SELECT DISTINCT TOP 10
		dos,
		SUM(encs) as encs,
		'missing' as enc_type
FROM #wcmissingacct
GROUP BY dos
ORDER BY dos DESC

--SELECT DISTINCT TOP 10
--		dos,
--		SUM(encs) as encs,
--		'missing' as enc_tpye
--FROM #wcmissingacct
--GROUP BY dos
--ORDER BY encs DESC


--SELECT DISTINCT TOP 10
--		dos,
--		SUM(encs) as encs,
--		practice_id,
--		'escreen' as enc_type

--FROM #escreenanalysis
--GROUP BY dos,
--		 practice_id

--UNION

--SELECT DISTINCT TOP 10
--		dos,
--		SUM(encs) as encs,
--		practice_id,
--		'missing' as enc_tpye
--FROM #wcmissingacct
--GROUP BY dos,
--		 practice_id
--ORDER BY dos DESC

