package sts::CypherQueries;
use base Exporter;
use strict;
our @EXPORT;

@EXPORT=qw/%queries/;

our %queries = (

	#// query 2 get domains
	get_valuesets =>
	'MATCH (v:value_set) return DISTINCT v.id as id, v.url as url',

	get_nodes => <<Q,
	     MATCH (n:node) 
	     RETURN DISTINCT n.handle, n.model
Q

	#// query 3 get properties
	get_properties => <<Q,
	     MATCH (p:property {value_domain:"enum"}) -[:has_value_set]-> (v:value_set) 
	     RETURN DISTINCT p.handle, p.value_domain, p.model, v.id, v.url
Q
    	#// get the version of the database, used in healthcheck that we can query the database
    	#// but does not require that the database have any data
    	get_database_version => <<Q,
        call dbms.components() 
	yield name, versions, edition unwind versions as version 
	return name, version, edition;
Q

	#// node - list
	nodes_list => <<Q,
	MATCH (n:node)
	RETURN DISTINCT n.handle, n.model;
Q

	#// node - detail
	nodes_detail => <<Q,
	MATCH (n1:node)
	OPTIONAL MATCH (n1)<-[:has_src]-(r12:relationship)-[:has_dst]->(n2:node)
	OPTIONAL MATCH (n3)<-[:has_src]-(r31:relationship)-[:has_dst]->(n1:node)
	OPTIONAL MATCH (n1)-[:has_property]->(p1:property)
	OPTIONAL MATCH (n1)-[:has_concept]->(c1:concept)
	OPTIONAL MATCH (ct:term)-[:represents]->(c1)
	OPTIONAL MATCH (ct)-[:has_origin]->(o:origin)
	RETURN DISTINCT n1.handle, 
			n1.model, 
			r12.handle, 
			n2.handle, 
			r31.handle, 
			n3.handle, 
			p1.handle, 
			ct.value, 
			ct.origin_id, 
			ct.origin_definition, 
			o.name;
Q
	
	#// property - list
	properties_list => <<Q,
	MATCH (p:property) 
	RETURN DISTINCT p.handle as `property-handle`, p.value_domain, p.model, p.is_required ;
Q
	
	#// property - detail
	properties_list => <<Q,
	MATCH (p:property)
	OPTIONAL MATCH (p)-[:has_value_set]->(vs)
	OPTIONAL MATCH (p)-[:has_concept]->(cp:concept)
	OPTIONAL MATCH (cpt:term)-[:represents]->(cp)
	OPTIONAL MATCH (ct)-[:has_origin]->(cto:origin)
	OPTIONAL MATCH (r:relationship)-[:has_property]->(p)
	OPTIONAL MATCH (n:node)-[:has_property]->(p)
	RETURN DISTINCT p.handle as `property-handle`, 
			p.model as `property-model`, 
			p.value_domain as `property-value_domain`, 
			p.is_required ,  
			vs.id as `property-value_set-id`, 
			vs.url as `property-value_set-url`,
			cp.id as `property-concept-id`, 
			cpt.value as `property-concept-term-value`, 
			cpt.id as `property-concept-term-id`, 
			cpt.origin_definition  as `property-concept-term-origin_definition`, 
			cpt.origin_id  as `property-concept-term-origin_id`,
			n.handle as `node-handle`, 
			r.handle as `relationship-handle`;
Q

	#// value_set - list
	value_sets_list => <<Q,
	MATCH (vs:value_set)
	OPTIONAL MATCH (p:property)-[:has_value_set]->(vs)
	RETURN DISTINCT p.handle as `property-handle`, vs.id as `id`, vs.url as `url`
Q

	#// value_set - detail
	value_sets_detail => <<Q,
	MATCH (vs:value_set)
	OPTIONAL MATCH (p:property)-[:has_value_set]->(vs)
	OPTIONAL MATCH (p)-[:has_concept]->(cp:concept)
	OPTIONAL MATCH (ct:term)-[:represents]->(cp)
	OPTIONAL MATCH (vs)-[:has_term]->(t:term)
	OPTIONAL MATCH (ct)-[:has_origin]->(cto:origin)
	OPTIONAL MATCH (vs)-[:has_origin]->(vso:origin)
	RETURN DISTINCT p.handle as `property-handle`, 
			p.model as `property-model`,
			vs.id as `value_set-id`, 
			vs.url as `value_set-url`, 
			t.id as `term-id`, 
			t.value as `term-value`;
Q

	#// concept - list
	concepts_list => <<Q,
	MATCH (c:concept)
	MATCH (ct:term)-[:represents]->(c)
	RETURN DISTINCT c.id as `concept-id`, 
			ct.value as `concept-term-value`; 
Q

	#// concept - detail
	concepts_detail => <<Q,
	MATCH (c:concept)
	MATCH (ct:term)-[:represents]->(c)
	OPTIONAL MATCH (ct)-[:has_origin]->(cto:origin)
	OPTIONAL MATCH (n:node)-[:has_concept]->(c)
	OPTIONAL MATCH (p:property)-[:has_concept]->(c)
	OPTIONAL MATCH (r:relationship)-[:has_concept]->(c)
	RETURN DISTINCT c.id as `concept-id`, 
			ct.value as `concept-term-value`, 
			ct.id as `concept-term-id`, 
			ct.origin_id as `concept-term-origin_id`, 
			ct.origin_definition as `concept-term-origin-definition`, 
			cto.name as `concept-term-origin-name`, 
			n.handle, 
			p.handle, 
			r.handle;
Q

);

1;
