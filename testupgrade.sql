--
-- Greenplum Database database dump
--

-- Dumped from database version 12.12
-- Dumped by pg_dump version 12.12

SET gp_default_storage_options = '';
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: gp_toolkit; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS gp_toolkit WITH SCHEMA public;


--
-- Name: EXTENSION gp_toolkit; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION gp_toolkit IS 'various GPDB administrative views/functions';


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: gitrefresh; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.gitrefresh (
    projecttag text,
    state character(1),
    analysis_started timestamp without time zone,
    analysis_ended timestamp without time zone,
    counter_requested integer,
    customer_id integer,
    id integer
) DISTRIBUTED BY (projecttag);


ALTER TABLE public.gitrefresh OWNER TO gpadmin;

--
-- Name: hash_test; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.hash_test (
    id integer,
    date text
) DISTRIBUTED BY (date);


ALTER TABLE public.hash_test OWNER TO gpadmin;

--
-- Name: partition_range_test; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.partition_range_test (
    id integer,
    date text
)
PARTITION BY RANGE (date) DISTRIBUTED BY (id);


ALTER TABLE public.partition_range_test OWNER TO gpadmin;

--
-- Name: partition_range_test_1_prt_feb; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.partition_range_test_1_prt_feb (
    id integer,
    date text
) DISTRIBUTED BY (id);


ALTER TABLE public.partition_range_test_1_prt_feb OWNER TO gpadmin;

--
-- Name: partition_range_test_1_prt_jan; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.partition_range_test_1_prt_jan (
    id integer,
    date text
) DISTRIBUTED BY (id);


ALTER TABLE public.partition_range_test_1_prt_jan OWNER TO gpadmin;

--
-- Name: partition_range_test_1_prt_mar; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.partition_range_test_1_prt_mar (
    id integer,
    date text
) DISTRIBUTED BY (id);


ALTER TABLE public.partition_range_test_1_prt_mar OWNER TO gpadmin;

SET default_table_access_method = ao_row;

--
-- Name: partition_range_test_ao; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.partition_range_test_ao (
    id integer,
    date text
)
PARTITION BY RANGE (date) DISTRIBUTED BY (id);


ALTER TABLE public.partition_range_test_ao OWNER TO gpadmin;

--
-- Name: partition_range_test_ao_1_prt_feb; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.partition_range_test_ao_1_prt_feb (
    id integer,
    date text
)
WITH (blocksize='32768', compresslevel='0', compresstype='none', checksum='true') DISTRIBUTED BY (id);


ALTER TABLE public.partition_range_test_ao_1_prt_feb OWNER TO gpadmin;

--
-- Name: partition_range_test_ao_1_prt_jan; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.partition_range_test_ao_1_prt_jan (
    id integer,
    date text
)
WITH (blocksize='32768', compresslevel='0', compresstype='none', checksum='true') DISTRIBUTED BY (id);


ALTER TABLE public.partition_range_test_ao_1_prt_jan OWNER TO gpadmin;

--
-- Name: partition_range_test_ao_1_prt_mar; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.partition_range_test_ao_1_prt_mar (
    id integer,
    date text
)
WITH (blocksize='32768', compresslevel='0', compresstype='none', checksum='true') DISTRIBUTED BY (id);


ALTER TABLE public.partition_range_test_ao_1_prt_mar OWNER TO gpadmin;

SET default_table_access_method = heap;

--
-- Name: repository; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.repository (
    id integer,
    slug character varying(100),
    name character varying(100),
    project_id character varying(100)
) DISTRIBUTED BY (slug, project_id);


ALTER TABLE public.repository OWNER TO gpadmin;

--
-- Name: root; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.root (
    id integer,
    date text
)
PARTITION BY RANGE (date) DISTRIBUTED BY (id);


ALTER TABLE public.root OWNER TO gpadmin;

--
-- Name: root_1_prt_feb; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.root_1_prt_feb (
    id integer,
    date text
) DISTRIBUTED BY (id);


ALTER TABLE public.root_1_prt_feb OWNER TO gpadmin;

--
-- Name: root_1_prt_jan; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.root_1_prt_jan (
    id integer,
    date text
) DISTRIBUTED BY (id);


ALTER TABLE public.root_1_prt_jan OWNER TO gpadmin;

--
-- Name: root_1_prt_mar; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.root_1_prt_mar (
    id integer,
    date text
) DISTRIBUTED BY (id);


ALTER TABLE public.root_1_prt_mar OWNER TO gpadmin;

--
-- Name: test; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.test (
    id integer,
    query text
) DISTRIBUTED BY (query);


ALTER TABLE public.test OWNER TO gpadmin;

--
-- Name: test1; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.test1 (
    content character varying
) DISTRIBUTED BY (content);


ALTER TABLE public.test1 OWNER TO gpadmin;

--
-- Name: test2; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.test2 (
    id integer,
    date text
)
PARTITION BY RANGE (date) DISTRIBUTED BY (id);


ALTER TABLE public.test2 OWNER TO gpadmin;

--
-- Name: test2_1_prt_1; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.test2_1_prt_1 (
    id integer,
    date text
) DISTRIBUTED BY (id);


ALTER TABLE public.test2_1_prt_1 OWNER TO gpadmin;

--
-- Name: test_character_type; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.test_character_type (
    char_1 character(1),
    varchar_10 character varying(10),
    txt text
) DISTRIBUTED BY (char_1);


ALTER TABLE public.test_character_type OWNER TO gpadmin;

--
-- Name: users; Type: TABLE; Schema: public; Owner: gpadmin
--

CREATE TABLE public.users (
    nick public.citext NOT NULL,
    pass text NOT NULL
) DISTRIBUTED BY (nick);


ALTER TABLE public.users OWNER TO gpadmin;

--
-- Name: partition_range_test_1_prt_feb; Type: TABLE ATTACH; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.partition_range_test ATTACH PARTITION public.partition_range_test_1_prt_feb FOR VALUES FROM ('02') TO ('03');


--
-- Name: partition_range_test_1_prt_jan; Type: TABLE ATTACH; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.partition_range_test ATTACH PARTITION public.partition_range_test_1_prt_jan FOR VALUES FROM ('01') TO ('02');


--
-- Name: partition_range_test_1_prt_mar; Type: TABLE ATTACH; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.partition_range_test ATTACH PARTITION public.partition_range_test_1_prt_mar FOR VALUES FROM ('03') TO ('04');


--
-- Name: partition_range_test_ao_1_prt_feb; Type: TABLE ATTACH; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.partition_range_test_ao ATTACH PARTITION public.partition_range_test_ao_1_prt_feb FOR VALUES FROM ('02') TO ('03');


--
-- Name: partition_range_test_ao_1_prt_jan; Type: TABLE ATTACH; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.partition_range_test_ao ATTACH PARTITION public.partition_range_test_ao_1_prt_jan FOR VALUES FROM ('01') TO ('02');


--
-- Name: partition_range_test_ao_1_prt_mar; Type: TABLE ATTACH; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.partition_range_test_ao ATTACH PARTITION public.partition_range_test_ao_1_prt_mar FOR VALUES FROM ('03') TO ('04');


--
-- Name: root_1_prt_feb; Type: TABLE ATTACH; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.root ATTACH PARTITION public.root_1_prt_feb FOR VALUES FROM ('02') TO ('03');


--
-- Name: root_1_prt_jan; Type: TABLE ATTACH; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.root ATTACH PARTITION public.root_1_prt_jan FOR VALUES FROM ('01') TO ('02');


--
-- Name: root_1_prt_mar; Type: TABLE ATTACH; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.root ATTACH PARTITION public.root_1_prt_mar FOR VALUES FROM ('03') TO ('04');


--
-- Name: test2_1_prt_1; Type: TABLE ATTACH; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.test2 ATTACH PARTITION public.test2_1_prt_1 FOR VALUES FROM ('01-01') TO ('11-01');


--
-- Data for Name: gitrefresh; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.gitrefresh (projecttag, state, analysis_started, analysis_ended, counter_requested, customer_id, id) FROM stdin;
npm@randombytes	Q	2023-08-01 17:22:43.615924	\N	1	0	\N
\.


--
-- Data for Name: hash_test; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.hash_test (id, date) FROM stdin;
1	01
1	"01"
2	"02"
3	02
4	03
\.


--
-- Data for Name: partition_range_test_1_prt_feb; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.partition_range_test_1_prt_feb (id, date) FROM stdin;
2	02
2	"02"
\.


--
-- Data for Name: partition_range_test_1_prt_jan; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.partition_range_test_1_prt_jan (id, date) FROM stdin;
1	01
1	"01"
\.


--
-- Data for Name: partition_range_test_1_prt_mar; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.partition_range_test_1_prt_mar (id, date) FROM stdin;
3	03
3	"03"
\.


--
-- Data for Name: partition_range_test_ao_1_prt_feb; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.partition_range_test_ao_1_prt_feb (id, date) FROM stdin;
2	"02-1"
2	"02"
2	02
\.


--
-- Data for Name: partition_range_test_ao_1_prt_jan; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.partition_range_test_ao_1_prt_jan (id, date) FROM stdin;
1	01
1	"01"
1	"01-1"
\.


--
-- Data for Name: partition_range_test_ao_1_prt_mar; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.partition_range_test_ao_1_prt_mar (id, date) FROM stdin;
\.


--
-- Data for Name: repository; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.repository (id, slug, name, project_id) FROM stdin;
793	text-rnn	text-rnn	146
812	ink_data	ink_data	146
\.


--
-- Data for Name: root_1_prt_feb; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.root_1_prt_feb (id, date) FROM stdin;
\.


--
-- Data for Name: root_1_prt_jan; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.root_1_prt_jan (id, date) FROM stdin;
\.


--
-- Data for Name: root_1_prt_mar; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.root_1_prt_mar (id, date) FROM stdin;
3	03
3	"03"
\.


--
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.test (id, query) FROM stdin;
\.


--
-- Data for Name: test1; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.test1 (content) FROM stdin;
a$
$a
a
$b
b
b$
B
$B
A
$A
B$
A$
\.


--
-- Data for Name: test2_1_prt_1; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.test2_1_prt_1 (id, date) FROM stdin;
2	02-1
1	1-1
2	03-1
1	11
2	09-01
2	08-1
\.


--
-- Data for Name: test_character_type; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.test_character_type (char_1, varchar_10, txt) FROM stdin;
\N	\N	TEXT column can store a string of any length
\N	HelloWorld	\N
Y	\N	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.users (nick, pass) FROM stdin;
Tom	\\xa0393a3eb52ffb4dfefef7bb09aca7836cb39c6f063544373620379760f771db
larry	\\x4da6de9cb0466f63f5467417343be178388c8120880308c061b847c624565e48
NEAL	\\xd644aa0eb648f1c9a84ac562c66de985494f707db4e52802d39d985d2b17e1ac
Damian	\\xa522aba0c4ad9d7cc8c09eaa91dd800bf89915089d33509e6c63fb36d52519fd
Bjørn	\\x5e26758e5072f3f89fd2b3f59900a011bdb536fac8f1c6dae7e3ff556b14f282
\.


--
-- Name: gitrefresh idx_projecttag; Type: CONSTRAINT; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.gitrefresh
    ADD CONSTRAINT idx_projecttag UNIQUE (projecttag);


--
-- Name: repository uk_slug_project_id; Type: CONSTRAINT; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.repository
    ADD CONSTRAINT uk_slug_project_id UNIQUE (slug, project_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (nick);


--
-- Name: pk_gitrefresh; Type: INDEX; Schema: public; Owner: gpadmin
--

CREATE INDEX pk_gitrefresh ON public.gitrefresh USING btree (id);


--
-- Name: test1_idx; Type: INDEX; Schema: public; Owner: gpadmin
--

CREATE INDEX test1_idx ON public.test1 USING btree (content);


--
-- Name: test_id1; Type: INDEX; Schema: public; Owner: gpadmin
--

CREATE INDEX test_id1 ON public.test_character_type USING btree (char_1);


--
-- Name: test_id2; Type: INDEX; Schema: public; Owner: gpadmin
--

CREATE INDEX test_id2 ON public.test_character_type USING btree (varchar_10);


--
-- Name: test_id3; Type: INDEX; Schema: public; Owner: gpadmin
--

CREATE INDEX test_id3 ON public.test_character_type USING btree (txt);


--
-- Name: test_id4; Type: INDEX; Schema: public; Owner: gpadmin
--

CREATE INDEX test_id4 ON public.users USING btree (nick);


--
-- Greenplum Database database dump complete
--

