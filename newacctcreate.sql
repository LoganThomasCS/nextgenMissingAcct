if object_id('tempdb..#missingacct') is not null drop table #missingacct;

create table #missingacct(
enterprise_id char(5) default '00001',
practice_id char(4), 
site_id char(3) default '000',
acct_id uniqueidentifier default newid(),
acct_nbr decimal(12,0), 
guar_id uniqueidentifier, 
guar_type char(1), 
print_stmt_ind char(1) default 'Y', 
print_invoice_ind char(1) default 'Y',
stmt_day_of_month smallint default (select DATEPART(day, GETDATE())), 
invoice_day_of_month smallint default (select DATEPART(day, GETDATE())), 
next_stmt_date varchar(8) default (select CONVERT(CHAR(8), DATEADD(month, 1, GETDATE()), 112)), 
next_invoice_date varchar(8) default (select CONVERT(CHAR(8), DATEADD(month, 1, GETDATE()), 112)), 
create_timestamp datetime default (select getdate()),
created_by int default 1,
modified_by int default 1
);

insert into #missingacct(
practice_id,
guar_id,
guar_type
)

select distinct 
		e.practice_id,
		e.person_id,
		e.guar_type
from patient_encounter e
	join vw_enc_balance b on b.enc_id = e.enc_id
	left join accounts a on a.guar_id = e.person_id
where e.guar_id = '0BD0C5BF-019A-4680-A2AF-EA7BC57D28ED'
	





/*
if object_id('tempdb..#tempEscreen') is not null drop table #tempEscreen;
--select encounters in History status > 1 year dos where Escreen National is guarantor 
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
--and pe.practice_id = 0001
and enc_status = 'H'
and b.enc_bal = 0
	--and billable_timestamp < getdate() -180
--drop table #tempEscreen
--select * from #tempEscreen
--update guarantor to patient if account exists
update patient_encounter
set guar_id = person_id, guar_type = 'P'
where enc_id in (select enc_id from #tempEscreen where acct_nbr is not null)
--select encounters where patient doesn't have account
select * from #tempEscreen
where enc_id in (select enc_id from #tempEscreen where acct_nbr is null)
*/