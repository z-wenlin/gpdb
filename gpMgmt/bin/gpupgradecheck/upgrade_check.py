#!-*- coding: utf-8 -*-
import argparse
import sys
from pygresql.pg import DB
import logging
import signal
from multiprocessing import Process, Pool
import time
import string
from collections import defaultdict
import os
import re
try:
    from pygresql import pg
except ImportError, e:
    sys.exit('ERROR: Cannot import modules.  Please check that you have sourced greenplum_path.sh.  Detail: ' + str(e))

total_leafs = 0
total_roots = 0
total_root_size = 0

dbkeywords = "-- DB name: "

class connection(object):
    def __init__(self, host, port, dbname, user):
        self.host = host
        self.port = port
        self.dbname = dbname
        self.user = user
    
    def _get_pg_port(self, port):
        if port is not None:
            return port
        try:
            port = os.environ.get('PGPORT')
            if not port:
                port = self.get_port_from_conf()
            return int(port)
        except:
            sys.exit("No port been set, please set env PGPORT or MASTER_DATA_DIRECTORY or specify the port in the command line")

    def get_port_from_conf(self):
        datadir = os.environ.get('MASTER_DATA_DIRECTORY')
        if datadir:
            file = datadir +'/postgresql.conf'
            if os.path.isfile(file):
                with open(file) as f:
                    for line in f.xreadlines():
                        match = re.search('port=\d+',line)
                        if match:
                            match1 = re.search('\d+', match.group())
                            if match1:
                                return match1.group()

    def get_default_db_conn(self):
        db = DB(dbname=self.dbname,
                host=self.host,
                port=self._get_pg_port(self.port), 
                user=self.user)
        return db
    
    def get_db_conn(self, dbname):
        db = DB(dbname=dbname,
                host=self.host,
                port=self._get_pg_port(self.port),
                user=self.user)
        return db
    
    def get_db_list(self):
        db = self.get_default_db_conn()
        sql = "select datname from pg_database where datname not in ('template0');"      
        dbs = [datname for datname, in db.query(sql).getresult()]
        db.close
        return dbs

class CheckIndexes(connection):
    def get_affected_user_indexes(self, dbname):
        db = self.get_db_conn(dbname)
        # The built-in collatable data types are text,varchar,and char, and the indcollation contains the OID of the collation 
        # to use for the index, or zero if the column is not of a collatable data type.
        sql = """
        SELECT indexrelid::regclass::text, indrelid::regclass::text, coll, collname, pg_get_indexdef(indexrelid)
FROM (SELECT indexrelid, indrelid, indcollation[i] coll FROM pg_index, generate_subscripts(indcollation, 1) g(i)) s
JOIN pg_collation c ON coll=c.oid
WHERE collname != 'C' and collname != 'POSIX' and indexrelid >= 16384;
        """
        index = db.query(sql).getresult()
        logger.info("There are {} user indexes in database {} that might be affected due to upgrade.".format(len(index), dbname))
        db.close()
        return index

    def get_affected_catalog_indexes(self):
        db = self.get_default_db_conn()
        sql = """
        SELECT indexrelid::regclass::text, indrelid::regclass::text, coll, collname, pg_get_indexdef(indexrelid)
FROM (SELECT indexrelid, indrelid, indcollation[i] coll FROM pg_index, generate_subscripts(indcollation, 1) g(i)) s
JOIN pg_collation c ON coll=c.oid
WHERE collname != 'C' and collname != 'POSIX' and indexrelid < 16384;
        """
        index = db.query(sql).getresult()
        logger.info("There are {} catalog indexes that might be affected due to upgrade.".format(len(index)))
        db.close()
        return index

    def handle_one_index(self, name):
        # no need to handle special charactor here, because the name will include the double quotes if it has special charactors.
        sql = """
        reindex index {};
        """.format(name)
        return sql.strip()

    def dump_index_info(self, fn):
        dblist = self.get_db_list()
        f = open(fn, "w")

        # print all catalog indexes that might be affected.
        cindex = self.get_affected_catalog_indexes()
        if cindex:
            print>>f, dbkeywords, self.dbname
        for indexname, tablename, collate, collname, indexdef in cindex:
            print>>f, "-- catalog index name:", indexname, "| table name:", tablename, "| collate:", collate, "| collname:", collname, "| indexdef: ", indexdef
            print>>f, self.handle_one_index(indexname)
            print>>f

        # print all user indexes in all databases that might be affected.
        for dbname in dblist:
            index = self.get_affected_user_indexes(dbname)
            if index:
                print>>f, dbkeywords, dbname
            for indexname, tablename, collate, collname, indexdef in index:
                print>>f, "-- index name:", indexname, "| table name:", tablename, "| collate:", collate, "| collname:", collname, "| indexdef: ", indexdef
                print>>f, self.handle_one_index(indexname)
                print>>f

        f.close()

class CheckTables(connection):
    def __init__(self, host, port, dbname, user, order_size_ascend):
        self.host = host
        self.port = port
        self.dbname = dbname
        self.user = user
        self.order_size_ascend = order_size_ascend

    def get_affected_partitioned_tables(self, dbname):
        db = self.get_db_conn(dbname)
        # The built-in collatable data types are text,varchar,and char, and the defined collation of the column, or zero if the column is not of a collatable data type
        # filter the partition by list, because only partiton by range might be affected.
        sql = """
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
        parisdefault
        FROM 
        might_affected_tables group by (prelid, coll, parisdefault)
        )
        select prelid::regclass::text as partitionname, coll, bool_or(parisdefault) as parhasdefault from par_has_default group by (prelid, coll) ;
        """
        tabs = db.query(sql).getresult()
        logger.info("There are {} partitioned tables in database {} that might be affected due to upgrade.".format(len(tabs), dbname))
        db.close()
        return tabs
    
    # Escape double-quotes in a string, so that the resulting string is suitable for
    # embedding as in SQL. Analogouous to libpq's PQescapeIdentifier
    def escape_identifier(self, str):
        # Does the string need quoting? Simple strings with all-lower case ASCII
        # letters don't.
        SAFE_RE = re.compile('[a-z][a-z0-9_]*$')

        if SAFE_RE.match(str):
            return str

        # Otherwise we have to quote it. Any double-quotes in the string need to be escaped
        # by doubling them.
        return '"' + str.replace('"', '""') + '"'

    def handle_one_table(self, name):
        bakname = "%s" % (self.escape_identifier(name + "_bak"))
        sql = """
begin; create temp table {1} as select * from {0}; truncate {0}; insert into {0} select * from {1}; commit;
        """.format(name, bakname)
        return sql.strip()

    def dump_table_info(self, db, name):
        name = "%s" % (pg.escape_string(name))
        sql_size = """
        with recursive cte(nlevel, table_oid) as (
            select 0, '{name}'::regclass::oid
            union all
            select nlevel+1, pi.inhrelid
            from cte, pg_inherits pi
            where cte.table_oid = pi.inhparent
        )
        select sum(pg_relation_size(table_oid))
        from cte where nlevel = (select max(nlevel) from cte);
        """
        r = db.query(sql_size.encode('utf-8').format(name=name))
        size = r.getresult()[0][0]
        sql_nleafs = """
        with recursive cte(nlevel, table_oid) as (
            select 0, '{name}'::regclass::oid
            union all
            select nlevel+1, pi.inhrelid
            from cte, pg_inherits pi
            where cte.table_oid = pi.inhparent
        )
        select count(1)
        from cte where nlevel = (select max(nlevel) from cte);
        """
        r = db.query(sql_nleafs.encode('utf-8').format(name=name))
        nleafs = r.getresult()[0][0]
        global total_leafs
        global total_roots
        global total_root_size
        total_root_size += size
        total_leafs += nleafs
        total_roots += 1
        return "partition table, %s leafs, size %s" % (nleafs, size), size

    def dump(self, fn):
        dblist = self.get_db_list()
        f = open(fn, "w")
        print>>f, "-- order table by size in %s order " % 'ascending' if self.order_size_ascend else '-- order table by size in descending order'

        for dbname in dblist:
            db = self.get_db_conn(dbname)

            table_info = []

            # partitioned tables
            parts = self.get_affected_partitioned_tables(dbname)
            if parts:
                print>>f, dbkeywords, dbname
            
            for name, coll, has_default_partition in parts:
                if has_default_partition == 'f':
                    logger.warning("no default partition for {}".format(name))
                msg, size = self.dump_table_info(db, name)
                table_info.append((name, coll, size, msg))

            if self.order_size_ascend:
                table_info.sort(key=lambda x: x[2], reverse=False)
            else:
                table_info.sort(key=lambda x: x[2], reverse=True)

            for name, coll, size, msg in table_info:   
                print>>f, "--", msg
                print>>f, "-- name:", name, "| coll:", coll
                print>>f, self.handle_one_table(name)
                print>>f

        f.close()

class ConcurrentRun(connection): 
    def __init__(self, dbname, port, host, user, script_file, nproc):
        self.dbname = dbname
        self.port = self._get_pg_port(port)
        self.host = host
        self.user = user
        self.script_file = script_file
        self.nproc = nproc
        self.dbdict = defaultdict(list)

        self.parse_inputfile()

    def parse_inputfile(self):
        with open(self.script_file) as f:
            for line in f:
                sql = line.strip()
                if sql.startswith(dbkeywords):
                    db_name = sql.split(dbkeywords)[1].strip()
                if (sql.startswith("reindex") and sql.endswith(";") and sql.count(";") == 1):
                    self.dbdict[db_name].append(sql)
                if (sql.startswith("begin;") and sql.endswith("commit;")):
                    self.dbdict[db_name].append(sql)

    def init_worker(self):
        signal.signal(signal.SIGINT, signal.SIG_IGN)

    def run(self):
        pool = Pool(self.nproc, self.init_worker)
        try:
            for db_name, commands in self.dbdict.items():
                total_counts = len(commands)
                logger.info("db: {}, total have {} commands to execute".format(db_name, total_counts))
                for index, command in enumerate(commands):
                    pool.apply_async(run_alter_command, (db_name, self.port, self.host, self.user,
                                                            command, index, total_counts)).get(1)
            # close the process pool
            pool.close()
            # wait a moment
            pool.join()
        except KeyboardInterrupt:
            print("Caught KeyboardInterrupt, terminating workers")
            pool.terminate()
            pool.join()
            sys.exit('\nUser Interrupted')

        logger.info("All done")

# since pickle for Python 2.7 could not pickle instance, just use function to apply.
def run_alter_command(db_name, port, host, user, command, current_idx, total_commands):
    try:
        db = DB(dbname=db_name, port=port, host=host, user=user)
        start = time.time()
        logger.info("db: {}, executing command: {}".format(db_name, command))
        db.query(command)

        if (command.startswith("begin")):
            pieces = [p for p in re.split("( |\\\".*?\\\"|'.*?')", command) if p.strip()]
            index = pieces.index("truncate")
            if 0 < index < len(pieces) - 1:
                table_name = pieces[index+1]
                analyze_sql = "analyze {};".format(table_name)
                logger.info("db: {}, executing analyze command: {}".format(db_name, analyze_sql))
                db.query(analyze_sql)

        elif (command.startswith("reindex")):
            c = command.strip().split()
            if len(c) > 2:
                table_name = c[2]

        end = time.time()
        total_time = end - start
        logger.info("Current worker {}: have {} remaining, {} seconds passed.".format(current_idx, total_commands - current_idx - 1, total_time))
        db.close()
    except Exception, e:
        logger.error("{}".format(str(e)))

def parseargs():
    parser = argparse.ArgumentParser(prog='upgrade_check')
    parser.add_argument('--host', type=str, help='Greenplum Database hostname')
    parser.add_argument('--port', type=int, help='Greenplum Database port')
    parser.add_argument('--dbname', type=str,  default='postgres', help='Greenplum Database database name')
    parser.add_argument('--user', type=str, help='Greenplum Database user name')

    subparsers = parser.add_subparsers(help='sub-command help', dest='cmd')
    parser_precheck_index = subparsers.add_parser('precheck-index', help='list affected index')
    parser_precheck_table = subparsers.add_parser('precheck-table', help='list affected tables')
    parser_precheck_table.add_argument('--order_size_ascend', action='store_true', help='sort the tables by size in ascending order')
    parser_precheck_table.set_defaults(order_size_ascend=False)
    parser_precheck_index.add_argument('--out', type=str, help='outfile path for the alter index commands', required=True)
    parser_precheck_table.add_argument('--out', type=str, help='outfile path for the alter partition table commands', required=True)

    parser_run = subparsers.add_parser('run', help='run the re-index and the alter partition table cmds')
    parser_run.add_argument('--input', type=str, help='the file contains reindex or alter partition table commands', required=True)
    parser_run.add_argument('--nproc', type=int, default=1, help='the concurrent proces to run the commands')

    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = parseargs()
    # initialize logger
    logging.basicConfig(level=logging.DEBUG, stream=sys.stdout, format="%(asctime)s - %(levelname)s - %(message)s")
    logger = logging.getLogger()

    if args.cmd == 'precheck-index':
        ci = CheckIndexes(args.host, args.port, args.dbname, args.user)
        ci.dump_index_info(args.out)
    elif args.cmd == 'precheck-table':
        ct = CheckTables(args.host, args.port, args.dbname, args.user, args.order_size_ascend)
        ct.dump(args.out)
        print "total table size (in GBytes) : %s" % (float(total_root_size) / 1024.0**3)
        print "total partition tables       : %s" % total_roots
        print "total leaf partitions        : %s" % total_leafs
    elif args.cmd == 'run':
        cr = ConcurrentRun(args.dbname, args.port, args.host, args.user, args.input, args.nproc)
        cr.run()
    else:
        sys.stderr.write("unknown subcommand!")
        sys.exit(127)
