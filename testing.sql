
-- Checking System Counters
select distinct last_generated, counter_type from system_counters where counter_type like '%account%'


-- Testing SP 
-- To do test higher amounts -- investigate batching? 
--exec [dbo].[csm_missingacct] @accounttype = 'escreen', @read_or_load = 1, @limitInt = 10000 -- 10k 8 seconds to display, 27 seconds to run
--exec [dbo].[csm_missingacct] @accounttype = 'escreen', @read_or_load = 1, @limitInt = 2000 -- 2k 3 seconds to display, 5 seconds to run
--exec [dbo].[csm_missingacct] @accounttype = 'escreen', @read_or_load = 1, @limitInt = 50000 -- Remainder -- 146,629 1:50 to display. 50k - 23s to display, 38 seconds to run
exec [dbo].[csm_missingacct] @accounttype = 'escreen', @read_or_load = 1, @limitInt = 500000 -- Remainder 96,569 :26 to display. :54 to run


-- Update system counters -- fix after initial testing 
/*
if object_id('tempdb..#lastgen') is not null drop table #lastgen;
select a.practice_id+'account' as counter_type,
		max(a.acct_nbr) as last_generated
	into #lastgen --select count(*)
from accounts a
	where convert(date, a.create_timestamp) = convert(date,getdate())
group by a.practice_id

update c
set c.last_generated = l.last_generated --select *
from system_counters c
	join #lastgen l on c.counter_type=l.counter_type
*/
select * from accounts where guar_id = '0BD0C5BF-019A-4680-A2AF-EA7BC57D28ED'