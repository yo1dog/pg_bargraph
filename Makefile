EXTENSION = pg_bargraph
DATA = pg_bargraph--1.1.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)