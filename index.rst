:tocdepth: 1

Introduction
============

Documentation is an integral deliverable of LSST Data Management's software development work, and is produced at all stages of development.
Before code is written, we document architecture designs, specifications, and experiments.
While code is being written, documentation describes the implementation and interfaces, and makes the software approachable through user guides and tutorials.

Documentation also underpins the usefulness of LSST software and data as a resource for the astronomical community.
All LSST Data Management software is open source and engineered with the expectation that it will find use beyond LSST's alert and data release pipelines.
For instance, astronomers exploring LSST data through the Level 3 compute environment will become direct users of LSST software.
And though it is not an explicit mission statement, we expect that future imaging surveys will adopt and build upon LSST software since the LSST pipelines are already engineered to process data from several observatories for testing purposes.
Documentation is prerequisite for any use and adoption of LSST software 
For any sustainable use of LSST software beyond LSST's internal teams.

Importance of Integrating Documentation and Code in Git
-------------------------------------------------------

Originally we authored and published documentation in a manner removed from the code itself, though Confluence wikis or PDFs archived to Docushare.
While these tools made the initial acts of content creation and publication straightforward, they provided no obvious workflow for updating and versioning documentation as part of regular development work.
As a result, documentation would often fall out of step with code.
An example manifestation of this problem is silent breakages of tutorials and user guides hosted on wikis as the code was been developed.

On the other hand, we already have an excellent workflow for developing well-tested and peer-reviewed code (see the `DM Development Workflow`_).
By treating documentation as code we realize the same workflow advantages for documentation development.
First, locating documentation in the same Git repository as the associated code removes any versioning ambiguity: documentation reflects changes in code potentially on a per-commit granularity.
Such documentation can also be continuously integrated against the associated code.
Continuous integration ensures that examples work, application programming interfaces are properly documented, and that the documentation web site itself can be built without errors.
Finally, such documentation can be reviewed as part of pull requests.
Overall, treating documentation as code can improve the overall documentation culture of a software development organization.
There is much less cognitive overhead for a developer to update documentation that lives a Git repository (even within a source code file) than there is to deal with a separate environment like a wiki.

Simply storing documentation in Git is only the first step.
Infrastructure is needed to build and deploy the documentation.
LSST Data Management has used Doxygen to extract and render documentation stored in in the Git repositories of software packages.
However, the documentation deployment implementation had several short-comings.
Documentation was only published once merged to master, hindering well-informed conversations about the documentation during code reviews.
This documentation build and deployment system was also highly specific to both the LSST Science Pipelines architecture and the build server.
This made it difficult to independently debug documentation builds.
Each LSST software project largely had to invent its own documentation deployment system, resulting in several ad-hoc approaches across the science pipelines, database, user interface and simulations teams.
Finally, limitations in Doxygen encouraged software documentation to also be hosted on Confluence wikis, leading to an entire class of issues already described.

Read the Docs and Continous Documentation Delivery
--------------------------------------------------

`Read the Docs`_ redefined expectations for how software documentation should be deployed.
Along with the Sphinx_ documentation build tool, Read the Docs has provided a common documentation infrastructure for open source software projects.
`As of 2015 <http://blog.readthedocs.com/read-the-docs-2015-stats/>`_, Read the Docs hosts documentation for 28,000 projects and served documentation to over 38 million unique visitors.

Through a `GitHub Service Hook`_, Read the Docs is notified when a Sphinx-based project has new commits.
ead the Docs then clones the Git repository, builds the Sphinx project (i.e., ``make html``) and deploys the HTML product.
Read the Docs can be configured to listen to different Git branches.
By default Read the Docs builds documentation from the ``master`` Git branch and publishes it do the ``/en/latest/`` URL path of the documentation website.
It can can publish additional branches, either for private code review or to maintain documentation for stable releases.
This branches are published to ``/en/branch-slug`` endpoints.
Though a UI element, Read the Docs allows reads to understand and switch between different versions of a software project.

Overall, the key innovation of Read the Docs is the generic automation of versioned documentation deployment that has enabled thousands of open source developers to maintain documentation with minimal overhead.

.. LSST would also use `Read the Docs`_ to deploy documentation if not for complications involved in automatically building our software stack as a prerequisite for automatically generating the API reference documentation.
.. Numpydoc_ is a Sphinx_ extension that inspects Python docstrings to generate accurate and well-organized API references.
.. To accomplish this docstring inspection, Numpydoc_ must be able to *import* the code being documented from within Python.
.. In other words, generating documentation requires that the software being documented be built and installed.
.. Naturally, `Read the Docs`_ accomplishes this by running a Python package's ``setup.py install`` command, which installs the package's dependencies, triggers builds of any C extensions, and finally installs the Python package itself.

.. Since LSST uses Scons and Eups rather than Python's standard Setuptools/Distutils (i.e., a ``setup.py`` file) in its build process, standard tools such as `Read the Docs`_ do not know how to build LSST software.
.. We are compelled, then, to build an equivalent of the `Read the Docs`_ service to build and deploy documentation for LSST's Eups and Scons-based software projects.

Beyond Read the Docs
--------------------

LSST Data Management deployed as many of 32 documentation projects on `Read the Docs`_, including the `DM Developer Guide`_, several stand-alone Python projects, and technical notes (see `SQR-000: The LSST DM Technical Note Publishing Platform`__).
This experience allowed us to be better understand our documentation deployment needs, and culminated in the design and implementation of a new documentation deployment platform, *LSST the Docs*.

.. __: http://sqr-000.lsst.io

Our experience underscored two categories of documentation deployment needs: first that we need to own the documentation build environments, and secondly that we require deeper integration and automation with respect to our development workflow.

Owning the build environment is the most important, and in fact, blocked us from publishing the LSST Science Pipelines documentation on Read the Docs.
Software documentation projects require that the software itself be built and available to the documentation build tool.
Sphinx_, and Numpydoc_ in particular, inspect the docstrings of installed code to automatically build accurate API reference documentation.
Continuous integration also requires that the software be installed to test examples and tutorials.
`Read the Docs`_ assumes that Python projects can be built with Python's standard Setuptools/Distutils (i.e., a ``setup.py`` file).
The LSST Science Pipelines build process does not follow this architecture, and instead uses EUPS_ to coordinate the versioning of tens of GitHub repositories and Scons_ to compile the software.
Simply put, the LSST Science Pipelines build process is incompatible with Read the Docs.

Another challenge was the scalability of administration for Read the Docs-hosted projects.
This challenge was particularly accurate with LSST Technotes.
Each technote was implemented as its own Read the Docs project.
To encourage the adoption of Technotes, a single DM team member was responsible for configuring a new Read the Docs project and requisite DNS configuration.
While this ensured consistent configuration, it created a bottleneck in Technote publication.
In some cases, DM team members forgot or didn't read enough of the documentation to realize they needed to ask the administrator to create their Read the Docs project.
Ideally, documentation project provisioning should be fully automated, perhaps even as a ChatOps command.

In day-to-day development work, this administration model was also a bottleneck.
For each development branch, the developer would have to ask the administrator to create a new branch build so that the documentation could be previewed in development and code review.
Often times, developers would never see their rendered documentation until it was merged, sometimes resulting in obvious formatting errors on the published ``master`` branch documentation.
Alternatively, developers would rely upon GitHub's rendering of reStructuredText file.
Developers who did this were often confused about rendering errors, not realizing that GitHub does not render the extended reStructuredText syntax available to Sphinx.
Instead, we want new versions of documentation to be published immediately and automatically for each branch.

In response to these challenges, the Science Quality and Reliability Engineering (SQuaRE) Team in LSST Data Management undertook the design and engineering of *LSST the Docs*, a platform for the continuous delivery of documentation.

This technote describes the architecture of *LSST the Docs*.
Those wishing to operate an instance of *LSST the Docs*, or produce content for a project published by *LSST the Docs*, should also refer to the documentation listed in :ref:`additional-reading`.

LSST the Docs: a microservice architecture
==========================================

In setting out to design *LSST the Docs*, we realized that the short-comings of both the original LSST Science Pipelines documentation deployment scripts and Read the Docs stemmed from their integrated architectures.
The Pipelines documentation deployment script was deeply integrated with the architecture of the LSST Science Pipelines and its build environment, making it impossible to adapt to other projects.
Read the Docs, on the other hand provided a common build and publication pipeline, yet that build environment was not flexible enough for all projects.

Instead, *LSST the Docs* is designed as a set of microservices.
Each service has a clear, well-defined responsibility along with well-defined interfaces between them.
This gives *LSST the Docs* the flexibility to host several a range of documentation projects, from simple Sphinx projects to multi-repository EUPS-based software stacks.
In fact, *LSST the Docs* is agnostic of the documentation build tool; a LaTeX document could be published as easily as a full Sphinx documentation project.
This microservice architecture also improves development efficiency since each component can be updated independently of the others.
We also take advantage of standard third-party infrastructure wherever possible.

The main components of *LSST the Docs* are `LTD Mason`_, `LTD Keeper`_, Amazon Web Services S3 and Route 53, and `Fastly`_.
:numref:`fig-ltd-arch` shows how these services operate together.

.. _fig-ltd-arch:

.. figure:: /_static/ltd_arch.svg

   Architecture of LSST the Docs (LTD) when specifically used to deploy documentation for the EUPS-based LSST Science Pipelines.
   Other projects might use other build platforms such as Travis CI, and even their own HTML compilation tools.
   LTD Mason provides the common interface for delivering built HTML to LSST the Docs.

In brief, a documentation deployment begins with `LTD Mason`_, which is intended to be run on existing on a project's existing continuous integration server, such as Jenkins or the publicly-hosted Travis CI, that is triggered by pushes to GitHub.
Not only does this strategy absolve *LSST the Docs* from maintaining build environments, it also follows our philosophy of treating documentation as code.

Mason is a standard Python package that is usually installed in a continuous integration environment like Jenkins or Travis.
Mason's primary responsibility is to upload documentation builds onto Amazon S3.
Mason is also optionally capable of driving complex multi-repository documentation build (this functionality gives Mason its name).

`LTD Keeper`_ is a RESTful web application that maintains a database of documentation projects (an arbitrary number of projects can be hosted by an *LSST the Docs* deployment).
Keeper coordinates all services, such as directing Mason uploads to S3, registering project domains on Route 53, and purging content from the `Fastly`_ cache.
Other projects, such as the `LSST DocHub`_, can use the LTD Keeper API to discover documentation projects and their published versions.

Finally, `Fastly`_ is a third-party content distribution network that serves documentation to readers.
In addition to making content delivery fast and reliable, `Fastly`_ allows LSST the Docs to serve highly intuitive URLs for versioned documentation.

The remainder of this technote will discuss each aspect of LSST the Docs in further details.

.. _ltd-mason-eups:

LTD Mason for Multi-Repository EUPS Documentation Projects
==========================================================

The role of LTD Mason in LSST the Docs is to register and upload new documentation builds from the continuous integration environment to AWS S3.
But since LSST the Docs was initially created specifically to build documentation for multi-repository EUPS, we added optional affordances to LTD Mason to build such projects.
Note that LTD Mason can also be used for non EUPS projects, see :ref:`ltd-mason-travis`.

For EUPS projects, documentation exists in two strata: in the repositories of individual EUPS packages, and in the product's doc repo.

The role of documentation embedded in packages is to document/teach the APIs and tasks that are maintained in that specific package.
Co-locating documentation in the code's Git repository ensures that documentation is versioned in step with the code itself.
The documentation for a package should also be independently buildable by a developer, locally.
Although broken cross-package links may be inevitable with local builds, such local builds are critical for the productivity of documentation writers.

The product's doc repo is a Sphinx project that produces the coherent documentation structure for a Stack product itself, such as ``lsst_apps`` or ``qserv``.
It establishes the overall table of contents that links into package documentation, and also contains its own content that applies at a Stack product level.
The product doc repo, in fact, is the lone Sphinx project seen by the Sphinx builder; content from each package is linked at compile time into the umbrella documentation repo.

The product's doc repo is not distributed by Eups to end-users, so it is not an Eups package.
Instead, Eups tags for releases are mapped to branch names in the product doc repo.

.. _eups-pkg-organization:

Package documentation organization
----------------------------------

To effect the integration of package documentation content into the umbrella documentation repo, each package must follow the following layout:

.. code-block:: text

   <package_name>/
      # ...
      doc/
         Makefile
         conf.py
         index.rst
         # ...
         _static/
            <package_name>/
               <image files>...

The role of the :file:`doc/Makefile`, :file:`doc/conf.py` and :file:`doc/index.rst` files are solely to allow local builds.

.. _eups-doc-product-organization:

Product documentation organization
----------------------------------

When ``ltd-mason`` builds documentation for an EUPS product, it links documentation resources from individual package repositories into a cloned copy of the product's documentation repository.
In Data Management's Jenkins environment, the Git repositories for each EUPS package are available on the filesystem through `lsstsw <http://developer.lsst.io/en/latest/build-ci/lsstsw.html>`.

Given the structure of individual packages described above, links are made from main product documentation repo as so:

.. code-block:: text

   <product_doc_repo>/
     Makefile
     conf.py
     index.rst
     # ...
     <package_1>/
       index.rst -> /<package_1>/doc/index.rst
       # ...
     <package_2>/
       index.rst -> /<package_2>/doc/index.rst
       # ...
     _static/
       <package_1>/ -> /<package_1>/doc/_static/<package_1>
       <package_2>/ -> /<package_2>/doc/_static/<package_2>
       # ...

Note how, in this scheme, the absolute paths to static assets in the :file:`_static/` directory is unchanged whether a packages documentation is built alone, or integrated into the EUPS product.

Once a EUPS product's documentation is linked, it is built by LTD Mason like any other Sphinx project.

The Build's YAML Manifest interface to LTD Mason
------------------------------------------------

Although ``ltd-mason`` runs on Jenkins in the Stack build environment, ``ltd-mason`` is not integrated tightly with LSST's build technologies (Eups and Scons).
This choice allows our build system to evolve independently of the Stack build environment, and can even be accommodate non-Eups based build environments.

The interface layer that bridges the software build system (``buildsstsw.sh``) to the documentation build system (``ltd-mason``) is a Manifest file, formatted as YAML.
Note that this YAML manifest is the sole input to ``ltd-mason``, besides environment variable-based configurations.

A minimal example of the manifest:

.. literalinclude:: _static/manifest.yaml
   :language: yaml

`A formal schema for this YAML manifest file <https://github.com/lsst-sqre/ltd-mason/blob/master/manifest_schema.yaml>`_ is available in the LTD Mason repository.
For reference, the fields are:

product_name
   This is the slug identifier that maps to a Product resource in ``ltd-keeper``.
   For Eups-based projects, this should correspond to the Stack meta-package name (e.g., ``lsst_apps``).

build_id
   A string uniquely identifying the Jenkins build.
   Typically this is a monotonically increasing (or time-sortable) number.

refs
   This is the set of branches or tags that a user entered upon triggering a Jenkins build of the software.
   E.g. ``[tickets/DM-XXXX, tickets/DM-YYYY]``.
   This field defines is used by ``ltd-keeper`` to map documentation Builds to Editions.

requester_github_handle
   This is an optional field that can contain the GitHub username of the person requesting the build.
   If provided, this will be used to notify the build requester through Slack.

doc_repo.url
   The Git URL of the product's documentation repository.
   For single repository software projects (or technical notes), this will be the repository of the software or technote itself.

doc_repo.ref
   This is the Git reference (commit, tag or branch) to checkout from the product's documentation repository.

packages
   This field consists of key-value objects for each package in an Eups-based multi-package software product.
   The keys correspond to the names of individual packages (and the Git repository name in the github.com/lsst organization)

   packages.<pkg_name>.dir
      Local directory where the package was installed in :file:`lsstsw/`.
   
   packages.<pkg_name>.url
      URL of the package's Git repository on GitHub

   packages.<pkg_name>.ref
      Git reference (typically a branch name) that was cloned and installed by lsstsw.

Summary of the documentation build process for EUPS-based projects
------------------------------------------------------------------

Given the input file, ``ltd-mason`` runs the following process to build an EUPS-based software product's HTML documentation:

1. Clone the product's documentation repo and checkout the appropriate Git reference (based on the YAML manifest's ``doc_repo`` key).

2. Link the `doc/` directories of each installed package (in :file:`lsstsw/install/`) to the cloned product documentation repository (see :ref:`eups-doc-product-organization`).

3. Run a Sphinx build of the complete product documentation with :command:`sphinx-build`.

The result is a built static HTML site.

.. _ltd-mason-uploads:

LTD Mason Documentation Uploads
===============================

Once documentation is compiled into a static website consisting of HTML, CSS, images, and other assets, LTD Mason uploads those resources to LSST the Doc's Amazon Web Services S3 bucket.

.. - Handshake with LTD Keeper
.. - Surrogate Key, Cache Control, ACL and content type headers 

The upload process is governed by a handshake with the LTD Keeper API server.
When a LTD Mason instance wants to upload a new documentation build it sends a `POST /products/(slug)/builds/ <https://ltd-keeper.lsst.io/products.html#post--products-(slug)-builds->`_ request.
The request body describes what Git branch this documentation corresponds to, and the request URL specifies the documentation Product maintained by LTD Keeper.
The response from LTD Keeper to this request is a Build resource that specifies where this build should be uploaded in the S3 bucket, and what surrogate key header to attach to uploaded documentation artifacts, among other metadata.

LTD Mason uses boto3_ to upload static documentation sites to S3. 
During this upload, LTD Mason gives every object a ``public-read`` Access Control List header to facilitate API access by Fastly.
``content-type`` and ``encoding-type`` headers are also set, based on :func:`mimetypes.guess_type`, to enable gzip compression on Fastly.
Finally, the ``x-amz-meta-surrogate-key`` header is set according to the Build resource returned by the LTD Keeper request.
This `surrogate key allows individual documentation builds to be purged <#>`_ from the Fastly CDN. FIXME internal link

Once the upload is complete, LTD Mason notifies LTD Keeper by sending a `PATCH request to the build resource <https://ltd-keeper.lsst.io/builds.html#patch--builds-(int-id)>`_ that changes the ``uploaded`` field from ``false`` to ``true``.


.. _ltd-mason-travis:

LTD Mason on Travis
===================

Although LTD Mason can run documentation builds for EUPS-based projects, not all projects use EUPS.
In fact, not all projects will even use Sphinx.
For such generic projects, Travis CI is a popular continuous integration environment.
LTD Mason provides an alternative command line interface, ``ltd-mason-travis`` specifically for publishing documentation from a Travis environment.
In this mode, LTD Mason can upload *any* static website to LSST the Docs, regardless of the tooling used to create that site.

The `LTD Mason documentation <https://ltd-mason.lsst.io/travis.html>`__ describes how to configure LTD Mason to publish documentation built on Travis.
The following is an realistic example Travis configuration :file:`.travis.yml` for a Python project that is also publishing documentation to LSST the Docs:

.. code-block:: yaml
   :linenos:
   :emphasize-lines: 11-14,19-23

   sudo: false
   language: python
   python:
     - '2.7'
     - '3.4'
     - '3.5'
     - '3.5-dev'
   matrix:
     allow_failures:
       - python: "3.5-dev"
     include:
       # This is the ltd-mason documentation deployment build
       - python: "3.5"
         env: LTD_MASON_BUILD=true
   install:
     - pip install -r requirements.txt
     - pip install ltd-mason
     - pip install -e .
   script:
     - py.test --flake8 --cov=ltdmason
     - sphinx-build -b html -a -n -W -d docs/_build/doctree docs docs/_build/html
   after_success:
     - ltd-mason-travis --html-dir docs/_build/html
   env:
     global:
       - LTD_MASON_BUILD=false  # disable builds in regular text matrix
       - LTD_MASON_PRODUCT="ltd-mason"
       # travis encrypt "LTD_MASON_AWS_ID=... LTD_MASON_AWS_SECRET=... LTD_KEEPER_URL=... LTD_KEEPER_USER=... LTD_KEEPER_PASSWORD=..." --add env.global 
       - secure: "CIpaoNzWwEQngjmj0/OQBRUOnkT9Rq8273N5ZgXmZTtVSliukfJMROQnp9m42x3a2XFamaYV60mmuAvMRNU8VHi4nePxF2vp7utVnp8cF4zFQQzL6KnN2rqWv0H3Snqc1sfMT2n4H9qgBlYG7w5Cv52VIXdwh8MqGSxl8HAiYgqcVNJ+q1Rxeb1Yk+Bv3VW6O0/K4AlrhGY2Gl/zbwgM4ph0K0UvT1IZg8ZjCdddOpgwxPq66kvzHNcpCR6JUnvy5vRVH+IgC83Ar+oJqOA/4pizcFccriLF7nANkVJMrRSL8B1h2IHuuGYpC2VzDPMlAuEPmU6t8QAhVCOq9BSy98902TgKkvt4enPcxS2iNqMoOJSNUW7q9yqvVacz4JApJfHWlq5K7uTy00p4XHV4TUs+9NEgBUCwEFE5CXcRQvg+Y2y1wqUUkH+12nb1Nv4CdGxG6k7yG+eM+qmANJ87jZK9vX0RmDLKXuA3gpJyVomrAKX1+MqqwD0Qu885AUsHCQevO+oDmXv6nKLK/x2ZeyHQrgWISj3LXU6B7LarLrqsrE7JWTwgo/iX6xiVHS422tj94/+rab3JarBWe+ntdG9rZBdILU92kLqzgMA570ryVxtsnu8GnzOB0/3yvdtW+duAgrrBUusBcg9E/Kz/68Cm5RbMLyjaeA6HxP6mfM4="

Several aspects of this :file:`.travis.yml` example are relevant to LSST the Docs users.
First, an extra build is added to the testing matrix where the environment variable ``LTD_MASON_BUILD`` is explicitly set to ``true``.
Since the ``ltd-mason-travis`` command is always run in the ``after_success`` phase of a Travis build, the ``LTD_MASON_BUILD`` environment variable helps ensure that only one build follows through on documentation publication.

We recommend running Sphinx in the ``script`` phase.
This allows errors in the documentation build to fail the entire build; which is likely desirable behavior.
In fact, ``sphinx-build`` is run with the ``-a -W`` flags that both turns 'warnings' into errors, and elevates missing references into errors.
Note how ``sphinx-build`` is entirely separate from ``ltd-mason-travis``; any static site builder could be used.

Finally, in the ``env.global`` section, `LTD Mason is configured through several environment variables <https://ltd-mason.lsst.io/travis.html#environment-variables-and-secrets>`_.
Travis's `encrypted environment variable feature <https://docs.travis-ci.com/user/encryption-keys/>`_ is used to to securely store credentials for AWS S3 and LTD Keeper.
The private key needed to decrypt these fields is known only to Travis and is directly associated with the GitHub repository.
In other words, forks of a repository cannot gain access, and publish to, LSST the Docs.

.. _urls:

Versioned Documentation URLs
============================

LSST the Docs is designed to host an arbitrary number of documentation projects, along with an arbitrary number of versions documentation.

LSST the Docs serves each documentation project under its own subdomain
of ``lsst.io``.
For example, ``sqr-000.lsst.io`` or ``ltd-keeper.lsst.io``.
These subdomains are memorable, and allow documentation to be referred to without need for a link shortener.
This URL model also concurs with the recent practice by Apple's Safari browser to collapse the entire URL to just the domain in the location bar.

Also note that LSST the Docs publishes specifically to ``lsst.io`` rather than ``lsst.org``.
This is because LSST the Docs requires programmatic access to a domain's DNS settings, and the ``lsst.io`` domain allows us to do that without interfering with ``lsst.org``'s operations.
Our intention is to brand ``lsst.io`` as synonymous with 'LSST Documentation.'

.. _default-url:

The default documentation edition
---------------------------------

From the root url for a documentation product, for example ``https://example.lsst.io/``, LSST the Docs serves what is considered to be the 'default' version of the documentation.
By default, this is documentation built from the ``master`` branch of a Git repository.
This choice can be changed on a per-project basis for strategic reasons.
For example, a software project may choose to serve documentation from a stable release branch at the root URL.

.. _edition-urls:

Additional editions for Git branches
------------------------------------

LSST the Docs serves separate editions of documentation for each branch of the project's parent repository.
These editions are served from a ``/v/`` path off of the root domain.
For example, a branch named ``v1`` would be served from ``https://example.lsst.io/v/v1/``.

For `ticket branches <http://developer.lsst.io/en/latest/processes/workflow.html#ticket-branches>`_ used by Data Management (e.g., ``tickets/DM-1234``), LSST the Docs transforms that branch name to create more convenient edition URLs: ``https://example.lsst.io/v/DM-1234/``.

Editions are created automatically for every new branch (they are provisioned on-demand when LTD Mason :ref:`POSTs a build <ltd-mason-uploads>` from a new Git branch).
We believe that this automation will be incredible useful for code reviews.
For any pull request is will be unambiguous where corresponding documentation can be found.
Making documentation more visible in code reviews should improve the culture of documentation within Data Management.

.. _build-urls:

Archived documentation builds
-----------------------------

LSST the Docs stores every documentation build uploaded as an immutable object that is never deleted, by default.
When a new documentation build is uploaded by LTD Mason, that build exists *alongside* the previous documentation builds rather than replacing them.
These individual builds are available from the ``/builds/`` path off the root domain. For example, the first build would be available at ``https://example.lsst.io/builds/1/``.

Having persistent build available serves two purposes.
First, it allows "A/B" comparisons of documentation during development.
During a code review, or debugging session, a developer can link to individual builds corresponding to individual pushes to GitHub.

Second, keeping builds available makes it possible for older builds to be hot-swapped into the role of serving an edition of the documentation should a build for an edition be broken.
If old builds were not available the only recourse we be to rebuild and re-upload the documentation from scratch.
If the documentation is somehow broken, this may not be a quick recovery operation.
With persistent builds, recovery to a known 'good' build is immediate.

.. _url-discovery:

Discovery of available editions and builds
------------------------------------------

A reader of an LSST the Docs-published project will likely want a convenient interface for discovering and switching between the available editions and even builds.
Such services are enabled by LTD Keeper's RESTful API. FIXME link

One type of interface would be edition switching interface elements embedded in published HTML pages.
Such interface elements are specific to the front-end architecture of documents published on LSST the Docs, and are out of scope of this document.

Another type of interface would be dashboard pages that dynamically list metadata about available editions and builds.
Though not yet implemented, we envision that such pages would be available at

.. code-block:: text

   https://example.lsst.io/v/index.html

for editions of a documentation project and

.. code-block:: text

   https://example.lsst.io/builds/index.html

for builds of a documentation project.
These dashboards would leverage data from the LTD Keeper API, and be rendered entirely on the client with React_, or example.

In addition, we anticipate that the LTD Keeper API will be consumed by `DocHub <http://sqr-011.lsst.io/en/latest/#a-documentation-index>`_, a propose LSST-wide API for documentation discovery.
With DocHub and the LTD Keeper API, documentation projects and their main editions would be dynamically listed from LSST documentation landing pages.

.. _seo:

Presenting versioned documentation to search engines
----------------------------------------------------

Having so many instances of a documentation sites is detrimental to those site's ranking in search engines such as Google.
Furthermore, we likely want a potential documentation reader to always land on the :ref:`default edition <default-url>` of the documentation.
These objectives can be achieved by setting the page's canonical URL in the HTML of documentation: 

.. code-block:: html

   <link rel="canonical" href="https://example.lsst.io/index.html">

Note that this will require modification of the HTML presentation of projects published on LSST the Docs.
As an alternative, LSST the Docs may in the future `set the canonical URL of pages it serves through an HTTP header <https://support.google.com/webmasters/answer/139066?hl=en&rd=1#6>`_:

.. code-block:: http

   Link: <https://example.lsst.io/index.html>; rel="canonical"

.. _fastly-cdn:

Serving Versioned Documentation for Unlimited Projects with Fastly
==================================================================

The previous section laid out the URL architecture of documentation projects hosted on LSST the Docs.
This section focuses on the practical implementation of documentation delivery to the reader.

Besides serving beautiful URLs, LSST the Doc's hosting design is governed by two key requirements.
First, LSST the Docs must be capable of serving an arbitrarily large number of documentation projects, along with an arbitrarily large number of versions of those documentation projects.
Second, web page delivery must be fast and reliable.
Since documentation consumption is an integral aspect of LSST development work, any documentation download latency or downtime is unacceptable.
Finally, LSST the Docs will host highly public documentation projects, such as documentation for LSST data releases.
LSST the Docs must scale to any web-scale traffic load.

To meet these requirements, LSST the Docs uses two managed services: Amazon Web Services S3 and the Fastly_ content distribution network.

The role of S3 is to authoritatively store all documentation sites hosted by LSST the Docs.
When readers visit an ``lsst.io`` site, they do not directly interact with S3, but rather with Fastly_.
As a content distribution network, Fastly_ has `points of presence <https://www.fastly.com/services/modern-network-design>`_ distributed globally.
When a page from LSST the Docs is requested for the first time, Fastly_ retrieves the page from S3 and forwards it the original requester.
At the same time, Fastly caches the page in all of its points of presence.
The next time the same page is requested, the Page is served directly from the nearby Fastly point of presence.
By bringing the documentation content closer to the reader, regardless of where on Earth the reader is, LSST the Docs can deliver content with less latency.

.. _s3-bucket:

Organization of documentation in S3
-----------------------------------

Amazon Web Services S3 is commonly used to host static web sites, such as those that can be hosted on LSST the Docs.
Static web pages are conceptually simple to serve since individual files on the servers filesystem map directly to URLs.
S3 specifically provides a cost effective static site hosting solution that is highly available and resilient to any traffic load.

S3 even includes a setting to turn its buckets into `statically hosted public websites <http://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html>`_.
In this approach, the S3 bucket's URL is named after the domain the site is served from.
For LSST the Docs, this would imply that each documentation project would need its own bucket in order to be served from its own subdomain.
Creating so many buckets, especially autonomously, is not a scalable approach since Amazon puts a soft-limit of 100 buckets per AWS account.

Instead of using multiple S3 buckets, we adopted a scalable solution advocated by Seth Vargo of HashiCorp where `multiple sites are stored in a single S3 bucket but served separately through Fastly <https://www.hashicorp.com/blog/serving-static-sites-with-fastly.html>`_.

Files for each documentation project are stored in separate root directories of the common S3 bucket.
The names of these directories match the projects' subdomains.
For example:

.. code-block:: text

   /
     sqr-000/
     sqr-001/
     ...

Within these project directories, builds are stored in a ``/builds`` subdirectory, and editions are stored in ``/v/`` directories.
For example,

.. code-block:: text

   /
     sqr-012/
       builds/
         1/
           index.html
         2/
           index.html
         ...
       v/
         main/
           index.html
         DM-5458/
           index.html
     ...

This path architecture purposefully mirrors the :ref:`URL architecture <urls>`.
This enables Fastly to serve multiple sites and builds or editions thereof by transforming the requested URL into URL in the S3 bucket.
This mechanism is described in the next section.

.. _fastly-vcl-url-rewrites:

Re-writing URLs in Varnish Control Language
-------------------------------------------

Every request to Fastly is processed by Varnish_.
Varnish is an open source caching HTTP reverse proxy.
Varnish gives LSST the Docs a great deal of flexibility since each HTTP request is processed in the Varnish Configuration Language (VCL), which is an extensible Turing-complete programming language.

Thus when a request is received, Varnish uses regular expressions to map the requested URL to a URL in the S3 origin bucket.
The follow tables describes the three types of URLs that need to be supported.

.. table::

   +---------+-------------------------------------------------+-------------------------------------------------------------------------+
   | Type    | Request URL                                     | S3 Origin URL                                                           |
   +=========+=================================================+=========================================================================+
   | default | ``https://example.lsst.io/``                    | ``{{ bucket }}.s3.amazonaws.com/example/v/main/index.html``             |
   +---------+-------------------------------------------------+-------------------------------------------------------------------------+
   | edition | ``https://example.lsst.io/v/{{ edition }}/``    | ``{{ bucket }}.s3.amazonaws.com/example/v/{{ edition }}/index.html``    |
   +---------+-------------------------------------------------+-------------------------------------------------------------------------+
   | build   | ``https://example.lsst.io/builds/{{ build }}/`` | ``{{ bucket }}.s3.amazonaws.com/example/builds/{{ build }}/index.html`` |
   +---------+-------------------------------------------------+-------------------------------------------------------------------------+

This is URL manipulation is accomplished with approximately the following VCL code:

.. literalinclude:: includes/rewrites.vcl
   :emphasize-lines: 6,12-17,19-24
   :linenos:

On line 6, the domain is changed from ``*.lsst.io`` to the bucket's API endpoint.

In the next highlight section, we detect any URL path (stored in the ``req.url`` variable) and test if it does not start with ``/v/`` or ``/build/``, meaning that the default documentation is being requested.
In that case, the path is re-written such that ``req.url`` is relative to the ``/v/main/`` subdirectory of a product in the S3 bucket (the default edition is an alias for ``/v/main/``).
The directory of the product is obtained from the subdomain of the original request domain (``req.http.Fastly-Orig-Host``).

For regular edition or build URLs, all that must be done is combine the product name extracted from ``req.http.Fastly-Orig-Host`` with the ``req.url`` to obtain the path in the S3 bucket.

Replicating web server behavior from S3's REST API
--------------------------------------------------

We configured Fastly to obtained resources through its `REST endpoint <http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region>`_ (e.g., ``{{ bucket }}.s3.amazonaws.com``) rather than the S3 website endpoint (e.g., ``s3-website-us-east-1.amazonaws.com/{{ bucket }}``).
The advantage of using the REST endpoint is that communications between Fastly and S3 are encrypted with TLS, preventing a 'man-in-the-middle' attack.

Using the REST endpoint, on the other hand, means forgoing some conveniences from a webserver built intending to service web browsers.
For example, a ``example.lsst.io/`` path does not automatically imply ``example.lsst.io/index.html``.
Instead, these conveniences must be built into the VCL logic.

For example, the code to re-write a directory URL to the :file:`index.html` document is

.. literalinclude:: includes/index-rewrite.vcl

Redirecting Read the Docs URLs
------------------------------

When LSST the Docs was launched, tens of LSST documents were already being published with Read the Docs.
Whereas LSST the Docs serves default documentation from the root URL, ``example.lsst.io/``, Read the Docs always exposes a version name in its URLs.
The default edition is ``example.lsst.io/en/latest/``.
The prevent broken URLs, we coded the VCL to send a 301 permanent HTTP redirect response to any path beginning with ``/en/latest/``.

In ``vcl_recv``, the deprecated URL is detected:

.. code-block:: text

   if( req.url ~ "^/en/latest" ) {
     error 900 "Fastly Internal";
   } 

This internal error (code 900) is caught in ``vcl_error``:

.. code-block:: text

   if (obj.status == 900 ) {
     set obj.http.Content-Type = "";   
     synthetic {""};
     return(deliver);
  }

and finally in ``vcl_deliver``:

.. literalinclude:: includes/rtd-redirect.vcl

Sending a 301 redirect rather than silently re-writing the URL improves search engine optimization since the canonical URL is enforced.

Serving HTTPS to the browser
----------------------------

Another convenience of Fastly is that web pages are encrypted to the browser with TLS (that is, served over HTTPS).
LSST the Docs uses a shared wildcard certificate to serve all ``*.lsst.io`` domains.

Although HTTP requests are accepted, we configured Fastly to redirect HTTP requests to HTTPS so that all communications are encrypted.

Non-TLS requests are detected early in the ``vcl_recv`` block with the ``Fastly-SSL`` header passed from Fastly's TLS terminator to the caching layer:

.. literalinclude:: includes/force-ssl-recv.vcl

Note how ``req.http.host`` is reset to the original host (``*.lsst.io``) rather than the S3 hostname.

This 801 error is serviced in ``vcl_error``:

.. literalinclude:: includes/force-ssl-error.vcl

.. _ltd-keeper:

LTD Keeper API
==============

`LTD Keeper`_ is a microservice that plays a central coordination and automation role in LSST the Docs.
It is implemented as a Python 3 web application, built upon the Flask_ microframework.
As shown in :numref:`fig-ltd-arch`, LTD Keeper directly interacts with AWS S3 (storage), AWS Route53 (DNS) and Fastly_ (CDN).
LTD Keeper also maintains an SQL database of all documentation products, editions and builds.
Clients can interact with LTD Keeper resources, and trigger actions, through a RESTful HTTP API.
LTD Mason is the original client of this API.

LTD Keeper's API is documented at https://ltd-keeper.lsst.io. 
This section will describe the API resources and methods broadly; those writing clients should consult the API reference documentation.

.. _ltd-keeper-auth:

LTD Keeper Authentication and Authorization
-------------------------------------------

LTD Keeper, at the moment, generally accepts anonymous read requests to facilitate clients that discovery documentation through the API.
HTTP methods that change state (``POST``, ``PUT`` and ``PATCH``) require the client to be both authenticated an authorized.

Authentication is implemented with HTTP basic auth.
Registered clients have a username and password.
Clients send these credential in the basic auth header to the `POST /token <https://ltd-keeper.lsst.io/auth.html#get--token>`_ API endpoint to receive a temporary auth token.
This auth token is used for all other API endpoints.

Users are also assigned different authorization roles.
These roles are:

.. table::

   +---------------------+-------------------------------------------------------+
   | Role                | Description                                           |
   +=====================+=======================================================+
   | ``ADMIN_USER``      | Can create a new API user, view API users, and modify |
   |                     | API user permissions.                                 |
   +---------------------+-------------------------------------------------------+
   | ``ADMIN_PRODUCT``   | Can add, modify and deprecate Products.               |
   +---------------------+-------------------------------------------------------+
   | ``ADMIN_EDITION``   | Permission to add, modify and deprecate Editions.     |
   +---------------------+-------------------------------------------------------+
   | ``UPLOAD_BUILD``    | Permission to create a new Build.                     |
   +---------------------+-------------------------------------------------------+
   | ``DEPRECATE_BUILD`` | Permission to deprecate a Build.                      |
   +---------------------+-------------------------------------------------------+

A given user can have several roles, although users should be given only the minimum permission set to accomplish their activities.
For example, the user accounts used by LTD Mason only have the ``UPLOAD_BUILD`` role.

.. _ltd-keeper-resources:

API resources
-------------

As a RESTful application, ``ltd-keeper`` makes resources available through URL endpoints that can be acted upon with HTTP methods.
The main resources are Products, Builds, and Editions.

.. _ltd-keeper-products:

Products
^^^^^^^^

Products, ``/products/`` are the root resource.
A product corresponds to a software project (such as ``lsst_apps`` or Qserv) or a pure documentation project, such as a technical note or design document.
Each product is served from its own subdomain of ``lsst.io``.

An administrator creates a new Product with `POST /products/ <https://ltd-keeper.lsst.io/products.html#post--products->`_.
When a new Product is created, LTD Keeper configures a CNAME DNS entry for that product's subdomain to the Fastly endpoint.
LTD Keeper also automatically creates an Edition called ``main`` that :ref:`serves documentation from the root URL <default-url>`.

Information about a single product can be retrieved with `GET /products/(slug) <https://ltd-keeper.lsst.io/products.html#get--products-(slug)>`_.
A listing of all products is obtained with `GET /products/ <https://ltd-keeper.lsst.io/products.html#get--products->`_.

See the `/products/ resource documentation <https://ltd-keeper.lsst.io/products.html>`_ for a full listing of the methods and metadata associated with a Product.

.. _ltd-keeper-builds:

Builds
^^^^^^

Builds are discrete, immutable uploads of a Product's documentation, typically uploaded by LTD Mason.
:ref:`The process of uploading a build <ltd-mason-uploads>` is described above.

Build resources contain a ``surrogate_key`` that corresponds to the surrogate key HTTP header set by LTD Mason.
Through this surrogate key, Fastly can purge a build from its cache.

Build resources also contain a ``git_refs`` field, which is a list of Git branches that describe the documentation version.
(Note that ``git_refs`` is a list type to accommodate multi-repository projects).
Editions use this ``git_refs`` field to identify builds that can be used by an edition.

Builds for a single Product can be discovered through the `GET /products/(slug)/builds/ <https://ltd-keeper.lsst.io/products.html#get--products-(slug)-builds->`_ endpoint

.. _ltd-keeper-editions:

Editions
^^^^^^^^

Editions are documentation published from `branches of a Git repository <edition-urls>` (e.g. ``example.lsst.io/v/{{ branch }}``.
Editions have a ``slug`` that corresponds to the Git branch name (though not necessarily; the slug does define the URL of the Edition).
Editions also have a ``tracked_refs`` field that lists the set of Git branches for which the Edition serves documentation.
As well, Editions have a pointer to the build that they are currently publishing, as well as a surrogate key.
This surrogate key is separate from the one used by the Build, and instead allows an Edition to be reliably purged from Fastly.

An edition can be updated by uploading new Builds with ``git_refs`` fields that match the ``tracked_refs`` field of the Edition.
Whenever a new build it posted, LTD Keeper automatically checks if that build corresponds to an Edition (which it should).
If so, the old Edition is delete and the new build is copied to the Edition's :ref:`location in the S3 bucket <s3-bucket>`.
During this copy the surrogate key header in files is change from that of the Build to the Edition.
By associating a stable surrogate key to an Edition, purges are easy to carry out.
In fact, LTD Keeper purges the Edition from the Fastly cache whenever an edition is changed.

Build storage on AWS S3
-------------------------------------

TODO

..
  Since Sphinx_ generates static files, there is no need to have a live webserver (such as Nginx or Apache) running a web application involved in hosting.
  Instead we can can use a static file server.
  Our preference is to use a commodity cloud file host, such as Amazon S3 or GitHub pages, since those are far more reliable and have less downtime than any resources that LSST DM can provide in house at this time.
  GitHub Pages has the advantage of being free with an automatically-configured CDN.
  However, S3 is more flexible and fits better with our team's DevOps experience.

.. _directory-structure:

Serving documentation Editions with Fastly
------------------------------------------

TODO

..
  .. note::
  
     Would it be preferably for each version to live in its own S3 bucket, and be served from independent *subdomains*?
  
  A requirement of our documentation platform is that multiple versions of the documentation must be served simultaneously to support each version of the software.
  `Read the Docs`_ exposes versioning to its users in two ways:
  
  1. Each version of the documentation is served from a sub-directory.
     The root endpoint, ``/``, for the documentation site's domain redirects, by default, to the ``lateset/`` directory of docs that reflects the ``master`` Git branch of the software's Git repository.
  2. From the documentation website, the user switch between versions of the documentation with a dropdown menu widget (e.g., implemented in React).
  
  The former is accomplished for LSST's doc platform by defining a directory structure that accommodates the classes of documentation versions we support, while the latter will be powered by the :ref:`ltd-keeper <ltd-keeper>`\ 's RESTful API for documentation discovery in conjunction with front-end engineering in the documentation website itself (which is outside the scope of this technical note).
  
  Here we define the directory structure of an LSST software documentation site:
  
  ``/``
     The root endpoint will redirect to ``/latest/``.
  
  ``/latest/``
     This documentation will be rebuilt whenever a Stack package (or the umbrella documentation repository) has new commits on the collective ``master`` Git branches.
  
  ``/<tag>/``
     Any tagged version of the software (such as a weekly build or a formal release) has a corresponding hosted version of documentation.
     The directories that these docs are hosted from are named after the Git or Eups tag itself.
  
  ``/<branches>/``
     On our Jenkins page, http://ci.lsst.codes, developers can enter either a single branch or a series of branch names that the build system then obtains in a priority cascade for each package (defaulting to ``master`` branches) to compose the built stack product.
     The documentation served for these developer-triggered build should be identified by the same sequence of branch names.
     For example, a build of ``users/jsick/special-project, tickets/DM-9999`` would be hosted from ``/users-jsick-special-project-tickets-dm-9999/``.
     Note the normalization of the branch names into URLs.
  
     These endpoints are meant to be transient.
     The :ref:`ltd-keeper <ltd-keeper>` service is responsible for deleting these development docs once they have become stale over a set time period (likely because the branch has been merged).

.. _additional-reading:

Additional Reading
==================

- The LTD Mason documentation: https://ltd-mason.lsst.io.
- The LTD Keeper documentation: https://ltd-keeper.lsst.io.
- Resources for documentation writers in the LSST DM Developer Guide: https://developer.lsst.io.

.. _LTD Mason: https://ltd-mason.lsst.io
.. _LTD Keeper: https://ltd-keeper.lsst.io
.. _LSST DocHub: http://sqr-011.lsst.io/en/latest/#a-documentation-index
.. _EUPS: https://github.com/RobertLuptonTheGood/eups
.. _Scons: http://scons.org
.. _DM Development Workflow: http://developer.lsst.io/en/latest/processes/workflow.html
.. _DM Developer Guide: http://developer.lsst.io
.. _Sphinx: http://sphinx-doc.org
.. _Read the Docs: http://readthedocs.org
.. _GitHub Service Hook: https://developer.github.com/webhooks/#service-hooks
.. _Astropy: http://docs.astropy.org
.. _Numpydoc: https://github.com/numpy/numpydoc
.. _sconsUtils: https://github.com/lsst/sconsUtils
.. _Breathe: http://breathe.readthedocs.org/en/latest/
.. _lsstsw: https://github.com/lsst/lsstsw
.. _Fastly: https://www.fastly.com
.. _Varnish: https://www.varnish-cache.org
.. _boto3: http://boto3.readthedocs.io/en/latest/
.. _React: https://facebook.github.io/react/
