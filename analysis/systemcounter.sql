select last_generated -- last_generated = 958591 --958581 --958580
from system_counters
where counter_type = '0001account'

select * 
from system_counters 
where last_generated = (select max(last_generated) from system_counters) 

select getdate()

select * 
from enterprise

select * 
from practice

select distinct 
		site_id
from patient_encounter

select distinct 
		site_id
from accounts

select distinct 
		guar_type
from accounts

select *
from user_mstr
where user_id <= 0

--rollbacks for loop test
update system_counters
set last_generated = (SELECT MAX(acct_nbr) FROM accounts where practice_id = '0001')
where counter_type = '0001account'

select ltrim(person_nbr),* 
from person 
where person_id in ('D9487EEC-DA91-4FED-8D4B-FFDFD579242E'
					,'EF9FD9D3-47C2-494E-AB3E-FFDD9CDCC5FC'
					,'51248372-0EB0-46D9-B675-FFFD8EBF358B'
					,'3BF7EF38-1E8D-4403-B250-FFFA607B19AC'
					,'D060D53E-8F77-4632-8319-FFEF329C7DE5'
					,'344448D5-331F-4B82-ADC0-FFEC74A5EBFF'
					,'A23148A3-F4B6-4431-9BF2-FFE6DE5B296B'
					,'668DDF34-EFE1-445D-83A1-FFE55594B7D5'
					,'D9487EEC-DA91-4FED-8D4B-FFDFD579242E'
					,'92CC069D-D96F-48FC-86F2-FFDF1FEDF42A'
					,'A62691F7-81FE-4517-9EA7-FFDEBF22DF3A'
					,'93EBBAEA-9CC6-42AA-A4E7-FFD50D7EEC7D')

--select * from accounts where guar_id = 'EF9FD9D3-47C2-494E-AB3E-FFDD9CDCC5FC'
select * from accounts where guar_id = 'BC4146E8-24DD-4A05-B6CB-C8D0CACEBCBD'