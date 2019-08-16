create table authority (
  id integer primary key,
  name text not null,
  uri text 
);

create table domain (
  id integer primary key,
  name text not null,
  domain_code text,
  authority integer,
  foreign key (authority) references authority (id) 
);

create table term (
  id integer primary key,
  term text not null,
);

create table term_domain (
  id integer primary key,
  term integer not null,
  domain integer not null,
  concept_code text,
  concept_authority integer,
  foreign key (authority) references authority (id)
  foreign key (term) references term (id)
  foreign key (domain) references domain (id)
);

create table prop_domain (
  id integer primary key,
  property text not null,
  domain integer,
  foreign key (domain) references domain (id)
);
  
