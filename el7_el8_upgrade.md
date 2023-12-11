# Background
> PostgreSQL, and Greenplum, uses locale data provided by the operating system’s C library for sorting text. Sorting happens in a variety of contexts, including for user output, merge joins, B-tree indexes, and range partitions. In the latter two cases, sorted data is persisted to disk. If the locale data in the C library changes during the lifetime of a database, the persisted data may become inconsistent with the expected sort order, which could lead to erroneous query results and other incorrect behavior. For example, if an index is not sorted in a way that an index scan is expecting it, a query could fail to find data that is actually there, and an update could insert duplicate data that should be disallowed. Similarly, in a partitioned table, a query could look in the wrong partition and an update could write to the wrong partition. Therefore, it is essential to the correct operation of a database that the locale definitions do not change incompatibly during the lifetime of a database. This issue is well known and documented for PostgreSQL.

see: <https://wiki.postgresql.org/wiki/Locale_data_changes>

> When an instance needs to be upgraded to a new glibc release, for example to upgrade the operating system, then after the upgrade
>
> - All indexes involving columns of type text, varchar, char, and citext should be reindexed before the instance is put into production.
>
> - Range-partitioned tables using those types in the partition key should be checked to verify that all rows are still in the correct partitions. (This is quite unlikely to be a problem, only with particularly obscure partitioning bounds.)
>
> - To avoid downtime due to reindexing or repartitioning, consider upgrading using logical replication.
> - Databases or table columns using the “C” or “POSIX” locales are not affected. All other locales are potentially affected.
> - Table columns using collations with the ICU provider are not affected.

The same issue impacts Greenplum Database and must be taken into consideration with a Major version upgrade from EL 7 to EL 8.

Reference: https://confluence.eng.vmware.com/pages/viewpage.action?spaceKey=TGP&title=Enterprise+Linux+7+to+8+Upgrades+for+Greenplum

# Problems
1. For range-partitioned tables, the rows might not in the correct partitions after upgrade. 

    Example:
```
-- with default partitions
CREATE TABLE partition_range_test_1 (id int, date text) DISTRIBUTED BY (id)
PARTITION BY RANGE (date)
      (PARTITION feb START ( '02') INCLUSIVE ,
      PARTITION Mar START ( '03') INCLUSIVE,
      Default partition others);

insert into partition_range_test_1 values (1, '01'), (1, '"01"'), (2, '"02"'), (2, '02'), (3, '03'), (3, '"03"'), (4, '04'), (4, '"04"');

----- RHEL7 test results
# select * from partition_range_test_1 order by date;
id | date
----+------
  1 | 01
  1 | "01"
  2 | 02
  2 | "02"
  3 | 03
  3 | "03"
  4 | 04
  4 | "04"
(8 rows)

# select * from partition_range_test_1_1_prt_feb;
 id | date
----+------
  2 | "02"
  2 | 02
(2 rows)

# select * from partition_range_test_1_1_prt_mar;
id | date
----+------
  3 | 03
  3 | "03"
  4 | 04
  4 | "04"
(4 rows)

# select * from partition_range_test_1_1_prt_others;
id | date
----+------
  1 | 01
  1 | "01"
(2 rows)

----- Rhel8 results
test=# select * from partition_range_test_1 order by date;
 id | date
----+------
  1 | "01"
  1 | 01
  2 | "02"
  2 | 02
  3 | "03"
  3 | 03
  4 | "04"
  4 | 04
(8 rows)

test=# select * from partition_range_test_1_1_prt_feb;
 id | date
----+------
  2 | 02
  3 | "03"
(2 rows)

test=# select * from partition_range_test_1_1_prt_mar;
 id | date
----+------
  3 | 03
  4 | 04
  4 | "04"
(3 rows)

test=# select * from partition_range_test_1_1_prt_others;
 id | date
----+------
  1 | 01
  1 | "01"
  2 | "02"
(3 rows)
```
2. For range-partitioned table, if it doesn't have default partition, it might encounter errors after upgrade.

```
----- test range partition with special character '“”', which could lead sub-partition data different and might cause error when upgrading.
----- without default partitions, it might encounter errors after upgrade.

CREATE TABLE partition_range_test_2 (id int, date text) DISTRIBUTED BY (id)
PARTITION BY RANGE (date)
      (PARTITION Jan START ( '01') INCLUSIVE ,
      PARTITION Feb START ( '02') INCLUSIVE ,
      PARTITION Mar START ( '03') INCLUSIVE
      END ( '04') EXCLUSIVE);

insert into partition_range_test_2 values (1, '01'), (1, '"01"'), (2, '"02"'), (2, '02'), (3, '03'), (3, '"03"');

----- RHEL 7 results
# select * from partition_range_test_2 order by date;
id | date
----+------
  1 | 01
  1 | "01"
  2 | 02
  2 | "02"
  3 | 03
  3 | "03"
(6 rows)
# select * from partition_range_test_2_1_prt_jan ;
 id | date
----+------
  1 | 01
  1 | "01"
(2 rows)

# select * from partition_range_test_2_1_prt_feb ;
 id | date
----+------
  2 | "02"
  2 | 02
(2 rows)

# select * from partition_range_test_2_1_prt_mar ;
 id | date
----+------
  3 | 03
  3 | "03"
(2 rows)

----- RHEL8 results
test=# insert into partition_range_test_2 values (1, '01'), (2, '"02"'), (2, '02'), (3, '03'), (3, '"03"');
INSERT 0 5
test=# insert into partition_range_test_2 values (1, '"01"');
ERROR:  no partition of relation "partition_range_test_2" found for row  (seg1 10.80.0.2:7003 pid=40499)
DETAIL:  Partition key of the failing row contains (date) = ("01").
test=# select * from partition_range_test_2 order by date;
id | date
----+------
  1 | 01
  2 | "02"
  2 | 02
  3 | "03"
  3 | 03
(5 rows)
```
    
3. For range-partitioned tables, a query could look in the wrong partition and lead wrong results.

```
CREATE TABLE partition_range_test_3(id int, date text) DISTRIBUTED BY (id)
PARTITION BY RANGE (date)
      (
        PARTITION jan START ('01') INCLUSIVE,
        PARTITION feb START ('"02"') INCLUSIVE,
        PARTITION mar START ('"03"') INCLUSIVE );

insert into partition_range_test_3 values (1, '01'), (1, '"01"'), (1, '"02"'), (1, '02'), (1, '03'), (1, '"03"'), (1, '04'), (1, '"04"');

testupgrade=# \dS+ partition_range_test_3;
                Table "public.partition_range_test_3"
 Column |  Type   | Modifiers | Storage  | Stats target | Description
--------+---------+-----------+----------+--------------+-------------
 id     | integer |           | plain    |              |
 date   | text    |           | extended |              |
Child tables: partition_range_test_3_1_prt_feb,
              partition_range_test_3_1_prt_jan,
              partition_range_test_3_1_prt_mar
Distributed by: (id)
Partition by: (date)

testupgrade=# select * from partition_range_test_3 order by date;
 id | date
----+------
  1 | "01"
  1 | 01
  1 | "02"
  1 | 02
  1 | "03"
  1 | 03
  1 | "04"
  1 | 04
(8 rows)

testupgrade=# select * from partition_range_test_3_1_prt_jan ;
 id | date
----+------
  1 | 01
  1 | "01"
  1 | 02
(3 rows)

testupgrade=# select * from partition_range_test_3_1_prt_feb ;
 id | date
----+------
  1 | "02"
  1 | 03
(2 rows)

testupgrade=# select * from partition_range_test_3_1_prt_mar ;
 id | date
----+------
  1 | "03"
  1 | 04
  1 | "04"
(3 rows)

--- !! wrong results here !!--------
testupgrade=# select * from partition_range_test_3 where date='03';
 id | date
----+------
(0 rows)

testupgrade=# explain select * from partition_range_test_3 where date='03';
                                           QUERY PLAN
------------------------------------------------------------------------------------------------
 Gather Motion 4:1  (slice1; segments: 4)  (cost=0.00..720.00 rows=50 width=36)
   ->  Append  (cost=0.00..720.00 rows=13 width=36)
         ->  Seq Scan on partition_range_test_3_1_prt_mar  (cost=0.00..720.00 rows=13 width=36)
               Filter: (date = '03'::text)
 Optimizer: Postgres query optimizer
(5 rows)

testupgrade=# select * from partition_range_test_3_1_prt_mar;
 id | date
----+------
  1 | "03"
  1 | 04
  1 | "04"
(3 rows)

testupgrade=# select * from partition_range_test_3_1_prt_feb ;
 id | date
----+------
  1 | "02"
  1 | 03
(2 rows)

--- !! wrong results with orca !! ----
testupgrade=# select * from partition_range_test_3 where date='03';
 id | date
----+------
(0 rows)

testupgrade=# explain select * from partition_range_test_3 where date='03';
                                                      QUERY PLAN
----------------------------------------------------------------------------------------------------------------------
 Gather Motion 4:1  (slice1; segments: 4)  (cost=0.00..431.00 rows=1 width=12)
   ->  Sequence  (cost=0.00..431.00 rows=1 width=12)
         ->  Partition Selector for partition_range_test_3 (dynamic scan id: 1)  (cost=10.00..100.00 rows=25 width=4)
               Partitions selected: 1 (out of 3)
         ->  Dynamic Seq Scan on partition_range_test_3 (dynamic scan id: 1)  (cost=0.00..431.00 rows=1 width=12)
               Filter: (date = '03'::text)
 Optimizer: Pivotal Optimizer (GPORCA)
(7 rows)
```

# PR 
https://github.com/greenplum-db/gpdb/pull/16312
1. How to filter the impacted indexes and range-partition tables

- For indexes

  Use this SQL query in each database to find out which indexes are affected.
```SQL
SELECT indexrelid::regclass::text, indrelid::regclass::text, coll, collname, pg_get_indexdef(indexrelid)
FROM (SELECT indexrelid, indrelid, indcollation[i] coll FROM pg_index, generate_subscripts(indcollation, 1) g(i)) s
JOIN pg_collation c ON coll=c.oid
WHERE collname != 'C' and collname != 'POSIX'
```
- For range-partitioned tables
    
  Use this SQL query in each database to find out which range-partitioned tables are affected.

```SQL
SELECT
  coll,
  attrelid::regclass::text,
  attname,
  attnum
FROM
  (
    select
      t.attcollation coll,
      t.attrelid,
      t.attname,
      t.attnum
    from
      pg_partition p
      join pg_attribute t on p.parrelid = t.attrelid
      and t.attnum = ANY(p.paratts :: smallint[])
  ) s
  JOIN pg_collation c ON coll = c.oid
WHERE
  collname NOT IN ('C', 'POSIX');
```
 
As mentioned in the problem #2, if there is no default partition, it might report error.
It's better to give a warning if there is no default partition.

So rewrite the upper SQL and use the following one, it's in `get_affected_partitioned_tables()`

```SQL
       WITH might_affected_tables AS (
        SELECT
        prelid,
        coll,
        attname,
        attnum,
        parisdefault
        FROM
        (
            select
            p.oid as poid,
            p.parrelid as prelid,
            t.attcollation coll,
            t.attname as attname,
            t.attnum as attnum
            from
            pg_partition p
            join pg_attribute t on p.parrelid = t.attrelid
            and t.attnum = ANY(p.paratts :: smallint[])
            and p.parkind = 'r'
        ) s
        JOIN pg_collation c ON coll = c.oid
        JOIN pg_partition_rule r ON poid = r.paroid
        WHERE
        collname != 'C' and collname != 'POSIX' 
        ),
        par_has_default AS (
        SELECT
        prelid,
        coll,
        attname,
        parisdefault
        FROM 
        might_affected_tables group by (prelid, coll, attname, parisdefault)
        )
        select prelid, prelid::regclass::text as partitionname, coll, attname, bool_or(parisdefault) as parhasdefault from par_has_default group by (prelid, coll, attname) ;
```
2. How to do pre-check
- Indexes

    Connect to each db, and run the upper filter SQL, then output the index infos into the specified output file.

    The precheck-index main functions are in `CheckIndexes()` and `dump_index_info()`
 
    Example usage:
    ```
  [gpadmin@cdw ~]$  python el8_migrate_locale.py precheck-index --out index.out
    2023-10-18 11:04:13,944 - INFO - There are 2 catalog indexes that needs reindex when doing OS upgrade from EL7->EL8.
    2023-10-18 11:04:14,001 - INFO - There are 7 user indexes in database test that needs reindex when doing OS upgrade from EL7->EL8.
    ```
  
    ```
    $ cat index.out
    \c  postgres
    -- catalog indexrelid: 3597 | index name: pg_seclabel_object_index | table name: pg_seclabel | collname: default | indexdef:  CREATE UNIQUE INDEX pg_seclabel_object_index ON pg_catalog.pg_seclabel USING btree (objoid, classoid, objsubid, provider)
    reindex index pg_seclabel_object_index;

    -- catalog indexrelid: 3593 | index name: pg_shseclabel_object_index | table name: pg_shseclabel | collname: default | indexdef:  CREATE UNIQUE INDEX pg_shseclabel_object_index ON pg_catalog.pg_shseclabel USING btree (objoid, classoid, provider)
    reindex index pg_shseclabel_object_index;

    \c  test
    -- indexrelid: 16512 | index name: testupgrade.hash_idx1 | table name: testupgrade.hash_test1 | collname: default | indexdef:  CREATE INDEX hash_idx1 ON testupgrade.hash_test1 USING btree (content)
    reindex index testupgrade.hash_idx1;
    ```

- Range-partitioned tables
  
   Connect to each db, and run the upper filter SQL, then dump the table info (like the size of the table, partition numbers, etc) to the specified output file.

   The precheck-index main functions are in `CheckTables()` and `dump_tables()`

   Notes: there is a new option pre_upgrade, which is used before OS upgrade, and it will print all the potential affected partition tables before OS upgrade.

  Example usage for check partition tables before OS upgrade:
  ```
  $ python el8_migrate_locale.py precheck-table --pre_upgrade --out table_pre_upgrade.out
  2023-10-18 08:04:06,907 - INFO - There are 6 partitioned tables in database testupgrade that should be checked when doing OS upgrade from EL7->EL8.
  2023-10-18 08:04:06,947 - WARNING - no default partition for testupgrade.partition_range_test_3
  2023-10-18 08:04:06,984 - WARNING - no default partition for testupgrade.partition_range_test_ao
  2023-10-18 08:04:07,021 - WARNING - no default partition for testupgrade.partition_range_test_2
  2023-10-18 08:04:07,100 - WARNING - no default partition for testupgrade.root
  ---------------------------------------------
  total partition tables size  : 416 KB
  total partition tables       : 6
  total leaf partitions        : 19
  ---------------------------------------------
  ```
  
   Output file content:
```
$ cat table_pre_upgrade.out  
-- order table by size in descending order
\c  testupgrade

-- parrelid: 16649 | coll: 100 | attname: date | msg: partition table, 3 leafs, size 98304
begin; create temp table "testupgrade.partition_range_test_3_bak" as select * from testupgrade.partition_range_test_3; truncate testupgrade.partition_range_test_3; insert into testupgrade.partition_range_test_3 select * from "testupgrade.partition_range_test_3_bak"; commit;

```

**New Update here**

  For range-partitioned tables, after OS upgrade, it's better to run the precheck-table again, but without the option pre_upgrade.
  It will filter the partition tables lists which getting from the upper SQLs again by using the GUC `gp_detect_data_correctness`, if the check failed, it means that the data is not in the expected partitions after the OS upgrade, and it will dump those tables info the specified output files.

  The GUC comes from this PR https://github.com/greenplum-db/gpdb/pull/16367/files

  Also, we are using multiple threads to do the checking.

Example usage for the check tables after OS upgrade:
```
$ python el8_migrate_locale.py precheck-table --out table.out
2023-10-16 04:12:19,064 - WARNING - There are 2 tables in database test that the distribution key is using custom operator class, should be checked when doing OS upgrade from EL7->EL8.
---------------------------------------------
tablename | distclass
('testdiskey', 16397)
('testupgrade.test_citext', 16454)
---------------------------------------------
2023-10-16 04:12:19,064 - INFO - There are 6 partitioned tables in database testupgrade that should be checked when doing OS upgrade from EL7->EL8.
2023-10-16 04:12:19,066 - INFO - worker[0]: begin:
2023-10-16 04:12:19,066 - INFO - worker[0]: connect to <testupgrade> ...
2023-10-16 04:12:19,110 - INFO - start checking table testupgrade.partition_range_test_3_1_prt_mar ...
2023-10-16 04:12:19,162 - INFO - check table testupgrade.partition_range_test_3_1_prt_mar OK.
2023-10-16 04:12:19,162 - INFO - start checking table testupgrade.partition_range_test_3_1_prt_feb ...
2023-10-16 04:12:19,574 - INFO - check table testupgrade.partition_range_test_3_1_prt_feb error out: ERROR:  trying to insert row into wrong partition  (seg1 10.0.138.96:20001 pid=3975)
DETAIL:  Expected partition: partition_range_test_3_1_prt_mar, provided partition: partition_range_test_3_1_prt_feb.

2023-10-16 04:12:19,575 - INFO - start checking table testupgrade.partition_range_test_3_1_prt_jan ...
2023-10-16 04:12:19,762 - INFO - check table testupgrade.partition_range_test_3_1_prt_jan error out: ERROR:  trying to insert row into wrong partition  (seg1 10.0.138.96:20001 pid=3975)
DETAIL:  Expected partition: partition_range_test_3_1_prt_feb, provided partition: partition_range_test_3_1_prt_jan.

2023-10-16 04:12:19,804 - WARNING - no default partition for testupgrade.partition_range_test_3
...
2023-10-16 04:12:22,058 - INFO - Current progress: have 0 remaining, 2.77 seconds passed.
2023-10-16 04:12:22,058 - INFO - worker[0]: finish.
---------------------------------------------
total partition tables size  : 416 KB
total partition tables       : 6
total leaf partitions        : 19
---------------------------------------------
```

```
$ cat table.out
-- order table by size in descending order
\c  testupgrade

-- parrelid: 16649 | coll: 100 | attname: date | msg: partition table, 3 leafs, size 98304
begin; create temp table "testupgrade.partition_range_test_3_bak" as select * from testupgrade.partition_range_test_3; truncate testupgrade.partition_range_test_3; insert into testupgrade.partition_range_test_3 select * from "testupgrade.partition_range_test_3_bak"; commit;
...
```
  
3. How to do the migrate
- For Indexes

    Just `reindex XXX`
    
- range-partitioned tables

    Re-build the partition

  `begin; create temp table XXX_bak as select * from XXX; truncate XXX; insert into XXX select * from XXX_bak; commit;`

Example usage for migrate index:
```
$ python el8_migrate_locale.py migrate --input index.out
2023-10-16 04:12:02,461 - INFO - db: testupgrade, total have 7 commands to execute
2023-10-16 04:12:02,467 - INFO - db: testupgrade, executing command: reindex index testupgrade.test_id1;
2023-10-16 04:12:02,541 - INFO - db: testupgrade, executing command: reindex index testupgrade.test_id2;
2023-10-16 04:12:02,566 - INFO - db: testupgrade, executing command: reindex index testupgrade.test_id3;
2023-10-16 04:12:02,592 - INFO - db: testupgrade, executing command: reindex index testupgrade.test_citext_pkey;
2023-10-16 04:12:02,623 - INFO - db: testupgrade, executing command: reindex index testupgrade.test_idx_citext;
2023-10-16 04:12:02,647 - INFO - db: testupgrade, executing command: reindex index testupgrade.hash_idx1;
2023-10-16 04:12:02,673 - INFO - db: testupgrade, executing command: reindex index testupgrade.idx_projecttag;
2023-10-16 04:12:02,692 - INFO - db: postgres, total have 2 commands to execute
2023-10-16 04:12:02,698 - INFO - db: postgres, executing command: reindex index pg_seclabel_object_index;
2023-10-16 04:12:02,730 - INFO - db: postgres, executing command: reindex index pg_shseclabel_object_index;
2023-10-16 04:12:02,754 - INFO - All done
```

Example usage for migrate tables:
```
$ python el8_migrate_locale.py migrate --input table.out
2023-10-16 04:14:17,003 - INFO - db: testupgrade, total have 6 commands to execute
2023-10-16 04:14:17,009 - INFO - db: testupgrade, executing command: begin; create temp table "testupgrade.partition_range_test_3_bak" as select * from testupgrade.partition_range_test_3; truncate testupgrade.partition_range_test_3; insert into testupgrade.partition_range_test_3 select * from "testupgrade.partition_range_test_3_bak"; commit;
2023-10-16 04:14:17,175 - INFO - db: testupgrade, executing analyze command: analyze testupgrade.partition_range_test_3;;
2023-10-16 04:14:17,201 - INFO - db: testupgrade, executing command: begin; create temp table "testupgrade.partition_range_test_2_bak" as select * from testupgrade.partition_range_test_2; truncate testupgrade.partition_range_test_2; insert into testupgrade.partition_range_test_2 select * from "testupgrade.partition_range_test_2_bak"; commit;
2023-10-16 04:14:17,490 - ERROR - ERROR:  no partition for partitioning key  (seg1 10.0.138.96:20001 pid=4028)

2023-10-16 04:14:17,497 - INFO - db: testupgrade, executing command: begin; create temp table "testupgrade.partition_range_test_4_bak" as select * from testupgrade.partition_range_test_4; truncate testupgrade.partition_range_test_4; insert into testupgrade.partition_range_test_4 select * from "testupgrade.partition_range_test_4_bak"; commit;
2023-10-16 04:14:17,628 - INFO - db: testupgrade, executing analyze command: analyze testupgrade.partition_range_test_4;;
2023-10-16 04:14:17,660 - INFO - db: testupgrade, executing command: begin; create temp table "testupgrade.partition_range_test_1_bak" as select * from testupgrade.partition_range_test_1; truncate testupgrade.partition_range_test_1; insert into testupgrade.partition_range_test_1 select * from "testupgrade.partition_range_test_1_bak"; commit;
2023-10-16 04:14:17,784 - INFO - db: testupgrade, executing analyze command: analyze testupgrade.partition_range_test_1;;
2023-10-16 04:14:17,808 - INFO - db: testupgrade, executing command: begin; create temp table "testupgrade.root_bak" as select * from testupgrade.root; truncate testupgrade.root; insert into testupgrade.root select * from "testupgrade.root_bak"; commit;
2023-10-16 04:14:17,928 - INFO - db: testupgrade, executing analyze command: analyze testupgrade.root;;
2023-10-16 04:14:17,952 - INFO - db: testupgrade, executing command: begin; create temp table "testupgrade.partition_range_test_ao_bak" as select * from testupgrade.partition_range_test_ao; truncate testupgrade.partition_range_test_ao; insert into testupgrade.partition_range_test_ao select * from "testupgrade.partition_range_test_ao_bak"; commit;
2023-10-16 04:14:18,276 - ERROR - ERROR:  no partition for partitioning key  (seg1 10.0.138.96:20001 pid=4060)

2023-10-16 04:14:18,277 - INFO - All done
```

The main function is in `migrate()`.

**New Update here**

Before that, the `migrate()` function are using multiple processes to run the alter commands. We changed it to use single process to avoid potential disk overhead.
