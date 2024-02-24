USE [NGDemo]
GO

/****** Object:  StoredProcedure [dbo].[csm_missingacct]    Script Date: 2/23/2024 9:32:44 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		<Logan Thomas>
-- Create date: <2023.02.26>
-- Description:	<Creates new accounts that are either guarantors but don't have accounts, or to prep escreen encounters for guarantor flip to person as guarantor.>
-- =============================================
CREATE PROCEDURE [dbo].[csm_missingacct]
	-- Add the parameters for the stored procedure here
	@accounttype varchar(20),
	@read_or_load bit 

AS
BEGIN
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
	
	if @accounttype = 'escreen' 
	begin
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
	end
	else 
	begin
		insert into #missingacct(
		practice_id,
		guar_id,
		guar_type,
		acc_counter
		)
		select distinct 
				e.practice_id,
				e.guar_id,
				e.guar_type,
				(select last_generated from system_counters where counter_type = ''+e.practice_id+'account') 
		from patient_encounter e
			left join accounts a on e.guar_id = a.guar_id
		where a.acct_id is null 
			and e.person_id <> e.guar_id
	end 
	
	-- return if there are no missing accounts 
	If (select count(*) from #missingacct) = 0
	begin
		return
	end
	else 
	begin 
		-- Add row number and generate new account #'s 
		if object_id('tempdb..#accountlogic') is not null drop table #accountlogic;
		select *,ROW_NUMBER () over (partition by practice_id order by guar_id) [rn] into #accountlogic from #missingacct
		update #accountlogic set acct_nbr = acc_counter+rn
		
		if @read_or_load = 1
		begin
			insert into accounts(
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
					modified_by)
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
	
			-- Update system counters
			update c
			set c.last_generated = (select max(acct_nbr) 
									from #accountlogic a	
									where ''+a.practice_id+'account'=c.counter_type
									)
			from system_counters c
		end
		else
		begin
			select distinct * from #accountlogic
		end
	
		
		-- Environment cleanup
		if object_id('tempdb..#accountlogic') is not null drop table #accountlogic;
		if object_id('tempdb..#missingacct') is not null drop table #missingacct;
	
	end
END
GO


