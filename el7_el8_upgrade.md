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
        select prelid::regclass::text as partitionname, coll, attname, bool_or(parisdefault) as parhasdefault from par_has_default group by (prelid, coll, attname) 
```
2. How to do pre-check
- Indexes

    Connect to each db, and run the upper filter SQL, then output the index infos into the specified output file.

    The precheck-index main functions are in `CheckIndexes()` and `dump_index_info()`
 
    Example usage:
    ```
  [gpadmin@cdw ~]$  python upgrade_check.py precheck-index --out index.out
    2023-09-11 10:31:31,592 - INFO - There are 2 catalog indexes that might be affected due to upgrade.
    2023-09-11 10:31:31,648 - INFO - There are 0 user indexes in database template1 that might be affected due to upgrade.
    2023-09-11 10:31:31,679 - INFO - There are 0 user indexes in database postgres that might be affected due to upgrade.
    2023-09-11 10:31:31,833 - INFO - There are 7 user indexes in database testupgrade that might be affected due to upgrade.
    ```
  
    ```
    $ cat index.out
    -- DB name:  postgres
    -- catalog index name: pg_seclabel_object_index | table name: pg_seclabel | collate: 100 | collname: default | indexdef:  CREATE UNIQUE INDEX pg_seclabel_object_index ON pg_catalog.pg_seclabel USING btree (objoid, classoid, objsubid, provider)
    reindex index pg_seclabel_object_index;
    
    -- catalog index name: pg_shseclabel_object_index | table name: pg_shseclabel | collate: 100 | collname: default | indexdef:  CREATE UNIQUE INDEX pg_shseclabel_object_index ON pg_catalog.pg_shseclabel USING btree (objoid, classoid, provider)
    reindex index pg_shseclabel_object_index;
  
    -- DB name:  test
    -- index name: test_idx_citext | table name: test_citext | collate: 100 | collname: default | indexdef:  CREATE INDEX test_idx_citext ON public.test_citext USING btree (nick)
    reindex index test_idx_citext;
    
    -- index name: id1 | table name: test1 | collate: 100 | collname: default | indexdef:  CREATE INDEX id1 ON public.test1 USING btree (content)
    reindex index id1;
    ```
- Range-partitioned tables
  
   Connect to each db, and run the upper filter SQL, then dump the table info (like the size of the table, partition numbers, etc) to the specified output file.

   The precheck-index main functions are in `CheckTables()` and `dump()`

   Example usage:
    ```
  [gpadmin@cdw ~]$  python upgrade_check.py precheck-table --out table.out
    2023-09-11 10:32:25,333 - INFO - There are 0 partitioned tables in database template1 that might be affected due to upgrade.
    2023-09-11 10:32:25,434 - INFO - There are 0 partitioned tables in database postgres that might be affected due to upgrade.
    2023-09-11 10:32:25,543 - INFO - There are 12 partitioned tables in database testupgrade that might be affected due to upgrade.
    2023-09-11 10:32:25,614 - WARNING - no default partition for partition_range_test_2
    2023-09-11 10:32:25,631 - WARNING - no default partition for root
    2023-09-11 10:32:25,648 - WARNING - no default partition for partition_range_test_ao
    total table size (in GBytes) : 0.000213801860809
    total partition tables       : 4
    total leaf partitions        : 12
    ```
  
    ```
    $ cat table.out
  -- order table by size in descending order
  -- DB name:  test
  -- partition table, 3 leafs, size 32768
  -- name: root | coll: 100 | attname: date
  insert into root select * from root;
  
  -- partition table, 1 leafs, size 65536
  -- name: test2 | coll: 100 | attname: date
  insert into test2 select * from test2;
  
  -- partition table, 3 leafs, size 98304
  -- name: partition_range_test_default | coll: 100 | attname: date
  insert into partition_range_test_default select * from partition_range_test_default;
    ```
  
3. How to do the postcheck
- For Indexes

    Just `reindex XXX`
    
- range-partitioned tables

    Re-build the partition

  `begin; create temp table XXX_bak as select * from XXX; truncate XXX; insert into XXX select * from XXX_bak; commit;`

Example usage:
```
[gpadmin@cdw ~]$  python upgrade_check.py run --input table.out
2023-09-11 10:32:43,478 - INFO - db: testupgrade, total have 4 commands to execute
2023-09-11 10:32:43,484 - INFO - db: testupgrade, executing command: begin; create temp table partition_range_test_1_bak as select * from partition_range_test_1; truncate partition_range_test_1; insert into partition_range_test_1 select * from partition_range_test_1_bak; commit;
2023-09-11 10:32:43,732 - INFO - db: testupgrade, executing analyze command: analyze partition_range_test_1;;
2023-09-11 10:32:43,752 - INFO - Current worker 0: have 3 remaining, 0.267693996429 seconds passed.
2023-09-11 10:32:43,798 - INFO - db: testupgrade, executing command: begin; create temp table partition_range_test_2_bak as select * from partition_range_test_2; truncate partition_range_test_2; insert into partition_range_test_2 select * from partition_range_test_2_bak; commit;
2023-09-11 10:32:44,247 - ERROR - ERROR:  no partition for partitioning key  (seg1 10.0.138.98:20001 pid=3979)

2023-09-11 10:32:44,263 - INFO - db: testupgrade, executing command: begin; create temp table root_bak as select * from root; truncate root; insert into root select * from root_bak; commit;
2023-09-11 10:32:44,403 - INFO - db: testupgrade, executing analyze command: analyze root;;
2023-09-11 10:32:44,424 - INFO - Current worker 2: have 1 remaining, 0.160354852676 seconds passed.
2023-09-11 10:32:44,478 - INFO - db: testupgrade, executing command: begin; create temp table partition_range_test_ao_bak as select * from partition_range_test_ao; truncate partition_range_test_ao; insert into partition_range_test_ao select * from partition_range_test_ao_bak; commit;
2023-09-11 10:32:44,842 - ERROR - ERROR:  no partition for partitioning key  (seg1 10.0.138.98:20001 pid=3995)

2023-09-11 10:32:44,981 - INFO - All done
```

The main function are in `ConcurrentRun()`.

