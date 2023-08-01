# Glibc upgrade testing

[https://wiki.postgresql.org/wiki/Locale_data_changes](https://wiki.postgresql.org/wiki/Locale_data_changes)

## What to do :

- All indexes involving columns of type text, varchar, char, and citext should be reindexed before the instance is put into production.

      1) Type char/varchar/text for index.

```sql
testupgrade=# CREATE TABLE test_character_type (
testupgrade(#   char_1 CHAR(1),
testupgrade(#   varchar_10 VARCHAR(10),
testupgrade(#   txt TEXT
testupgrade(# );
NOTICE:  Table doesn't have 'DISTRIBUTED BY' clause -- Using column named 'char_1' as the Greenplum Database data distribution key for this table.
HINT:  The 'DISTRIBUTED BY' clause determines the distribution of data. Make sure column(s) chosen are the optimal data distribution key to minimize skew.
CREATE TABLE

INSERT INTO test_character_type (char_1)
VALUES('Y    ')
RETURNING *;

INSERT INTO test_character_type (char_1)
VALUES('Y    ')
RETURNING *;

INSERT INTO test_character_type (txt)
VALUES('TEXT column can store a string of any length')
RETURNING txt;

testupgrade=# create index test_id1 on test_character_type(char_1);
CREATE INDEX
testupgrade=# create index test_id2 on test_character_type(varchar_10);
CREATE INDEX
testupgrade=# create index test_id3 on test_character_type(txt);
CREATE INDEX
testupgrade=#  SELECT coll, indexrelid, indrelid::regclass::text, indexrelid::regclass::text, collname, pg_get_indexdef(indexrelid)
FROM (SELECT indexrelid, indrelid, indcollation[i] coll FROM pg_index, generate_subscripts(indcollation, 1) g(i)) s
  JOIN pg_collation c ON coll=c.oid
WHERE collprovider IN ('d', 'c') AND collname NOT IN ('C', 'POSIX');
 coll | indexrelid |      indrelid       | indexrelid | collname |                               pg_get_indexdef
------+------------+---------------------+------------+----------+------------------------------------------------------------------------------
  100 |     140895 | test1               | test1_idx  | default  | CREATE INDEX test1_idx ON public.test1 USING btree (content)
  100 |     140943 | test_character_type | test_id1   | default  | CREATE INDEX test_id1 ON public.test_character_type USING btree (char_1)
  100 |     140944 | test_character_type | test_id2   | default  | CREATE INDEX test_id2 ON public.test_character_type USING btree (varchar_10)
  100 |     140945 | test_character_type | test_id3   | default  | CREATE INDEX test_id3 ON public.test_character_type USING btree (txt)
(4 rows)
```

        2) type citext

```sql
testupgrade=# create extension citext;
CREATE EXTENSION
testupgrade=# CREATE TABLE users (
testupgrade(#     nick CITEXT PRIMARY KEY,
testupgrade(#     pass TEXT   NOT NULL
testupgrade(# );
CREATE TABLE
testupgrade=#
testupgrade=# INSERT INTO users VALUES ( 'larry',  sha256(random()::text::bytea) );
INSERT 0 1
testupgrade=# INSERT INTO users VALUES ( 'Tom',    sha256(random()::text::bytea) );
INSERT 0 1
testupgrade=# INSERT INTO users VALUES ( 'Damian', sha256(random()::text::bytea) );
INSERT 0 1
testupgrade=# INSERT INTO users VALUES ( 'NEAL',   sha256(random()::text::bytea) );
INSERT 0 1
testupgrade=# INSERT INTO users VALUES ( 'Bjørn',  sha256(random()::text::bytea) );
INSERT 0 1
testupgrade=# create index test_id4 on users(nick);
CREATE INDEX

---------------Use this SQL query in each database to find out which indexes are affected---------------------

SELECT coll, indexrelid, indrelid::regclass::text, indexrelid::regclass::text, collname, pg_get_indexdef(indexrelid)
FROM (SELECT indexrelid, indrelid, indcollation[i] coll FROM pg_index, generate_subscripts(indcollation, 1) g(i)) s
JOIN pg_collation c ON coll=c.oid
WHERE collprovider IN ('d', 'c') AND collname NOT IN ('C', 'POSIX');

 coll | indexrelid |      indrelid       | indexrelid | collname |                               pg_get_indexdef
------+------------+---------------------+------------+----------+------------------------------------------------------------------------------
  100 |     140895 | test1               | test1_idx  | default  | CREATE INDEX test1_idx ON public.test1 USING btree (content)
  100 |     140943 | test_character_type | test_id1   | default  | CREATE INDEX test_id1 ON public.test_character_type USING btree (char_1)
  100 |     140944 | test_character_type | test_id2   | default  | CREATE INDEX test_id2 ON public.test_character_type USING btree (varchar_10)
  100 |     140945 | test_character_type | test_id3   | default  | CREATE INDEX test_id3 ON public.test_character_type USING btree (txt)
  100 |     141064 | users               | users_pkey | default  | CREATE UNIQUE INDEX users_pkey ON public.users USING btree (nick)
  100 |     141066 | users               | test_id4   | default  | CREATE INDEX test_id4 ON public.users USING btree (nick)
(6 rows)
```

- Range-partitioned tables using those types in the partition key should be checked to verify that all rows are still in the correct partitions. (This is quite unlikely to be a problem, only with particularly obscure partitioning bounds.)

  https://github.com/SmartKeyerror/gpdb/commit/c5e63af0d0e50f1d1001fdd3c243f44ec5f66dcf


## Special case that can make sort show different results.

```sql
1. SELECT * FROM (values ('a'), ('$a'), ('a$'), ('b'), ('$b'), ('b$'), ('A'), ('B')) AS l(x) ORDER BY x ;
2. echo "1-1"; echo "11"
3. SELECT * FROM (values ('"0102"'), ('0102')) AS x(x)
   ORDER BY x;
```

Redhat8:

```sql
[gpadmin@2ff393a9-5c68-403d-5e07-3ccee565dd22 ~]$  ( echo "1-1"; echo "11" ) | LC_COLLATE=en_US.UTF-8 sort
1-1
11
postgres=# SELECT * FROM (values ('a'), ('$a'), ('a$'), ('b'), ('$b'), ('b$'), ('A'), ('B')) AS l(x) ORDER BY x ;
 x
----
 $a
 $b
 a
 A
 a$
 b
 B
 b$
(8 rows)

[gpadmin@8b021245-e38c-4ffc-6c0d-f53ed88ac55a ~]$ psql postgres
psql (12.12)
Type "help" for help.

postgres=# SELECT * FROM (values ('"0102"'), ('0102')) AS x(x)
postgres-#    ORDER BY x;
   x
--------
 "0102"
 0102
(2 rows)
```

Redhat7

```sql
$  ( echo "1-1"; echo "11" ) | LC_COLLATE=en_US.UTF-8 sort
11
1-1

postgres=# SELECT * FROM (values ('a'), ('$a'), ('a$'), ('b'), ('$b'), ('b$'), ('A'), ('B')) AS l(x) ORDER BY x ;
 x
----
 a
 $a
 a$
 A
 b
 $b
 b$
 B
(8 rows)

testupgrade=# SELECT * FROM (values ('"0102"'), ('0102')) AS x(x)
testupgrade-#    ORDER BY x;
   x
--------
 0102
 "0102"
(2 rows)
```

## Case design principle:

> PostgreSQL uses locale data provided by the operating system’s C library for sorting text. Sorting happens in a variety of contexts, including for user output, merge joins, B-tree indexes, and range partitions. In the latter two cases, sorted data is persisted to disk. If the locale data in the C library changes during the lifetime of a database, the persisted data may become inconsistent with the expected sort order, which could lead to erroneous query results and other incorrect behavior. For example, if an index is not sorted in a way that an index scan is expecting it, a query could fail to find data that is actually there, and an update could insert duplicate data that should be disallowed. Similarly, in a partitioned table, a query could look in the wrong partition and an update could write to the wrong partition. Therefore, *it is essential to the correct operation of a database that the locale definitions do not change incompatibly during the lifetime of a database*.
>

内存sort不用管，只用管持久化磁盘，比如index和partition，且涉及到sort比较的，才会有可能受到影响

For GP cases:

1. distributed by hash (text, varchar, char, citext)
2. index with these types (text, varchar, char, citext)
3. range partition (text, varchar, char, and citext)

case1: test $ with varchar for distributed by hash and index

```sql
create table test1(content varchar);
insert into test1 (content) values ('a'), ('$a'), ('a$'), ('b'), ('$b'), ('b$'), ('A'), ('B');
create index id1 on test1(content);

testgrade=# \dS+ test1;
                              Table "public.test1"
 Column  |       Type        | Modifiers | Storage  | Stats target | Description
---------+-------------------+-----------+----------+--------------+-------------
 content | character varying |           | extended |              |
Indexes:
    "id1" btree (content)
Distributed by: (content)

testgrade=# explain select * from test1 order by content;
                                  QUERY PLAN
------------------------------------------------------------------------------
 Gather Motion 3:1  (slice1; segments: 3)  (cost=0.12..200.14 rows=1 width=2)
   Merge Key: content
   ->  Index Only Scan using id1 on test1  (cost=0.12..200.14 rows=1 width=2)
 Optimizer: Postgres query optimizer
(4 rows)

testgrade=# select * from test1 order by content;
 content
---------
 $a
 $A
 $b
 $B
 a
 A
 a$
 A$
 b
 B
 b$
 B$
(12 rows)

testgrade=# select * from test1 where content < 'b';
 content
---------
 $a
 $A
 $B
 a
 A
 A$
 $b
 a$
(8 rows)

[gpadmin@2ff393a9-5c68-403d-5e07-3ccee565dd22 ~]$ PGOPTIONS='-c gp_session_role=utility' psql -p 6002 -d testgrade
psql (9.4.26)
Type "help" for help.

testgrade=# select * from test1;
 content
---------
 a$
 $b
 B
(3 rows)

testgrade=# \q
[gpadmin@2ff393a9-5c68-403d-5e07-3ccee565dd22 ~]$ PGOPTIONS='-c gp_session_role=utility' psql -p 6003 -d testgrade
psql (9.4.26)
Type "help" for help.

testgrade=# select * from test1;
 content
---------
 $a
 b
 $A
 $B
(4 rows)

testgrade=# \q
[gpadmin@2ff393a9-5c68-403d-5e07-3ccee565dd22 ~]$ PGOPTIONS='-c gp_session_role=utility' psql -p 6004 -d testgrade
psql (9.4.26)
Type "help" for help.

testgrade=# select * from test1;
 content
---------
 a
 b$
 A
 A$
 B$
(5 rows)

------------
以下是redhat7

testupgrade=# select * from test1 order by content;
content
---------
 a
 $a
 a$
 A
 $A
 A$
 b
 $b
 b$
 B
 $B
 B$
(12 rows)

testupgrade=# select * from test1 where content < 'b';
 content
---------
 $a
 $A
 a
 A
 A$
 a$
(6 rows)

$ PGOPTIONS='-c gp_session_role=utility' psql -p 7002 -d testupgrade
psql (12.12)
Type "help" for help.

testupgrade=# select * from test1;
 content
---------
 a$
 $b
 B
(3 rows)

$ PGOPTIONS='-c gp_session_role=utility' psql -p 7003 -d testupgrade
psql (12.12)
Type "help" for help.

testupgrade=# select * from test1;
 content
---------
 $a
 b
 $B
 $A
(4 rows)

$ PGOPTIONS='-c gp_session_role=utility' psql -p 7004 -d testupgrade
psql (12.12)
Type "help" for help.

testupgrade=# select * from test1;
 content
---------
 a
 b$
 A
 B$
 A$
(5 rows)
```

case2: test hash distributed with special character ‘””’

Redhat8

```sql
postgres=# CREATE TABLE hash__test (id int, date text) DISTRIBUTED BY (date);
CREATE TABLE
postgres=# insert into hash__test values (1, '01');
INSERT 0 1
postgres=# insert into hash__test values (1, '"01"');
INSERT 0 1
postgres=# insert into hash__test values (2, '"02"');
INSERT 0 1
postgres=# insert into hash__test values (3, '02');
INSERT 0 1
postgres=# insert into hash__test values (4, '03');
INSERT 0 1
postgres=# select * from hash__test order by date;
 id | date
----+------
  1 | "01"
  1 | 01
  2 | "02"
  3 | 02
  4 | 03

```

case3: test range partition with text/char/varchar with  special charactor ‘-’

```sql
CREATE TABLE test2 (id int, date text)
DISTRIBUTED BY (id)
PARTITION BY RANGE (date)
( START (text '01-01') INCLUSIVE
   END (text '11-01') EXCLUSIVE
 );

Table "public.test2"
 Column |  Type   | Modifiers | Storage  | Stats target | Description
--------+---------+-----------+----------+--------------+-------------
 id     | integer |           | plain    |              |
 date   | text    |           | extended |              |
Child tables: test2_1_prt_1
Distributed by: (id)
Partition by: (date)

testgrade=# insert into test2 values (2, '02-1'), (2, '03-1'), (2, '08-1'), (2, '09-01'), (1, '11'), (1, '1-1');
INSERT 0 6
testgrade=# select * from test2 order by date;
 id | date
----+-------
  2 | 02-1
  2 | 03-1
  2 | 08-1
  2 | 09-01
  1 | 1-1
  1 | 11
(6 rows)

testgrade=# select count(*), gp_segment_id from test2 group by gp_segment_id;
 count | gp_segment_id
-------+---------------
     4 |             0
     2 |             1
(2 rows)

testgrade=# select * from test2 where date < '1-1';
 id | date
----+-------
  2 | 02-1
  2 | 03-1
  2 | 08-1
  2 | 09-01
(4 rows)
----------------------
redhat7

testupgrade=# select count(*), gp_segment_id from test2 group by gp_segment_id;
 count | gp_segment_id
-------+---------------
     4 |             0
     2 |             1
(2 rows)

testupgrade=# select * from test2 order by date;
 id | date
----+-------
  2 | 02-1
  2 | 03-1
  2 | 08-1
  2 | 09-01
  1 | 11
  1 | 1-1
(6 rows)

testupgrade=# select * from test2 where date < '1-1';
 id | date
----+-------
  2 | 02-1
  2 | 03-1
  2 | 09-01
  2 | 08-1
  1 | 11
(5 rows)
```

case4: test partition range with special character ‘’”’

(由于glibc升级的影响，导致字符串排序受到了影响，对于range partition, 某些在rhel7上可以Insert的数据，在rhel8上会报错，比如下方的 insert into partition_range_test values (1, '"01"'), 原因是在rhel7上 01在“01”前面，但是rhel8上 “01”在 01前面)

```sql
Redhat7: 
CREATE TABLE partition_range_test (id int, date text) DISTRIBUTED BY (id)
PARTITION BY RANGE (date)
      (PARTITION Jan START ( '01') INCLUSIVE ,
      PARTITION Feb START ( '02') INCLUSIVE ,
      PARTITION Mar START ( '03') INCLUSIVE
      END ( '04') EXCLUSIVE);

testupgrade=# CREATE TABLE partition_range_test (id int, date text) DISTRIBUTED BY (id)
testupgrade-# PARTITION BY RANGE (date)
testupgrade-#       (PARTITION Jan START ( '01') INCLUSIVE ,
testupgrade(#       PARTITION Feb START ( '02') INCLUSIVE ,
testupgrade(#       PARTITION Mar START ( '03') INCLUSIVE
testupgrade(#       END ( '04') EXCLUSIVE);
CREATE TABLE
testupgrade=# \dS+ partition_range_test;
                      Partitioned table "public.partition_range_test"
 Column |  Type   | Collation | Nullable | Default | Storage  | Stats target | Description
--------+---------+-----------+----------+---------+----------+--------------+-------------
 id     | integer |           |          |         | plain    |              |
 date   | text    |           |          |         | extended |              |
Partition key: RANGE (date)
Partitions: partition_range_test_1_prt_feb FOR VALUES FROM ('02') TO ('03'),
            partition_range_test_1_prt_jan FOR VALUES FROM ('01') TO ('02'),
            partition_range_test_1_prt_mar FOR VALUES FROM ('03') TO ('04')
Distributed by: (id)
Access method: heap

testupgrade=# insert into partition_range_test values (1, '01');
INSERT 0 1
testupgrade=# insert into partition_range_test values (1, '"01"');
INSERT 0 1
testupgrade=# insert into partition_range_test values (2, '"02"');
INSERT 0 1
testupgrade=# insert into partition_range_test values (2, '02');
INSERT 0 1
testupgrade=# insert into partition_range_test values (3, '03');
INSERT 0 1
testupgrade=# insert into partition_range_test values (3, '"03"');
INSERT 0 1
testupgrade=# select * from partition_range_test order by date;
 id | date
----+------
  1 | 01
  1 | "01"
  2 | 02
  2 | "02"
  3 | 03
  3 | "03"
(6 rows)

testupgrade=# insert into partition_range_test values (4, '"04"');
ERROR:  no partition of relation "partition_range_test" found for row  (seg0 127.0.0.1:7002 pid=8957)
DETAIL:  Partition key of the failing row contains (date) = ("04").
```

```sql
Redhat8:
postgres=# CREATE TABLE partition_range_test (id int, date text) DISTRIBUTED BY (id)
postgres-# PARTITION BY RANGE (date)
postgres-#       (PARTITION Jan START ( '01') INCLUSIVE ,
postgres(#       PARTITION Feb START ( '02') INCLUSIVE ,
postgres(#       PARTITION Mar START ( '03') INCLUSIVE
postgres(#       END ( '04') EXCLUSIVE);
CREATE TABLE

postgres=# \dS+ partition_range_test;
                      Partitioned table "public.partition_range_test"
 Column |  Type   | Collation | Nullable | Default | Storage  | Stats target | Description
--------+---------+-----------+----------+---------+----------+--------------+-------------
 id     | integer |           |          |         | plain    |              |
 date   | text    |           |          |         | extended |              |
Partition key: RANGE (date)
Partitions: partition_range_test_1_prt_feb FOR VALUES FROM ('02') TO ('03'),
            partition_range_test_1_prt_jan FOR VALUES FROM ('01') TO ('02'),
            partition_range_test_1_prt_mar FOR VALUES FROM ('03') TO ('04')
Distributed by: (id)
Access method: heap

postgres=# insert into partition_range_test values (1, '01');
INSERT 0 1
postgres=# insert into partition_range_test values (1, '"01"');
ERROR:  no partition of relation "partition_range_test" found for row  (seg1 10.80.0.58:7003 pid=491156)
DETAIL:  Partition key of the failing row contains (date) = ("01").

postgres=# insert into partition_range_test values (3, '03');
INSERT 0 1
postgres=# select * from partition_range_test order by date;
 id | date
----+------
  1 | 01
  2 | "02"
  2 | 02
  3 | "03"
  3 | 03
(5 rows)

postgres=# insert into partition_range_test values (4, '"04"');
INSERT 0 1

postgres=# select version();
                                                                                                                                         version
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
 PostgreSQL 12.12 (Greenplum Database 7.0.0-beta.4+dev.194.g61a22a841b build commit:61a22a841bc443a4576403b99a458fec76d0d091) on x86_64-pc-linux-gnu, compiled by gcc (GCC)
 8.5.0 20210514 (Red Hat 8.5.0-18), 64-bit compiled on Jul 28 2023 09:02:19 (with assert checking) Bhuvnesh C.
(1 row)
```

case5：test partition range with AO

```sql
Redhat7:
CREATE TABLE partition_range_test_ao (id int, date text)
WITH (appendonly = true)
DISTRIBUTED BY (id)
PARTITION BY RANGE (date)
      (PARTITION Jan START ('01') INCLUSIVE ,
      PARTITION Feb START ('02') INCLUSIVE ,
      PARTITION Mar START ('03') INCLUSIVE
      END ('04') EXCLUSIVE);

testupgrade=# \dS+ partition_range_test_ao;
                    Partitioned table "public.partition_range_test_ao"
 Column |  Type   | Collation | Nullable | Default | Storage  | Stats target | Description
--------+---------+-----------+----------+---------+----------+--------------+-------------
 id     | integer |           |          |         | plain    |              |
 date   | text    |           |          |         | extended |              |
Partition key: RANGE (date)
Partitions: partition_range_test_ao_1_prt_feb FOR VALUES FROM ('02') TO ('03'),
            partition_range_test_ao_1_prt_jan FOR VALUES FROM ('01') TO ('02'),
            partition_range_test_ao_1_prt_mar FOR VALUES FROM ('03') TO ('04')
Distributed by: (id)
Access method: ao_row

insert into partition_range_test_ao values (1, '01');
insert into partition_range_test_ao values (1, '"01"');
insert into partition_range_test_ao values (1, '"01-1"');
insert into partition_range_test_ao values (2, '"02-1"');
insert into partition_range_test_ao values (2, '"02"');
insert into partition_range_test_ao values (2, '02');
testupgrade=# select * from partition_range_test_ao order by date;
 id |  date
----+--------
  1 | 01
  1 | "01"
  1 | "01-1"
  2 | 02
  2 | "02"
  2 | "02-1"
(6 rows)
```

```sql
Redhat8:
postgres=# CREATE TABLE partition_range_test_ao (id int, date text)
postgres-# WITH (appendonly = true)
postgres-# DISTRIBUTED BY (id)
postgres-# PARTITION BY RANGE (date)
postgres-#       (PARTITION Jan START ('01') INCLUSIVE ,
postgres(#       PARTITION Feb START ('02') INCLUSIVE ,
postgres(#       PARTITION Mar START ('03') INCLUSIVE
postgres(#       END ('04') EXCLUSIVE);
CREATE TABLE

postgres=# \dS+ partition_range_test_ao;
                    Partitioned table "public.partition_range_test_ao"
 Column |  Type   | Collation | Nullable | Default | Storage  | Stats target | Description
--------+---------+-----------+----------+---------+----------+--------------+-------------
 id     | integer |           |          |         | plain    |              |
 date   | text    |           |          |         | extended |              |
Partition key: RANGE (date)
Partitions: partition_range_test_ao_1_prt_feb FOR VALUES FROM ('02') TO ('03'),
            partition_range_test_ao_1_prt_jan FOR VALUES FROM ('01') TO ('02'),
            partition_range_test_ao_1_prt_mar FOR VALUES FROM ('03') TO ('04')
Distributed by: (id)
Access method: ao_row

postgres=#
postgres=# insert into partition_range_test_ao values (1, '01');
INSERT 0 1
postgres=# insert into partition_range_test_ao values (1, '"01"');
ERROR:  no partition of relation "partition_range_test_ao" found for row  (seg1 10.80.0.58:7003 pid=491156)
DETAIL:  Partition key of the failing row contains (date) = ("01").
postgres=# insert into partition_range_test_ao values (1, '"01-1"');
INSERT 0 1
postgres=# insert into partition_range_test_ao values (2, '"02-1"');
INSERT 0 1
postgres=# insert into partition_range_test_ao values (2, '"02"');
INSERT 0 1
postgres=# insert into partition_range_test_ao values (2, '02');
INSERT 0 1

postgres=# select * from partition_range_test_ao order by date;
 id |  date
----+--------
  1 | 01
  1 | "01-1"
  2 | "02"
  2 | 02
  2 | "02-1"
(5 rows
```

---

---

1. 构造一个SQL查出有可能有问题的partition table

```sql
SELECT partrelid::regclass::text
FROM (SELECT partrelid, partcollation[i] coll FROM pg_partitioned_table, generate_subscripts(partcollation, 1) g(i)) s
JOIN pg_collation c ON coll=c.oid
WHERE collprovider IN ('d', 'c') AND collname NOT IN ('C', 'POSIX');
```

2. range partition wrong results due to glibc upgrade.


```sql
Redhat7: 
testupgrade=# create table root (id int, date text) DISTRIBUTED BY (id)
testupgrade-# PARTITION BY RANGE (date)
testupgrade-#       (PARTITION Jan START ( '01') INCLUSIVE ,
testupgrade(#       PARTITION Feb START ( '02') INCLUSIVE ,
testupgrade(#       PARTITION Mar START ( '03') INCLUSIVE
testupgrade(#       END ( '04') EXCLUSIVE);
CREATE TABLE
testupgrade=# insert into root values (1, '01'), (1, '"01"');
INSERT 0 2
testupgrade=# insert into root values (2, '02'), (2, '"02"');
INSERT 0 2
testupgrade=# insert into root values (3, '03'), (3, '"03"');
INSERT 0 2
testupgrade=# select * from root order by date;
 id | date
----+------
  1 | 01
  1 | "01"
  2 | 02
  2 | "02"
  3 | 03
  3 | "03"
(6 rows)

testupgrade=# select * from root_1_prt_
root_1_prt_feb  root_1_prt_jan  root_1_prt_mar
testupgrade=# select * from root_1_prt_jan ;
 id | date
----+------
  1 | 01
  1 | "01"
(2 rows)

testupgrade=# select * from root_1_prt_feb ;
 id | date
----+------
  2 | 02
  2 | "02"
(2 rows)

testupgrade=# select * from root_1_prt_mar ;
 id | date
----+------
  3 | 03
  3 | "03"
(2 rows)

testupgrade=# insert into root values (4, '04');
ERROR:  no partition of relation "root" found for row  (seg0 127.0.0.1:7002 pid=2341)
DETAIL:  Partition key of the failing row contains (date) = (04).
testupgrade=# insert into root values (4, '"04"');
ERROR:  no partition of relation "root" found for row  (seg0 127.0.0.1:7002 pid=2341)
DETAIL:  Partition key of the failing row contains (date) = ("04").

testupgrade=# explain insert into root select * from partition_range_test where date > '"02"';
                                           QUERY PLAN
------------------------------------------------------------------------------------------------
 Insert on root  (cost=0.00..536.44 rows=11022 width=36)
   ->  Append  (cost=0.00..536.44 rows=11022 width=36)
         ->  Seq Scan on partition_range_test_1_prt_feb  (cost=0.00..240.67 rows=5511 width=36)
               Filter: (date > '"02"'::text)
         ->  Seq Scan on partition_range_test_1_prt_mar  (cost=0.00..240.67 rows=5511 width=36)
               Filter: (date > '"02"'::text)
 Optimizer: Postgres query optimizer
(7 rows)

testupgrade=# insert into root select * from partition_range_test where date > '"02"';
INSERT 0 2
testupgrade=# select * from root;
 id | date
----+------
  3 | 03
  3 | "03"
(2 rows)

```

```sql
Redhat8: 
testupgrade=# select count(*) from partition_range_test_1_prt_jan;
 count
-------
     2
(1 row)

testupgrade=# select count(*) from partition_range_test_1_prt_feb;
 count
-------
     2
(1 row)

testupgrade=# select count(*) from partition_range_test_1_prt_mar;
 count
-------
     1
(1 row)

testupgrade=# select * from partition_range_test_1_prt_jan ;
 id | date
----+------
  1 | 01
  2 | "02"
(2 rows)

testupgrade=# select * from partition_range_test_1_prt_feb ;
 id | date
----+------
  2 | 02
  3 | "03"
(2 rows)

testupgrade=# select * from partition_range_test_1_prt_mar ;
 id | date
----+------
  3 | 03
(1 row)

testupgrade=# select * from partition_range_test where date > '"02"'
;
 id | date
----+------
  2 | 02
  3 | "03"
  3 | 03
(3 rows)

testupgrade=# explain select * from partition_range_test where date > '"02"'
;
                                     QUERY PLAN
-------------------------------------------------------------------------------------
 Gather Motion 3:1  (slice1; segments: 3)  (cost=0.00..431.00 rows=1 width=12)
   ->  Dynamic Seq Scan on partition_range_test  (cost=0.00..431.00 rows=1 width=12)
         Number of partitions to scan: 3 (out of 3)
         Filter: (date > '"02"'::text)
 Optimizer: Pivotal Optimizer (GPORCA)
(5 rows)

testupgrade=# set optimizer=off;
SET
testupgrade=# explain select * from partition_range_test where date > '"02"'
;
                                           QUERY PLAN
------------------------------------------------------------------------------------------------
 Gather Motion 3:1  (slice1; segments: 3)  (cost=0.00..1466.00 rows=49600 width=36)
   ->  Append  (cost=0.00..804.67 rows=16533 width=36)
         ->  Seq Scan on partition_range_test_1_prt_jan  (cost=0.00..240.67 rows=5511 width=36)
               Filter: (date > '"02"'::text)
         ->  Seq Scan on partition_range_test_1_prt_feb  (cost=0.00..240.67 rows=5511 width=36)
               Filter: (date > '"02"'::text)
         ->  Seq Scan on partition_range_test_1_prt_mar  (cost=0.00..240.67 rows=5511 width=36)
               Filter: (date > '"02"'::text)
 Optimizer: Postgres query optimizer
(9 rows)

testupgrade=# insert into root select * from partition_range_test where date > '"02"';
INSERT 0 3
testupgrade=# explain insert into root select * from partition_range_test where date > '"02"';
                                           QUERY PLAN
------------------------------------------------------------------------------------------------
 Insert on root  (cost=0.00..804.67 rows=16533 width=36)
   ->  Append  (cost=0.00..804.67 rows=16533 width=36)
         ->  Seq Scan on partition_range_test_1_prt_jan  (cost=0.00..240.67 rows=5511 width=36)
               Filter: (date > '"02"'::text)
         ->  Seq Scan on partition_range_test_1_prt_feb  (cost=0.00..240.67 rows=5511 width=36)
               Filter: (date > '"02"'::text)
         ->  Seq Scan on partition_range_test_1_prt_mar  (cost=0.00..240.67 rows=5511 width=36)
               Filter: (date > '"02"'::text)
 Optimizer: Postgres query optimizer
(9 rows)

testupgrade=# select * from root;
 id | date
----+------
  2 | 02
  3 | "03"
  3 | 03
(3 rows)

testupgrade=# insert into partition_range_test values (4, '"04"');
INSERT 0 1
testupgrade=# select * from partition_range_test_1_prt_mar ;
 id | date
----+------
  3 | 03
  4 | "04"
(2 rows)
```

3. unique constraint violation ****(reference**** [https://dba.stackexchange.com/questions/320683/duplicate-key-value-violates-unique-constraint-in-upsert-in-postgres-14](https://dba.stackexchange.com/questions/320683/duplicate-key-value-violates-unique-constraint-in-upsert-in-postgres-14)

   [https://confluence.atlassian.com/bitbucketserverkb/unique-constraint-violation-in-postgres-due-to-os-upgrade-1155145124.html](https://confluence.atlassian.com/bitbucketserverkb/unique-constraint-violation-in-postgres-due-to-os-upgrade-1155145124.html) )


```sql
create table gitrefresh(projecttag text, state character(1), analysis_started timestamp without time zone , analysis_ended timestamp without time zone , counter_requested integer, customer_id integer, id int, constraint idx_projecttag unique(projecttag));
create index pk_gitrefresh on gitrefresh(id);
INSERT INTO gitrefresh(projecttag, state, analysis_started, counter_requested, customer_id) 
VALUES('npm@randombytes', 'Q', NOW(), 1, 0) 
ON CONFLICT (projecttag) DO UPDATE SET state='Q';
```

4. Other references

[https://pganalyze.com/blog/5mins-postgres-collations](https://pganalyze.com/blog/5mins-postgres-collations)
