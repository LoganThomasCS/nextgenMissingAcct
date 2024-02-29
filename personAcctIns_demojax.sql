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

-- Gather missing person accounts
if OBJECT_ID('tempdb..#tempmissacct') is not null drop table #tempmissacct;
select distinct 
		e.person_id,
		--e.site_id,
		--t.*,
		row_number () over (order by e.person_id) as rn 
	into #tempmissacct
from #tempEscreen t
	join patient_encounter e on t.enc_id=e.enc_id
where t.enc_id in (select enc_id from #tempEscreen where acct_nbr is null)

-- set number of times to loop
declare @iteration int = (select max(rn) from #tempmissacct)

-- create audit to track changes
if object_id('tempdb..#auditloopoutput') is not null drop table #auditloopoutput;
create table #auditloopoutput(
iteration int,
person_id uniqueidentifier,
new_acct uniqueidentifier,
new_acct_nbr decimal(12,0)
);

while @iteration > 0
begin
	begin transaction
		-- set new variables for accounts table
		declare @acct_id uniqueidentifier = newid()
		declare @acct_nbr decimal(12,0) = (select max(last_generated)+1 from system_counters where counter_type = '0001account')
		-- log insert values
		insert into #auditloopoutput
		select distinct 
				rn,
				person_id,
				@acct_id,
				@acct_nbr
		from #tempmissacct
		where rn = @iteration

		---- insert new accounts
		INSERT INTO accounts (
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
		)
		select distinct 
			'00001', 		--enterprise_id
			'0001', 		--practice_id
			'000', 			--site_id
			@acct_id,		--acct_id
			@acct_nbr, 		--acct_nbr
			person_id , 	--guar_id
			'P', 			--guar_type
			'Y',			--print_stmt_ind, 
			'Y',			--print_invoice_ind, 
			DATEPART(day, GETDATE()),	--stmt_day_of_month, 
			DATEPART(day, GETDATE()),	--invoice_day_of_month, 
			CONVERT(CHAR(8), DATEADD(month, 1, GETDATE()), 112),	--next_stmt_date, (112 means format of YYYYMMDD)
			CONVERT(CHAR(8), DATEADD(month, 1, GETDATE()), 112),	--next_invoice_date (112 means format of YYYYMMDD)
  			GETDATE(),		-- create_timestamp
			1,				-- created_by (1 denotes Administrator)
			1				-- modified_by
		from #tempmissacct
		where rn = @iteration

		-- increment system counters
		update system_counters
		set	last_generated = @acct_nbr -- select * from system_counters
		where counter_type = '0001account'

		-- decrement loop iterator value
		set @iteration = (select @iteration-1)
	commit transaction
end 

-- output audit details 
select * from #auditloopoutput order by new_acct_nbr desc;
-- TODO: refactor: 2 Loops? -- Lock table until insert is done to avoid constraint violations?
-- Loop over batches update system counter outside of outer loop (increment inside of inside loop)?
-- Delete from temp table after insertion (in outside batch loop)

 

----update guarantor to patient if account exists
--update patient_encounter
--set guar_id = person_id, guar_type = 'P'
--where enc_id in (select enc_id from #tempEscreen where acct_nbr is not null)
----select encounters where patient doesn't have account
