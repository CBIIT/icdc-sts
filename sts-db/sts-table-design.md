# STS Table Design

Outline of RDBMS tables necessary for an STS prototype, based on [the spec](../README.md).

## Authority table

`authority` enumerates the terminology authorities needed for terms and domains.

|| column | desc ||
| id | standardized authority id | text, non-null, unique (PK) |
| name | authority human-readable name | text, non-null |
| uri | authority url/uri | text, null |

## Domain table

`domain` records the domain metadata

| column | desc | attrs |
| ------ | ---- | ---- |
| id | standardized domain id | text, non-null, unique (PK) |
| name | domain human-readable name | text, non-null |
| authority | FK to `authority` | fk(authority.id), null |

## Term table

`term` records the dictionary of terms that domains may incorporate

|| column | desc | attrs ||
| id | standardized term id | text, non-null, unique (PK) |
| term | the term as string | text, non-null |
| concept\_code | external concept code mapped to this term | text, null |
| authority | FK to `authority` - the source of the concept code | fk(authority.id), null |

## Term-Domain table

`term_domain` associates terms with domains. The domain contents are specified in this table.

| column | desc | attr |
| ------ | ---- | ---- |
| domain\_id | domain id | fk(domain.id), non-null |
| term\_id | term id | fk(term.id), non-null |

## Property-domain table

`prop_domain` allows lookup of domain by property name.

| column | desc | attr |
| ------ | ---- | ---- |
| property | MDF property | text, non-null | "
| domain_id | domain id | fk(domain.id), non-null |

# STS DB queries

* All terms in a given domain, by domain name

        select d.name as domain, term.*
          from inner join term t, term_domain td, domain d
                   on t.id=td.term and d.id=td.domain
          where d.name = :domain_name:


* Whether given term is present in given domain

        select d.name as domain, term.*
        from inner join term t, term_domain td, domain d
        on t.id=td.term and d.id=td.domain
        where t.name = :term_name: and d.name = :domain_name:

* All terms

        select t.name from term t;

* All domain names

        select d.name from domain d;

* Search terms in a given domain (LIKE pattern)

        select d.name as domain, term.*
        from inner join term t, term_domain td, domain d
        on t.id=td.term and d.id=td.domain
        where d.name = :domain_name: and
        t.name like :term_search:

