if object_id('tempdb..#missingacct') is not null drop table #missingacct;

create table #missingacct(
enterprise_id char(5) default '00001',
practice_id char(4), 
site_id char(3) default '000',
acct_id uniqueidentifier default newid(),
acc_counter decimal(12,0),
acct_nbr decimal(12,0), 
guar_id uniqueidentifier, 
guar_type char(1), 
print_stmt_ind char(1) default 'Y', 
print_invoice_ind char(1) default 'Y',
stmt_day_of_month smallint default DATEPART(day, GETDATE()), 
invoice_day_of_month smallint default DATEPART(day, GETDATE()), 
next_stmt_date varchar(8) default CONVERT(CHAR(8), DATEADD(month, 1, GETDATE()), 112), 
next_invoice_date varchar(8) default CONVERT(CHAR(8), DATEADD(month, 1, GETDATE()), 112), 
create_timestamp datetime default getdate(),
created_by int default 1,
modified_by int default 1, 
);

insert into #missingacct(
practice_id,
guar_id,
guar_type,
acc_counter
)

select distinct 
		e.practice_id,
		e.person_id,
		'P',
		(select last_generated from system_counters where counter_type = ''+e.practice_id+'account') 
from patient_encounter e
	join vw_enc_balance b on b.enc_id = e.enc_id
	left join accounts a on a.guar_id = e.person_id
where e.guar_id = '0BD0C5BF-019A-4680-A2AF-EA7BC57D28ED'
	and b.enc_bal = 0 
	and a.acct_id is null 
	and e.person_id <> e.guar_id

	 

if object_id('tempdb..#accountlogic') is not null drop table #accountlogic;
select distinct *,ROW_NUMBER () over(partition by practice_id order by guar_id)[rn] into #accountlogic from #missingacct --order by newid()

Update #accountlogic set acct_nbr = acc_counter+rn;

select top 100 practice_id,acc_counter,acct_nbr, rn
from #accountlogic
where practice_id < '0009'
	and rn < 11
order by acct_nbr



select count(*) 
from #accountlogic a
	join person p on p.person_id=a.guar_id
where convert(date,p.date_of_birth) > (select dateadd(year,-18,CONVERT(date,getdate())))

-- TODO: Insert, need batching? 
-- TODO: back off and use guar <> account_guar? - guarantee performance issues ironed out.
-- TODO: Analyze the account / employer records - how many employers would we need? 