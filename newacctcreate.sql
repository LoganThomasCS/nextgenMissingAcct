-- Creat table of escreen encounters where the person does not have an account.
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

-- Populate loading escreen table with current account number per practice
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
where e.guar_id = '0BD0C5BF-019A-4680-A2AF-EA7BC57D28ED' -- escreen guarantor
	and b.enc_bal = 0 
	and a.acct_id is null 
	and e.person_id <> e.guar_id

-- Add row number to generate new account #'s 
if object_id('tempdb..#accountlogic') is not null drop table #accountlogic;
select distinct 
			*,
			ROW_NUMBER () over(partition by practice_id order by guar_id)[rn] 
		into #accountlogic 
from #missingacct

-- Set new account numbers in loading table
Update #accountlogic set acct_nbr = acc_counter+rn;


--validation, delete once done testing
select top 100 practice_id,acc_counter,acct_nbr, rn
from #accountlogic
where practice_id < '0009'
	and rn < 11
order by acct_nbr


--validation, delete once done testing (under 18 as of today)
select count(*) 
from #accountlogic a
	join person p on p.person_id=a.guar_id
where convert(date,p.date_of_birth) > (select dateadd(year,-18,CONVERT(date,getdate())))

--testing insert command speeds. delete once testing is complete and uncomment 
if object_id('tempdb..#accounts') is not null drop table #accounts;
create table #accounts (
enterprise_id char(5),
practice_id char(4), 
site_id char(3),
acct_id uniqueidentifier,
acct_nbr decimal(12,0), 
guar_id uniqueidentifier, 
guar_type char(1), 
print_stmt_ind char(1), 
print_invoice_ind char(1),
stmt_day_of_month smallint, 
invoice_day_of_month smallint, 
next_stmt_date varchar(8), 
next_invoice_date varchar(8), 
create_timestamp datetime,
created_by int,
modified_by int, 
);

--insert into accounts(
--		enterprise_id,
--		practice_id, 
--		site_id,
--		acct_id,
--		acct_nbr, 
--		guar_id, 
--		guar_type, 
--		print_stmt_ind, 
--		print_invoice_ind,
--		stmt_day_of_month, 
--		invoice_day_of_month, 
--		next_stmt_date, 
--		next_invoice_date, 
--		create_timestamp,
--		created_by,
--		modified_by)

-- delete insert command once done testing -- select command will stay the same.
insert into #accounts
select distinct
		enterprise_id,
		practice_id,
		site_id,
		acct_id,
		acct_nbr,
		guar_id,
		guar_type,
		print_stmt_ind,
		print_invoice_ind,
		stmt_day_of_month,
		invoice_day_of_month,
		next_stmt_date,
		next_invoice_date,
		create_timestamp,
		created_by,
		modified_by	
from #accountlogic

-- =========== Testing updates -- delete these and uncomment the real table name updates once done with validation. ===========
if object_id('tempdb..#system_counters') is not null drop table #system_counters;
create table #system_counters(
    counter_type varchar(20),
    last_generated varchar(50)
);

insert into #system_counters
select distinct
        counter_type,
        last_generated
from system_counters c
	join #accountlogic a on c.counter_type = ''+a.practice_id+'account'

update s set s.last_generated = (select max(acct_nbr) 
								 from #accountlogic a	
								 where ''+a.practice_id+'account'=s.counter_type
												)
from #system_counters s

select * from system_counters where counter_type = '0002account'
select * from #system_counters where counter_type = '0002account'
select max(rn) from #accountlogic where practice_id = '0002'

-- =========== Testing updates -- delete these and uncomment the real table name updates once done with validation. ===========

-- Uncomment for final run
--update c
--set c.last_generated = (select max(acct_nbr) 
--						from #accountlogic a	
--						where ''+a.practice_id+'account'=s.counter_type
--						)
--from system_counters c


-- =========== Create Table for WC encounters wher guarantor has no account ===========
-- Creat table of WC case encounters where no account exists for the guarantor
if object_id('tempdb..#missingwcacct') is not null drop table #missingwcacct;

create table #missingwcacct(
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

select distinct 
		e.practice_id,
		e.guar_id,
		e.guar_type,
		(select last_generated from system_counters where counter_type = ''+e.practice_id+'account') 
from patient_encounter e
	left join accounts a on e.guar_id = a.guar_id
where a.acct_id is null 
	and e.person_id <> e.guar_id

-- =========== Create Table for WC encounters where guarantor has no account ===========