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

users as (
  select
    cast(userid as string) as regid,
    audience,
    case
      when
        audience like '%2021-04-08%'
      then
        DATE(2021, 04, 08)
      when
        audience like '%2021-04-11%'
      then
        DATE(2021, 04, 11)
      when 
        audience like '%control%' 
      then 
        DATE(2021, 04, 08)
    end as push_date
  from
    `i-dss-ent-data.temp_tliu.masters_data`
  where
    userid is not null
),

users_count as (
  select
    audience,
    count(distinct regid) as total_users
  from
    users
  group by
    1
),

masters_viewers as (
  select
      distinct v69_registration_id_nbr as regid
  from
      `i-dss-ent-data.dw_vw.aa_video_detail_reporting_day`
  where
    (
        lower(reporting_series_nm) like '%the masters%'
        -- lower(reporting_series_nm) like '%golf%'
    )
    and day_dt >= '2021-04-08'
    and video_full_episode_ind = True
),

pga_viewers as (
  select
    distinct v69_registration_id_nbr as regid
  from
    `i-dss-ent-data.dw_vw.aa_video_detail_reporting_day` ms
  LEFT OUTER JOIN
    dw_vw.registration_user_dim ru
  ON
    (
      ms.v69_registration_id_nbr = CAST(ru.reg_user_id AS string)
      and src_system_id=115
    )
  join
    `i-dss-ent-data.ent_vw.cbs_aa_syncbak_schedule_dim` sbk
  on  
    ( 
      (
        case
          when CHAR_LENGTH(livetv_affiliate_cd) > 10
          then REPLACE(livetv_affiliate_cd, "dkvhjg_qfzvelkdc8utphelhywgy8eib|", "")
          when livetv_affiliate_cd like 'kpax%'
          then REPLACE(livetv_affiliate_cd, "kpax-", "")
          else livetv_affiliate_cd
        end
      ) = lower(sbk.affiliate_cd)
     and
      ( 
        (ms.strm_start_event_dt_ut between sbk.start_time_dt_ut and sbk.end_time_dt_ut)
        or (ms.strm_end_event_dt_ut between sbk.start_time_dt_ut and sbk.end_time_dt_ut)
        or (ms.strm_start_event_dt_ut <= sbk.start_time_dt_ut and ms.strm_end_event_dt_ut >= sbk.end_time_dt_ut)
       )
    )
  where 
    v31_mpx_reference_guid in ('70C7B4F3-E4B7-13C3-0A99-E1A1C2DE72CD', '_55cL7EscO2mdFcpsZVcQ3VtXNA5bcA_')
    and blackout_ind is false
    and (
      lower(show_nm) like '%golf%'
      or lower(show_nm) like '%masters%'
    )
    and ms.day_dt >= '2021-04-08'
    and sbk.day_dt >= '2021-04-08'
    and v69_registration_id_nbr is not null 
),

aa_data as (
  select
    distinct regid,
  from
    (
      select
        regid
      from
        masters_viewers
      union distinct
      select
        regid
      from
        pga_viewers
    ) as reg
),

aa_data_new as (
  select 
    distinct v69_registration_id_nbr as regid
  from 
   `i-dss-ent-data.dw_vw.aa_video_detail_reporting_day`
  where
    day_dt between '2021-04-08' and '2021-06-01'
    and v69_registration_id_nbr is not null
    and (lower(video_show_nm) not like '%pga%' or lower(video_show_nm) not like '%the%masters%')
    and video_full_episode_ind = True
    and video_content_duration_sec_qty >= 180
),

new_content as (
  select
    audience,
    count(distinct regid) as new_content_users
  from
    users
  where
    regid in (select regid from aa_data_new)
    and regid is not null
  group by
    1)
,
golf_content as (
  select
    audience,
    count(distinct regid) as golf_content_users
  from
    users
  where
    regid in (select regid from aa_data)
    and regid is not null
  group by
    1
),

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
    and ui.expiration_dt between u.push_date and '2021-05-27'
  group by
   1
),

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
)

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
  ) as ret30_rate
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
group by
  1
order by
  SPLIT(uc.audience, '_')[safe_ordinal(2)], 1