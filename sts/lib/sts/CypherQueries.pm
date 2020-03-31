package sts::CypherQueries;
use base Exporter;
use strict;
our @EXPORT;

@EXPORT=qw/%stmts/;

our %queries = (

	#// query 2 get domains
	get_domains =>
	'MATCH (v:value_set) return DISTINCT v.id as id, v.url as url'
	,

	#// query 3 get properties
	get_properties => 
	'MATCH (p:property {value_domain:"enum"}) -[:has_value_set]->(v:value_set) 
	 RETURN DISTINCT p.handle, p.value_domain, p.model, v.id, v.url'
	,

	);



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

  MATCH (p:property {value_domain:"enum"}) -[:has_value_set]->(v:value_set)
  WHERE p.id = ?
  RETURN DISTINCT v.id as value_set_name
  		 ,v.id as value_set_id
		 ,p.model as value_set_code
                 ,p.model as value_set_authority
                 ,p.model as value_set_authority_uri;

Q
  domain_info_by_name => <<Q,
  
  MATCH (p:property {value_domain:"enum"}) -[:has_value_set]->(v:value_set)
  WHERE p.handle = ?
  RETURN DISTINCT v.id as value_set_name
  		 ,v.id as value_set_id
		 ,p.model as value_set_code
                 ,p.model as value_set_authority
                 ,p.model as value_set_authority_uri;

Q
  domain_id_by_prop => <<Q,
  
  MATCH (p:property {value_domain:"enum"}) -[:has_value_set]->(v:value_set) 
  WHERE p.handle = ?
  RETURN DISTINCT v.id, p.handle

Q
  value_set_list => <<Q,

  MATCH (p:property {value_domain:"enum"}) -[:has_value_set]->(v:value_set)
  RETURN DISTINCT v.id as value_set_id
                 ,p.handle as property
		 ,v.id as value_set_name

Q
  list => <<Q,

  MATCH (p:property {value_domain:"enum"}) -[:has_value_set]->(v:value_set) 
  MATCH (v)-[:has_term]-> (t:term) -[:has_origin]-> (o:origin) 
  MATCH (t:term) -[:represents]-> (c:concept)
  RETURN DISTINCT t.value as term, t.id as term_id, v.id as value_set_id, o.name as term_authority, c.id as concept_id
  WHERE vs.id = ?

Q
);

1;
