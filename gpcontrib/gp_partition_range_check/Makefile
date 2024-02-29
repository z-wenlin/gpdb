MODULE_big = gp_partition_range_check

EXTENSION = gp_partition_range_check
DATA = gp_partition_range_check--1.0.sql

OBJS       = gp_partition_range_check.o
PG_CPPFLAGS = -I$(libpq_srcdir)

REGRESS = gp_partition_range_check

ifdef USE_PGXS
PGXS := $(shell pg_config --pgxs)
include $(PGXS)
else
subdir = contrib/gp_partition_range_check
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif

