CREATE TYPE graph_input AS (label TEXT, val DOUBLE PRECISION);

CREATE OR REPLACE FUNCTION graph (
  width DOUBLE PRECISION
) RETURNS TEXT
AS $$
SELECT
  repeat('█', floor(width)::INT) ||
  CASE
    WHEN width < 0 THEN NULL
    WHEN width - floor(width) < 0.25 THEN ''
    WHEN width - floor(width) < 0.75 THEN '▌'
    ELSE '█'
  END
$$
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION graph_neg (
  width DOUBLE PRECISION,
  lpad INT
) RETURNS TEXT
AS $$
SELECT CASE
  WHEN lpad < 0 THEN NULL
  WHEN ceil(-width) > lpad THEN NULL
  WHEN width < 0 THEN (
    repeat(' ', lpad - ceil(-width)::INT) ||
    CASE
      WHEN ceil(width) - width = 0 THEN ''
      WHEN ceil(width) - width < 0.25 THEN ' '
      WHEN ceil(width) - width < 0.75 THEN '▐'
      ELSE '█'
    END ||
    repeat('█', floor(-width)::INT)
  )
  ELSE (
    repeat(' ', lpad) ||
    repeat('█', floor(width)::INT) ||
    CASE
      WHEN width - floor(width) < 0.25 THEN ''
      WHEN width - floor(width) < 0.75 THEN '▌'
      ELSE '█'
    END
  )
END
$$
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION graph (
  val DOUBLE PRECISION,
  min DOUBLE PRECISION,
  max DOUBLE PRECISION,
  graph_width INT DEFAULT 50
) RETURNS TEXT
AS $$
SELECT CASE
  WHEN val < min THEN NULL
  WHEN val > max THEN NULL
  WHEN min = 0 AND max = 0 THEN ''
  WHEN graph_width < 0 THEN NULL
  WHEN min >= 0 THEN graph((val/max::DOUBLE PRECISION)*graph_width)
  WHEN max < 0 THEN graph_neg(
    (val/-min::DOUBLE PRECISION)*graph_width,
    graph_width
  )
  ELSE graph_neg(
          (val/(max - min)::DOUBLE PRECISION)*graph_width,
    ceil(-(min/(max - min)::DOUBLE PRECISION)*graph_width)::INT
  )
END
$$
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION graph (
  vals DOUBLE PRECISION[],
  graph_width INT DEFAULT 50
) RETURNS TABLE (
  val DOUBLE PRECISION,
  graph TEXT
)
AS $$
WITH t1 AS (
  SELECT MIN(val), MAX(val) FROM unnest(vals) val
)
SELECT val, graph(val, min, max, graph_width) FROM t1, unnest(vals) val
$$
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION graph (
  inputs graph_input[],
  graph_width INT DEFAULT 50
) RETURNS TABLE (
  label TEXT,
  val DOUBLE PRECISION,
  graph TEXT
) AS $$
WITH t1 AS (
  SELECT MIN(val), MAX(val) FROM unnest(inputs) input
)
SELECT label, val, graph(val, min, max, graph_width) FROM t1, unnest(inputs) input
$$
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;
