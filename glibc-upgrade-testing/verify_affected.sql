-- Use this SQL query in each database to find out which indexes are affected --
SELECT indrelid::regclass::text, indexrelid::regclass::text, collname, pg_get_indexdef(indexrelid)
FROM (SELECT indexrelid, indrelid, indcollation[i] coll FROM pg_index, generate_subscripts(indcollation, 1) g(i)) s
         JOIN pg_collation c ON coll=c.oid
WHERE collprovider IN ('d', 'c') AND collname NOT IN ('C', 'POSIX');

-- Use this SQL query in each database to find out which partition table are affected --
SELECT partrelid::regclass::text
FROM (SELECT partrelid, partcollation[i] coll FROM pg_partitioned_table, generate_subscripts(partcollation, 1) g(i)) s
         JOIN pg_collation c ON coll=c.oid
WHERE collprovider IN ('d', 'c') AND collname NOT IN ('C', 'POSIX');
