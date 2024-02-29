
-- Checking System Counters
select distinct last_generated, counter_type from system_counters where counter_type like '%account%'


-- Testing SP 
-- To do test higher amounts -- investigate batching? 
exec [dbo].[csm_missingacct] @accounttype = 'escreen', @read_or_load = 1


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