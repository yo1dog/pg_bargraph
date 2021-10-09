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
SELECT
  CASE WHEN width < 0 THEN
    repeat(' ', lpad - ceil(-width)::INT) ||
    CASE
      WHEN ceil(width) - width = 0 THEN ''
      WHEN ceil(width) - width < 0.25 THEN ' '
      WHEN ceil(width) - width < 0.75 THEN '▐'
      ELSE '█'
    END ||
    repeat('█', floor(-width)::INT)
  ELSE
    repeat(' ', lpad) ||
    repeat('█', floor(width)::INT) ||
    CASE
      WHEN width - floor(width) < 0.25 THEN ''
      WHEN width - floor(width) < 0.75 THEN '▌'
      ELSE '█'
    END
  END
$$
LANGUAGE SQL
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION graph (
  val DOUBLE PRECISION,
  max DOUBLE PRECISION,
  graph_width INT DEFAULT 50
) RETURNS TEXT
AS $$
SELECT graph((val/max::DOUBLE PRECISION)*graph_width)
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
  WHEN min < 0 THEN graph_neg((val/(max - min)::DOUBLE PRECISION)*graph_width, ceil((-min/(max - min)::DOUBLE PRECISION)*graph_width)::INT)
  ELSE graph((val/max::DOUBLE PRECISION)*graph_width)
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
