1. use `python upgrade_check.py precheck-index` to list affected indexes.
2. use `pythonn upgrade_check.py precheck-table` to list affected partitioned tables.
3. use `python upgrade_check.py run` to run the re-index and alter partition table commands.

```
$ python upgrade_check.py --help
usage: upgrade_check [-h] [--host HOST] [--port PORT] [--dbname DBNAME]
                     [--user USER]
                     {precheck-index,precheck-table,run} ...

positional arguments:
  {precheck-index,precheck-table,run}
                        sub-command help
    precheck-index      list affected index
    precheck-table      list affected tables
    run                 run the re-index and the alter partition table cmds

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
  --out OUT   outfile path for the alter index commands

$ python upgrade_check.py precheck-table -h
usage: upgrade_check precheck-table [-h] [--order_size_ascend] --out OUT

optional arguments:
  -h, --help           show this help message and exit
  --order_size_ascend  sort the tables by size in ascending order
  --out OUT            outfile path for the alter partition table commands

$ python upgrade_check.py run -h
usage: upgrade_check run [-h] --input INPUT [--nproc NPROC]

optional arguments:
  -h, --help     show this help message and exit
  --input INPUT  the file contains reindex or alter partition table commands
  --nproc NPROC  the concurrent proces to run the commands
```

Example usages:
```
[gpadmin@cdw ~]$  python upgrade_check.py precheck-index --out index.out
2023-09-11 10:31:31,592 - INFO - There are 2 catalog indexes that might be affected due to upgrade.
2023-09-11 10:31:31,648 - INFO - There are 0 user indexes in database template1 that might be affected due to upgrade.
2023-09-11 10:31:31,679 - INFO - There are 0 user indexes in database postgres that might be affected due to upgrade.
2023-09-11 10:31:31,833 - INFO - There are 7 user indexes in database testupgrade that might be affected due to upgrade.

[gpadmin@cdw ~]$  python upgrade_check.py run --input index.out
2023-09-11 10:31:59,877 - INFO - db: testupgrade, total have 7 commands to execute
2023-09-11 10:31:59,883 - INFO - db: testupgrade, executing command: reindex index test_id1;
2023-09-11 10:32:00,005 - INFO - Current worker 0: have 6 remaining, 0.122126817703 seconds passed.
2023-09-11 10:32:00,047 - INFO - db: testupgrade, executing command: reindex index test_id2;
2023-09-11 10:32:00,072 - INFO - Current worker 1: have 5 remaining, 0.0251789093018 seconds passed.
2023-09-11 10:32:00,079 - INFO - db: testupgrade, executing command: reindex index test_id3;
2023-09-11 10:32:00,104 - INFO - Current worker 2: have 4 remaining, 0.0253138542175 seconds passed.
2023-09-11 10:32:00,111 - INFO - db: testupgrade, executing command: reindex index test_citext_pkey;
2023-09-11 10:32:00,151 - INFO - Current worker 3: have 3 remaining, 0.0398077964783 seconds passed.
2023-09-11 10:32:00,175 - INFO - db: testupgrade, executing command: reindex index test_idx_citext;
2023-09-11 10:32:00,202 - INFO - Current worker 4: have 2 remaining, 0.0275771617889 seconds passed.
2023-09-11 10:32:00,238 - INFO - db: testupgrade, executing command: reindex index hash_idx1;
2023-09-11 10:32:00,270 - INFO - Current worker 5: have 1 remaining, 0.0314960479736 seconds passed.
2023-09-11 10:32:00,302 - INFO - db: testupgrade, executing command: reindex index idx_projecttag;
2023-09-11 10:32:00,328 - INFO - Current worker 6: have 0 remaining, 0.0259289741516 seconds passed.
2023-09-11 10:32:00,329 - INFO - db: postgres, total have 2 commands to execute
2023-09-11 10:32:00,334 - INFO - db: postgres, executing command: reindex index pg_seclabel_object_index;
2023-09-11 10:32:00,380 - INFO - Current worker 0: have 1 remaining, 0.0461161136627 seconds passed.
2023-09-11 10:32:00,398 - INFO - db: postgres, executing command: reindex index pg_shseclabel_object_index;
2023-09-11 10:32:00,432 - INFO - Current worker 1: have 0 remaining, 0.0340991020203 seconds passed.
2023-09-11 10:32:00,479 - INFO - All done

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