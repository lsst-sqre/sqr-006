:tocdepth: 1

.. sectnum::

Introduction
============

Documentation is an integral deliverable of LSST Data Management's software development work, and is produced at all stages of our process.
Before code is written, we document architectural designs, specifications, and experiments.
While code is being written, documentation describes implementations and interfaces.
Documentation makes the software understandable through user guides, tutorials, and references.

Documentation underpins the usefulness of LSST software and data as a resource for the astronomical community.
All LSST Data Management software is open source and engineered with the expectation that it will find use beyond LSST's alert and data release pipelines.
For instance, astronomers exploring LSST data through the Level 3 compute environment will become direct users of LSST software.
And though it is not an explicit mission statement, we expect that future imaging surveys will adopt and build upon LSST software since the LSST pipelines are already engineered to process data from several observatories for testing purposes.
Documentation is prerequisite for any use and adoption of LSST software beyond LSST's internal teams.

Importance of Integrating Documentation and Code in Git
-------------------------------------------------------

Originally we authored and published documentation in a manner removed from the code itself, such as Confluence wikis or PDFs archived to Docushare.
While these tools made the initial acts of content creation and publication straightforward, they provided no obvious workflow for updating and versioning documentation as part of regular development work.
As a result, documentation would often fall out of step with code.
An example manifestation of this problem has been silent breakages of tutorials and user guides hosted on wikis as the code was been developed elsewhere.

On the other hand, we already have an excellent workflow for developing well-tested and peer-reviewed code (see the `DM Development Workflow`_).
By treating documentation as code we realize the same workflow advantages for documentation development.
First, co-locating documentation and code in the same Git repository removes any versioning ambiguity: documentation reflects changes in code potentially on a per-commit granularity.
Such documentation can also be continuously integrated against the associated code.
Continuous integration ensures that examples work, application programming interfaces are properly documented, and that the documentation web site itself can be built without errors.
Finally, such documentation can be reviewed as part of pull requests.
Overall, treating documentation as code can improve the overall documentation culture of a software development organization.
There is much less cognitive overhead for a developer to update documentation that lives in a Git repository (even within a source code file) than there is to deal with a separate environment like a wiki.

Simply storing documentation in Git is only the first step.
Infrastructure is needed to build and deploy that documentation.
LSST Data Management has already used Doxygen to extract and render documentation stored in the Git repositories of software packages.
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
Read the Docs then clones the Git repository, builds the Sphinx project (i.e., ``make html``) and deploys the HTML product.

Read the Docs can be configured to listen to different Git branches.
By default, Read the Docs builds documentation from the ``master`` Git branch and publishes it to a ``/en/latest/`` URL path prefix.
It can can publish additional branches, either for private code review or to maintain documentation for stable releases.
Such branches are published from ``/en/branch-slug/`` path prefixes.
Through a UI element, Read the Docs allows readers to discover and switch between different versions of a software project.

Overall, the key innovation of Read the Docs is the generic automation of versioned documentation deployment that has enabled thousands of open source developers to maintain documentation with minimal overhead.

Beyond Read the Docs
--------------------

LSST Data Management deployed as many of 39 documentation projects on `Read the Docs`_, including the `DM Developer Guide`_, several stand-alone Python projects, and technical notes (see `SQR-000: The LSST DM Technical Note Publishing Platform`__).
This experience allowed us to be better understand our documentation deployment needs, and culminated in the design and implementation of a new documentation deployment platform, *LSST the Docs*.

.. __: http://sqr-000.lsst.io

Our experience underscored two categories of documentation deployment needs: first that we need to own the documentation build environments, and secondly that we require deeper integration and automation with respect to our development workflow.

Owning the build environment is the most important requirement, which in fact blocked us from publishing the LSST Science Pipelines documentation on Read the Docs.
Software documentation projects require that the software itself be built and available to the documentation build tool.
Sphinx_, and Numpydoc_ in particular, inspect the docstrings of installed code to automatically build accurate API reference documentation.
Continuous integration also requires that the software be installed to test examples and tutorials.
`Read the Docs`_ assumes that Python projects can be built with Python's standard Setuptools/Distutils (i.e., a ``setup.py`` file).
The LSST Science Pipelines build process does not follow this architecture, and instead uses EUPS_ to coordinate the versioning of tens of GitHub repositories and Scons_ to compile the software.
Simply put, the LSST Science Pipelines build process is incompatible with Read the Docs.

Another challenge was the scalability of administration for Read the Docs-hosted projects.
This challenge was particularly accurate with LSST Technotes.
Each technote was implemented as its own Read the Docs project.
To encourage the adoption of Technotes, a single DM team member was responsible for configuring a new Read the Docs project (including DNS configuration).
While this ensured consistent configuration, it created a bottleneck in Technote publication.
In some cases, DM team members forgot or didn't read enough of the documentation to realize they needed to ask the administrator to create their Read the Docs project.
Ideally, documentation project provisioning should be fully automated, perhaps even as a ChatOps command.

In day-to-day development work, this administration model was also a bottleneck.
For each development branch, the developer would have to ask the administrator to create a new branch build so that the documentation could be previewed in development and code review.
Often times, developers would never see their rendered documentation until it was merged, sometimes resulting in obvious formatting errors on the published ``master`` branch documentation.
Alternatively, developers would rely upon GitHub's rendering of a reStructuredText file.
Developers who did this were often confused about rendering errors, not realizing that GitHub does not render the extended reStructuredText syntax available to Sphinx.
Instead, we want new versions of documentation to be published immediately and automatically for each branch.

In response to these challenges, the Science Quality and Reliability Engineering (SQuaRE) Team in LSST Data Management undertook the design and engineering of *LSST the Docs*, a platform for the continuous delivery of documentation.

This technote describes the architecture of *LSST the Docs*.
Those wishing to operate an instance of *LSST the Docs*, or produce content for a project published by *LSST the Docs*, should also refer to the documentation listed in :ref:`additional-reading`.

LSST the Docs: A Microservice Architecture
==========================================

In setting out to design *LSST the Docs*, we realized that the short-comings of both the original LSST Science Pipelines documentation deployment scripts and Read the Docs stemmed from their integrated architectures.
The Pipelines documentation deployment script was deeply integrated with the architecture of the LSST Science Pipelines and its build environment, making it impossible to adapt to other projects.
Read the Docs, on the other hand, provided a common build and publication pipeline---yet that build environment was not flexible enough for all projects.

Instead, *LSST the Docs* is designed as a set of microservices.
Each service has a clear, well-defined responsibility along with well-defined interfaces between them.
This gives *LSST the Docs* the flexibility to host a range of documentation projects, from simple Sphinx_ projects to multi-repository EUPS-based software stacks.
In fact, *LSST the Docs* is agnostic of the documentation build tool; a LaTeX document could be published as easily as a full Sphinx project.
This microservice architecture also improves development efficiency since each component can be updated independently of the others.
*LSST the Docs* also takes advantage of standard third-party infrastructure wherever possible.

The main components of *LSST the Docs* are `LTD Mason`_, `LTD Keeper`_, Amazon Web Services S3 and Route 53, and `Fastly`_.
:numref:`fig-ltd-arch` shows how these services operate together.

.. _fig-ltd-arch:

.. figure:: /_static/ltd_arch.svg

   Architecture of LSST the Docs (LTD) when specifically used to deploy documentation for the EUPS-based LSST Science Pipelines.
   Other projects might use other build platforms such as Travis CI, and even their own HTML compilation tools.
   LTD Mason provides the common interface for delivering built HTML to LSST the Docs.

In brief, a documentation deployment begins with `LTD Mason`_, which is a Python tool intended to be run on a project's existing continuous integration server, such as Jenkins_ or the publicly-hosted `Travis CI`_, that is triggered by pushes to GitHub_.
Not only does this strategy absolve *LSST the Docs* from maintaining build environments, it also follows our philosophy of treating documentation as code.
Mason's primary responsibility is to upload documentation builds onto Amazon S3.
Mason is also optionally capable of driving complex multi-repository documentation build (this functionality gives Mason its name).

`LTD Keeper`_ is a RESTful web application that maintains a database of documentation projects.
An arbitrary number of projects can be hosted by an *LSST the Docs* deployment.
Keeper coordinates all services, such as directing Mason uploads to S3, registering project domains on Route 53, and purging content from the `Fastly`_ cache.
Other projects, such as the `LSST DocHub`_, can use LTD Keeper's public API to discover documentation projects and their published versions.

Finally, `Fastly`_ is a third-party content distribution network that serves documentation to readers.
In addition to making content delivery fast and reliable, `Fastly`_ allows LSST the Docs to serve highly intuitive URLs for versioned documentation.

The remainder of this technote will discuss each aspect of LSST the Docs in further detail.

.. _ltd-mason-eups:

LTD Mason for Multi-Repository EUPS Documentation Projects
==========================================================

The role of LTD Mason in *LSST the Docs* is to register and upload new documentation builds from the continuous integration server to AWS S3.
Since *LSST the Docs* was initially created specifically to build documentation for multi-repository EUPS_ products such as ``lsst_apps` and ``qserv``, we added optional affordances to LTD Mason to build such projects.
Note that LTD Mason can also be used for non-EUPS projects, see :ref:`ltd-mason-travis`.

For EUPS_ products, documentation exists in two strata.
The base tier consists of the repositories of individual EUPS packages.
The second tier is the product's *doc repo.*

The role of documentation embedded in packages provide API references and guides specific for code in that package.
Co-locating documentation in the code's Git repository ensures that documentation is versioned in step with the code itself.
The documentation for a package should also be independently build-able in a developer's local environment.
Although broken cross-package links may be inevitable with local builds, such local builds are critical for the productivity of documentation writers.

The product's doc repo is a Sphinx_ project that produces the coherent documentation structure for the EUPS_ product itself.
The product doc repo establishes the overall table of contents that links into package documentation, and also contains its own content that applies at a product-wide level.
In fact, The product doc repo is the lone Sphinx project seen directly by the Sphinx_ builder.

The product's doc repo is not distributed by EUPS to end-users, so it is not an EUPS package.
Instead, EUPS tags for releases are mapped to branch names in the product doc repo.

.. _eups-pkg-organization:

Package documentation organization
----------------------------------

To effect the integration of package documentation content into the product documentation repo, each package must adhere the following file layout:

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

The role of the :file:`doc/Makefile`, :file:`doc/conf.py` and :file:`doc/index.rst` files is solely to allow local builds.
Also note how static assets for packages are isolated in the :file:`_static/<package_name>/` directory.

.. _eups-doc-product-organization:

Product documentation organization
----------------------------------

When ``ltd-mason`` builds documentation for an EUPS product, it links documentation resources from individual package repositories into a cloned copy of the product's documentation repository.
In Data Management's Jenkins environment, the Git repositories for each EUPS package are available on the filesystem through `lsstsw <http://developer.lsst.io/en/latest/build-ci/lsstsw.html>`__.

Given the structure of individual packages described above, softlinks are made from the product documentation repo as so:

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
       <package_1>/ -> /<package_1>/doc/_static/<package_1>/
       <package_2>/ -> /<package_2>/doc/_static/<package_2>/
       # ...

In this scheme, the absolute paths to static assets in the :file:`_static/` directory is unchanged whether a package's documentation is built alone, or integrated into the EUPS product.

Once an EUPS product's documentation is linked, it is built by LTD Mason like any other Sphinx project.

The Build's YAML Manifest interface to LTD Mason
------------------------------------------------

Although LTD Mason runs on Jenkins in the Stack build environment, LTD Mason is not integrated tightly with LSST's build technologies (Eups and Scons).
This choice allows our build system to evolve independently of the Stack build environment, and can even accommodate non-EUPS based build environments.

The interface layer that bridges the software build system (``buildsstsw.sh``) to the documentation build system (the ``ltd-mason`` command line too) is a Manifest file, formatted as YAML.
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
   This field defines is used by LTD Keeper to map documentation Builds to Editions.

requester_github_handle
   This is an optional field that can contain the GitHub username of the person requesting the build.
   If provided, this will be used to notify the build requester through Slack.

doc_repo.url
   The Git URL of the product's documentation repository.

doc_repo.ref
   This is the Git reference (commit, tag or branch) to checkout from the product's documentation repository.

packages
   This field consists of key-value objects for each package in an EUPS-based multi-package software product.
   The keys correspond to the names of individual packages (and the Git repository names in the `github.com/lsst <https://github.com/lsst>`_ organization).

   packages.<pkg_name>.dir
      Local directory where the package was installed by :file:`lsstsw/`.
   
   packages.<pkg_name>.url
      URL of the package's Git repository on GitHub.

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

Once documentation is compiled into a static website consisting of HTML, CSS, images, and other assets, LTD Mason uploads those resources to *LSST the Doc's* Amazon Web Services S3 bucket.

The upload process is governed by a handshake with the LTD Keeper API server.
When an LTD Mason instance wants to upload a new build it sends a `POST /products/(slug)/builds/ <https://ltd-keeper.lsst.io/products.html#post--products-(slug)-builds->`_ request to LTD Keeper.
The request body describes what Git branch this documentation corresponds to, and the request URL specifies the documentation :ref:`Product <ltd-keeper-products>` maintained by LTD Keeper.
The response from LTD Keeper to this request is a :ref:`Build <ltd-keeper-builds>` resource that specifies where this build should be uploaded in the S3 bucket, along with metadata that should be attached to uploaded artifacts.

LTD Mason uses boto3_ to upload static documentation sites to S3. 
During this upload, LTD Mason gives every object a ``public-read`` Access Control List header to facilitate API access by Fastly.
``Content-Type`` headers are also set, based on :func:`mimetypes.guess_type`, to enable gzip-compressed delivery with Fastly.
The ``Cache-Control`` header is set to ``max-age=31536000``, which allows content to be retained in Fastly's cache for one year, or until specifically purged.
Purges are facilitated by also setting the ``x-amz-meta-surrogate-key`` header according to the Build resource returned by the LTD Keeper request.
This :ref:`surrogate key allows individual documentation builds to be purged <ltd-keeper-edition-updates>` from the Fastly CDN.

Once the upload is complete, LTD Mason notifies LTD Keeper by sending a `PATCH request to the build resource <https://ltd-keeper.lsst.io/builds.html#patch--builds-(int-id)>`_ that changes the ``uploaded`` field from ``false`` to ``true``.


.. _ltd-mason-travis:

LTD Mason on Travis
===================

Although LTD Mason can run documentation builds for EUPS-based projects, not all projects use EUPS.
In fact, not all projects will even use Sphinx.
For such generic projects, Travis CI is a popular continuous integration environment.
LTD Mason provides an alternative command line interface, ``ltd-mason-travis``, specifically for publishing documentation from a Travis environment.
In this mode, LTD Mason can upload *any* static website to *LSST the Docs,* regardless of the tooling used to create that site.

The `LTD Mason documentation <https://ltd-mason.lsst.io/travis.html>`__ describes how to configure Travis.
The following is a realistic example Travis configuration :file:`.travis.yml` for a Python project that is also publishing documentation to *LSST the Docs:*

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

Several aspects of this :file:`.travis.yml` example are relevant to *LSST the Docs* users.
First, an extra build is added to the testing matrix where the environment variable ``LTD_MASON_BUILD`` is explicitly set to ``true``.
Since the ``ltd-mason-travis`` command is always run in the ``after_success`` phase of a Travis build, the ``LTD_MASON_BUILD`` environment variable helps ensure that only one build in the matrix follows through on documentation publication.

We recommend running Sphinx_ (or similar) in the ``script`` phase.
This ensures that errors in the documentation build to fail the entire build, which is likely desirable behavior.
In fact, ``sphinx-build`` is run with the ``-a -W`` flags that both turns 'warnings' into errors, and elevates missing references into errors.
Again, note how ``sphinx-build`` is entirely separate from ``ltd-mason-travis``; any static site builder could be used.

Finally, in the ``env.global`` section, `LTD Mason is configured through several environment variables <https://ltd-mason.lsst.io/travis.html#environment-variables-and-secrets>`_.
Travis's `encrypted environment variable feature <https://docs.travis-ci.com/user/encryption-keys/>`_ is used to to securely store credentials for AWS S3 and LTD Keeper.
The private key needed to decrypt these fields is known only to Travis and is directly associated with the GitHub repository.
In other words, forks of a repository cannot gain access, and publish to, *LSST the Docs.*

.. _urls:

Versioned Documentation URLs
============================

*LSST the Docs* is designed to host an arbitrary number of documentation projects, along with an arbitrary number of versions of those projects.

*LSST the Docs* serves each documentation project from its own subdomain
of ``lsst.io``.
For example, ``sqr-000.lsst.io`` or ``ltd-keeper.lsst.io``.
These subdomains are memorable, and allow documentation to be referenced without need for a link shortener.
This URL model also concurs with the recent practice by Apple's Safari browser to collapse the entire URL to just the domain in the location bar.

Also note that *LSST the Docs* publishes specifically to ``lsst.io`` rather than ``lsst.org``.
This is because *LSST the Docs* requires programmatic access to a domain's DNS settings, and the ``lsst.io`` domain allows us to do that without interfering with ``lsst.org``'s operations.
Our intention is to brand ``lsst.io`` as synonymous with 'LSST Documentation.'

.. _default-url:

The default documentation edition
---------------------------------

From the root URL for a documentation product, for example ``https://example.lsst.io/``, *LSST the Docs* serves what is considered to be the 'default' version of the documentation.
Conventionally, this is documentation built from the ``master`` branch of a Git repository.
This choice can be changed on a per-project basis for strategic reasons.
For example, a software project may choose to serve documentation from a stable release branch at the root URL.

.. _edition-urls:

Additional editions for Git branches
------------------------------------

*LSST the Docs* serves separate editions of documentation for each branch of the project's parent repository.
These editions are served from a ``/v/`` path off of the root domain.
For example, a branch named ``v1`` would be served from ``https://example.lsst.io/v/v1/``.

For `ticket branches <http://developer.lsst.io/en/latest/processes/workflow.html#ticket-branches>`_ used by Data Management (e.g., ``tickets/DM-1234``), *LSST the Docs* transforms that branch name to create more convenient edition URLs: ``https://example.lsst.io/v/DM-1234/``.

Editions are created automatically for every new branch (as in, they are provisioned on-demand when LTD Mason :ref:`POSTs a build <ltd-mason-uploads>` from a new Git branch).
We believe that this automation will be incredibly useful for code reviews.
For any pull request it will be unambiguous where corresponding documentation can be found.
Making documentation more visible in code reviews should improve the culture of documentation within Data Management.

.. _build-urls:

Archived documentation builds
-----------------------------

*LSST the Docs* stores every documentation build uploaded as an immutable object that is never deleted, by default.
When a new documentation build is uploaded by LTD Mason, that build exists *alongside* the previous documentation builds rather than replacing them.
These individual builds are available from the ``/builds/`` path off the root domain. For example, the first build would be available at ``https://example.lsst.io/builds/1/``.

Retaining builds serves two purposes.
First, it allows "A/B" comparisons of documentation during development.
During a code review, or debugging session, a developer can link to individual builds corresponding to individual pushes to GitHub.

Second, keeping builds available provides a recovery mechanism should a published build for an edition be broken.
If old builds were not available the only recourse we be to rebuild and re-upload the documentation from scratch.
Yet if the documentation is somehow broken, this may not be a quick recovery operation.
This entire scenario is solved by retaining all builds so that recovery to a known 'good' build is immediate.

.. _url-discovery:

Discovery of available editions and builds
------------------------------------------

A reader of an *LSST the Docs*\ -published project will likely want a convenient interface for discovering and switching between the available editions and even builds.
Such services are enabled by :ref:`LTD Keeper's RESTful API <ltd-keeper>`.

One type of interface would be edition-switcher interface elements embedded in published HTML pages.
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

In addition, we anticipate that the LTD Keeper API will be consumed by `DocHub <http://sqr-011.lsst.io/en/latest/#a-documentation-index>`_, a proposed LSST-wide API for documentation discovery.
With DocHub and the LTD Keeper API, documentation projects and their main editions would be dynamically listed from LSST documentation landing pages.

.. _canonical-urls:

Presenting versioned documentation to search engines
----------------------------------------------------

Having so many instances of documentation sites is detrimental to those site's ranking in search engines, such as Google.
Furthermore, we likely want a potential documentation reader to always land on the :ref:`default edition <default-url>` of the documentation.
These objectives can be achieved by setting the page's canonical URL in HTML: 

.. code-block:: html

   <link rel="canonical" href="https://example.lsst.io/index.html">

Of course, this will require modification of the HTML presentation of projects published on *LSST the Docs.*
As an alternative, *LSST the Docs* may in the future `set the canonical URL of pages it serves through an HTTP header <https://support.google.com/webmasters/answer/139066?hl=en&rd=1#6>`_:

.. code-block:: text

   Link: <https://example.lsst.io/index.html>; rel="canonical"

.. _fastly-cdn:

Serving Versioned Documentation for Unlimited Projects with Fastly
==================================================================

The previous section laid out the URL architecture of documentation projects hosted on *LSST the Docs.*
This section focuses on the practical implementation of documentation delivery to the reader.

Besides serving beautiful URLs, *LSST the Doc's* hosting design is governed by two key requirements.
First, *LSST the Docs* must be capable of serving an arbitrarily large number of documentation projects, along with an arbitrarily large number of versions of those documentation projects.
Second, web page delivery must be fast and reliable.
Since documentation consumption is an integral aspect of LSST development work, any documentation download latency or downtime is unacceptable.
Finally, *LSST the Docs* will host highly public documentation projects, such as documentation for LSST data releases.
*LSST the Docs* must gracefully handle any web-scale traffic load.

To meet these requirements, *LSST the Docs* uses two managed services: Amazon Web Services S3 and the Fastly_ content distribution network.

The role of S3 is to authoritatively store all documentation sites hosted by *LSST the Docs.*
When readers visit an ``lsst.io`` site, they do not directly interact with S3, but rather with Fastly_.
As a content distribution network, Fastly_ has `points of presence <https://www.fastly.com/services/modern-network-design>`_ distributed globally.
When a page from *LSST the Docs* is requested for the first time, Fastly_ retrieves the page from S3 and forwards it the original requester.
At the same time, Fastly caches the page in all of its points of presence.
The next time the same page is requested, it is served directly from the nearby Fastly point of presence.
By bringing the documentation content closer to the reader, regardless of where on Earth the reader is, *LSST the Docs* can deliver content with less latency.

.. _s3-bucket:

Organization of documentation in S3
-----------------------------------

Amazon Web Services S3 is commonly used to host static web sites.
Static web pages are conceptually simple to serve since individual files on the server's filesystem map directly to URLs.
S3 specifically provides a cost-effective static site hosting solution that is highly available and resilient to any traffic load.

S3 even includes a setting to turn its buckets into `statically hosted public websites <http://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html>`_.
In this approach, the S3 bucket's URL is named after the domain the site is served from.
For *LSST the Docs,* this would imply that each documentation project would need its own bucket in order to be served from its own subdomain.
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
For example:

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
This enables Fastly to serve multiple sites, and builds or editions thereof, by transforming the requested URL into a URL in the S3 bucket.
This mechanism is described in the next section.

.. _fastly-vcl-url-rewrites:

Re-writing URLs in Varnish Control Language
-------------------------------------------

Every HTTP request to Fastly is processed by Varnish_.
Varnish is an open source caching HTTP reverse proxy.
Varnish gives *LSST the Docs* a great deal of flexibility since each HTTP request is processed in the Varnish Configuration Language (VCL), which is an extensible Turing-complete programming language.

Thus when a request is received, we have programmed Varnish to  map the requested URL to a URL in the S3 origin bucket through simple regular-expression base manipulations.
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

We configured Fastly to obtain resources from S3 through its `REST endpoint <http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region>`_ (e.g., ``{{ bucket }}.s3.amazonaws.com``) rather than the S3 website endpoint (e.g., ``s3-website-us-east-1.amazonaws.com/{{ bucket }}``).
The advantage of using the REST endpoint is that communications between Fastly and S3 are encrypted with TLS, preventing a 'man-in-the-middle' attack.

Using the REST endpoint, on the other hand, means forgoing some conveniences of a web server built for browser traffic.
For example, a ``example.lsst.io/`` path does not automatically imply ``example.lsst.io/index.html``.
Instead, these conveniences must be built into the VCL logic.

For example, the code to re-write a directory URL to the :file:`index.html` document is

.. literalinclude:: includes/index-rewrite.vcl

Redirecting Read the Docs URLs
------------------------------

When *LSST the Docs* was launched, tens of LSST documents were already being published with Read the Docs.
Whereas *LSST the Docs* serves default documentation from the root URL, ``example.lsst.io/``, Read the Docs always exposes a version name in its URLs.
The default edition is ``example.lsst.io/en/latest/``.
To prevent broken URLs, we coded the VCL to send a 301 permanent HTTP redirect response to any path beginning with ``/en/latest/``.

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
*LSST the Docs* uses a shared wildcard certificate to serve all ``*.lsst.io`` domains.

Although HTTP requests are accepted, we configured Fastly to redirect HTTP requests to HTTPS so that all communications are encrypted.

Non-TLS requests are detected early in the ``vcl_recv`` block with the ``Fastly-SSL`` header passed from Fastly's TLS terminator to the caching layer:

.. literalinclude:: includes/force-ssl-recv.vcl

Note how ``req.http.host`` is reset to the original host (``*.lsst.io``) rather than the S3 hostname.

This 801 error is serviced in ``vcl_error``:

.. literalinclude:: includes/force-ssl-error.vcl

Serving Gzip-compressed content
-------------------------------

We have configured Fastly to serve text-based content with Gzip compression.
Specifically, HTML, CSS, JavaScript, web font, JSON, XML and SVG content is compressed en route to the browser.
This reduces bandwidth and creates a better user experience.

.. _fastly-cache-management:

Managing Fastly and browser caching
-----------------------------------

Caches accelerate browsing performance.
In *LSST the Docs* there is not one cache but two: Fastly, and the local cache maintained by a web browser.
With caches there is a natural tendency between the lifetime of objects in a cache and ensuring that a browser is always displaying the most recent content.
This section summarizes how *LSST the Docs* manages caches.
Note that this cache logic is controlled both by the :ref:`LTD Mason upload phase <ltd-mason-uploads>` and :ref:`LTD Keeper's Edition updates <ltd-keeper-edition-updates>`.

Controlling the Fastly cache with surrogate key purges
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

*LSST the Docs* ensures that Fastly points of presence retain data for as long as possible by either setting ``Cache-Control: max-age=31536000`` or ``x-amz-meta-surrogate-control: max-age=31536000`` (i.e., one year) in the headers of objects stored on S3.

If content cached in Fastly needs to be updated, *LSST the Docs* is able to do so with a surrogate key purge.
LTD Keeper assigns unique surrogate keys to every Build and Edition resource.
When either LTD Mason or LTD Keeper add files to S3, these surrogate keys are inserted into the ``x-amz-meta-surrogate-key`` headers of objects.
Thus when an :ref:`Edition is updated <ltd-keeper-edition-updates>`, for example, LTD Keeper is able to purge that Edition specifically through its surrogate key with the Fastly API: `POST
/service/{{id}}/purge/{{key}} <https://docs.fastly.com/api/purge#purge_077dfb4aa07f49792b13c87647415537>`_.

Controlling the browser's caching
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For maximum performance, the browser's cache must also be managed.
By default, LTD Mason uploads objects with a ``Cache-Control: max-age=31536000`` header.
This header applies to both Fastly and browsers.
Since builds are immutable, such a potentially long-lived cache in the browser is acceptable.

Editions have more complex caching requirements since objects at a given URL can be updated.
In fact, for editions serving development branches, a developer will want the edition to reliably represent the most recent push to GitHub.
To accomplish this, LTD Keeper alters the headers of objects in editions to include the following headers:

.. code-block:: text

   x-amz-meta-surrogate-control: max-age=31536000
   Cache-Control: no-cache

The ``x-amz-meta-surrogate-control`` header instructs Fastly to retain the edition in its caches for one year (or until purged). This `Surrogate Control key is only used by Fastly, and is not send to the browser <https://docs.fastly.com/guides/tutorials/cache-control-tutorial#surrogate-control>`_.
This allows the ``Cache-Control`` header to exclusively manage browser caching.

Here, ``Cache-Control: no-cache`` means that a browser *can* cache content, but that each request `must be re-validated by the server <https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/http-caching#cache-control>`_ (Fastly).
In this re-validation process, the browser provides Fastly with the `ETag <https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/http-caching#validating-cached-responses-with-etags>`_ of the object in its cache.
If that ETag matches the current version, Fastly responds with a content-less HTTP 304 response.
Otherwise, Fastly returns the entire new object.
This caching approach balances the needs of reducing network bandwidth while ensuring content is up-to-date, though at the expense of lightweight validation requests to Fastly.

.. _ltd-keeper:

LTD Keeper API
==============

`LTD Keeper`_ is a microservice that plays a central coordination and automation role in *LSST the Docs.*
It is implemented as a Python 3 web application, built upon the Flask_ microframework.
As shown in :numref:`fig-ltd-arch`, LTD Keeper directly interacts with AWS S3 (storage), AWS Route53 (DNS) and Fastly_ (CDN).
LTD Keeper also maintains an SQL database of all documentation products, editions and builds.
Clients can interact with LTD Keeper resources, and trigger actions, through a RESTful HTTP API.
LTD Mason is the original consumer of this API.

LTD Keeper's API is documented at https://ltd-keeper.lsst.io. 
This section will describe the API resources and methods broadly; those writing clients should consult the API reference documentation.

.. _ltd-keeper-auth:

LTD Keeper Authentication and Authorization
-------------------------------------------

LTD Keeper, at the moment, generally accepts anonymous read requests to facilitate clients that discovery documentation through the API.
HTTP methods that change state (``POST``, ``PUT`` and ``PATCH``) require the client to be both authenticated an authorized.

Authentication is implemented with HTTP basic auth.
Registered clients have a username and password.
Clients send these credentials in the basic auth header to the `POST /token <https://ltd-keeper.lsst.io/auth.html#get--token>`_ API endpoint to receive a temporary auth token.
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

As a RESTful application, LTD Keeper makes resources available through URL endpoints that can be acted upon with HTTP methods.
The main resources are Products_, Builds_, and Editions_.

.. _ltd-keeper-products:

Products
^^^^^^^^

Products_ (``/products/``) are the root resource.
A Product corresponds to a software project (such as ``lsst_apps`` or Qserv) or a pure documentation project, such as a technical note or design document.
Each Product is served from its own subdomain of ``lsst.io``.

An administrator creates a new Product with `POST /products/ <https://ltd-keeper.lsst.io/products.html#post--products->`_.
When a new Product is created, LTD Keeper configures a CNAME DNS entry for that product's subdomain to the Fastly endpoint.
LTD Keeper also automatically creates an Edition called ``main`` that :ref:`serves documentation from the root URL <default-url>`.

Information about a single Product can be retrieved with `GET /products/(slug) <https://ltd-keeper.lsst.io/products.html#get--products-(slug)>`_.
A listing of all Products is obtained with `GET /products/ <https://ltd-keeper.lsst.io/products.html#get--products->`_.

See the `/products/ resource documentation <https://ltd-keeper.lsst.io/products.html>`_ for a full listing of the methods and metadata associated with a Product.

.. _ltd-keeper-builds:

Builds
^^^^^^

Builds_ are discrete, immutable uploads of a Product's documentation, typically uploaded by LTD Mason.
:ref:`The process of uploading a build <ltd-mason-uploads>` is described above.

Build resources contain a ``surrogate_key`` that corresponds to the ``X-Surrogate-Key`` HTTP header set by LTD Mason.
Through this surrogate key, Fastly can purge a specific build from its cache.

Build resources also contain a ``git_refs`` field, which is a list of Git branches that describe the documentation's version.
(Note that ``git_refs`` is a list type to accommodate multi-repository projects).
This ``git_refs`` field is used to identify Builds that can be published through an Edition.

Builds for a single Product can be discovered through the `GET /products/(slug)/builds/ <https://ltd-keeper.lsst.io/products.html#get--products-(slug)-builds->`_ endpoint

.. _ltd-keeper-editions:

Editions
^^^^^^^^

Editions are documentation published from :ref:`branches of a Git repository <edition-urls>` (e.g. ``example.lsst.io/v/{{ branch }}``.
The :ref:`default documentation published at the root URL <default-url>` is also an Edition.

Editions have a ``slug`` that corresponds to the both the Edition's :ref:`subdirectory in S3 <s3-bucket>` and the :ref:`Edition's URL path <edition-urls>`.
Editions also have a ``tracked_refs`` field that lists the set of Git branches for which the Edition serves documentation.
The ``slug`` is typically derived from ``tracked_refs``, though not necessarily.
For example, *LSST the Docs* includes a rule to transform ticket branch names like ``tickets/DM-1234`` into readable slugs like ``DM-1234``.

As well, Editions have a pointer to the Build that they are currently publishing, as well as a surrogate key.
This surrogate key is separate from the one used by the Build, and instead allows a specific Edition to be reliably purged from Fastly's cache.

.. _ltd-keeper-edition-updates:

Updating Editions with new Builds
"""""""""""""""""""""""""""""""""

An Edition can be updated by uploading new Builds with ``git_refs`` fields that match the ``tracked_refs`` field of the Edition.
Whenever a new build it posted, LTD Keeper automatically checks if that build corresponds to an Edition.
An edition can also be manually 're-built' by sending a `PATCH request to the Edition resource <https://ltd-keeper.lsst.io/editions.html#patch--editions-(int-id)>`_ that contains a new ``build_url``.
This feature is useful for scenarios where a new Build is broken and the Edition needs to be reset to a previous Build without needing to upload a completely new Build.

When an Edition is being updated, the old copy of the Edition is deleted and the new build is copied to the Edition's :ref:`location in the S3 bucket <s3-bucket>`.
During this copy operation the surrogate key metadata in the files is changed from that of the Build to the Edition.
Cache control headers are also modified to ensure that browsers request the latest version of any Edition.
By associating a stable surrogate key to an Edition, purges are easy to carry out.
Indeed, once the new build is copied into the Edition's directory, LTD Keeper :ref:`purges the Edition from the Fastly cache <fastly-cache-management>`.
This means that during the copy there is no downtime since content is served from Fastly's cache.
Once the copy is complete, and the old build purged, the updated Edition is served.
See the section :ref:`fastly-cache-management` for more details.

.. _ltd-keeper-kubernetes:

LTD Keeper Deployment with Kubernetes
=====================================

LTD Keeper is deployed in Docker containers orchestrated by Kubernetes_ on Google Container Engine.

LSST the Docs as a manifestation of DevOps culture
--------------------------------------------------

Given that LTD Keeper is a relatively modest application, it may not have been unreasonable in some organizations to deploy the application manually.
This process would likely involve provisioning a virtual machine, installing dependencies like Python on it, installing Nginx and uwsgi, installing the LTD Keeper application, and finally configuring all this software.
The problem with this approach is that it does not scale.
Each hand-configured server is a special snowflake with its own operational rules.
Without extensive documentation, such applications cannot be managed by anyone on the team of than the person who originally configured it.

The generic solution to this problem is to treat *infrastructure as code.*
In this case, the infrastructure is completely specified in code that can be checked into a Git repository and documented.
Software (like Puppet_ and Terraform_) can apply this configuration to provision and manage servers.
If a server breaks or an application needs to be updated, the operator simply applies or updates the configuration.
Treating infrastructure as code dramatically improves service reliability, improves a team's operational efficiency, and makes it easier for a team to collectively manage production services.

Infrastructure as code also gives rise to DevOps (development/operations).
In DevOps, an application's developers are also its operational administrators.
SQuaRE, the team which builds *LSST the Docs,* is an excellent example of a DevOps team.
Since we are a small, agile group, we cannot afford to hire staff who either only develop, or only operate, services.
Another advantage of DevOps is that there are massive incentives for developers to write reliable, easy to maintain, services---otherwise developers would never have time to develop new features.
Google's `Site Reliability Engineer <http://shop.oreilly.com/product/0636920041528.do>`_ program is an especially good example.
Google SREs are only 'allowed' to spend 50% of their time operating services.
If a service requires more operational effort, regular developers are temporarily drafted into an SRE team until systematic operational issues are resolved. :cite:`Murphy2016`
This feedback loop ensures that operational technical debt is kept in check.

Docker and Kubernetes
---------------------

Containers, particularly Docker_ containers, are an excellent tool for DevOps.
Essentially, a container is a very lightweight isolated Linux environment.
With containers, a developer can build and test an application in exactly the same environment as in production.
Furthermore, this environment is fully specified in a Dockerfile_ that is maintained in Git.

Containers are closely aligned with the idea of microservices: each container should only serve a specific function.
For example, a Python web application, HTTP reverse proxy, and database should all reside in separate containers.
This architecture makes containers (or rather, their images) easier to re-use across projects (see `Docker Hub`_), isolates complexity, and also makes a deployment easier to scale.

Given proliferation of containers in a typical deployment, a vibrant class of container orchestration platforms has established itself.
Examples include `Mesos and Mesosphere DC/OS <https://mesosphere.com/why-mesos/>`_, Docker `Swarm <https://www.docker.com/products/docker-swarm>`_ and `Compose <https://www.docker.com/products/docker-compose>`_, and Kubernetes_.

Ultimately we chose to deploy LTD Keeper with Kubernetes_ for several reasons.
First, we subjectively found Kubernetes easy to use.
Kubernetes is spun off of Google's proprietary `Borg <https://research.google.com/pubs/pub43438.html>`_ orchestration platform.
Thus Kubernetes inherits Google's operational experience.
We found that Kubernetes' Pod, Replication Controller, and Load Balancer service patterns (all configured with YAML) were easy to build a complete LTD Keeper deployment around (:ref:`see below <kubernetes-arch>`).

Another benefit of Kubernetes is that it allows us to deploy LTD Keeper in a cloud (saving operational costs and improving reliability) without being locked into a single cloud provider.
As a counter-example, Amazon Web Service's Elastic Container Service (ECS) provides a variant of Mesos.
If we developed an LTD Keeper deployment against ECS, we would effectively be locked into the integrated Amazon Web Services API.
By contrast, Kubernetes is positioned as a developer-friendly orchestration service that can itself by deployed on `OpenStack <http://blog.kubernetes.io/2015/05/kubernetes-on-openstack.html>`__, `Amazon Web Services <http://kubernetes.io/docs/getting-started-guides/aws/>`__, or even `atop another orchestration layer such as Mesos <http://kubernetes.io/docs/getting-started-guides/mesos/>`_.

Currently, LTD Keeper runs on a Kubernetes deployment managed by the Google Cloud Platform (`Google Container Engine`_).
At any time SQuaRE could opt to use its own Kubernetes deployment should it make strategic sense.

As a footnote, LTD Keeper also `supports Docker Compose  for local development <https://ltd-keeper.lsst.io/compose.html>`_.
The next section, however, will focus on production deployments with Kubernetes.

.. _kubernetes-arch:

Kubernetes deployment architecture
----------------------------------

The Kubernetes deployment architecture for LTD Keeper is depicted in the following diagram.

Full operational details are provided in `LTD Keeper's documentation. <https://ltd-keeper.lsst.io/#ops-guide>`__.

.. _fig-kubernetes-arch:

.. figure:: _static/kubernetes_arch.svg
   
   LTD Keeper deployment with Kubernetes. In this diagram, an incoming web request is roughly processed from top to bottom.

TLS termination service tier
----------------------------

The web request first encounters the ``nginx-ssl-proxy`` service_.
In Kubernetes, a service_ encapsulates networking details from the outside to Pods running within.
``nginx-ssl-proxy`` is unique in that is exposed to external internet traffic and gives LTD Keeper a fixed IP address.
Services like ``nginx-ssl-proxy`` also act as load balancers, distributing traffic to pods.

Pods in the ``nginx-ssl-proxy`` service are managed by a `replication controller`_ of the same name.
The role of replication controllers in Kubernetes is to launch Pods, and ensure that the desired number of Pods is active.
If a pod dies (perhaps because it crashed, or the physical node it is running on failed), the replication controller automatically schedules a replacement pod.
Replication controllers also provide a means of scaling the number of pods in a service.
A configuration template for the ``nginx-ssl-proxy`` replication controller is `available on GitHub <https://github.com/lsst-sqre/ltd-keeper/blob/master/kubernetes/ssl-proxy.yaml>`__.

Pods run under ``nginx-ssl-proxy`` each host an Nginx reverse proxy container, whose `image is made available by Google Cloud Platform <https://github.com/GoogleCloudPlatform/nginx-ssl-proxy>`_.
Containers created from this image are configured to terminate TLS traffic using our own TLS certificate, as well as permanently redirect non-TLS traffic to HTTPS.
These containers are configured with TLS certificates deployed via Kubernetes Secrets_.
A configuration template for ``nginx-ssl-proxy`` Secrets is `available on GitHub <https://github.com/lsst-sqre/ltd-keeper/blob/master/kubernetes/ssl-proxy-secrets.template.yaml>`_.

Keeper service tier
-------------------

Traffic from ``nginx-ssl-proxy`` is directed to the ``keeper`` service.
The role of this service is to provide a networking endpoint for the LTD Keeper application pods, as well as to load balance traffic to these pods.
Pods containing the LTD Keeper application are managed by a replication controller, which, again, ensures that the required number of ``keeper`` pods is available, and scales that number on demand.

Rather than create a `replication controller`_ directly, we chose to use the higher-level Kubernetes deployment_ API.
In addition to maintaining a replication controller, deployments provide a convenient API for upgrading pods.
Pod updates can be rolled out, use a canary pattern for testing, and be rolled back if necessary.
Through the deployment_ API, deploying an upgrade of LTD Keeper in production is as simple as `pushing a new image to Docker Hub, and rolling out that update with a single Kubernetes command <https://ltd-keeper.lsst.io/gke-update.html>`_.

``keeper`` pods consist of two containers that are internally networked. (*In Kubernetes, pods are a mechanism for ensuring that closely related containers are scheduled together on the same node.*)
The first pod is an Nginx reverse proxy, while the second contains the LTD Keeper codebase and runs it as a uWSGI_ application.
The latter ``uwsgi`` container receives its configuration through a `keeper-secets <https://github.com/lsst-sqre/ltd-keeper/blob/master/kubernetes/keeper-secrets.template.yaml>`_ resource.
These secrets---which include the secret key for hashing passwords, the administrator's password, API keys for AWS and Fastly, and more benign configuration such as the database URI---are mapped to environment variables that the LTD Keeper application reads to configure itself.
A `keeper-deployment.yaml template is available on GitHub <https://github.com/lsst-sqre/ltd-keeper/blob/master/kubernetes/keeper-deployment.yaml>`_.

Both containers are derived from images based on the Python 3.5 base image on Docker Hub.
Using a common base image reduces the container footprint on the host node.
See the `lsst-sqre/nginx-python-docker <https://github.com/lsst-sqre/nginx-python-docker>`_ project and the `lsst-sqre/ltd-keeper <https://github.com/lsst-sqre/ltd-keeper>`_ GitHub repositories for Dockerfiles specifying both containers' images.

Note that in the overall Kubernetes deployment there are two layers of Nginx reverse proxies: one in ``nginx-ssl-proxy`` and another embedded in ``keeper`` pods.
This architecture, while not strictly necessary, is consistent with a microservices approach.
Nginx reverse proxies in ``nginx-ssl-proxy`` are solely responsible for TLS termination, while Nginx reverse proxy containers in ``keeper`` containers provide a solid HTTP interface to the LTD Keeper uWSGI application server.
In the future, Nginx containers in ``nginx-ssl-proxy`` may be replaced by a built-in `Kubernetes Ingress Service that terminates TLS <http://kubernetes.io/docs/user-guide/ingress/#tls>`_.
As well, pairing a Nginx reverse proxy container with LTD Keeper's uWSGI container allows us to `test their interaction on a local development environment with Docker Compose <https://ltd-keeper.lsst.io/compose.html>`_.

Management pods
---------------

In general, containers run by Pods start automatically and there is no need to log into a running container.
Pods are intended to be run as immutable infrastructure.

Databases run counter to this philosophy since they are stateful.
Provisioning a new database, or migrating a database's schema, are special events that require an operator in the loop.

To deal these circumstances we use a management pod that is modified to run a container with the LTD Keeper codebase, yet not serve traffic.
When deployed, an operator can log into the management pod and run maintenance tasks included in the LTD Keeper codebase, while having access to production configurations.
LTD Keeper's documentation includes `a playbook for executing database migrations through a maintenance pod <https://ltd-keeper.lsst.io/gke-migrations.html>`_.

Database
--------

For its initial launch, *LSST the Docs'* Keeper deployment uses SQLite_ as its relational database.
Since Kubernetes pods are ephemeral, the SQLite database is stored on a Google Compute Engine persistent disk that is attached to the node hosting the ``keeper`` pod.
This choice imposes a limitation on LTD Keeper's reliability since the persistent disk can only be attached to a single node.
Ideally we would run several ``keeper`` pods simultaneously from multiple nodes.

We plan to eventually migrate from SQLite_ to a hosted relational database solution.
Given our current use of Google Cloud Platform, the `Google Cloud SQL <https://cloud.google.com/sql/>`_ hosted MySQL database is the primary choice.
Since LTD Keeper uses SQLAlchemy_ to generically interact with SQL databases, this eventual migration will be easy. 

.. _additional-reading:

Additional Resources
====================

*LSST the Docs* code is MIT-Licensed open source.
It's built either natively for, or compatible with, Python 3.
Here are the main repositories and their documentation:

- LTD Mason
  
  - Source code: https://github.com/lsst-sqre/ltd-mason
  - Documentation: https://ltd-mason.lsst.io.

- LTD Keeper

  - Source code: https://github.com/lsst-sqre/ltd-keeper.
  - Documentation: https://ltd-keeper.lsst.io.

Work on *LSST the Docs* is labeled under `'lsst-the-docs' <https://jira.lsstcorp.org/issues/?jql=labels%20%3D%20lsst-the-docs%20ORDER%20BY%20key%20ASC>`_ on LSST Data Management's JIRA.

*LSST the Docs* is part of a greater LSST Data Management documentation and communications strategy.
For more information:

- `SQR-000: The LSST DM Technical Note Publishing Platform <http://sqr-000.lsst.io>`_.
- `SQR-011: LSST Data Management Communication & Publication Platforms <http://sqr-011.lsst.io>`_.
- Resources for documentation writers in the LSST DM Developer Guide: https://developer.lsst.io.

References
==========

.. bibliography:: bibliography.bib
   :encoding: latex+latin
   :style: plain


.. _LTD Mason: https://ltd-mason.lsst.io
.. _LTD Keeper: https://ltd-keeper.lsst.io
.. _Travis CI: https://travis-ci.org
.. _Jenkins: https://jenkins.io
.. _GitHub: https://github.com
.. _Products: https://ltd-keeper.lsst.io/products.html
.. _Builds: https://ltd-keeper.lsst.io/builds.html
.. _Editions: https://ltd-keeper.lsst.io/editions.html
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
.. _Flask: http://flask.pocoo.org
.. _SQLAlchemy: http://www.sqlalchemy.org
.. _Kubernetes: http://kubernetes.io
.. _Puppet: https://puppet.com
.. _Terraform: https://www.terraform.io
.. _Docker: https://www.docker.com
.. _Docker Hub: https://www.docker.com/products/docker-hub
.. _Dockerfile: https://docs.docker.com/engine/reference/builder/
.. _Google Container Engine: https://cloud.google.com/container-engine/
.. _Service: http://kubernetes.io/docs/user-guide/services/
.. _Replication Controller: http://kubernetes.io/docs/user-guide/replication-controller/
.. _Deployment: http://kubernetes.io/docs/user-guide/deployments/
.. _Pod: http://kubernetes.io/docs/user-guide/pods/
.. _Secrets: http://kubernetes.io/docs/user-guide/secrets/
.. _SQLite: https://www.sqlite.org
.. _uWSGI: http://uwsgi-docs.readthedocs.io/en/latest/
