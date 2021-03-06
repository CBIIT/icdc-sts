package sts::queries;
use base Exporter;
use strict;
our @EXPORT;

@EXPORT=qw/%stmts/;

our %stmts = (
  validate => <<Q,
    SELECT domain
    	  ,domain_id
	  ,term
	  ,term_id
	  ,concept_code
	  ,au.name as term_authority
	  ,au.uri as term_authority_uri
    FROM
       ( SELECT d.name as domain
       	       ,d.id as domain_id
	       ,t.term as term
               ,t.id as term_id
	       ,cc.concept_code as concept_code
	       ,cc.concept_authority as authority 
	 FROM
    	      ( SELECT td.domain as d_id
	              ,td.term as t_id
		      ,td.concept_code as concept_code
		      ,td.concept_authority as concept_authority
    		FROM term_domain td
    		WHERE td.domain = ? 
		AND td.term = 
		 	( SELECT t.id as term_id 
			  FROM term t 
			  WHERE t.term = ? )
              ) cc
    	 INNER JOIN term t
    	 ON t.id = cc.t_id
    	 INNER JOIN domain d
	 ON d.id = cc.d_id
       ) cctd
    INNER JOIN authority as au
    ON cctd.authority = au.id
Q
  list => <<Q,
  select t.term as term, t.id as term_id, td.concept_code as concept_code,
      au.name as term_authority, au.uri as term_authority_uri
      from term t 
      inner join domain d
      on t.id=td.term
      inner join term_domain td
      on td.domain=d.id
      left join authority au
      on td.concept_authority = au.id
      where d.id = ?
Q
  search_terms => <<Q,
  select t.term as term, t.id as term_id, td.concept_code as concept_code,
      au.name as term_authority, au.uri as term_authority_uri
      from term t 
      inner join domain d
      on t.id=td.term
      inner join term_domain td
      on td.domain=d.id
      left join authority au
      on td.concept_authority = au.id
      where d.id = ? and
            t.term like ?
Q
  domain_info_by_id => <<Q,
  select d.name as domain_name,d.id as domain_id, domain_code,
    au.name as domain_authority, au.uri as domain_authority_uri
    from domain d 
    left join authority au
    on d.authority = au.id
    where d.id = ?
Q
  domain_info_by_name => <<Q,
  select d.name as domain_name,d.id as domain_id, domain_code,
    au.name as domain_authority, au.uri as domain_authority_uri
    from domain d 
    left join authority au
    on d.authority = au.id
    where d.name = ?
Q
  domain_id_by_prop => <<Q,
  select domain, property
  from prop_domain
  where property = ?
Q
  domain_list => <<Q,
  select d.id as domain_id, pd.property as property, 
    d.name as domain_name
  from domain d inner join prop_domain pd
  on d.id = pd.domain
Q
);

1;
