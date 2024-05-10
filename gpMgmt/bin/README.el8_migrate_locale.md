# el8_migrate_locale

el8_migrate_locale helps you identify and address the main challenges associated with an in-place upgrade from EL 7 to 8 or EL 9 caused by the glibc GNU C library changes.

## usage

```
$ el8_migrate_locale --help
usage: el8_migrate_locale [-h] [--host HOST] [--port PORT] [--dbname DBNAME]
                          [--user USER] [--verbose]
                          {identify,prepare,validate,migrate} ...

positional arguments:
  {identify,prepare,validate,migrate}
                        sub-command help
    identify            run a check of an existing Greenplum cluster for
                        impacted index and tables
    prepare             prepare the commands for migrating (recreating) BOTH
                        the impacted index and partitioned tables
    validate            validate the data correctness of partitioned tables
                        using "gp_detect_data_correctness "
    migrate             run the reindex and the rebuild partition commands

optional arguments:
  -h, --help            show this help message and exit
  --host HOST           Greenplum Database hostname
  --port PORT           Greenplum Database port
  --dbname DBNAME       Greenplum Database database name
  --user USER           Greenplum Database user name
  --verbose             Print more info
```

```
$ el8_migrate_locale identify --help
usage: el8_migrate_locale identify [-h] [--index] [--table]

optional arguments:
  -h, --help  show this help message and exit
  --index     run a check of an existing Greenplum cluster for impacted
              indices ONLY
  --table     run a check of an existing Greenplum cluster for impacted tables
              ONLY
```

## output example of `el8_migrate_locale identify`

```
2024-04-25 18:20:57,085 - INFO - There are 2 catalog indexes that needs reindex when doing OS upgrade from EL7 to EL8.
indexrelid|indexname                 |tablename    |collname|pg_get_indexdef                                                                                                          
----------+--------------------------+-------------+--------+-------------------------------------------------------------------------------------------------------------------------
3597      |pg_seclabel_object_index  |pg_seclabel  |default |CREATE UNIQUE INDEX pg_seclabel_object_index ON pg_catalog.pg_seclabel USING btree (objoid, classoid, objsubid, provider)
3593      |pg_shseclabel_object_index|pg_shseclabel|default |CREATE UNIQUE INDEX pg_shseclabel_object_index ON pg_catalog.pg_shseclabel USING btree (objoid, classoid, provider)      
(2 rows)


2024-04-25 18:20:57,213 - INFO - There are 5 user indexes in database test that needs reindex when doing OS upgrade from EL7 to EL8.
indexrelid|indexname        |tablename          |collname|pg_get_indexdef                                                                      
----------+-----------------+-------------------+--------+-------------------------------------------------------------------------------------
16392     |"test_id2 \ $ \\"|test_character_type|default |CREATE INDEX "test_id2 \ $ \\" ON public.test_character_type USING btree (varchar_10)
16391     |"test_id1 's "   |test_character_type|default |CREATE INDEX "test_id1 's " ON public.test_character_type USING btree (char_1)       
16486     |test_idx_citext  |test_citext        |default |CREATE INDEX test_idx_citext ON public.test_citext USING btree (nick)                
16484     |test_citext_pkey |test_citext        |default |CREATE UNIQUE INDEX test_citext_pkey ON public.test_citext USING btree (nick)        
16393     |" test_id "" 3 " |test_character_type|default |CREATE INDEX " test_id "" 3 " ON public.test_character_type USING btree (txt)        
(5 rows)


2024-04-25 18:20:57,465 - WARNING - There are 1 tables in database test that the distribution key is using custom operator class, should be checked when doing OS upgrade from EL7 to EL8.
tablename  |distclass
-----------+---------
test_citext|16435    
(1 row)


2024-04-25 18:20:57,521 - WARNING - There are 7 range partitioning tables with partition key in collate types(like varchar, char, text) in database test, these tables might be affected due to Glibc upgrade and should be checked when doing OS upgrade from EL7 to EL8.
parrelid|tablename             |collation|attname|hasdefaultpartition
--------+----------------------+---------+-------+-------------------
16487   |partition_range_test_3|100      |date   |f                  
16515   |partition_range_test_4|100      |date   |t                  
16631   |partition_range_test_1|100      |date   |t                  
16658   |partition_range_test_2|100      |date   |f                  
16576   |testddlwithnodata     |100      |date   |f                  
16597   |testddlwithdata       |100      |date   |t                  
16549   |testddl               |100      |date   |t                  
(7 rows)

```

## output example of `el8_migrate_locale identify --index`

```
2024-04-25 18:40:50,288 - INFO - There are 2 catalog indexes that needs reindex when doing OS upgrade from EL7 to EL8.
indexrelid|indexname                 |tablename    |collname|pg_get_indexdef                                                                                                          
----------+--------------------------+-------------+--------+-------------------------------------------------------------------------------------------------------------------------
3597      |pg_seclabel_object_index  |pg_seclabel  |default |CREATE UNIQUE INDEX pg_seclabel_object_index ON pg_catalog.pg_seclabel USING btree (objoid, classoid, objsubid, provider)
3593      |pg_shseclabel_object_index|pg_shseclabel|default |CREATE UNIQUE INDEX pg_shseclabel_object_index ON pg_catalog.pg_shseclabel USING btree (objoid, classoid, provider)      
(2 rows)


2024-04-25 18:40:50,416 - INFO - There are 5 user indexes in database test that needs reindex when doing OS upgrade from EL7 to EL8.
indexrelid|indexname        |tablename          |collname|pg_get_indexdef                                                                      
----------+-----------------+-------------------+--------+-------------------------------------------------------------------------------------
16392     |"test_id2 \ $ \\"|test_character_type|default |CREATE INDEX "test_id2 \ $ \\" ON public.test_character_type USING btree (varchar_10)
16391     |"test_id1 's "   |test_character_type|default |CREATE INDEX "test_id1 's " ON public.test_character_type USING btree (char_1)       
16486     |test_idx_citext  |test_citext        |default |CREATE INDEX test_idx_citext ON public.test_citext USING btree (nick)                
16484     |test_citext_pkey |test_citext        |default |CREATE UNIQUE INDEX test_citext_pkey ON public.test_citext USING btree (nick)        
16393     |" test_id "" 3 " |test_character_type|default |CREATE INDEX " test_id "" 3 " ON public.test_character_type USING btree (txt)        
(5 rows)

```

## output example of `el8_migrate_locale identify --table`

```
2024-04-25 18:41:47,151 - WARNING - There are 1 tables in database test that the distribution key is using custom operator class, should be checked when doing OS upgrade from EL7 to EL8.
tablename  |distclass
-----------+---------
test_citext|16435    
(1 row)


2024-04-25 18:41:47,207 - WARNING - There are 7 range partitioning tables with partition key in collate types(like varchar, char, text) in database test, these tables might be affected due to Glibc upgrade and should be checked when doing OS upgrade from EL7 to EL8.
parrelid|tablename             |collation|attname|hasdefaultpartition
--------+----------------------+---------+-------+-------------------
16487   |partition_range_test_3|100      |date   |f                  
16515   |partition_range_test_4|100      |date   |t                  
16631   |partition_range_test_1|100      |date   |t                  
16658   |partition_range_test_2|100      |date   |f                  
16576   |testddlwithnodata     |100      |date   |f                  
16597   |testddlwithdata       |100      |date   |t                  
16549   |testddl               |100      |date   |t                  
(7 rows)

```

## output file example of `el8_migrate_locale prepare --output prepare.out`

```
\c  postgres
-- catalog indexrelid: 3597 | index name: pg_seclabel_object_index | table name: pg_seclabel | collname: default | indexdef:  CREATE UNIQUE INDEX pg_seclabel_object_index ON pg_catalog.pg_seclabel USING btree (objoid, classoid, objsubid, provider)
reindex index pg_seclabel_object_index;

-- catalog indexrelid: 3593 | index name: pg_shseclabel_object_index | table name: pg_shseclabel | collname: default | indexdef:  CREATE UNIQUE INDEX pg_shseclabel_object_index ON pg_catalog.pg_shseclabel USING btree (objoid, classoid, provider)
reindex index pg_shseclabel_object_index;

\c  test
-- indexrelid: 16392 | index name: "test_id2 \ $ \\" | table name: test_character_type | collname: default | indexdef:  CREATE INDEX "test_id2 \ $ \\" ON public.test_character_type USING btree (varchar_10)
reindex index "test_id2 \ $ \\";

-- indexrelid: 16391 | index name: "test_id1 's " | table name: test_character_type | collname: default | indexdef:  CREATE INDEX "test_id1 's " ON public.test_character_type USING btree (char_1)
reindex index "test_id1 's ";

-- indexrelid: 16486 | index name: test_idx_citext | table name: test_citext | collname: default | indexdef:  CREATE INDEX test_idx_citext ON public.test_citext USING btree (nick)
reindex index test_idx_citext;

-- indexrelid: 16484 | index name: test_citext_pkey | table name: test_citext | collname: default | indexdef:  CREATE UNIQUE INDEX test_citext_pkey ON public.test_citext USING btree (nick)
reindex index test_citext_pkey;

-- indexrelid: 16393 | index name: " test_id "" 3 " | table name: test_character_type | collname: default | indexdef:  CREATE INDEX " test_id "" 3 " ON public.test_character_type USING btree (txt)
reindex index " test_id "" 3 ";

-- order table by size in descending order
\c  test

-- parrelid: 16487 | coll: 100 | attname: date | msg: partition table, 3 leafs, size 98304
begin; create temp table partition_range_test_3_bak as select * from partition_range_test_3; truncate partition_range_test_3; insert into partition_range_test_3 select * from partition_range_test_3_bak; commit;

-- parrelid: 16515 | coll: 100 | attname: date | msg: partition table, 4 leafs, size 98304
begin; create temp table partition_range_test_4_bak as select * from partition_range_test_4; truncate partition_range_test_4; insert into partition_range_test_4 select * from partition_range_test_4_bak; commit;

-- parrelid: 16631 | coll: 100 | attname: date | msg: partition table, 3 leafs, size 98304
begin; create temp table partition_range_test_1_bak as select * from partition_range_test_1; truncate partition_range_test_1; insert into partition_range_test_1 select * from partition_range_test_1_bak; commit;

-- parrelid: 16658 | coll: 100 | attname: date | msg: partition table, 3 leafs, size 98304
begin; create temp table partition_range_test_2_bak as select * from partition_range_test_2; truncate partition_range_test_2; insert into partition_range_test_2 select * from partition_range_test_2_bak; commit;

-- parrelid: 16597 | coll: 100 | attname: date | msg: partition table, 4 leafs, size 65536
begin; create temp table testddlwithdata_bak as select * from testddlwithdata; truncate testddlwithdata; insert into testddlwithdata select * from testddlwithdata_bak; commit;

-- parrelid: 16549 | coll: 100 | attname: date | msg: partition table, 3 leafs, size 32768
begin; create temp table testddl_bak as select * from testddl; truncate testddl; insert into testddl select * from testddl_bak; commit;

-- parrelid: 16576 | coll: 100 | attname: date | msg: partition table, 2 leafs, size 0
begin; create temp table testddlwithnodata_bak as select * from testddlwithnodata; truncate testddlwithnodata; insert into testddlwithnodata select * from testddlwithnodata_bak; commit;
```

## output file example of `el8_migrate_locale prepare --index --output prepare_index.out`

```
\c  postgres
-- catalog indexrelid: 3597 | index name: pg_seclabel_object_index | table name: pg_seclabel | collname: default | indexdef:  CREATE UNIQUE INDEX pg_seclabel_object_index ON pg_catalog.pg_seclabel USING btree (objoid, classoid, objsubid, provider)
reindex index pg_seclabel_object_index;

-- catalog indexrelid: 3593 | index name: pg_shseclabel_object_index | table name: pg_shseclabel | collname: default | indexdef:  CREATE UNIQUE INDEX pg_shseclabel_object_index ON pg_catalog.pg_shseclabel USING btree (objoid, classoid, provider)
reindex index pg_shseclabel_object_index;

\c  test
-- indexrelid: 16392 | index name: "test_id2 \ $ \\" | table name: test_character_type | collname: default | indexdef:  CREATE INDEX "test_id2 \ $ \\" ON public.test_character_type USING btree (varchar_10)
reindex index "test_id2 \ $ \\";

-- indexrelid: 16391 | index name: "test_id1 's " | table name: test_character_type | collname: default | indexdef:  CREATE INDEX "test_id1 's " ON public.test_character_type USING btree (char_1)
reindex index "test_id1 's ";

-- indexrelid: 16486 | index name: test_idx_citext | table name: test_citext | collname: default | indexdef:  CREATE INDEX test_idx_citext ON public.test_citext USING btree (nick)
reindex index test_idx_citext;

-- indexrelid: 16484 | index name: test_citext_pkey | table name: test_citext | collname: default | indexdef:  CREATE UNIQUE INDEX test_citext_pkey ON public.test_citext USING btree (nick)
reindex index test_citext_pkey;

-- indexrelid: 16393 | index name: " test_id "" 3 " | table name: test_character_type | collname: default | indexdef:  CREATE INDEX " test_id "" 3 " ON public.test_character_type USING btree (txt)
reindex index " test_id "" 3 ";
```

## output file example of `el8_migrate_locale prepare --table --output prepare_table.out`

```
-- order table by size in descending order
\c  test

-- parrelid: 16487 | coll: 100 | attname: date | msg: partition table, 3 leafs, size 98304
begin; create temp table partition_range_test_3_bak as select * from partition_range_test_3; truncate partition_range_test_3; insert into partition_range_test_3 select * from partition_range_test_3_bak; commit;

-- parrelid: 16515 | coll: 100 | attname: date | msg: partition table, 4 leafs, size 98304
begin; create temp table partition_range_test_4_bak as select * from partition_range_test_4; truncate partition_range_test_4; insert into partition_range_test_4 select * from partition_range_test_4_bak; commit;

-- parrelid: 16631 | coll: 100 | attname: date | msg: partition table, 3 leafs, size 98304
begin; create temp table partition_range_test_1_bak as select * from partition_range_test_1; truncate partition_range_test_1; insert into partition_range_test_1 select * from partition_range_test_1_bak; commit;

-- parrelid: 16658 | coll: 100 | attname: date | msg: partition table, 3 leafs, size 98304
begin; create temp table partition_range_test_2_bak as select * from partition_range_test_2; truncate partition_range_test_2; insert into partition_range_test_2 select * from partition_range_test_2_bak; commit;

-- parrelid: 16597 | coll: 100 | attname: date | msg: partition table, 4 leafs, size 65536
begin; create temp table testddlwithdata_bak as select * from testddlwithdata; truncate testddlwithdata; insert into testddlwithdata select * from testddlwithdata_bak; commit;

-- parrelid: 16549 | coll: 100 | attname: date | msg: partition table, 3 leafs, size 32768
begin; create temp table testddl_bak as select * from testddl; truncate testddl; insert into testddl select * from testddl_bak; commit;

-- parrelid: 16576 | coll: 100 | attname: date | msg: partition table, 2 leafs, size 0
begin; create temp table testddlwithnodata_bak as select * from testddlwithnodata; truncate testddlwithnodata; insert into testddlwithnodata select * from testddlwithnodata_bak; commit;
```

## output example of `el8_migrate_locale validate`

```
2024-04-25 18:44:41,191 - INFO - worker[0]: begin: 
2024-04-25 18:44:41,191 - INFO - worker[0]: connect to <template1> ...
2024-04-25 18:44:41,197 - INFO - worker[0]: finish.
2024-04-25 18:44:41,249 - INFO - worker[0]: begin: 
2024-04-25 18:44:41,249 - INFO - worker[0]: connect to <postgres> ...
2024-04-25 18:44:41,256 - INFO - worker[0]: finish.
2024-04-25 18:44:41,312 - WARNING - There are 7 range partitioning tables with partition key in collate types(like varchar, char, text) in database test, these tables might be affected due to Glibc upgrade and should be checked when doing OS upgrade from EL7 to EL8.
parrelid|tablename             |collation|attname|hasdefaultpartition
--------+----------------------+---------+-------+-------------------
16487   |partition_range_test_3|100      |date   |f                  
16515   |partition_range_test_4|100      |date   |t                  
16631   |partition_range_test_1|100      |date   |t                  
16658   |partition_range_test_2|100      |date   |f                  
16576   |testddlwithnodata     |100      |date   |f                  
16597   |testddlwithdata       |100      |date   |t                  
16549   |testddl               |100      |date   |t                  
(7 rows)


2024-04-25 18:44:41,312 - INFO - worker[0]: begin: 
2024-04-25 18:44:41,312 - INFO - worker[0]: connect to <test> ...
2024-04-25 18:44:41,355 - INFO - start checking table partition_range_test_3_1_prt_mar ...
2024-04-25 18:44:41,406 - INFO - check table partition_range_test_3_1_prt_mar OK.
2024-04-25 18:44:41,406 - INFO - start checking table partition_range_test_3_1_prt_feb ...
2024-04-25 18:44:41,434 - INFO - check table partition_range_test_3_1_prt_feb OK.
2024-04-25 18:44:41,434 - INFO - start checking table partition_range_test_3_1_prt_jan ...
2024-04-25 18:44:41,456 - INFO - check table partition_range_test_3_1_prt_jan OK.
2024-04-25 18:44:41,500 - INFO - Current progress: have 6 remaining, 0.19 seconds passed.
2024-04-25 18:44:41,511 - INFO - start checking table partition_range_test_4_1_prt_mar ...
2024-04-25 18:44:41,546 - INFO - check table partition_range_test_4_1_prt_mar OK.
2024-04-25 18:44:41,546 - INFO - start checking table partition_range_test_4_1_prt_feb ...
2024-04-25 18:44:41,572 - INFO - check table partition_range_test_4_1_prt_feb OK.
2024-04-25 18:44:41,572 - INFO - start checking table partition_range_test_4_1_prt_jan ...
2024-04-25 18:44:41,594 - INFO - check table partition_range_test_4_1_prt_jan OK.
2024-04-25 18:44:41,594 - INFO - start checking table partition_range_test_4_1_prt_others ...
2024-04-25 18:44:41,611 - INFO - check table partition_range_test_4_1_prt_others OK.
2024-04-25 18:44:41,656 - INFO - Current progress: have 5 remaining, 0.34 seconds passed.
2024-04-25 18:44:41,667 - INFO - start checking table partition_range_test_1_1_prt_mar ...
2024-04-25 18:44:41,703 - INFO - check table partition_range_test_1_1_prt_mar OK.
2024-04-25 18:44:41,703 - INFO - start checking table partition_range_test_1_1_prt_feb ...
2024-04-25 18:44:41,729 - INFO - check table partition_range_test_1_1_prt_feb OK.
2024-04-25 18:44:41,729 - INFO - start checking table partition_range_test_1_1_prt_others ...
2024-04-25 18:44:41,746 - INFO - check table partition_range_test_1_1_prt_others OK.
2024-04-25 18:44:41,791 - INFO - Current progress: have 4 remaining, 0.48 seconds passed.
2024-04-25 18:44:41,802 - INFO - start checking table partition_range_test_2_1_prt_mar ...
2024-04-25 18:44:41,844 - INFO - check table partition_range_test_2_1_prt_mar OK.
2024-04-25 18:44:41,844 - INFO - start checking table partition_range_test_2_1_prt_feb ...
2024-04-25 18:44:41,865 - INFO - check table partition_range_test_2_1_prt_feb OK.
2024-04-25 18:44:41,865 - INFO - start checking table partition_range_test_2_1_prt_jan ...
2024-04-25 18:44:41,887 - INFO - check table partition_range_test_2_1_prt_jan OK.
2024-04-25 18:44:41,931 - INFO - Current progress: have 3 remaining, 0.62 seconds passed.
2024-04-25 18:44:41,943 - INFO - start checking table testddlwithnodata_1_prt_feb ...
2024-04-25 18:44:41,983 - INFO - check table testddlwithnodata_1_prt_feb OK.
2024-04-25 18:44:41,983 - INFO - start checking table testddlwithnodata_1_prt_jan ...
2024-04-25 18:44:42,005 - INFO - check table testddlwithnodata_1_prt_jan OK.
2024-04-25 18:44:42,049 - INFO - Current progress: have 2 remaining, 0.74 seconds passed.
2024-04-25 18:44:42,060 - INFO - start checking table testddlwithdata_1_prt_mar ...
2024-04-25 18:44:42,101 - INFO - check table testddlwithdata_1_prt_mar OK.
2024-04-25 18:44:42,101 - INFO - start checking table testddlwithdata_1_prt_feb ...
2024-04-25 18:44:42,122 - INFO - check table testddlwithdata_1_prt_feb OK.
2024-04-25 18:44:42,122 - INFO - start checking table testddlwithdata_1_prt_jan ...
2024-04-25 18:44:42,143 - INFO - check table testddlwithdata_1_prt_jan OK.
2024-04-25 18:44:42,143 - INFO - start checking table testddlwithdata_1_prt_others ...
2024-04-25 18:44:42,161 - INFO - check table testddlwithdata_1_prt_others OK.
2024-04-25 18:44:42,206 - INFO - Current progress: have 1 remaining, 0.89 seconds passed.
2024-04-25 18:44:42,217 - INFO - start checking table testddl_1_prt_feb ...
2024-04-25 18:44:42,258 - INFO - check table testddl_1_prt_feb OK.
2024-04-25 18:44:42,258 - INFO - start checking table testddl_1_prt_jan ...
2024-04-25 18:44:42,279 - INFO - check table testddl_1_prt_jan OK.
2024-04-25 18:44:42,279 - INFO - start checking table testddl_1_prt_others ...
2024-04-25 18:44:42,296 - INFO - check table testddl_1_prt_others OK.
2024-04-25 18:44:42,340 - INFO - Current progress: have 0 remaining, 1.03 seconds passed.
2024-04-25 18:44:42,340 - INFO - worker[0]: finish.
```

## the test set of above examples

```
-- case1 test basic table and index with char/varchar/text type
CREATE TABLE test_character_type
(
    char_1     CHAR(1),
    varchar_10 VARCHAR(10),
    txt        TEXT
);

INSERT INTO test_character_type (char_1)
VALUES ('Y    ') RETURNING *;

INSERT INTO test_character_type (varchar_10)
VALUES ('HelloWorld    ') RETURNING *;

INSERT INTO test_character_type (txt)
VALUES ('TEXT column can store a string of any length') RETURNING txt;

create index "test_id1 's " on test_character_type (char_1);
create index "test_id2 \ $ \\" on test_character_type (varchar_10);
create index " test_id "" 3 " on test_character_type (txt);

-- case2 test type citext;
create extension citext;
CREATE TABLE test_citext
(
    nick CITEXT PRIMARY KEY,
    pass TEXT NOT NULL
);

INSERT INTO test_citext VALUES ('larry', random()::text);
INSERT INTO test_citext VALUES ('Tom', random()::text);
INSERT INTO test_citext VALUES ('Damian', random()::text);
INSERT INTO test_citext VALUES ('NEAL', random()::text);
INSERT INTO test_citext VALUES ('Bjørn', random()::text);

create index test_idx_citext on test_citext (nick);

----- case 3 test special case with $
create table test1
(
    content varchar
) DISTRIBUTED by (content);
insert into test1 (content)
values ('a'),
       ('$a'),
       ('a$'),
       ('b'),
       ('$b'),
       ('b$'),
       ('A'),
       ('B');
create index id1 on test1 (content);

----  case4 test speical case with '""'
CREATE TABLE hash_test
(
    id   int,
    date text
) DISTRIBUTED BY (date);
insert into hash_test values (1, '01');
insert into hash_test values (1, '"01"');
insert into hash_test values (2, '"02"');
insert into hash_test values (3, '02');
insert into hash_test values (4, '03');

----  case5 test speical case with 1-1 vs 11
CREATE TABLE test2
(
    id   int,
    date text
) DISTRIBUTED BY (id)
PARTITION BY RANGE (date)
( START (text '01-01') INCLUSIVE
   END (text '11-01') EXCLUSIVE
 );

insert into test2
values (2, '02-1'),
       (2, '03-1'),
       (2, '08-1'),
       (2, '09-01'),
       (1, '11'),
       (1, '1-1');

--- case6 test range partition with special character '“”'
CREATE TABLE partition_range_test
(
    id   int,
    date text
) DISTRIBUTED BY (id)
PARTITION BY RANGE (date)
      (PARTITION Jan START ( '01') INCLUSIVE ,
      PARTITION Feb START ( '02') INCLUSIVE ,
      PARTITION Mar START ( '03') INCLUSIVE
      END ( '04') EXCLUSIVE);

insert into partition_range_test values (1, '01');
insert into partition_range_test values (1, '"01"');
insert into partition_range_test values (2, '"02"');
insert into partition_range_test values (2, '02');
insert into partition_range_test values (3, '03');
insert into partition_range_test values (3, '"03"');

-- case7 test range partition with default partition.
CREATE TABLE partition_range_test_default (id int, date text) DISTRIBUTED BY (id)
PARTITION BY RANGE (date)
      (PARTITION feb START ( '02') INCLUSIVE ,
      PARTITION Mar START ( '03') INCLUSIVE,
      Default partition others);

insert into partition_range_test_default values (1, '01'), (1, '"01"'), (2, '"02"'), (2, '02'), (3, '03'), (3, '"03"'), (4, '04'), (4, '"04"');

-- case8 for testing insert into root select * from partition_range_test where date > '"02"';
create table root
(
    id   int,
    date text
) DISTRIBUTED BY (id)
PARTITION BY RANGE (date)
(PARTITION Jan START ( '01') INCLUSIVE ,
PARTITION Feb START ( '02') INCLUSIVE ,
PARTITION Mar START ( '03') INCLUSIVE
END ( '04') EXCLUSIVE);

insert into root
select *
from partition_range_test
where date > '"02"';

--- case9 test range partition with special character '“”' with ao
CREATE TABLE partition_range_test_ao
(
    id   int,
    date text
)
    WITH (appendonly = true)
    DISTRIBUTED BY (id)
    PARTITION BY RANGE (date)
    (PARTITION Jan START ('01') INCLUSIVE ,
    PARTITION Feb START ('02') INCLUSIVE ,
    PARTITION Mar START ('03') INCLUSIVE
    END ('04') EXCLUSIVE);

insert into partition_range_test_ao values (1, '01');
insert into partition_range_test_ao values (1, '"01"');
insert into partition_range_test_ao values (1, '"01-1"');
insert into partition_range_test_ao values (2, '"02-1"');
insert into partition_range_test_ao values (2, '"02"');
insert into partition_range_test_ao values (2, '02');

--- case10 for index constraint violation 
CREATE TABLE repository
(
    id         integer,
    slug       character varying(100),
    name       character varying(100),
    project_id character varying(100)
) DISTRIBUTED BY (slug, project_id);

insert into repository values (793, 'text-rnn', 'text-rnn', 146);
insert into repository values (812, 'ink_data', 'ink_data', 146);

-- case11 for index unique constraint violation 
create table gitrefresh
(
    projecttag        text,
    state             character(1),
    analysis_started  timestamp without time zone,
    analysis_ended    timestamp without time zone,
    counter_requested integer,
    customer_id       integer,
    id                int,
    constraint idx_projecttag unique (projecttag)
);
create index pk_gitrefresh on gitrefresh (id);
INSERT INTO gitrefresh(projecttag, state, analysis_started, counter_requested, customer_id)
VALUES ('npm@randombytes', 'Q', NOW(), 1, 0);

-- case12 for partition range list and special characters
CREATE TABLE rank
(
    id     int,
    gender char(1)
) DISTRIBUTED BY (id)
PARTITION BY LIST (gender)
( PARTITION girls VALUES ('F'), 
  PARTITION boys VALUES ('M'), 
  DEFAULT PARTITION other );

CREATE TABLE "rank $ % &"
(
    id     int,
    gender char(1)
) DISTRIBUTED BY (id)
PARTITION BY LIST (gender)
( PARTITION girls VALUES ('F'), 
  PARTITION boys VALUES ('M'), 
  DEFAULT PARTITION other );

CREATE TABLE "rank $ % & ! *"
(
    id     int,
    gender char(1)
) DISTRIBUTED BY (id)
PARTITION BY LIST (gender)
( PARTITION girls VALUES ('F'), 
  PARTITION boys VALUES ('M'), 
  DEFAULT PARTITION other );

CREATE TABLE "rank 's "
(
    id     int,
    gender char(1)
) DISTRIBUTED BY (id)
PARTITION BY LIST (gender)
( PARTITION girls VALUES ('F'), 
  PARTITION boys VALUES ('M'), 
  DEFAULT PARTITION other );

CREATE TABLE "rank 's' "
(
    id     int,
    gender char(1)
) DISTRIBUTED BY (id)
PARTITION BY LIST (gender)
( PARTITION girls VALUES ('F'), 
  PARTITION boys VALUES ('M'), 
  DEFAULT PARTITION other );

CREATE TABLE "rank b c"
(
    id     int,
    gender char(1)
) DISTRIBUTED BY (id)
PARTITION BY LIST (gender)
( PARTITION girls VALUES ('F'), 
  PARTITION boys VALUES ('M'), 
  DEFAULT PARTITION other );

-- case13 for testing partition key is type date
CREATE TABLE sales (id int, time date, amt decimal(10,2))
DISTRIBUTED BY (id)
PARTITION BY RANGE (time)
( START (date '2022-01-01') INCLUSIVE
   END (date '2023-01-01') EXCLUSIVE
   EVERY (INTERVAL '1 month') );

-- case14 for testing partition range with special characters in name
CREATE TABLE "partition_range_ 's " (id int, date text) 
DISTRIBUTED BY (id)
PARTITION BY RANGE (date)
      (PARTITION feb START ( '02') INCLUSIVE ,
      PARTITION Mar START ( '03') INCLUSIVE,
      Default partition others);

CREATE TABLE "partition_range_ 's' " (id int, date text) 
DISTRIBUTED BY (id)
PARTITION BY RANGE (date)
      (PARTITION feb START ( '02') INCLUSIVE ,
      PARTITION Mar START ( '03') INCLUSIVE,
      Default partition others);
```
