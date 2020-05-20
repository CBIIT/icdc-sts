package sts::CypherQueries;
use base Exporter;
#use strict;
our @EXPORT;

@EXPORT = qw/%queries/;

our %queries = (

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

    get_database_node_count => <<Q,
        MATCH (n)
        RETURN count(n) as count
Q


    #// node - list
    get_list_of_nodes => <<Q,
	    MATCH (n:node)
    	RETURN DISTINCT n.id, n.handle, n.model;
Q

    get_all_node_details => <<'Q',
	    MATCH (n1:node)				
    	OPTIONAL MATCH (n1)<-[:has_src]-(r12:relationship)-[:has_dst]->(n2:node)
	    OPTIONAL MATCH (n3)<-[:has_src]-(r31:relationship)-[:has_dst]->(n1:node)
    	OPTIONAL MATCH (n1)-[:has_property]->(p1:property)
    	OPTIONAL MATCH (n1)-[:has_concept]->(c1:concept)
    	OPTIONAL MATCH (ct:term)-[:represents]->(c1)
    	OPTIONAL MATCH (ct)-[:has_origin]->(o:origin)
    	RETURN DISTINCT n1.id as `node-id`,
						n1.handle as `node-handle`, 
            			n1.model as `node-model`, 
            			r12.handle as `to-relationship`,
						n2.id as `to-node`, 
            			n2.handle, 
						n2.model,
            			r31.handle,
						n3.id, 
            			n3.handle,
						n3.model, 
            			p1.id,
						p1.handle,
						p1.value_domain,
						p1.model,
						c1.id, 
            			ct.id,
						ct.value, 
            			ct.origin_id, 
            			ct.origin_definition, 
						ct.comments, 
            			ct.notes,
            			o.name;
Q

    #// node - detail
	#// idea: n3 -> n1 --> n2
    get_node_details => <<'Q',
	    MATCH (n1:node)				
		WHERE n1.id = $param
    	OPTIONAL MATCH (n1)<-[:has_src]-(r12:relationship)-[:has_dst]->(n2:node)
	    OPTIONAL MATCH (n3)<-[:has_src]-(r31:relationship)-[:has_dst]->(n1:node)
    	OPTIONAL MATCH (n1)-[:has_property]->(p1:property)
    	OPTIONAL MATCH (n1)-[:has_concept]->(c1:concept)
    	OPTIONAL MATCH (ct:term)-[:represents]->(c1)
    	OPTIONAL MATCH (ct)-[:has_origin]->(o:origin)
    	RETURN DISTINCT n1.id as `node-id`,
						n1.handle as `node-handle`, 
            			n1.model as `node-model`, 
            			r12.handle as `to-relationship`,
						n2.id as `to-node`, 
            			n2.handle, 
						n2.model,
            			r31.handle,
						n3.id, 
            			n3.handle,
						n3.model, 
            			p1.id,
						p1.handle,
						p1.value_domain,
						p1.model,
						c1.id, 
            			ct.id,
						ct.value, 
            			ct.origin_id, 
            			ct.origin_definition, 
						ct.comments, 
            			ct.notes,
            			o.name;
Q

    #// property - list
    get_properties_list => <<Q,
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
    get_value_sets_list => <<'Q',
    	MATCH (vs:value_set)
    	MATCH (p:property)-[:has_value_set]->(vs)
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

    #// value_set - detail
    get_value_set_detail => <<'Q',
    	MATCH (vs:value_set)
    	MATCH (p:property)-[:has_value_set]->(vs)
        WHERE vs.id = $param
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


    #// term - list
    get_terms_list => <<Q,
        MATCH (vs:value_set) -[:has_term]->(t:term)
        OPTIONAL MATCH (t)-[:represents]->(cp:concept)
        OPTIONAL MATCH (t)-[:has_origin]->(to:origin)
        RETURN DISTINCT t.value as `term-value`, 
                        t.id as `term-id`,  
                        to.name as `origin`;
Q

    #// term - detail
    get_term_detail => <<'Q',
        MATCH (vs:value_set)-[:has_term]->(t:term)
        WHERE t.value = $param 
        OPTIONAL MATCH (t)-[:represents]->(cp:concept)
        OPTIONAL MATCH (t)-[:has_origin]->(to:origin)
        RETURN DISTINCT t.value as `term-value`, 
                        t.id as `term-id`, 
                        to.name as `origin-name`,
                        cp.id as `concept-id`,
                        vs.url as `value_set-url`, 
                        vs.id as `value_set-id`;
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
