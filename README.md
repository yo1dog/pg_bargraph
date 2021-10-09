# pg_bargraph

PostgreSQL extension that adds the ability to generate bar graphs.

```
select * from graph('{5.5,10,15,13,8,3.1,-1,2,5,7,4}'::FLOAT[]);

 val │                        graph
─────┼─────────────────────────────────────────────────────
 5.5 │     █████████████████
  10 │     ███████████████████████████████▌
  15 │     ███████████████████████████████████████████████
  13 │     ████████████████████████████████████████▌
   8 │     █████████████████████████
 3.1 │     █████████▌
  -1 │  ███
   2 │     ██████▌
   5 │     ███████████████▌
   7 │     ██████████████████████
   4 │     ████████████▌
```

This is not meant to be a replacement for a proper graphing utility or GUI visualizer. I find it useful when I want to quickly visually compare data sets from the CLI when it otherwise would not be worth the time.

To install using PGXS: `make install`. Or you can manually install: `cp pg_bargraph* /your/extensions/dir/` Or, you can create the functions directly (not recommended): `cat pg_bargraph--1.0.sql | psql ...`.

--------------------------------


The examples bellow use this table:

```
create table data (name text, val float);
insert into data values
('a', 10.6),
('b', 6.1),
('c', -2.9),
('d', 2.8);
```

--------------------------------

`graph(vals: double[], graph_width?: int) → table(val double, graph text)`

Graphs the given values. `graph_width` defaults to 50.

```
select (graph(array_agg(val))).* from data;
or
select * from graph((select array_agg(val) from data));

 val  │                        graph
──────┼─────────────────────────────────────────────────────
 10.6 │            ███████████████████████████████████████▌
  6.1 │            ██████████████████████▌
 -2.9 │ ▐██████████
  2.8 │            ██████████▌
```

```
select (graph(array_agg(val), 20)).* from data;

 val  │         graph
──────┼───────────────────────
 10.6 │      ███████████████▌
  6.1 │      █████████
 -2.9 │ ▐████
  2.8 │      ████
```

--------------------------------

`graph(inputs: graph_input[], graph_width?: int) → table(label text, val double, graph text)`

`type graph_input = (label text, val double)`

Same as above, but accepts label and value tuples.

```
select (graph(array_agg((name, val)::graph_input))).* from data;

 label │ val  │                        graph
───────┼──────┼─────────────────────────────────────────────────────
 a     │ 10.6 │            ███████████████████████████████████████▌
 b     │  6.1 │            ██████████████████████▌
 c     │ -2.9 │ ▐██████████
 d     │  2.8 │            ██████████▌
```

--------------------------------

`graph(width: double) → text`

Creates a bar with a width equal to the given width in characters. Negative widths return NULL.

```
select name, val, graph(val) from data;

 name │ val  │    graph
──────┼──────┼─────────────
 a    │ 10.6 │ ██████████▌
 b    │  6.1 │ ██████
 c    │ -2.9 │ null
 d    │  2.8 │ ███
```

--------------------------------

`graph(val: double, max: double, graph_width?: int) → text`

Creates a bar with a width equal to the given value as a percentage of the max value and the graph's width. `graph_width` defaults to 50. Negative values return NULL.

```
select name, val, graph(val, max) from data, (select max(val) from data) t1;

 name │ val  │                       graph
──────┼──────┼────────────────────────────────────────────────────
 a    │ 10.6 │ ██████████████████████████████████████████████████
 b    │  6.1 │ █████████████████████████████
 c    │ -2.9 │ null
 d    │  2.8 │ █████████████
```

--------------------------------

`graph(val: double, min: double, max: double, graph_width?: int) → text`

Same as above, but negative values are supported.

```
select name, val, graph(val, min, max) from data, (select min(val), max(val) from data) t1;

 name │ val  │                        graph
──────┼──────┼─────────────────────────────────────────────────────
 a    │ 10.6 │            ███████████████████████████████████████▌
 b    │  6.1 │            ██████████████████████▌
 c    │ -2.9 │ ▐██████████
 d    │  2.8 │            ██████████▌
```

--------------------------------

The `graph(vals: double[], ...)` and `graph(inputs: graph_input[], ...)` are usually the easiest and safest to use due to the function handling the min and max calculations. However, the other variants allow for more customization. For example, here is how to use a logarithmic scale:

```
with data(val) as (values (100),(200),(300))
select val, graph(log(val), log(max)) from data, (select max(val) from data) t1;

 val │                       graph
─────┼────────────────────────────────────────────────────
 100 │ ████████████████████████████████████████▌
 200 │ ██████████████████████████████████████████████▌
 300 │ ██████████████████████████████████████████████████
 ```