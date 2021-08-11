-- CASUAL VS AVID FAN

with top_matches as (
SELECT
  match_nm,
  DATE_TRUNC(schedule_start_dt_ht, DAY) as schedule_dt,
  tournament_nm,
  SUM(media_start_cnt) as streams,
  SUM(match_stream_sec_qty)/60 as minutes
FROM
`i-dss-ent-data.ent_vw.uefa_video_overall_detail_day` 
WHERE LOWER(video_type_cd) = 'live'
AND day_dt > '2020-08-01'
AND report_suite_id_nm IN ('cnetcbscomsite')
-- AND report_suite_id_nm IN ('cnetcbscomsite', 'cbsicbssportssite')
AND tournament_nm IN ('UCL', 'UEL')
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 10
),match_counts as (
SELECT
  v69_registration_id_nbr,
--   v126_profile_id,
  COUNT(DISTINCT(CASE WHEN t.match_nm IS NOT NULL THEN u.match_nm ELSE NULL END)) as top_ten_matches,
  COUNT(DISTINCT(CASE WHEN t.match_nm IS NULL THEN u.match_nm ELSE NULL END)) as non_top_ten_matches,
  COUNT(DISTINCT(CASE WHEN u.tournament_nm = 'UEL' AND u.match_stream_sec_qty >= 180 THEN u.match_nm ELSE NULL END)) as uel_matches,
  COUNT(DISTINCT(CASE WHEN u.tournament_nm = 'UCL' AND u.match_stream_sec_qty >= 180 THEN u.match_nm ELSE NULL END)) as ucl_matches,
  
FROM `i-dss-ent-data.ent_vw.uefa_video_overall_detail_day` u
LEFT JOIN top_matches t
ON u.match_nm = t.match_nm
AND DATE_TRUNC(u.schedule_start_dt_ht, DAY) = t.schedule_dt
WHERE u.day_dt > '2020-08-01'
AND LOWER(video_type_cd) = 'live'
AND u.report_suite_id_nm IN ('cnetcbscomsite')
AND u.tournament_nm IN ('UCL', 'UEL')
AND u.media_start_cnt > 0
GROUP BY 1
)SELECT
  COUNT(DISTINCT(CASE WHEN top_ten_matches > 0 AND non_top_ten_matches = 0 THEN v69_registration_id_nbr ELSE NULL END)) as casual_fan,
  COUNT(DISTINCT(CASE WHEN uel_matches >= 10 AND ucl_matches >= 10 THEN v69_registration_id_nbr ELSE NULL END)) as avid_fan
FROM match_counts

-----------------------------------------------

--SQL for number of accounts/hh broken down by match days watched (3 minutes minumum)
with account_match_days as (
SELECT
  v69_registration_id_nbr,
  COUNT(DISTINCT(date_trunc(schedule_start_dt_ht, DAY))) as match_days
FROM
`i-dss-ent-data.ent_vw.uefa_video_overall_detail_day` u
WHERE LOWER(video_type_cd) = 'live'
AND day_dt > '2020-10-01'
AND report_suite_id_nm IN ('cnetcbscomsite')
-- AND report_suite_id_nm IN ('cnetcbscomsite', 'cbsicbssportssite')
AND tournament_nm IN ('UCL', 'UEL')
AND match_stream_sec_qty >= 180
GROUP BY 1
)SELECT
  match_days,
  COUNT(DISTINCT(v69_registration_id_nbr )) as sub_hh
FROM account_match_days a
JOIN `i-dss-ent-data.ent_vw.subscription_fct` s
ON a.v69_registration_id_nbr = s.cbs_reg_user_id_cd 
WHERE src_system_id in (115) 
AND (s.expiration_dt >= CURRENT_DATE() OR s.expiration_dt IS NULL)
GROUP BY 1
ORDER BY 1 DESC

----------------------------------------------------

--TEAM FANDOM
with home_away_matches as (
-- home matches
SELECT
  CASE 
    WHEN home_team_nm IN ('AC Milan', 'Milan') THEN 'AC Milan'
    WHEN home_team_nm IN ('AFC Ajax', 'Ajax') THEN 'Ajax'
    WHEN home_team_nm IN ('Antwerp', 'Royal Antwerp FC') THEN 'Antwerp'
    WHEN home_team_nm IN ('Arsenal', 'Arsenal FC') THEN 'Arsenal'
    WHEN home_team_nm IN ('AS Roma', 'Roma') THEN 'Roma'
    WHEN home_team_nm IN ('Atalanta BC', 'Atalanta') THEN 'Atalanta'
    WHEN home_team_nm IN ('Atlético', 'Club Atlético de Madrid') THEN 'Atlético'
    WHEN home_team_nm IN ('B. Mönchengladbach', 'Mönchengladbach') THEN 'Mönchengladbach'
    WHEN home_team_nm IN ('Barcelona', 'FC Barcelona') THEN 'Barcelona'
    WHEN home_team_nm IN ('Leverkusen', 'Bayer 04 Leverkusen') THEN 'Leverkusen'
    WHEN home_team_nm IN ('Bayern', 'Bayern München', 'FC Bayern München') THEN 'Bayern'
    WHEN home_team_nm IN ('Benfica', 'SL Benfica') THEN 'Benfica'
    WHEN home_team_nm IN ('Borussia Dortmund', 'Dortmund') THEN 'Dortmund'
    WHEN home_team_nm IN ('Braga', 'SC Braga') THEN 'Braga'
    WHEN home_team_nm IN ('BSC Young Boys', 'Young Boys') THEN 'Young Boys'
    WHEN home_team_nm IN ('Chelsea', 'Chelsea FC') THEN 'Chelsea'
    WHEN home_team_nm IN ('Crvena zvezda', 'FK Crvena zvezda') THEN 'Crvena zvezda'
    WHEN home_team_nm IN ('Dinamo Zagreb', 'GNK Dinamo') THEN 'Dinamo Zagreb'
    WHEN home_team_nm IN ('Dynamo Kyiv', 'FC Dynamo Kyiv') THEN 'Dynamo Kyiv'
    WHEN home_team_nm IN ('FC Internazionale Milano', 'Internationale', 'Internationale', 'Internazionale') THEN 'Inter Milan'
    WHEN home_team_nm IN ('FC Krasnodar', 'Krasnodar') THEN 'Krasnodar'
    WHEN home_team_nm IN ('FC Midtjylland', 'Midtjylland') THEN 'Midtjylland'
    WHEN home_team_nm IN ('FC Porto', 'Porto') THEN 'Porto'
    WHEN home_team_nm IN ('FC Salzburg', 'Salzburg') THEN 'Salzburg'
    WHEN home_team_nm IN ('FC Shakhtar Donetsk', 'Shakhtar Donetsk') THEN 'Shakhtar Donetsk' 
    WHEN home_team_nm LIKE ('%Ferencvárosi%') THEN 'Ferencvárosi'
    WHEN home_team_nm IN ('KAA Gent', 'Gent') THEN 'Gent'
    WHEN home_team_nm IN ('Granada', 'Granada CF') THEN 'Granada'
    WHEN home_team_nm IN ('TSG 1899 Hoffenheim', 'Hoffenheim') THEN 'Hoffenheim'
    WHEN home_team_nm LIKE ('%stanbul Ba%') THEN 'Istanbul Basaksehir FK'
    WHEN home_team_nm IN ('S.S. Lazio', 'Lazio') THEN 'Lazio'
    WHEN home_team_nm IN ('Leicester City FC', 'Leicester') THEN 'Leicester'
    WHEN home_team_nm IN ('RB Leipzig', 'Leipzig') THEN 'Leipzig'
    WHEN home_team_nm IN ('Liverpool FC', 'Liverpool') THEN 'Liverpool'
    WHEN home_team_nm IN ('LOSC', 'LOSC Lille') THEN 'LOSC'
    WHEN home_team_nm IN ('M. Tel-Aviv', 'Maccabi Tel-Aviv FC') THEN 'Maccabi Tel-Aviv FC'
    WHEN home_team_nm IN ('Man. City', 'Manchester City FC') THEN 'Man. City'
    WHEN home_team_nm IN ('Man. United', 'Manchester United FC') THEN 'Man. United'
    WHEN home_team_nm IN ('Molde FK', 'Molde') THEN 'Molde'
    WHEN home_team_nm IN ('SSC Napoli', 'Napoli') THEN 'Napoli'
    WHEN home_team_nm IN ('Olympiacos FC', 'Olympiacos') THEN 'Olympiacos'
    WHEN home_team_nm IN ('Omonia FC', 'Omonia') THEN 'Omonia'
    WHEN home_team_nm IN ('PAOK FC', 'PAOK') THEN 'PAOK'
    WHEN home_team_nm IN ('Paris Saint-Germain', 'Paris') THEN 'PSG'
    WHEN home_team_nm IN ('PSV Eindhoven', 'PSV') THEN 'PSV'
    WHEN home_team_nm IN ('Rangers FC', 'Rangers') THEN 'Rangers'
    WHEN home_team_nm IN ('Real Madrid CF', 'Real Madrid') THEN 'Real Madrid'
    WHEN home_team_nm IN ('Real Sociedad de Fútbol', 'Real Sociedad') THEN 'Real Sociedad'
    WHEN home_team_nm IN ('Sevilla FC', 'Sevilla') THEN 'Sevilla'
    WHEN home_team_nm IN ('SK Slavia Praha', 'Slavia Praha') THEN 'Slavia Praha'
    WHEN home_team_nm IN ('Tottenham Hotspur', 'Tottenham') THEN 'Tottenham'
    WHEN home_team_nm IN ('Villarreal CF', 'Villarreal') THEN 'Villarreal'
    WHEN home_team_nm IN ('Wolfsberger AC', 'Wolfsberg') THEN 'Wolfsberg'
    ELSE home_team_nm END as team_nm,
  COUNT(DISTINCT(schedule_start_dt_ht)) as match_days
FROM
`i-dss-ent-data.ent_vw.uefa_video_overall_detail_day` 
WHERE LOWER(video_type_cd) = 'live'
AND day_dt > '2020-08-01'
AND report_suite_id_nm IN ('cnetcbscomsite')
AND tournament_nm IN ('UCL', 'UEL')
AND LOWER(match_nm) NOT LIKE ('star cam%')
GROUP BY 1UNION ALL
-- away matches
SELECT
  CASE 
    WHEN away_team_nm IN ('AC Milan', 'Milan') THEN 'AC Milan'
    WHEN away_team_nm IN ('AFC Ajax', 'Ajax') THEN 'Ajax'
    WHEN away_team_nm IN ('Antwerp', 'Royal Antwerp FC') THEN 'Antwerp'
    WHEN away_team_nm IN ('Arsenal', 'Arsenal FC') THEN 'Arsenal'
    WHEN away_team_nm IN ('AS Roma', 'Roma') THEN 'Roma'
    WHEN away_team_nm IN ('Atalanta BC', 'Atalanta') THEN 'Atalanta'
    WHEN away_team_nm IN ('Atlético', 'Club Atlético de Madrid') THEN 'Atlético'
    WHEN away_team_nm IN ('B. Mönchengladbach', 'Mönchengladbach') THEN 'Mönchengladbach'
    WHEN away_team_nm IN ('Barcelona', 'FC Barcelona') THEN 'Barcelona'
    WHEN away_team_nm IN ('Leverkusen', 'Bayer 04 Leverkusen') THEN 'Leverkusen'
    WHEN away_team_nm IN ('Bayern', 'Bayern München', 'FC Bayern München') THEN 'Bayern'
    WHEN away_team_nm IN ('Benfica', 'SL Benfica') THEN 'Benfica'
    WHEN away_team_nm IN ('Borussia Dortmund', 'Dortmund') THEN 'Dortmund'
    WHEN away_team_nm IN ('Braga', 'SC Braga') THEN 'Braga'
    WHEN away_team_nm IN ('BSC Young Boys', 'Young Boys') THEN 'Young Boys'
    WHEN away_team_nm IN ('Chelsea', 'Chelsea FC') THEN 'Chelsea'
    WHEN away_team_nm IN ('Crvena zvezda', 'FK Crvena zvezda') THEN 'Crvena zvezda'
    WHEN away_team_nm IN ('Dinamo Zagreb', 'GNK Dinamo') THEN 'Dinamo Zagreb'
    WHEN away_team_nm IN ('Dynamo Kyiv', 'FC Dynamo Kyiv') THEN 'Dynamo Kyiv'
    WHEN away_team_nm IN ('FC Internazionale Milano', 'Internationale', 'Internationale', 'Internazionale') THEN 'Inter Milan'
    WHEN away_team_nm IN ('FC Krasnodar', 'Krasnodar') THEN 'Krasnodar'
    WHEN away_team_nm IN ('FC Midtjylland', 'Midtjylland') THEN 'Midtjylland'
    WHEN away_team_nm IN ('FC Porto', 'Porto') THEN 'Porto'
    WHEN away_team_nm IN ('FC Salzburg', 'Salzburg') THEN 'Salzburg'
    WHEN away_team_nm IN ('FC Shakhtar Donetsk', 'Shakhtar Donetsk') THEN 'Shakhtar Donetsk' 
    WHEN away_team_nm LIKE ('%Ferencvárosi%') THEN 'Ferencvárosi'
    WHEN away_team_nm IN ('KAA Gent', 'Gent') THEN 'Gent'
    WHEN away_team_nm IN ('Granada', 'Granada CF') THEN 'Granada'
    WHEN away_team_nm IN ('TSG 1899 Hoffenheim', 'Hoffenheim') THEN 'Hoffenheim'
    WHEN away_team_nm LIKE ('%stanbul Ba%') THEN 'Istanbul Basaksehir FK'
    WHEN away_team_nm IN ('S.S. Lazio', 'Lazio') THEN 'Lazio'
    WHEN away_team_nm IN ('Leicester City FC', 'Leicester') THEN 'Leicester'
    WHEN away_team_nm IN ('RB Leipzig', 'Leipzig') THEN 'Leipzig'
    WHEN away_team_nm IN ('Liverpool FC', 'Liverpool') THEN 'Liverpool'
    WHEN away_team_nm IN ('LOSC', 'LOSC Lille') THEN 'LOSC'
    WHEN away_team_nm IN ('M. Tel-Aviv', 'Maccabi Tel-Aviv FC') THEN 'Maccabi Tel-Aviv FC'
    WHEN away_team_nm IN ('Man. City', 'Manchester City FC') THEN 'Man. City'
    WHEN away_team_nm IN ('Man. United', 'Manchester United FC') THEN 'Man. United'
    WHEN away_team_nm IN ('Molde FK', 'Molde') THEN 'Molde'
    WHEN away_team_nm IN ('SSC Napoli', 'Napoli') THEN 'Napoli'
    WHEN away_team_nm IN ('Olympiacos FC', 'Olympiacos') THEN 'Olympiacos'
    WHEN away_team_nm IN ('Omonia FC', 'Omonia') THEN 'Omonia'
    WHEN away_team_nm IN ('PAOK FC', 'PAOK') THEN 'PAOK'
    WHEN away_team_nm IN ('Paris Saint-Germain', 'Paris') THEN 'PSG'
    WHEN away_team_nm IN ('PSV Eindhoven', 'PSV') THEN 'PSV'
    WHEN away_team_nm IN ('Rangers FC', 'Rangers') THEN 'Rangers'
    WHEN away_team_nm IN ('Real Madrid CF', 'Real Madrid') THEN 'Real Madrid'
    WHEN away_team_nm IN ('Real Sociedad de Fútbol', 'Real Sociedad') THEN 'Real Sociedad'
    WHEN away_team_nm IN ('Sevilla FC', 'Sevilla') THEN 'Sevilla'
    WHEN away_team_nm IN ('SK Slavia Praha', 'Slavia Praha') THEN 'Slavia Praha'
    WHEN away_team_nm IN ('Tottenham Hotspur', 'Tottenham') THEN 'Tottenham'
    WHEN away_team_nm IN ('Villarreal CF', 'Villarreal') THEN 'Villarreal'
    WHEN away_team_nm IN ('Wolfsberger AC', 'Wolfsberg') THEN 'Wolfsberg'
    ELSE away_team_nm END as team_nm,
  COUNT(DISTINCT(schedule_start_dt_ht)) as match_days
FROM
`i-dss-ent-data.ent_vw.uefa_video_overall_detail_day` 
WHERE LOWER(video_type_cd) = 'live'
AND day_dt > '2020-08-01'
AND report_suite_id_nm IN ('cnetcbscomsite')
AND tournament_nm IN ('UCL', 'UEL')
AND LOWER(match_nm) NOT LIKE ('star cam%')
GROUP BY 1
),team_matches as (
SELECT
  team_nm,
  SUM(match_days) as match_days
FROM home_away_matches 
GROUP BY 1
),home_away_match_counts as (
--home match counts
SELECT
  v69_registration_id_nbr,
  CASE 
    WHEN home_team_nm IN ('AC Milan', 'Milan') THEN 'AC Milan'
    WHEN home_team_nm IN ('AFC Ajax', 'Ajax') THEN 'Ajax'
    WHEN home_team_nm IN ('Antwerp', 'Royal Antwerp FC') THEN 'Antwerp'
    WHEN home_team_nm IN ('Arsenal', 'Arsenal FC') THEN 'Arsenal'
    WHEN home_team_nm IN ('AS Roma', 'Roma') THEN 'Roma'
    WHEN home_team_nm IN ('Atalanta BC', 'Atalanta') THEN 'Atalanta'
    WHEN home_team_nm IN ('Atlético', 'Club Atlético de Madrid') THEN 'Atlético'
    WHEN home_team_nm IN ('B. Mönchengladbach', 'Mönchengladbach') THEN 'Mönchengladbach'
    WHEN home_team_nm IN ('Barcelona', 'FC Barcelona') THEN 'Barcelona'
    WHEN home_team_nm IN ('Leverkusen', 'Bayer 04 Leverkusen') THEN 'Leverkusen'
    WHEN home_team_nm IN ('Bayern', 'Bayern München', 'FC Bayern München') THEN 'Bayern'
    WHEN home_team_nm IN ('Benfica', 'SL Benfica') THEN 'Benfica'
    WHEN home_team_nm IN ('Borussia Dortmund', 'Dortmund') THEN 'Dortmund'
    WHEN home_team_nm IN ('Braga', 'SC Braga') THEN 'Braga'
    WHEN home_team_nm IN ('BSC Young Boys', 'Young Boys') THEN 'Young Boys'
    WHEN home_team_nm IN ('Chelsea', 'Chelsea FC') THEN 'Chelsea'
    WHEN home_team_nm IN ('Crvena zvezda', 'FK Crvena zvezda') THEN 'Crvena zvezda'
    WHEN home_team_nm IN ('Dinamo Zagreb', 'GNK Dinamo') THEN 'Dinamo Zagreb'
    WHEN home_team_nm IN ('Dynamo Kyiv', 'FC Dynamo Kyiv') THEN 'Dynamo Kyiv'
    WHEN home_team_nm IN ('FC Internazionale Milano', 'Internationale', 'Internationale', 'Internazionale') THEN 'Inter Milan'
    WHEN home_team_nm IN ('FC Krasnodar', 'Krasnodar') THEN 'Krasnodar'
    WHEN home_team_nm IN ('FC Midtjylland', 'Midtjylland') THEN 'Midtjylland'
    WHEN home_team_nm IN ('FC Porto', 'Porto') THEN 'Porto'
    WHEN home_team_nm IN ('FC Salzburg', 'Salzburg') THEN 'Salzburg'
    WHEN home_team_nm IN ('FC Shakhtar Donetsk', 'Shakhtar Donetsk') THEN 'Shakhtar Donetsk' 
    WHEN home_team_nm LIKE ('%Ferencvárosi%') THEN 'Ferencvárosi'
    WHEN home_team_nm IN ('KAA Gent', 'Gent') THEN 'Gent'
    WHEN home_team_nm IN ('Granada', 'Granada CF') THEN 'Granada'
    WHEN home_team_nm IN ('TSG 1899 Hoffenheim', 'Hoffenheim') THEN 'Hoffenheim'
    WHEN home_team_nm LIKE ('%stanbul Ba%') THEN 'Istanbul Basaksehir FK'
    WHEN home_team_nm IN ('S.S. Lazio', 'Lazio') THEN 'Lazio'
    WHEN home_team_nm IN ('Leicester City FC', 'Leicester') THEN 'Leicester'
    WHEN home_team_nm IN ('RB Leipzig', 'Leipzig') THEN 'Leipzig'
    WHEN home_team_nm IN ('Liverpool FC', 'Liverpool') THEN 'Liverpool'
    WHEN home_team_nm IN ('LOSC', 'LOSC Lille') THEN 'LOSC'
    WHEN home_team_nm IN ('M. Tel-Aviv', 'Maccabi Tel-Aviv FC') THEN 'Maccabi Tel-Aviv FC'
    WHEN home_team_nm IN ('Man. City', 'Manchester City FC') THEN 'Man. City'
    WHEN home_team_nm IN ('Man. United', 'Manchester United FC') THEN 'Man. United'
    WHEN home_team_nm IN ('Molde FK', 'Molde') THEN 'Molde'
    WHEN home_team_nm IN ('SSC Napoli', 'Napoli') THEN 'Napoli'
    WHEN home_team_nm IN ('Olympiacos FC', 'Olympiacos') THEN 'Olympiacos'
    WHEN home_team_nm IN ('Omonia FC', 'Omonia') THEN 'Omonia'
    WHEN home_team_nm IN ('PAOK FC', 'PAOK') THEN 'PAOK'
    WHEN home_team_nm IN ('Paris Saint-Germain', 'Paris') THEN 'PSG'
    WHEN home_team_nm IN ('PSV Eindhoven', 'PSV') THEN 'PSV'
    WHEN home_team_nm IN ('Rangers FC', 'Rangers') THEN 'Rangers'
    WHEN home_team_nm IN ('Real Madrid CF', 'Real Madrid') THEN 'Real Madrid'
    WHEN home_team_nm IN ('Real Sociedad de Fútbol', 'Real Sociedad') THEN 'Real Sociedad'
    WHEN home_team_nm IN ('Sevilla FC', 'Sevilla') THEN 'Sevilla'
    WHEN home_team_nm IN ('SK Slavia Praha', 'Slavia Praha') THEN 'Slavia Praha'
    WHEN home_team_nm IN ('Tottenham Hotspur', 'Tottenham') THEN 'Tottenham'
    WHEN home_team_nm IN ('Villarreal CF', 'Villarreal') THEN 'Villarreal'
    WHEN home_team_nm IN ('Wolfsberger AC', 'Wolfsberg') THEN 'Wolfsberg'
    ELSE home_team_nm END as team_nm,
  COUNT(DISTINCT(schedule_start_dt_ht)) as match_days
FROM `i-dss-ent-data.ent_vw.uefa_video_overall_detail_day` u
WHERE u.day_dt > '2020-08-01'
AND LOWER(video_type_cd) = 'live'
AND u.report_suite_id_nm IN ('cnetcbscomsite')
AND u.tournament_nm IN ('UCL', 'UEL')
AND LOWER(match_nm) NOT LIKE ('star cam%')
AND u.match_stream_sec_qty >= 180
GROUP BY 1,2UNION ALL
--away match counts
SELECT
  v69_registration_id_nbr,
  CASE 
    WHEN away_team_nm IN ('AC Milan', 'Milan') THEN 'AC Milan'
    WHEN away_team_nm IN ('AFC Ajax', 'Ajax') THEN 'Ajax'
    WHEN away_team_nm IN ('Antwerp', 'Royal Antwerp FC') THEN 'Antwerp'
    WHEN away_team_nm IN ('Arsenal', 'Arsenal FC') THEN 'Arsenal'
    WHEN away_team_nm IN ('AS Roma', 'Roma') THEN 'Roma'
    WHEN away_team_nm IN ('Atalanta BC', 'Atalanta') THEN 'Atalanta'
    WHEN away_team_nm IN ('Atlético', 'Club Atlético de Madrid') THEN 'Atlético'
    WHEN away_team_nm IN ('B. Mönchengladbach', 'Mönchengladbach') THEN 'Mönchengladbach'
    WHEN away_team_nm IN ('Barcelona', 'FC Barcelona') THEN 'Barcelona'
    WHEN away_team_nm IN ('Leverkusen', 'Bayer 04 Leverkusen') THEN 'Leverkusen'
    WHEN away_team_nm IN ('Bayern', 'Bayern München', 'FC Bayern München') THEN 'Bayern'
    WHEN away_team_nm IN ('Benfica', 'SL Benfica') THEN 'Benfica'
    WHEN away_team_nm IN ('Borussia Dortmund', 'Dortmund') THEN 'Dortmund'
    WHEN away_team_nm IN ('Braga', 'SC Braga') THEN 'Braga'
    WHEN away_team_nm IN ('BSC Young Boys', 'Young Boys') THEN 'Young Boys'
    WHEN away_team_nm IN ('Chelsea', 'Chelsea FC') THEN 'Chelsea'
    WHEN away_team_nm IN ('Crvena zvezda', 'FK Crvena zvezda') THEN 'Crvena zvezda'
    WHEN away_team_nm IN ('Dinamo Zagreb', 'GNK Dinamo') THEN 'Dinamo Zagreb'
    WHEN away_team_nm IN ('Dynamo Kyiv', 'FC Dynamo Kyiv') THEN 'Dynamo Kyiv'
    WHEN away_team_nm IN ('FC Internazionale Milano', 'Internationale', 'Internationale', 'Internazionale') THEN 'Inter Milan'
    WHEN away_team_nm IN ('FC Krasnodar', 'Krasnodar') THEN 'Krasnodar'
    WHEN away_team_nm IN ('FC Midtjylland', 'Midtjylland') THEN 'Midtjylland'
    WHEN away_team_nm IN ('FC Porto', 'Porto') THEN 'Porto'
    WHEN away_team_nm IN ('FC Salzburg', 'Salzburg') THEN 'Salzburg'
    WHEN away_team_nm IN ('FC Shakhtar Donetsk', 'Shakhtar Donetsk') THEN 'Shakhtar Donetsk' 
    WHEN away_team_nm LIKE ('%Ferencvárosi%') THEN 'Ferencvárosi'
    WHEN away_team_nm IN ('KAA Gent', 'Gent') THEN 'Gent'
    WHEN away_team_nm IN ('Granada', 'Granada CF') THEN 'Granada'
    WHEN away_team_nm IN ('TSG 1899 Hoffenheim', 'Hoffenheim') THEN 'Hoffenheim'
    WHEN away_team_nm LIKE ('%stanbul Ba%') THEN 'Istanbul Basaksehir FK'
    WHEN away_team_nm IN ('S.S. Lazio', 'Lazio') THEN 'Lazio'
    WHEN away_team_nm IN ('Leicester City FC', 'Leicester') THEN 'Leicester'
    WHEN away_team_nm IN ('RB Leipzig', 'Leipzig') THEN 'Leipzig'
    WHEN away_team_nm IN ('Liverpool FC', 'Liverpool') THEN 'Liverpool'
    WHEN away_team_nm IN ('LOSC', 'LOSC Lille') THEN 'LOSC'
    WHEN away_team_nm IN ('M. Tel-Aviv', 'Maccabi Tel-Aviv FC') THEN 'Maccabi Tel-Aviv FC'
    WHEN away_team_nm IN ('Man. City', 'Manchester City FC') THEN 'Man. City'
    WHEN away_team_nm IN ('Man. United', 'Manchester United FC') THEN 'Man. United'
    WHEN away_team_nm IN ('Molde FK', 'Molde') THEN 'Molde'
    WHEN away_team_nm IN ('SSC Napoli', 'Napoli') THEN 'Napoli'
    WHEN away_team_nm IN ('Olympiacos FC', 'Olympiacos') THEN 'Olympiacos'
    WHEN away_team_nm IN ('Omonia FC', 'Omonia') THEN 'Omonia'
    WHEN away_team_nm IN ('PAOK FC', 'PAOK') THEN 'PAOK'
    WHEN away_team_nm IN ('Paris Saint-Germain', 'Paris') THEN 'PSG'
    WHEN away_team_nm IN ('PSV Eindhoven', 'PSV') THEN 'PSV'
    WHEN away_team_nm IN ('Rangers FC', 'Rangers') THEN 'Rangers'
    WHEN away_team_nm IN ('Real Madrid CF', 'Real Madrid') THEN 'Real Madrid'
    WHEN away_team_nm IN ('Real Sociedad de Fútbol', 'Real Sociedad') THEN 'Real Sociedad'
    WHEN away_team_nm IN ('Sevilla FC', 'Sevilla') THEN 'Sevilla'
    WHEN away_team_nm IN ('SK Slavia Praha', 'Slavia Praha') THEN 'Slavia Praha'
    WHEN away_team_nm IN ('Tottenham Hotspur', 'Tottenham') THEN 'Tottenham'
    WHEN away_team_nm IN ('Villarreal CF', 'Villarreal') THEN 'Villarreal'
    WHEN away_team_nm IN ('Wolfsberger AC', 'Wolfsberg') THEN 'Wolfsberg'
    ELSE away_team_nm END as team_nm,
  COUNT(DISTINCT(schedule_start_dt_ht)) as match_days
FROM `i-dss-ent-data.ent_vw.uefa_video_overall_detail_day` u
WHERE u.day_dt > '2020-08-01'
AND LOWER(video_type_cd) = 'live'
AND u.report_suite_id_nm IN ('cnetcbscomsite')
AND u.tournament_nm IN ('UCL', 'UEL')
AND LOWER(match_nm) NOT LIKE ('star cam%')
AND u.match_stream_sec_qty >= 180
GROUP BY 1,2
),match_counts as (
SELECT
  v69_registration_id_nbr,
  team_nm,
  SUM(match_days) as match_days
FROM home_away_match_counts 
GROUP BY 1,2
),perc_match_days as (
SELECT
  u.v69_registration_id_nbr,
  u.team_nm,
  u.match_days as match_days_watched,
  s.match_days as team_match_days,
  u.match_days/s.match_days as perc_match_days_watched
FROM match_counts u
JOIN team_matches s
ON u.team_nm = s.team_nm
)SELECT
  team_nm,
  team_match_days,
  COUNT(DISTINCT(v69_registration_id_nbr )) as total_hh,
  AVG(perc_match_days_watched) avg_perc_match_days_watched,
  COUNT(DISTINCT(CASE WHEN perc_match_days_watched >= 0.8 THEN v69_registration_id_nbr ELSE NULL END)) as team_fans
FROM perc_match_days 
GROUP BY 1,2