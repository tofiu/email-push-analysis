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
​
users as (
  select
    cast(regid as string) as regid,
    audience,
    case
      when
        audience like '%11-01-20%'
      then
        DATE(2020, 11, 01)
      when
        audience like '%12-05-20%'
      then
        DATE(2020, 12, 05)
    end as push_date
  from
    `i-dss-ent-data.temp_mk.uefa_rfy_tactics`
  where
    regid is not null
),
​
users_count as (
  select
    audience,
    count(distinct regid) as total_users
  from
    users
  group by
    1
),
​
aa_data as (
  select
    distinct v69_registration_id_nbr as regid,
  from
    `i-dss-ent-data.dw_vw.aa_video_detail_reporting_day`
  where
    day_dt between '2020-11-01' and '2021-01-27'
    and v69_registration_id_nbr is not null
    and lower(video_show_nm) not like '%uefa%'
    and video_full_episode_ind = True
    and video_content_duration_sec_qty >= 180
),
​
new_content as (
  select
    audience,
    count(distinct regid) as new_content_users
  from
    users
  where
    regid in (select regid from aa_data)
    and regid is not null
  group by
    1
),
​
cancelled_users as (
  select
    audience,
    count(distinct u.regid) as cancelled
  from
    users as u
  left join
    user_info as ui
  on
    u.regid = ui.regid
  where
    ui.expiration_dt is not null
    and ui.expiration_dt between u.push_date and '2021-01-27'
  group by
   1
),
​
ret_30_day as (
  select
    audience,
    count(distinct u.regid) as ret30_users
  from
    users as u
  left join
    user_info as ui
  on
    u.regid = ui.regid
  where
    ui.expiration_dt is null
    or ui.expiration_dt >= date_add(u.push_date, INTERVAL 30 DAY)
  group by
   1
),
​
ret_60_day as (
  select
    audience,
    count(distinct u.regid) as ret60_users
  from
    users as u
  left join
    user_info as ui
  on
    u.regid = ui.regid
  where
    ui.expiration_dt is null
    or ui.expiration_dt >= date_add(u.push_date, INTERVAL 60 DAY)
  group by
   1
)
​
select
  uc.audience,
  sum(total_users) as audience_size,
  sum(new_content_users) as new_content_users,
  round(
    sum(new_content_users) / sum(total_users), 2
  ) as new_content_users_percent,
  sum(cancelled) as cancelled,
  round(
    sum(cancelled) / sum(total_users), 2
  ) as cancellation_rate,
  sum(ret30_users) as ret30_days,
  round(
    sum(ret30_users) / sum(total_users), 2
  ) as ret30_rate,
  sum(ret60_users) as ret60_days,
  round(
    sum(ret60_users) / sum(total_users), 2
  ) as ret60_rate,
from
  users_count as uc
join
  new_content as nc
on
  uc.audience = nc.audience
join
  cancelled_users as cu
on
  uc.audience = cu.audience
join
  ret_30_day as r30
on
  uc.audience = r30.audience
join
  ret_60_day as r60
on
  uc.audience = r60.audience
group by
  1
order by
  SPLIT(uc.audience, '_')[safe_ordinal(2)], 1