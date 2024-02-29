/*
 * Copyright (c) 2013 EMC Corporation All Rights Reserved
 *
 * This software is protected, without limitation, by copyright law
 * and international treaties. Use of this software and the intellectual
 * property contained therein is expressly limited to the terms and
 * conditions of the License Agreement under which it is provided by
 * or on behalf of EMC.
 *
 * ---------------------------------------------------------------------
 *
 * Interface to functions related to checking the correct distribution in GPDB.
 *
 * This is used to expose these functions in a dynamically linked library
 * so that they can be referenced by using CREATE FUNCTION command in SQL,
 * like below:
 *
 *CREATE OR REPLACE FUNCTION gp_partition_range_heap_table_check(oid)
 * RETURNS bool
 * AS '$libdir/gp_partition_range_check.so','gp_partition_range_heap_table_check'
 * LANGUAGE C VOLATILE STRICT; *
 */

#include "postgres.h"

#include "fmgr.h"
#include "funcapi.h"
#include "utils/builtins.h"
#include "utils/snapmgr.h"
#include "cdb/cdbhash.h"
#include "cdb/cdbvars.h"
#include "utils/lsyscache.h"
#include "miscadmin.h"
#include "catalog/indexing.h"
#include "utils/array.h"
#include "utils/tqual.h"
#include "cdb/cdbpartition.h"
#include "utils/fmgroids.h"
#include "utils/syscache.h"


#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

extern Datum gp_partition_range_heap_table_check(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(gp_partition_range_heap_table_check);

/* 
 * Verifies the partition range bound
 */
Datum
gp_partition_range_heap_table_check(PG_FUNCTION_ARGS)
{
	Oid			relOid = PG_GETARG_OID(0);
	Oid			opclassId = PG_GETARG_OID(1);
	Oid         attypeOid = PG_GETARG_OID(2);
	Oid         collOid = PG_GETARG_OID(3);

	bool		result = true;
	ScanKeyData scankey;

	bool		isnull;

	/* Open gp_partition_rule */
	Relation partrulerel = heap_open(PartitionRuleRelationId, AccessShareLock);

	ScanKeyInit(&scankey, Anum_pg_partition_rule_parchildrelid,
			BTEqualStrategyNumber, F_OIDEQ,
			ObjectIdGetDatum(relOid));

	SysScanDesc sscan = systable_beginscan(partrulerel, PartitionRuleParchildrelidIndexId, true,
							NULL, 1, &scankey);

	HeapTuple tuple = systable_getnext(sscan);

	while (HeapTupleIsValid(tuple))
	{
		CHECK_FOR_INTERRUPTS();

		/* get rangeStart by using 
		 *  select pg_get_expr(pr1.parrangestart, pr1.parchildrelid) AS partitionrangestart from pg_partition_rule pr1;
		*/

		Form_pg_partition_rule partitionRule = (Form_pg_partition_rule) GETSTRUCT(tuple);
		
		Datum parrangestart = SysCacheGetAttr(PARTRULEOID, tuple,Anum_pg_partition_rule_parrangestart,&isnull);
		Datum parrangeend = SysCacheGetAttr(PARTRULEOID, tuple,Anum_pg_partition_rule_parrangeend,&isnull);
		Datum expr1 = DirectFunctionCall2(pg_get_expr, parrangestart,
										ObjectIdGetDatum(relOid));

		Datum expr2 = DirectFunctionCall2(pg_get_expr, parrangeend,
										ObjectIdGetDatum(relOid));

		//elog(WARNING, "parrangestart is %s", TextDatumGetCString(expr1));
		//elog(WARNING, "parrangeend is %s", TextDatumGetCString(expr2));

		bool parrangestartincl = partitionRule->parrangestartincl;
		bool parrangeendincl = partitionRule->parrangeendincl;
		//bool parrangeendincl = SysCacheGetAttr(PARTRULEOID, tuple,Anum_pg_partition_rule_parrangeendincl,&isnull);

		elog(WARNING, "parrangestartincl is %x", parrangestartincl);
		elog(WARNING, "parrangeendincl is %x", parrangeendincl);

		int strat = BTLessStrategyNumber;

		Oid opfamily = get_opclass_family(opclassId);
		Oid cmp_op = get_opfamily_member(opfamily,
								attypeOid,
								attypeOid,
								strat);
		RegProcedure cmp_proc = get_opcode(cmp_op);

		if (RegProcedureIsValid(cmp_proc))
		{
			elog(WARNING, "cmp_proc is %d and collOid is %d and expr1 is %ld and expr2 is %ld",cmp_proc, collOid, expr1, expr2);
			result = DatumGetBool(OidFunctionCall2Coll(cmp_proc,
														collOid,
														expr1,
														expr2));
		}

		elog(WARNING, "result is %d", result);
		if(!result)
		{
			break;
		}
		tuple = systable_getnext(sscan);
	}

	systable_endscan(sscan);
	heap_close(partrulerel, AccessShareLock);
	
	PG_RETURN_BOOL(result);
}

