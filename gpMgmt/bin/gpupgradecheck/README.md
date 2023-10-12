1. use `python upgrade_check.py precheck-index` to list affected indexes.
2. use `pythonn upgrade_check.py precheck-table` to list affected partitioned tables.
3. use `python upgrade_check.py postfix` to run the re-index and alter partition table commands.

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
    postfix             postfix run the reindex and the rebuild partition
                        commands

optional arguments:
  -h, --help            show this help message and exit
  --host HOST           Greenplum Database hostname
  --port PORT           Greenplum Database port
  --dbname DBNAME       Greenplum Database database name
  --user USER           Greenplum Database user name

$ python upgrade_check.py precheck-index -h
usage: upgrade_check precheck-index [-h] --out OUT

optional arguments:
  -h, --help  show this help message and exit
  --out OUT   outfile path for the reindex commands

$ python upgrade_check.py precheck-table -h
usage: upgrade_check precheck-table [-h] [--order_size_ascend] --out OUT

optional arguments:
  -h, --help           show this help message and exit
  --order_size_ascend  sort the tables by size in ascending order
  --out OUT            outfile path for the rebuild partition commands

$ python upgrade_check.py postfix -h
usage: upgrade_check postfix [-h] --input INPUT [--nproc NPROC]

optional arguments:
  -h, --help     show this help message and exit
  --input INPUT  the file contains reindex or rebuild partition ccommandsmds
  --nproc NPROC  the concurrent proces to run the commands
```

Example usages:
```
[gpadmin@cdw ~]$ python upgrade_check.py precheck-index --out index.out
2023-10-12 03:38:57,733 - INFO - There are 2 catalog indexes that might be affected due to upgrade.
2023-10-12 03:38:57,763 - INFO - There are 0 user indexes in database template1 that might be affected due to upgrade.
2023-10-12 03:38:57,793 - INFO - There are 0 user indexes in database postgres that might be affected due to upgrade.
2023-10-12 03:38:57,826 - INFO - There are 7 user indexes in database testupgrade that might be affected due to upgrade.

2023-10-12 03:39:20,239 - INFO - All done

[gpadmin@cdw ~]$ cat index.out
-- DB name:  postgres
-- catalog index name: pg_seclabel_object_index | table name: pg_seclabel | collate: 100 | collname: default | indexdef:  CREATE UNIQUE INDEX pg_seclabel_object_index ON pg_catalog.pg_seclabel USING btree (objoid, classoid, objsubid, provider)
reindex index pg_seclabel_object_index;

-- catalog index name: pg_shseclabel_object_index | table name: pg_shseclabel | collate: 100 | collname: default | indexdef:  CREATE UNIQUE INDEX pg_shseclabel_object_index ON pg_catalog.pg_shseclabel USING btree (objoid, classoid, provider)
reindex index pg_shseclabel_object_index;

-- DB name:  testupgrade
-- index name: test_id1 | table name: test_character_type | collate: 100 | collname: default | indexdef:  CREATE INDEX test_id1 ON public.test_character_type USING btree (char_1)
reindex index test_id1;

-- index name: test_id2 | table name: test_character_type | collate: 100 | collname: default | indexdef:  CREATE INDEX test_id2 ON public.test_character_type USING btree (varchar_10)
reindex index test_id2;

-- index name: test_id3 | table name: test_character_type | collate: 100 | collname: default | indexdef:  CREATE INDEX test_id3 ON public.test_character_type USING btree (txt)
reindex index test_id3;

-- index name: test_citext_pkey | table name: test_citext | collate: 100 | collname: default | indexdef:  CREATE UNIQUE INDEX test_citext_pkey ON public.test_citext USING btree (nick)
reindex index test_citext_pkey;

-- index name: test_idx_citext | table name: test_citext | collate: 100 | collname: default | indexdef:  CREATE INDEX test_idx_citext ON public.test_citext USING btree (nick)
reindex index test_idx_citext;

-- index name: hash_idx1 | table name: hash_test1 | collate: 100 | collname: default | indexdef:  CREATE INDEX hash_idx1 ON public.hash_test1 USING btree (content)
reindex index hash_idx1;

-- index name: idx_projecttag | table name: gitrefresh | collate: 100 | collname: default | indexdef:  CREATE UNIQUE INDEX idx_projecttag ON public.gitrefresh USING btree (projecttag)
reindex index idx_projecttag;

[gpadmin@cdw ~]$ python upgrade_check.py postfix --input index.out
2023-10-12 03:39:19,838 - INFO - db: testupgrade, total have 7 commands to execute
2023-10-12 03:39:19,845 - INFO - db: testupgrade, executing command: reindex index test_id1;
2023-10-12 03:39:19,872 - INFO - Current worker 0: have 6 remaining, 0.0271010398865 seconds passed.
2023-10-12 03:39:19,908 - INFO - db: testupgrade, executing command: reindex index test_id2;
2023-10-12 03:39:19,926 - INFO - Current worker 1: have 5 remaining, 0.0178480148315 seconds passed.
2023-10-12 03:39:19,940 - INFO - db: testupgrade, executing command: reindex index test_id3;
2023-10-12 03:39:19,958 - INFO - Current worker 2: have 4 remaining, 0.0179879665375 seconds passed.
2023-10-12 03:39:19,971 - INFO - db: testupgrade, executing command: reindex index test_citext_pkey;
2023-10-12 03:39:19,995 - INFO - Current worker 3: have 3 remaining, 0.0233221054077 seconds passed.
2023-10-12 03:39:20,003 - INFO - db: testupgrade, executing command: reindex index test_idx_citext;
2023-10-12 03:39:20,023 - INFO - Current worker 4: have 2 remaining, 0.0196900367737 seconds passed.
2023-10-12 03:39:20,035 - INFO - db: testupgrade, executing command: reindex index hash_idx1;
2023-10-12 03:39:20,054 - INFO - Current worker 5: have 1 remaining, 0.0189678668976 seconds passed.
2023-10-12 03:39:20,067 - INFO - db: testupgrade, executing command: reindex index idx_projecttag;
2023-10-12 03:39:20,085 - INFO - Current worker 6: have 0 remaining, 0.0178339481354 seconds passed.
2023-10-12 03:39:20,093 - INFO - db: postgres, total have 2 commands to execute
2023-10-12 03:39:20,098 - INFO - db: postgres, executing command: reindex index pg_seclabel_object_index;
2023-10-12 03:39:20,128 - INFO - Current worker 0: have 1 remaining, 0.0295078754425 seconds passed.
2023-10-12 03:39:20,162 - INFO - db: postgres, executing command: reindex index pg_shseclabel_object_index;
2023-10-12 03:39:20,186 - INFO - Current worker 1: have 0 remaining, 0.0234160423279 seconds passed.
2023-10-12 03:39:20,239 - INFO - All done

[gpadmin@cdw ~]$ python upgrade_check.py precheck-table --out table.out
2023-10-12 03:35:19,605 - INFO - There are 0 partitioned tables in database template1 that might be affected due to upgrade.
2023-10-12 03:35:19,668 - INFO - There are 0 partitioned tables in database postgres that might be affected due to upgrade.
2023-10-12 03:35:19,726 - INFO - There are 5 partitioned tables in database testupgrade that might be affected due to upgrade.
2023-10-12 03:35:19,752 - INFO - start checking table partition_range_test_1 ...
2023-10-12 03:35:19,802 - INFO - check table partition_range_test_1 OK.
2023-10-12 03:35:19,802 - INFO - start checking table partition_range_test_3 ...
2023-10-12 03:35:20,205 - INFO - check table partition_range_test_3 error out: ERROR:  no partition for partitioning key  (seg1 10.0.138.67:20001 pid=3888)

2023-10-12 03:35:20,205 - WARNING - no default partition for partition_range_test_3
2023-10-12 03:35:20,237 - INFO - start checking table root ...
2023-10-12 03:35:20,256 - INFO - check table root OK.
2023-10-12 03:35:20,256 - INFO - start checking table partition_range_test_ao ...
2023-10-12 03:35:20,470 - INFO - check table partition_range_test_ao error out: ERROR:  no partition for partitioning key  (seg1 10.0.138.67:20001 pid=3888)

2023-10-12 03:35:20,470 - WARNING - no default partition for partition_range_test_ao
2023-10-12 03:35:20,489 - INFO - start checking table partition_range_test_2 ...
2023-10-12 03:35:20,672 - INFO - check table partition_range_test_2 error out: ERROR:  no partition for partitioning key  (seg1 10.0.138.67:20001 pid=3888)

2023-10-12 03:35:20,672 - WARNING - no default partition for partition_range_test_2
total table size (in GBytes) : 0.000183284282684
total partition tables       : 3
total leaf partitions        : 9

[gpadmin@cdw ~]$ cat table.out
-- order table by size in descending order
-- DB name:  testupgrade
-- partition table, 3 leafs, size 98304
-- name: partition_range_test_3 | coll: 100 | attname: date
begin; create temp table partition_range_test_3_bak as select * from partition_range_test_3; truncate partition_range_test_3; insert into partition_range_test_3 select * from partition_range_test_3_bak; commit;

-- partition table, 3 leafs, size 98304
-- name: partition_range_test_2 | coll: 100 | attname: date
begin; create temp table partition_range_test_2_bak as select * from partition_range_test_2; truncate partition_range_test_2; insert into partition_range_test_2 select * from partition_range_test_2_bak; commit;

-- partition table, 3 leafs, size 192
-- name: partition_range_test_ao | coll: 100 | attname: date
begin; create temp table partition_range_test_ao_bak as select * from partition_range_test_ao; truncate partition_range_test_ao; insert into partition_range_test_ao select * from partition_range_test_ao_bak; commit;

[gpadmin@cdw ~]$ python upgrade_check.py postfix --input table.out
2023-10-12 03:37:05,869 - INFO - db: testupgrade, total have 3 commands to execute
2023-10-12 03:37:05,875 - INFO - db: testupgrade, executing command: begin; create temp table partition_range_test_3_bak as select * from partition_range_test_3; truncate partition_range_test_3; insert into partition_range_test_3 select * from partition_range_test_3_bak; commit;
2023-10-12 03:37:06,231 - ERROR - ERROR:  no partition for partitioning key  (seg1 10.0.138.67:20001 pid=3900)

2023-10-12 03:37:06,240 - INFO - db: testupgrade, executing command: begin; create temp table partition_range_test_2_bak as select * from partition_range_test_2; truncate partition_range_test_2; insert into partition_range_test_2 select * from partition_range_test_2_bak; commit;
2023-10-12 03:37:06,526 - ERROR - ERROR:  no partition for partitioning key  (seg1 10.0.138.67:20001 pid=3908)

2023-10-12 03:37:06,554 - INFO - db: testupgrade, executing command: begin; create temp table partition_range_test_ao_bak as select * from partition_range_test_ao; truncate partition_range_test_ao; insert into partition_range_test_ao select * from partition_range_test_ao_bak; commit;
2023-10-12 03:37:06,883 - ERROR - ERROR:  no partition for partitioning key  (seg1 10.0.138.67:20001 pid=3917)

2023-10-12 03:37:06,972 - INFO - All done
```