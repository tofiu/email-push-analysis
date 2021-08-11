with device_data as (
  SELECT 
  -- a.day_dt,
  -- device_type_nm ,
  case when subscription_state_desc ='tve' then 'TVE' else 'AA Subs' end as User_type,
  count(distinct a.visit_session_id) as total_sessions,
  count(distinct post_visitor_id) total_viewers,
  count(distinct v69_registration_id_nbr) total_subscribers,
  -- count(distinct v69_registration_id_nbr)+(count(distinct(case when v69_registration_id_nbr <>'-' then null else post_visitor_id end))/
  -- (count(distinct case when v69_registration_id_nbr <>'-' then post_visitor_id else null end)/count(distinct v69_registration_id_nbr))) as total_adjusted_subscribers,
  sum(a. video_start_cnt ) as total_streams, 
  round(sum(DATETIME_DIFF((case when strm_end_event_dt_ht >= end_time_dt_ht
          then end_time_dt_ht else strm_end_event_dt_ht end),
      (case when strm_start_event_dt_ht <= start_time_dt_ht
              then start_time_dt_ht else strm_start_event_dt_ht end), SECOND))/3600, 1) as total_streaming_hours
  FROM 
  dw_vw.aa_video_detail_reporting_day a join 
  
  (select  
        lower(affiliate_cd) as affiliate_cd, day_dt, show_nm, start_time_dt_ht, end_time_dt_ht
        from `i-dss-cdm-data.ent_vw.cbs_aa_syncbak_schedule_dim` syn
        where syn.day_dt between '{start_date}' and '{end_date}' --- modify the date selection based on date we have SEC game on AA
        ) b 
  on a.livetv_affiliate_cd = b.affiliate_cd and a.day_dt =cast(b.start_time_dt_ht as date)
  where (a.day_Dt between '{start_date}' and '{end_date}'  --- modify the date selection based on date we have SEC game on AA
  )
  and v31_mpx_reference_guid in ('70C7B4F3-E4B7-13C3-0A99-E1A1C2DE72CD','_55cL7EscO2mdFcpsZVcQ3VtXNA5bcA_')
        and 
        ( (strm_start_event_dt_ht between start_time_dt_ht and end_time_dt_ht)
          or (strm_end_event_dt_ht between start_time_dt_ht and end_time_dt_ht)
         or (strm_start_event_dt_ht <= start_time_dt_ht and strm_end_event_dt_ht >= end_time_dt_ht )
         )
  and show_nm='College Football'
  and v69_registration_id_nbr is not null
  and device_type_nm not like 'Mobile Web'
  group by 1
  order by 1
)
select * from device_data
;

with soccer_data as (
SELECT 
  device_platform_nm, 
  v69_registration_id_nbr,
  -- device_type_nm,
  count(distinct a.visit_session_id) total_sessions,
  count(distinct a.post_visitor_id) total_viewers, 
  count(distinct a.v69_registration_id_nbr) total_subscribers, 
  sum(a.video_start_cnt) as total_streams, 
  sum(video_content_duration_sec_qty) as sec_watch
  from dw_vw. aa_video_detail_reporting_day a
      where video_full_episode_ind = true
      and day_dt >= '2021-01-01'
      AND ((reporting_series_nm) IN ("UEFA Champions League","UEFA Europa League")
        OR video_show_nm IN ("UEFA Champions League","UEFA Europa League"))
      and (v25_video_title_nm like '%Atalanta%' 
       or v25_video_title_nm like '%Benevento%'
       or v25_video_title_nm like '%Bologna%' 
       or v25_video_title_nm like '%Cagliari%' 
       or v25_video_title_nm like '%Crotone%'
       or v25_video_title_nm like '%Florentina%' 
       or v25_video_title_nm like '%Genoa%' 
       or v25_video_title_nm like '%Hellas Vernoa%' 
       or v25_video_title_nm like '%Internazionale%' 
       or v25_video_title_nm like '%Juventus%' 
       or v25_video_title_nm like '%Lazio%' 
       or v25_video_title_nm like '%Milan%' 
       or v25_video_title_nm like '%Napoli%' 
       or v25_video_title_nm like '%Parma%' 
       or v25_video_title_nm like '%Roma%' 
       or v25_video_title_nm like '%Sampdoria%' 
       or v25_video_title_nm like '%Sassuolo%' 
       or v25_video_title_nm like '%Spezia%' 
       or v25_video_title_nm like '%Torino%' 
       or v25_video_title_nm like '%Udinese%')
group by 1,2
), 
demos as (
SELECT 
*,
    CASE
        WHEN LOWER(gender_cd) LIKE 'f%'
        OR  LOWER(gender_cd) = 'girls'
        THEN 'F'
        WHEN LOWER(gender_cd) LIKE 'm%'
        OR  LOWER(gender_cd) = 'boys'
        THEN 'M'
        ELSE 'NA'
    END AS gender,
(EXTRACT(YEAR FROM CURRENT_DATE()) - CAST(birth_year_nbr AS INT64)) AS age

FROM soccer_data cs 
LEFT OUTER JOIN 
    dw_vw.registration_user_dim ru
ON
    (
        cs.v69_registration_id_nbr = CAST(ru.reg_user_id AS string)
        and src_system_id=108
    )
)
SELECT avg(age) subs FROM demos 
where total_streams >= 3 
and sec_watch > 180
and age < 99












with soccer_data as (
SELECT 
v69_registration_id_nbr,
  count(distinct a.visit_session_id) total_sessions,
  count(distinct a.post_visitor_id) total_viewers, 
  count(distinct a.v69_registration_id_nbr) total_subscribers, 
  sum(a.video_start_cnt) as total_streams, 
  sum(video_content_duration_sec_qty) as sec_watch
  from dw_vw. aa_video_detail_reporting_day a
      where video_full_episode_ind = true
      and day_dt >= '2021-01-01'
      AND ((reporting_series_nm) IN ("UEFA Champions League","UEFA Europa League")
        OR video_show_nm IN ("UEFA Champions League","UEFA Europa League"))
      and (v25_video_title_nm like '%Atalanta%' 
       or v25_video_title_nm like '%Benevento%'
       or v25_video_title_nm like '%Bologna%' 
       or v25_video_title_nm like '%Cagliari%' 
       or v25_video_title_nm like '%Crotone%'
       or v25_video_title_nm like '%Florentina%' 
       or v25_video_title_nm like '%Genoa%' 
       or v25_video_title_nm like '%Hellas Vernoa%' 
       or v25_video_title_nm like '%Internazionale%' 
       or v25_video_title_nm like '%Juventus%' 
       or v25_video_title_nm like '%Lazio%' 
       or v25_video_title_nm like '%Milan%' 
       or v25_video_title_nm like '%Napoli%' 
       or v25_video_title_nm like '%Parma%' 
       or v25_video_title_nm like '%Roma%' 
       or v25_video_title_nm like '%Sampdoria%' 
       or v25_video_title_nm like '%Sassuolo%' 
       or v25_video_title_nm like '%Spezia%' 
       or v25_video_title_nm like '%Torino%' 
       or v25_video_title_nm like '%Udinese%')
group by 1),

plans as (
SELECT 
v69_registration_id_nbr,
total_subscribers,
total_streams,
sec_watch,
case when plan_cd in ('allaccess_monthly', 'allaccess_annual') then 'lc'
when plan_cd in ('allaccess_ad_free_monthly', 'allaccess_ad_free_annual') then 'cf'
else null end as plan
from soccer_data s 
left join ent_vw.subscription_fct ru on s.v69_registration_id_nbr = CAST(ru.cbs_reg_user_id_cd AS string))

SELECT plan, sum(total_streams) total_streams
FROM plans
where total_streams >= 3 
and sec_watch > 180

group by 1