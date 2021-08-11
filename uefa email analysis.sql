with user_info as (
  select
    cast(cbs_reg_user_id_cd as string) as regid,
    max(cancel_dt) as cancel_dt,
    max(expiration_dt) as expiration_dt,
  from
    `i-dss-ent-data.ent_vw.subscription_fct` subs
  where
    cbs_reg_user_id_cd is not null
    and src_system_id in (115, 134, 139)
    and subscription_platform_cd not in ('Apple iOS','Apple TV')
  group by
    1
),
open_users as (
select userid, 
'open' as audience,
DATE(2021, 05, 02) as email_date
from temp_tliu.uefa_may_open),

holdout_users as (
select userid, 
'holdout' as audience, 
DATE(2021, 05, 02) as email_date
from temp_tliu.uefa_may_holdout),

users as (
select userid, 
audience ,
email_date
from open_users
union all 
select userid, 
audience, 
email_date
from holdout_users)
,

users_count as (
  select
    audience,
    count(distinct userid) as total_users
  from
    users
  group by
    1
),

cancelled_users as (
  select
    audience,
    count(distinct userid) as cancelled
  from
    users as u
  left join
    user_info as ui
  on
    u.userid = ui.regid
  where
    ui.expiration_dt is not null
    and ui.expiration_dt between u.email_date and '2021-06-04'
  group by
   1
)
,
ret_users as ( 
select audience, 
count(distinct u.userid) as ret_users 
from users as u 
left join 
user_info as ui on u.userid = ui.regid
where ui.expiration_dt is null 
or ui.expiration_dt > '2021-06-04'
group by 1
)


select   
uc.audience,
  sum(total_users) as audience_size,
  sum(cancelled) as cancelled,
  round(
    sum(cancelled) / sum(total_users), 2
  ) as cancellation_rate,
  sum(ret_users) as ret, 
  round(
    sum(ret_users) / sum(total_users), 2
    ) as ret_rate
from
  users_count as uc
join
  cancelled_users as cu
on
  uc.audience = cu.audience
join ret_users as ru 
on uc.audience = ru.audience

group by
  1
order by
  SPLIT(uc.audience, '_')[safe_ordinal(2)], 1