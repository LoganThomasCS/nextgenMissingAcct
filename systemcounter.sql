select * from system_counters where last_generated = (select max(last_generated) from system_counters) 

select getdate()