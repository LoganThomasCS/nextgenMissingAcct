SELECT * from person where person_id = 'DD79A75A-C1B2-4163-BF03-0B6E0211D2AA'

select billable_timestamp,billable_ind, * from patient_encounter 
--select * into patient_encounter_bkup_20191025_guar from patient_encounter
where person_id = 'DD79A75A-C1B2-4163-BF03-0B6E0211D2AA'
--and enc_nbr = '609779'

select * from accounts where guar_id = 'DD79A75A-C1B2-4163-BF03-0B6E0211D2AA'



DECLARE v_cursor CURSOR FOR 
SELECT DISTINCT enterprise_id, practice_id, site_id, guar_id, guar_type 
FROM patient_encounter pe
WHERE NOT EXISTS (SELECT * 
					FROM accounts
						WHERE practice_id=pe.practice_id
						    AND guar_id=pe.guar_id
							AND guar_type=pe.guar_type)
	--AND pe.practice_id in ('0001','0002','0003','0012','0013')
	
FOR READ ONLY

DECLARE @enterprise_id char(5) 
DECLARE @practice_id char(4) 
DECLARE @site_id char(3) 
DECLARE @acct_nbr char(15)
DECLARE @guar_id char(36) 
DECLARE @guar_type char(1) 
DECLARE @next_acct_counter char(15)

OPEN v_cursor
FETCH v_cursor INTO @enterprise_id, @practice_id, @site_id, @guar_id, @guar_type

-------------------------------------------------------------
-- for each candidate record...
-------------------------------------------------------------
WHILE @@fetch_status = 0
BEGIN
	-------------------------------------------------------------
	-- get the NEXT account number from the counter table
	-------------------------------------------------------------
	SELECT @next_acct_counter = CONVERT(CHAR(15),last_generated + 1, 15) 
		from system_counters where counter_type = '' + @practice_id + 'account'
	SET @acct_nbr = @next_acct_counter 

	-------------------------------------------------------------
	-- create the missing account record
	-------------------------------------------------------------
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
	) VALUES ( 
	@enterprise_id, 		--enterprise_id
	@practice_id, 			--practice_id
	@site_id, 			--site_id
	NEWID(),			--acct_id
	@acct_nbr, 			--acct_nbr
	@guar_id, 	--guar_id
	@guar_type, 				--guar_type
	'Y',				--print_stmt_ind, 
	'Y',				--print_invoice_ind, 
	DATEPART(day, GETDATE()),	--stmt_day_of_month, 
	DATEPART(day, GETDATE()),	--invoice_day_of_month, 
	CONVERT(CHAR(8), DATEADD(month, 1, GETDATE()), 112),	--next_stmt_date, (112 means format of YYYYMMDD)
	CONVERT(CHAR(8), DATEADD(month, 1, GETDATE()), 112),	--next_invoice_date (112 means format of YYYYMMDD)
  	GETDATE(),			-- create_timestamp
	1,				-- created_by (1 denotes Administrator)
	1				-- modified_by
	)

	-------------------------------------------------------------
	-- one-up the counters table
	-------------------------------------------------------------
	UPDATE system_counters SET last_generated = @next_acct_counter 
		WHERE counter_type = '' + @practice_id + 'account'

	-------------------------------------------------------------
	-- get next candidate record
	-------------------------------------------------------------
	FETCH v_cursor INTO @enterprise_id, @practice_id, @site_id, @guar_id, @guar_type
END

CLOSE v_cursor
DEALLOCATE v_cursor