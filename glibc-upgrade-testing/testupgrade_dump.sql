--
-- Greenplum Database database dump
--

SET gp_default_storage_options = '';
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: gitrefresh; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.gitrefresh (
    projecttag text,
    state character(1),
    analysis_started timestamp without time zone,
    analysis_ended timestamp without time zone,
    counter_requested integer,
    customer_id integer,
    id integer
)
 DISTRIBUTED BY (projecttag);


ALTER TABLE public.gitrefresh OWNER TO gpadmin;

--
-- Name: hash_test; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.hash_test (
    id integer,
    date text
)
 DISTRIBUTED BY (date);


ALTER TABLE public.hash_test OWNER TO gpadmin;

--
-- Name: partition_range_test; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.partition_range_test (
    id integer,
    date text
)
 DISTRIBUTED BY (id) PARTITION BY RANGE(date) 
          (
          PARTITION jan START ('01'::text) END ('02'::text) WITH (tablename='partition_range_test_1_prt_jan', appendonly='false'), 
          PARTITION feb START ('02'::text) END ('03'::text) WITH (tablename='partition_range_test_1_prt_feb', appendonly='false'), 
          PARTITION mar START ('03'::text) END ('04'::text) WITH (tablename='partition_range_test_1_prt_mar', appendonly='false')
          );
 ;


ALTER TABLE public.partition_range_test OWNER TO gpadmin;

--
-- Name: partition_range_test_ao; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.partition_range_test_ao (
    id integer,
    date text
)
WITH (appendonly='true')
 DISTRIBUTED BY (id) PARTITION BY RANGE(date) 
          (
          PARTITION jan START ('01'::text) END ('02'::text) WITH (tablename='partition_range_test_ao_1_prt_jan', appendonly='true' ), 
          PARTITION feb START ('02'::text) END ('03'::text) WITH (tablename='partition_range_test_ao_1_prt_feb', appendonly='true' ), 
          PARTITION mar START ('03'::text) END ('04'::text) WITH (tablename='partition_range_test_ao_1_prt_mar', appendonly='true' )
          );
 ;


ALTER TABLE public.partition_range_test_ao OWNER TO gpadmin;

--
-- Name: repository; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.repository (
    id integer,
    slug character varying(100),
    name character varying(100),
    project_id character varying(100)
)
 DISTRIBUTED BY (slug, project_id);


ALTER TABLE public.repository OWNER TO gpadmin;

--
-- Name: root; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.root (
    id integer,
    date text
)
 DISTRIBUTED BY (id) PARTITION BY RANGE(date) 
          (
          PARTITION jan START ('01'::text) END ('02'::text) WITH (tablename='root_1_prt_jan', appendonly='false'), 
          PARTITION feb START ('02'::text) END ('03'::text) WITH (tablename='root_1_prt_feb', appendonly='false'), 
          PARTITION mar START ('03'::text) END ('04'::text) WITH (tablename='root_1_prt_mar', appendonly='false')
          );
 ;


ALTER TABLE public.root OWNER TO gpadmin;

--
-- Name: test1; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.test1 (
    content character varying
)
 DISTRIBUTED BY (content);


ALTER TABLE public.test1 OWNER TO gpadmin;

--
-- Name: test2; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.test2 (
    id integer,
    date text
)
 DISTRIBUTED BY (id) PARTITION BY RANGE(date) 
          (
          START ('01-01'::text) END ('11-01'::text) WITH (tablename='test2_1_prt_1', appendonly='false')
          );
 ;


ALTER TABLE public.test2 OWNER TO gpadmin;

--
-- Name: test_character_type; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.test_character_type (
    char_1 character(1),
    varchar_10 character varying(10),
    txt text
)
 DISTRIBUTED BY (char_1);


ALTER TABLE public.test_character_type OWNER TO gpadmin;

--
-- Name: test_citext; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.test_citext (
    nick public.citext NOT NULL,
    pass text NOT NULL
)
 DISTRIBUTED BY (nick);


ALTER TABLE public.test_citext OWNER TO gpadmin;

--
-- Data for Name: gitrefresh; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.gitrefresh (projecttag, state, analysis_started, analysis_ended, counter_requested, customer_id, id) FROM stdin;
npm@randombytes	Q	2023-08-02 17:13:31.315884	\N	1	0	\N
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
-- Data for Name: partition_range_test; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.partition_range_test (id, date) FROM stdin;
2	"02"
1	01
2	02
1	"01"
3	03
3	"03"
\.


--
-- Data for Name: partition_range_test_ao; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.partition_range_test_ao (id, date) FROM stdin;
2	"02-1"
1	01
2	"02"
1	"01"
2	02
1	"01-1"
\.


--
-- Data for Name: repository; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.repository (id, slug, name, project_id) FROM stdin;
793	text-rnn	text-rnn	146
812	ink_data	ink_data	146
\.


--
-- Data for Name: root; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.root (id, date) FROM stdin;
3	03
3	"03"
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
A
\.


--
-- Data for Name: test2; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.test2 (id, date) FROM stdin;
2	02-1
1	11
2	03-1
1	1-1
2	08-1
2	09-01
\.


--
-- Data for Name: test_character_type; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.test_character_type (char_1, varchar_10, txt) FROM stdin;
\N	HelloWorld	\N
\N	\N	TEXT column can store a string of any length
Y	\N	\N
\.


--
-- Data for Name: test_citext; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.test_citext (nick, pass) FROM stdin;
Tom	0.725153944920748
larry	0.608437665272504
NEAL	0.56411035778001
Damian	0.292159063741565
Bjørn	0.337510227691382
\.


--
-- Name: id1; Type: INDEX; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE INDEX id1 ON public.test1 USING btree (content);


--
-- Name: idx_projecttag; Type: CONSTRAINT; Schema: public; Owner: gpadmin; Tablespace: 
--

ALTER TABLE ONLY public.gitrefresh
    ADD CONSTRAINT idx_projecttag UNIQUE (projecttag);


--
-- Name: pk_gitrefresh; Type: INDEX; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE INDEX pk_gitrefresh ON public.gitrefresh USING btree (id);


--
-- Name: test_citext_pkey; Type: CONSTRAINT; Schema: public; Owner: gpadmin; Tablespace: 
--

ALTER TABLE ONLY public.test_citext
    ADD CONSTRAINT test_citext_pkey PRIMARY KEY (nick);


--
-- Name: test_id1; Type: INDEX; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE INDEX test_id1 ON public.test_character_type USING btree (char_1);


--
-- Name: test_id2; Type: INDEX; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE INDEX test_id2 ON public.test_character_type USING btree (varchar_10);


--
-- Name: test_id3; Type: INDEX; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE INDEX test_id3 ON public.test_character_type USING btree (txt);


--
-- Name: test_idx_citext; Type: INDEX; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE INDEX test_idx_citext ON public.test_citext USING btree (nick);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: gpadmin
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM gpadmin;
GRANT ALL ON SCHEMA public TO gpadmin;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Greenplum Database database dump complete
--

