/* contrib/gp_partition_range_check/gp_partition_range_check--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION gp_partition_range_check" to load this file. \quit

SET search_path = public;

-- This function validates the partition range bound
CREATE OR REPLACE FUNCTION gp_partition_range_heap_table_check(relid regclass, parclass Oid, atttype Oid, collOid Oid) RETURNS boolean
AS '$libdir/gp_partition_range_check','gp_partition_range_heap_table_check'
LANGUAGE C IMMUTABLE STRICT;

