-- upgrades
select *
from ent_vw.subscription_fct 
where src_system_id=115
and signup_plan_cd='allaccess_monthly'
and trial_start_dt between '2020-01-01' and '2020-01-31'
and paid_start_dt is not null
and subscription_platform_cd not in ('Apple iOS','Apple TV','SHOWTIME')
and plan_cd='allaccess_ad_free_monthly'
and cast(latest_plan_change_dt_ut as date) between '2020-01-01' and '2020-01-31' ---apply filter for date when they upgraded their plan

-- trial conversion 
select count(distinct case when trial_start_dt is not null and paid_start_dt is not null then subscription_guid else null end) as Trial_to_paid,
count(distinct case when trial_start_dt is not null then subscription_guid else null end) as Trial_starts,
count(distinct case when trial_start_dt is not null and cancel_dt is not null and paid_start_dt is null then subscription_guid else null end) as Trial_to_cancelled,
count(distinct case when trial_start_dt is not null and paid_start_dt is not null then subscription_guid else null end)/count(distinct case when trial_start_dt is not null  then subscription_guid else null end) as Trial_to_paid_conversion
from ent_vw.subscription_fct 
where src_system_id=115
and trial_start_dt between = '2021-03-14'
and subscription_platform_cd in ('RECURLY') 