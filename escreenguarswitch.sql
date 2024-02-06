--select encounters in History status > 1 year dos where Escreen National is guarantor 
if object_id('tempdb..#tempEscreen') is not null drop table #tempEscreen;
select distinct 
		pe.enc_id,
		pe.practice_id,
		pe.enc_nbr,
		a.acct_nbr

	into #tempEscreen

from patient_encounter pe
	join vw_enc_balance b on b.enc_id = pe.enc_id
	left join accounts a on a.guar_id = pe.person_id
where pe.guar_id = '0BD0C5BF-019A-4680-A2AF-EA7BC57D28ED' --escreen national
	and pe.practice_id = 0001
	and enc_status = 'H'
	and b.enc_bal = 0
	and billable_timestamp < getdate() -180
 
--drop table #tempEscreen

--select * from #tempEscreen
 
--update guarantor to patient if account exists

update patient_encounter
set guar_id = person_id, guar_type = 'P'
where enc_id in (select enc_id from #tempEscreen where acct_nbr is not null)
--select encounters where patient doesn't have account

select * 
from #tempEscreen
where enc_id in (select enc_id from #tempEscreen where acct_nbr is null)