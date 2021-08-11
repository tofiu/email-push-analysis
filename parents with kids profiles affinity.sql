with stage1 as (
select
  *,
  RANK() OVER(PARTITION BY cbs_reg_user_id_cd  order by activation_dt desc) rank1
from
  `i-dss-ent-data.ent_vw.subscription_fct`
where
  src_system_id =115
  and cbs_reg_user_id_cd IS NOT NULL
),
sub_data as (
select cbs_reg_user_id_cd  from stage1
where rank1=1 and sub_status_desc='active'
),

kids_profiles as ( 
select distinct v69_registration_id_nbr, 
from dw_vw.aa_video_detail_reporting_day 
where v69_registration_id_nbr is not null 
and lower(v127_profile_type_cd) like "%kids%"
), 

parents_with_kids as (
select distinct v69_registration_id_nbr regid, 
v126_profile_id, 
v127_profile_type_cd,
from dw_vw.aa_video_detail_reporting_day 
where v69_registration_id_nbr is not null 
and lower(v127_profile_type_cd) like "%adult%" 
and v69_registration_id_nbr in (select distinct v69_registration_id_nbr from kids_profiles)
and v69_registration_id_nbr in (select distinct cbs_reg_user_id_cd from sub_data)
),


vod_affinity as (
select 
	vc.video_series_nm, 
	SUM(video_content_duration_sec_qty)/120 streaming_hours, 
	SUM(video_start_cnt) streams, 
	COUNT(distinct v69_registration_id_nbr) current_active_users
from `dw_vw.aa_video_detail_reporting_day` cs
join
  `dw_vw.mpx_video_content` vc
on 
  cs. v31_mpx_reference_guid = vc.mpx_reference_guid
where
  cs.video_full_episode_ind IS TRUE
  and report_suite_id_nm not in ("cbsicbstve")
  and day_dt between '2021-01-01' and '2021-05-31'
  and v126_profile_id in (select distinct v126_profile_id from parents_with_kids)
group by 1
order by 2 desc
)

select * from VOD_affinity 