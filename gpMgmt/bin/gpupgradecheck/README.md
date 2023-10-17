1. use `python upgrade_check.py precheck-index` to list affected indexes.
2. use `python upgrade_check.py precheck-table` to list affected partitioned tables.
3. use `python upgrade_check.py postfix` to run the reindex and alter partition table commands.

```
$ python upgrade_check.py --help
usage: upgrade_check [-h] [--host HOST] [--port PORT] [--dbname DBNAME]
                     [--user USER]
                     {precheck-index,precheck-table,postfix} ...

positional arguments:
  {precheck-index,precheck-table,postfix}
                        sub-command help
    precheck-index      list affected index
    precheck-table      list affected tables
    postfix             run the reindex and the rebuild partition commands

optional arguments:
  -h, --help            show this help message and exit
  --host HOST           Greenplum Database hostname
  --port PORT           Greenplum Database port
  --dbname DBNAME       Greenplum Database database name
  --user USER           Greenplum Database user name
```
```
$ python upgrade_check.py precheck-index -h
usage: upgrade_check precheck-index [-h] --out OUT

optional arguments:
  -h, --help  show this help message and exit
  --out OUT   outfile path for the reindex commands

Example usage:

$ python upgrade_check.py precheck-index --out index.out
2023-10-12 03:38:57,733 - INFO - There are 2 catalog indexes that might be affected due to upgrade.
2023-10-12 03:38:57,826 - INFO - There are 7 user indexes in database testupgrade that might be affected due to upgrade.

$ cat index.out
-- DB name:  postgres
-- catalog index name: pg_seclabel_object_index | table name: pg_seclabel | collate: 100 | collname: default | indexdef:  CREATE UNIQUE INDEX pg_seclabel_object_index ON pg_catalog.pg_seclabel USING btree (objoid, classoid, objsubid, provider)
reindex index pg_seclabel_object_index;

-- catalog index name: pg_shseclabel_object_index | table name: pg_shseclabel | collate: 100 | collname: default | indexdef:  CREATE UNIQUE INDEX pg_shseclabel_object_index ON pg_catalog.pg_shseclabel USING btree (objoid, classoid, provider)
reindex index pg_shseclabel_object_index;

-- DB name:  testupgrade
-- index name: test_id1 | table name: test_character_type | collate: 100 | collname: default | indexdef:  CREATE INDEX test_id1 ON public.test_character_type USING btree (char_1)
reindex index test_id1;
...
```
```
$ python upgrade_check.py precheck-table -h
usage: upgrade_check precheck-table [-h] [--order_size_ascend] --out OUT
                                    [--nthread NTHREAD]

optional arguments:
  -h, --help           show this help message and exit
  --order_size_ascend  sort the tables by size in ascending order
  --out OUT            outfile path for the rebuild partition commands
  --nthread NTHREAD    the concurrent threads to check partition tables

Example usage:
$ python upgrade_check.py precheck-table --out table.out
2023-10-16 04:12:19,064 - WARNING - There are 1 tables in database test that the distribution column use customize operator class:
---------------------------------------------
tablename | distclass
('testdiskey', 16397)
---------------------------------------------
2023-10-16 04:12:19,064 - INFO - There are 6 partitioned tables in database testupgrade that might be affected due to upgrade.
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
2023-10-16 04:12:22,058 - INFO - Current progress: have 0 remaining, 2.99126505852 seconds passed.
2023-10-16 04:12:22,058 - INFO - worker[0]: finish.
---------------------------------------------
total table size (in GBytes) : 0.000396907329559
total partition tables       : 6
total leaf partitions        : 19
---------------------------------------------

Example Usage for using nthreads:
$ python upgrade_check.py precheck-table --out table.out --nthread 3
2023-10-16 04:15:54,812 - INFO - There are 6 partitioned tables in database testupgrade that might be affected due to upgrade.
2023-10-16 04:15:54,813 - INFO - worker[0]: begin:
2023-10-16 04:15:54,813 - INFO - worker[0]: connect to <testupgrade> ...
2023-10-16 04:15:54,814 - INFO - worker[1]: begin:
2023-10-16 04:15:54,814 - INFO - worker[1]: connect to <testupgrade> ...
2023-10-16 04:15:54,814 - INFO - worker[2]: begin:
2023-10-16 04:15:54,815 - INFO - worker[2]: connect to <testupgrade> ...
2023-10-16 04:15:54,866 - INFO - start checking table testupgrade.partition_range_test_2_1_prt_mar ...
2023-10-16 04:15:54,870 - INFO - start checking table testupgrade.partition_range_test_ao_1_prt_mar ...
2023-10-16 04:15:54,879 - INFO - start checking table testupgrade.partition_range_test_3_1_prt_mar ...
2023-10-16 04:15:54,921 - INFO - check table testupgrade.partition_range_test_ao_1_prt_mar OK.
2023-10-16 04:15:54,922 - INFO - start checking table testupgrade.partition_range_test_ao_1_prt_feb ...
2023-10-16 04:15:54,926 - INFO - check table testupgrade.partition_range_test_3_1_prt_mar OK.
2023-10-16 04:15:54,926 - INFO - start checking table testupgrade.partition_range_test_3_1_prt_feb ...
2023-10-16 04:15:54,949 - INFO - check table testupgrade.partition_range_test_3_1_prt_feb OK.
2023-10-16 04:15:54,949 - INFO - start checking table testupgrade.partition_range_test_3_1_prt_jan ...
2023-10-16 04:15:54,971 - INFO - check table testupgrade.partition_range_test_3_1_prt_jan OK.
2023-10-16 04:15:55,039 - WARNING - no default partition for testupgrade.partition_range_test_3
2023-10-16 04:15:55,055 - INFO - start checking table testupgrade.partition_range_test_4_1_prt_mar ...
2023-10-16 04:15:55,077 - INFO - check table testupgrade.partition_range_test_4_1_prt_mar OK.
2023-10-16 04:15:55,078 - INFO - start checking table testupgrade.partition_range_test_4_1_prt_feb ...
2023-10-16 04:15:55,098 - INFO - check table testupgrade.partition_range_test_4_1_prt_feb OK.
2023-10-16 04:15:55,098 - INFO - start checking table testupgrade.partition_range_test_4_1_prt_jan ...
2023-10-16 04:15:55,115 - INFO - check table testupgrade.partition_range_test_4_1_prt_jan OK.
2023-10-16 04:15:55,115 - INFO - start checking table testupgrade.partition_range_test_4_1_prt_others ...
2023-10-16 04:15:55,124 - INFO - check table testupgrade.partition_range_test_2_1_prt_mar error out: ERROR:  trying to insert row into wrong partition  (seg0 10.0.138.96:20000 pid=4084)
DETAIL:  Expected partition: partition_range_test_2_1_prt_feb, provided partition: partition_range_test_2_1_prt_mar.
...
2023-10-16 04:15:55,430 - INFO - worker[0]: finish.
2023-10-16 04:15:55,452 - INFO - check table testupgrade.partition_range_test_ao_1_prt_jan error out: ERROR:  no partition for partitioning key  (seg1 10.0.138.96:20001 pid=4079)

2023-10-16 04:15:55,493 - WARNING - no default partition for testupgrade.partition_range_test_ao
2023-10-16 04:15:55,495 - INFO - Current progress: have 0 remaining, 0.680027961731 seconds passed.
2023-10-16 04:15:55,495 - INFO - worker[2]: finish.
2023-10-16 04:15:55,544 - INFO - check table testupgrade.partition_range_test_2_1_prt_jan error out: ERROR:  no partition for partitioning key  (seg1 10.0.138.96:20001 pid=4083)

2023-10-16 04:15:55,583 - WARNING - no default partition for testupgrade.partition_range_test_2
2023-10-16 04:15:55,585 - INFO - Current progress: have 0 remaining, 0.770350933075 seconds passed.
2023-10-16 04:15:55,585 - INFO - worker[1]: finish.
---------------------------------------------
total table size (in GBytes) : 0.000396907329559
total partition tables       : 6
total leaf partitions        : 19
---------------------------------------------

$ cat table.out
-- order table by size in descending order
-- DB name:  testupgrade

-- parrelid: 16649 | coll: 100 | attname: date | msg: partition table, 3 leafs, size 98304
begin; create temp table "testupgrade.partition_range_test_3_bak" as select * from testupgrade.partition_range_test_3; truncate testupgrade.partition_range_test_3; insert into testupgrade.partition_range_test_3 select * from "testupgrade.partition_range_test_3_bak"; commit;
...

```
```
$ python upgrade_check.py postfix -h
usage: upgrade_check postfix [-h] --input INPUT

optional arguments:
  -h, --help     show this help message and exit
  --input INPUT  the file contains reindex or rebuild partition ccommandsmds

Example usage for postfix index:
$ python upgrade_check.py postfix --input index.out
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

Example usage for postfix tables:
$ python upgrade_check.py postfix --input table.out
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
Note: For easier reading, some contents is omitted with ellipses.
