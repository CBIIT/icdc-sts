# Simple Terminology Server (STS) (icdc-sts)

## Description

The STS is intended to provide a simple RESTful way to validate data
values against enumerated value domains.

The STS backend is a repository of value domains. That is, the _set_
of terms that comprise a value domain is treated as an addressable
unit, with its own identifier.

The STS is model aware. Validation queries can address the value
domain of a property defined in the [model description files](https://github.com/CBIIT/icdc-model-tool/tree/master/model-desc).

## Endpoints

The STS endpoints have three components: \<domain\>, \<action\> and \<query\>

    https://localhost:3000/<domain>/<action>?<query>

* Domain

The \<domain\> can either be the STS domain identifier, can reference
the domain name, or it can reference the model _property_ (as defined
in the [MDF](https://github.com/CBIIT/icdc-model-tool/tree/master/model-desc) whose value domain is required:

    https://localhost:3000/67/<...>
    https://localhost:3000/domain/Gynecologic Tumor Grouping Cervical Endometrial FIGO 2009 Stage/<...>
    https://localhost:3000/property/figo_stage/<...>

If the domain is provided with no following action, STS will return
the domain description in JSON format with status 200. If the domain
does not exist, STS responds with status 400 (Bad Request).

* Action and Query

    * Validate

            https://localhost:3000/domain/ICD-O Primary Disease Diagnosis Type/validate?q=Acute lymphocytic leukemia

If the term in the query field exists in the domain, STS returns the
term record in JSON format with status 200.  If the term does not
exist, STS returns status 404 (Not Found). If the domain does not
exist, STS returns 400 (Bad Request).

   * Search

            https://localhost:3000/property/primary_site/search?q=%Breast%

The query field is a search string. STS returns matching term records
as an array in JSON format with status 200.

   * List

            https://localhost:3000/property/adverse_event/list

No query field present. STS returns all term records contained in the
referenced domain as an array in JSON format with status 200, or
status 400 (Bad Request) if domain does not exist.


## Backend Domain Structure

Each value domain is a set of records that possess a single identifier. These records have the following form:

     { "term" : <a term>,
       "term_id" : <a unique id for the term>,
       "concept_code" : <a concept code for the term in the domain context, from the code_authority>,
       "code_authority" : {
         "authority_name": <resource from which code was obtained>,
         "authority_uri": <link to authority>,
         "code_uri": <link to code at authority>
         }
         "domain" : <domain_structure>
    }

Note that the full information on a term must include its domain
context. This is because the string representing the term may be used
in multiple contexts, and have a different meaning in each
context. For example, "Stage I" may appear in a number of domains,
each referring to a different disease staging system.

A value domain itself has the following structure:

    { "domain" :
      { "domain_name": <an optional human-readable name>,
          "domain_id": <a unique id for the domain>,
          "domain_code": <a code for the domain as such from the domain_authority>,
          "domain_authority" : {
             "authority_name": <the name or id of any external authority that has compiled this domain>,
             "authority_uri": <link to authority>,
             "domain_uri": <link to code at authority>
           }
      "terms" : [
        <term>,
        <term>,
        ... ]
    }

This structure may be implemented in any database. Maintenance of this database (adding domains, adding terms to domains, changing term and domain properties, updating database representations of external value domains) is a separate set of technical tasks and processes.

The identifiers for terms and domains are unique within the system. They should have a standardized format, and be recognizable to humans as a STS identifier.

## Concept Codes

Concept codes are not required to run the prototype. They are,
however, critical for semantic purposes. For example, multiple disease
staging systems exist for describing cancer progression. Almost all of
them use the term "Stage I", therefore it is critical that the
appropriate concept code travel with the amibiguous term "Stage I", so
that the meaning of the term in the correct domain context is
understood by the data consumer. In the prototype,

for:

    https://localhost:3000/property/figo_stage/validate?q=Stage I

the `concept_code` returned is
[C96244](https://ncit.nci.nih.gov/ncitbrowser/ConceptReport.jsp?dictionary=NCI_Thesaurus&ns=ncit&code=C96244).

and for 

    https://localhost:3000/property/ajcc_clinical_stage/validate?q=Stage I

the `concept_code` is [C27966](https://ncit.nci.nih.gov/ncitbrowser/ConceptReport.jsp?dictionary=NCI_Thesaurus&ns=ncit&code=C27966)
   
If either concept or domain codes are present in a record, the corresponding authority property must also be present.

The code authority should generally be the [NCI Thesaurus](https://ncit.nci.nih.gov), and concept codes should be valid codes from that resource.

The domain authority should indicate a resource that has compiled the standard set of values for the given domain, if the domain is externally defined. Examples: caDSR, ICD-11, AJCCv8.

