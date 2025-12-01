----1-----
CREATE OR REPLACE VIEW v_tracks_catalogue AS
SELECT
    t.track_id   ,
    t.title      ,
    t.duration_s ,
    a.name AS name_artist,
	a.country AS artist_country
FROM tracks t
JOIN artists a ON a.artist_id = t.artist_id;

---2----
CREATE OR REPLACE VIEW v_premium_users AS
SELECT
    user_id,
    username,
    country,
    subscription
FROM users
WHERE country = 'France'
  AND subscription = 'Premium';

---3---
CREATE VIEW  v_listening_history AS
SELECT 
    l.listening_id,
    l.user_id,
    u.username,
    u.country AS user_country,
    u.subscription,
    l.track_id,
    t.title AS track_title,
    a.artist_id,
    a.name AS artist_name,
    l.listened_at,
    l.seconds_played,
    t.duration_s AS track_duration
FROM listenings l
JOIN users u ON l.user_id = u.user_id
JOIN tracks t ON l.track_id = t.track_id
JOIN artists a ON t.artist_id = a.artist_id;

---4---
CREATE MATERIALIZED VIEW v_artist_stats AS
SELECT
    a.artist_id,
    a.name AS artist_name,
    COUNT(l.listening_id) AS total_listens,
    SUM(l.seconds_played) AS total_seconds_played,
    ROUND(AVG(l.seconds_played),2) AS avg_seconds_played
FROM artists a
JOIN tracks t ON a.artist_id = t.artist_id
JOIN listenings l ON t.track_id = l.track_id
GROUP BY a.artist_id, a.name;

---5---

SELECT
    a.country AS artist_country,
    SUM(vas.total_seconds_played) AS total_listening_volume,
    COUNT(DISTINCT vas.artist_id) AS number_of_artists
FROM artists a
INNER JOIN v_artist_stats vas ON a.artist_id = vas.artist_id
GROUP BY a.country
ORDER BY total_listening_volume DESC;

---6---
CREATE INDEX idx_artist_stats_artist_name ON v_artist_stats (artist_name);
CREATE INDEX idx_artist_stats_total_seconds_played ON v_artist_stats (total_seconds_played);
CREATE INDEX idx_artist_stats_avg_seconds_played ON v_artist_stats (avg_seconds_played);
CREATE INDEX idx_artist_stats_total_listens ON v_artist_stats (total_listens);