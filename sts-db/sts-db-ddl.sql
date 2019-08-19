create table authority (
  id integer primary key,
  name text unique not null,
  uri text 
);

create table domain (
  id integer primary key,
  name text unique not null,
  domain_code text,
  authority integer,
  foreign key(authority) references authority(id) 
);

create table term (
  id integer primary key,
  term text unique not null
);

create table term_domain (
  id integer primary key,
  term integer not null,
  domain integer not null,
  concept_code text,
  concept_authority integer,
  foreign key(concept_authority) references authority(id),
  foreign key(term) references term(id),
  foreign key(domain) references domain(id)
);

create table prop_domain (
  id integer primary key,
  property text not null,
  domain integer,
  foreign key(domain) references domain(id)
);
  
1192	5	8	C17998	2
1202	5	9	C17998	2
1209	5	10	C17998	2
1352	5	11	C17998	2
1357	5	12	C17998	2
1361	5	13	C17998	2
1384	5	14	C17998	2
1388	5	15	C17998	2
1393	5	16	C17998	2
1403	5	17	C17998	2
1496	5	18	C17998	2
1500	5	19	C17998	2
1504	5	20	C17998	2
1508	5	21	C17998	2
1523	5	23	C17998	2
1531	5	24		
1543	5	25	C17998	2
1548	5	26		
1556	5	27	C17998	2
1616	5	28	C17998	2
1905	5	29	C17998	2
1931	5	30	C17998	2
1940	5	32	C17998	2
1964	5	34	C17998	2
1968	5	35	C17998	2
2002	5	39	C17998	2
3129	5	40	C17998	2
3161	5	41	C17998	2
3194	5	42	C17998	2
3198	5	43	C17998	2
3207	5	45	C17998	2
3240	5	47	C17998	2
3245	5	48	C17998	2
3249	5	49	C17998	2
3254	5	50	C17998	2
3269	5	52	C17998	2
3280	5	53	C17998	2
3289	5	54	C17998	2
3295	5	55	C17998	2
3300	5	56	C17998	2
3304	5	57	C17998	2
3317	5	58	C17998	2
3353	5	59	C17998	2
3385	5	61	C17998	2
3390	5	62	C17998	2
3416	5	63	C17998	2
3421	5	64	C17998	2
3426	5	65	C17998	2
3432	5	66	C17998	2
3437	5	67	C17998	2
3443	5	68	C17998	2
3447	5	69	C17998	2
3453	5	70	C17998	2
3459	5	71	C17998	2
3465	5	72	C17998	2
3471	5	73	C17998	2
3484	5	74	C17998	2
3490	5	75	C17998	2
3496	5	76	C17998	2
3500	5	77	C17998	2
3504	5	78	C17998	2
3540	5	79	C17998	2
3546	5	80	C17998	2
3552	5	81	C17998	2
3557	5	82	C17998	2
3561	5	83	C17998	2
3569	5	84	C17998	2
3574	5	85	C17998	2
3578	5	86	C17998	2
3584	5	87	C17998	2
3591	5	88	C17998	2
3595	5	31	C17998	2
3602	5	90	C17998	2
3609	5	91	C17998	2
3616	5	92	C17998	2
3948	5	93	C17998	2
3958	5	94	C17998	2
6539	5	95	C17998	2
6599	5	98	C17998	2
6603	5	99	C17998	2
6608	5	100	C17998	2
6940	5	93	C17998	2
6944	5	102	C17998	2
6949	5	24		
6956	5	104	C17998	2
6982	5	105	C17998	2
6988	5	106		
6992	5	107	C17998	2
7028	5	108	C17998	2
7035	5	109	C17998	2
7066	5	111	C17998	2
7072	5	112	C17998	2
7076	5	113	C17998	2
7082	5	114	C17998	2
7089	5	115	C17998	2
7104	5	117	C17998	2
7112	5	118	C17998	2
7176	5	120	C17998	2
7225	5	121	C17998	2
7301	5	123	C17998	2
7328	5	109	C17998	2
7405	5	125		
7411	5	126	C17998	2
7415	5	127	C17998	2
7423	5	128	C17998	2
7430	5	129	C17998	2
7435	5	130		
7720	5	131	C17998	2
7753	5	132	C17998	2
7803	5	133	C17998	2
8512	5	134	C17998	2
8537	5	135	C17998	2
8545	5	136	C17998	2
8565	5	137	C17998	2
8588	5	138		
8642	5	140	C17998	2
9348	5	141	C17998	2
9360	5	143	C17998	2
9366	5	144	C17998	2
9370	5	145		
9397	5	146	C17998	2
9401	5	147	C17998	2
9442	5	148		
9472	5	149	C17998	2
9479	5	150	C17998	2
9493	5	151	C17998	2
9501	5	152	C17998	2
9506	5	153		
9509	5	154		
9544	5	155		
9569	5	157	C17998	2
9572	5	157	C17998	2
9575	5	159	C17998	2
9581	5	160		
9584	5	161		
9588	5	162	C17998	2
9595	5	163	C17998	2
9720	5	166	C17998	2
9771	5	167	C17998	2
sqlite> .exit
.exit

Process SQL exited abnormally with code 1

SQLite version 3.24.0 2018-06-04 14:10:15
Enter ".help" for usage hints.
sqlite> select count(*) from term;
select count(*) from term;
7298
sqlite> select count(*) from domain;
select count(*) from domain;
159
sqlite> select count(*) from term_domain;
select count(*) from term_domain;
9788
sqlite> .exit
.exit

Process SQL finished

SQLite version 3.24.0 2018-06-04 14:10:15
Enter ".help" for usage hints.
sqlite> .tables
.tables
authority    domain       gdcncit      prop_domain  term         term_domain
sqlite> .schema gdcncit
.schema gdcncit
CREATE TABLE gdcncit (
 category text,
 node text,
 property text,
 gdc_value text,
 nci_pv text,
 ncit_code text,
 icdo3_code text,
 icdo3_strings,
 term_type text,
 cde_pv_meaning text,
 cde_pv_meaning_concept_codes text,
 cde_id text);
