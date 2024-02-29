IF OBJECT_ID('tempdb..#enchg') IS NOT NULL DROP TABLE #enchg;

SELECT DISTINCT 
		e.practice_id,
		e.location_id,
		e.guar_id,
		count(e.enc_id) as encs,
		count(c.charge_id) as chgs
	INTO #enchg
FROM patient_encounter e
	JOIN charges c ON e.enc_id = c.source_id
WHERE e.guar_type = 'E'
	AND e.billable_ind = 'Y' 
	--and e.guar_id IN ('','')
GROUP BY e.practice_id,
		 e.location_id,
		 e.guar_id
	

SELECT DISTINCT TOP 100
		(SELECT practice_name from practice WHERE practice_id=g.practice_id) practice,
		(SELECT location_name FROM location_mstr where location_id=g.location_id) center,
		(SELECT name FROM employer_mstr WHERE employer_id=g.guar_id) employer,
		g.encs,
		g.chgs,
		(SELECT acct_nbr FROM accounts where guar_id=g.guar_id and practice_id=g.practice_id) acct_nbr
FROM #enchg g

ORDER BY g.encs desc


SELECT DISTINCT TOP 100
		(SELECT practice_name FROM practice WHERE practice_id=e.practice_id) practice,
		(SELECT name FROM employer_mstr WHERE employer_id=e.guar_id) employer,
		SUM(e.encs) as encs,
		SUM(e.chgs) as chgs

FROM #enchg e
GROUP BY e.practice_id,
		 e.guar_id
ORDER BY 3 DESC

SELECT DISTINCT TOP 100
		(SELECT name FROM employer_mstr WHERE employer_id=e.guar_id) employer,
		SUM(e.encs) as encs,
		SUM(e.chgs) as chgs

FROM #enchg e
GROUP BY e.guar_id
ORDER BY 2 DESC