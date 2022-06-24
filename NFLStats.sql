/* Exploring lesser-seen 2021 NFL stats before the 2022 season, 
and prepping queries for 2022's databases

Order of queries:
	-Overview focusing on ball security, player efficiency, and volume
	-QBs
    -WRs
	-RBs
	-TEs */

-- Team ball security on offense
SELECT DISTINCT team, ROUND(AVG((rec + pass_att + rush_att)/(fumbles_lost + pass_int)), 1) team_ball_security
FROM nflstats
WHERE rush_att > 50
OR pass_att > 50
OR targets >30
GROUP BY team
ORDER BY team_ball_security DESC;

/* All players' ball security next to their position average, but with 
some parameters to ensure that only starting-calibre players are considered. */
SELECT DISTINCT player, position,
ROUND(AVG((rec + pass_att + rush_att)/(fumbles_lost + pass_int)) 
	OVER(PARTITION BY player)) AS touch_per_fumble,
ROUND(AVG((rec + pass_att + rush_att)/(fumbles_lost + pass_int)) 
	OVER(PARTITION BY Position)) AS positionavg_touch_per_fumble
FROM nflstats
WHERE rush_att > 50
OR pass_att > 50
OR targets >30
ORDER BY touch_per_fumble DESC;

/* A Fullback fulfilled our criteria for a starting player and returned a null value 
(as they never fumbled, props to them) and I'm curious who the culprit is */
SELECT player, targets
FROM nflstats
WHERE position = 'fb'
AND (rush_att > 50 
	OR pass_att > 50 
    OR targets > 30);
-- (Spoiler: It's SF's Kyle Kuszczyk)

-- Quarterbacks
-- A view of overall volume per qb.
CREATE VIEW qb_volume AS
SELECT player, position, team, (pass_att + rush_att + targets) plays
FROM nflstats
WHERE position = 'qb'
GROUP BY player
ORDER BY plays DESC
LIMIT 100;

SELECT * FROM qb_volume
LIMIT 20;

-- Which starting-calibre QBs are more efficient runners than the average RB?
SELECT player, ROUND(rush_yds/rush_att, 2) AS yds_per_rush, rush_att, 
	(SELECT ROUND(AVG(rush_yds/rush_att), 2)
    FROM nflstats
    WHERE position = 'rb'
    AND rush_att > 50) AS rbavg_yds_per_rush
FROM nflstats
WHERE position = 'qb'
AND pass_att >= 100
AND rush_yds/rush_att > 
	(SELECT AVG(rush_yds/rush_att)
    FROM nflstats
    WHERE position = 'rb'
    AND rush_att > 50)
ORDER BY yds_per_rush DESC;
 
-- Who protec ball?
SELECT player, (rush_att + pass_att) / (pass_int + fumbles_lost) ball_security
FROM nflstats
WHERE pass_att >= 100
AND position = 'qb'
ORDER BY ball_security DESC;

-- Wide Receivers 
-- WR Volume
CREATE VIEW wr_volume AS 
SELECT player, position, team, (targets + rush_att + pass_att) AS wr_volume
FROM nflstats
WHERE position = 'WR'
ORDER BY wr_volume DESC
LIMIT 100;

SELECT distinct (player, tea FROM wr_volume
LIMIT 25;

-- Team volume for WR plays. I'm also sure to include WR pass plays. 
SELECT team, SUM(targets + rush_att + pass_att) wrtouches
FROM nflstats
WHERE position = 'WR'
GROUP BY team
ORDER BY wrtouches DESC;

-- A closer look at WRs who pass.
SELECT player, pass_yds, pass_td, pass_cmp, pass_att, pass_int, 
	CASE
		WHEN pass_cmp >=2 THEN 'gunslinger'
        WHEN pass_td >= 1 THEN 'gunslinger'
		WHEN pass_cmp =1 THEN 'acceptable'
		ELSE 'failure'
	END AS pass_prowess
FROM nflstats
WHERE position = 'wr' AND Pass_att > 0
ORDER BY pass_yds DESC;

-- RunningBacks
-- Overall RB volume by player
CREATE VIEW rb_volume AS
SELECT player, position, team, (targets + rush_att + pass_att) looks
FROM nflstats
WHERE position = 'RB'
GROUP BY player
ORDER BY looks DESC
LIMIT 100;

Select * from rb_volume
LIMIT 25;

/* Ball security check for starting-calibre RBs. The final ranking isn't exactly 
what we want here, but we can drum up some helpful views from this. */
SELECT player, (rec + rush_att) AS touches,  fumbles_lost, (targets + rush_att) / fumbles_lost  AS touches_per_fumble
FROM nflstats
WHERE position = 'rb'
AND rec + rush_att > 60
AND rush_yds + rec_yds> 500
ORDER BY fumbles_lost, 
	touches_per_fumble DESC,
    touches DESC;

/* Team total volume for RBs, including RB pass plays */
SELECT team, SUM(targets + rush_att + pass_att) rb_plays 
FROM nflstats
WHERE position = 'RB'
GROUP BY team
ORDER BY rb_plays DESC;

-- RB throwing plays. A much smaller body of work here compared to wrs.
SELECT player, pass_yds, pass_td, pass_cmp, pass_att, pass_int, 
	CASE
		WHEN pass_cmp >=2 THEN 'gunslinger'
        WHEN pass_td >= 1 THEN 'gunslinger'
		WHEN pass_cmp =1 THEN 'acceptable'
        WHEN pass_int >=1 THEN 'cannot_throw'
		ELSE 'failure'
	END AS pass_prowess
FROM nflstats
WHERE position = 'rb' AND Pass_att > 0
ORDER BY pass_yds DESC;

-- Tight Ends --
-- TE Player use volume
CREATE VIEW te_volume AS
SELECT player, position, team, targets + rush_att looks
FROM nflstats
WHERE position = 'te'
GROUP BY player
ORDER BY looks DESC
LIMIT 100;

SELECT * from te_volume;

-- TE receiving efficiency, with context
SELECT player, (rec_yds / rec) yds_per_rec , rec_yac
FROM nflstats
WHERE position = 'TE'
AND rec >= 20
ORDER BY yds_per_rec DESC;

-- Total Team TE Use
SELECT team, SUM(targets + rush_att + pass_att) te_touches
FROM nflstats
WHERE position = 'TE'
GROUP BY team
ORDER BY te_touches DESC;

-- Which team deploys the most TE trick plays and endzone runs?
SELECT team , SUM(rush_att + pass_att) te_tricks
FROM nflstats
WHERE position = 'TE'
GROUP BY team
ORDER BY te_tricks DESC;


