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

The main components of *LSST the Docs* are `LTD Mason`_, `LTD Keeper`_, Amazon Web Services S3 and Route 53, and Fastly_.
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
Keeper coordinates all services, such as directing Mason uploads to S3, registering project domains on Route 53, and purging content from the Fastly_ cache.
Other projects, such as the `LSST DocHub`_, can use the LTD Keeper API to discover documentation projects and their published versions.

Finally, Fastly_ is a third-party content distribution network that serves documentation to readers.
In addition to making content delivery fast and reliable, Fastly_ allows LSST the Docs to serve highly intuitive URLs for versioned documentation.

The remainder of this technote will discuss each aspect of LSST the Docs in further details.

Walk-through of LSST the Docs
-----------------------------

To understand how LSST the Docs works, we can walk through a documentation build and publishing process.
We'll explore specific aspects of LSST the Docs in greater depth later in this document.

Stack build phase on Jenkins with `buildlsstsw.sh`
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Documentation builds begin on LSST's Jenkins system, ``ci.lsst.io``.
As is already the case, a user triggers a build of the LSST Stack by entering what Eups product should be built (e.g., `lsst_apps``) along with specific development branches (e.g., ``tickets/DM-9999``) to pull from.
Jenkins triggers the ``buildlsstsw.sh`` script, which in turn runs lsstsw's rebuild command to clone the Stack repositories, then build and test the Stack itself via Eups and Scons commands.

This *existing service* does two useful things for the documentation build.
First, the Stack is built and installed (such that it is importable as a Python package) with the full checked-out source available on a file system.
Second, the :command:`scons doc` command produces Doxygen XML artifacts for each package.

Documentation build phase with `ltd-mason`
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When the build is complete, ``buildlsstsw.sh`` calls ``ltd-mason``, which also runs on Jenkins.
The role of ``ltd-mason`` is to combine documentation sources from each package's locally cloned Git repository and run Sphinx_\ ’s ``sphinx-build`` command to compile a static documentation website (see ).
The interface between ``buildlsstsw.sh`` and ``ltd-mason`` is a well-specified YAML-encoded manifest file that tells ``ltd-mason`` about the documentation project that the user is building, what version of the documentation is being built, and where each cloned package repository can be found on the Jenkins file system (see :ref:`yaml-manifest`).
In this way, ``ltd-mason`` is fully isolated from any dependency on Eups or Scons (and likewise, the LSST Stack is isolated from any dependency on Sphinx and related Python tools).

Documentation build publishing phase with `ltd-mason`, `ltd-keeper` and S3
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Run by ``ltd-mason``, Sphinx_ yields a static documentation website.
``ltd-mason`` registers this build with ``ltd-keeper``, a RESTful web application that manages the state of documentation publications, by sending a ``POST /products/<product>/builds/`` request.
``ltd-keeper`` replies with information about the S3 bucket and bucket 'directory' where files for this documentation build should be uploadeded.

See :ref:`ltd-keeper` for further details about the ``ltd-keeper`` application and API

Publishing documentation editions with ltd-keeper and Fastly
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Notice that ``ltd-mason``\ ’s scope is only to upload discrete *builds* of a software product's documentation to S3.

However, ``ltd-mason`` passes on information from the YAML manifest about the version composition of the software being documented.
These documentation builds might reflect the latest ``master`` branches of the software, a development ticket branch, or even updated documentation for previous software releases
LSST the Docs supports publishing several multiple versions of a product's documentation simultaneously through the concept of documentation *Editions*.
Editions have a fixed URL, but can have updated content.

.. TODO: add reference to Product / Build / Edition resource

``ltd-keeper`` watches for new builds that correspond to an Edition, and automatically updates the Edition by serving the Edition from the new build.
Fastly and its Varnish layer allows us to point an Edition to a new build in S3.
See :ref:`s3-hosting` for further details.

Documentation maintenance and discovery via the `ltd-keeper` API
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Once documentation is published, there will be several consumers of information about the available editions of documentation.
The ``ltd-keeper`` API and internal code is designed to accommodate these use cases, such as:

- React components in DM documentation and websites will send ``GET products/<product>/versions`` requests to ``ltd-keeper`` to populate lists of available documentation.
- A build cleanup service to remove old developer documentation versions builds.

In the remaining sections of this document we explore individual components mentioned in the walk-through of LSST the Docs in greater detail.

.. _doc-source:

Structure of documentation repositories and sources
===================================================

Documentation repositories
--------------------------

Documentation exists in two strata: in the repositories of individual Stack packages, and in the product's doc repo.

The role of documentation embedded in packages is to document/teach the APIs and tasks that are maintained in that specific package.
Co-locating documentation in the code's Git repository ensures that documentation is versioned in step with the code itself.
The documentation for a package should also be independently buildable by a developer, locally.
Although broken cross-package links are inevitable with local builds, such local builds are critical for the productivity of documentation writers.

The product's doc repo is a Sphinx project that produces the coherent documentation structure for a Stack product itself, such as ``lsst_apps`` or ``qserv``.
It establishes the overall table of contents that links into package documentation, and also contains its own content that applies at a Stack product level.
The product doc repo, in fact, is the lone Sphinx project seen by the Sphinx builder; content from each package is linked at compile time into the umbrella documentation repo.

The product's doc repo is not distributed by Eups to end-users, so it is not an Eups package.
Instead, Eups tags for releases are mapped to branch names in the product doc repo.

.. _doc-source-pkg-organization:

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

.. _doc-product-organization:

Product documentation organization
----------------------------------

When ``ltd-mason`` builds documentation for a product, it links documentation resources from individual package repositories into a cloned copy of the product's documentation repository.

The links are arranged as so:

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

See :ref:`ltd-mason` for further details about the documentation build process.

..
  .. _sconsutils-modifications:
  
  Overview of the Jenkins-hosted build system
  ===========================================
  
  How Jenkins builds and tests the stack
  --------------------------------------
  
  TODO.
  
  Modifying sconsUtils to build Doxygen XML
  -----------------------------------------
  
  Our C++ API reference uses Doxygen to inspect the C++ source and Breathe_ to bridge Doxygen's output to Sphinx autodoc.
  Breathe_ operates specifically on Doxygen's XML output.
  We have modified the Doxygen builder in `sconsUtils's builders.py <https://github.com/lsst/sconsUtils/blob/u/jonathansick/new-docs/python/lsst/sconsUtils/builders.py>`_ to generate this XML during the normal ``scons doc`` build target.
  
  .. literalinclude:: snippets/scons_doxygen_builder.py
     :language: python
     :emphasize-lines: 9
  
  Generated XML is installed in the ``<package_name>/doc/XML/`` directory.
  
  This modification is currently available in the ``u/jonathansick/new-docs`` branch of ``sconsUtils``.

  .. _lsstsw-modifications:
  
  Modifications to buildlsstsw.sh
  -------------------------------
  
  TODO.
  
  ``buildlsstsw.sh`` will be modified to call :ref:`ltd-mason <ltd-mason>` to initiate a documentation build.
  The interface between ``buildlsstsw.sh`` and :ref:`ltd-mason <ltd-mason>` is a YAML-encoded file or stream.

.. _ltd-mason:

The `ltd-mason` documentation build service
===========================================

``ltd-mason`` is a Python command line application that operates on the Jenkins build server, and is an after-burner for the regular software build process.
``ltd-mason``\ ’s source is available on GitHub at https://github.com/lsst-sqre/ltd-mason.

.. _yaml-manifest:

The `buildlsstsw.sh` - `ltd-mason` YAML Manifest interface
----------------------------------------------------------

Although ``ltd-mason`` runs on Jenkins in the Stack build environment, ``ltd-mason`` is not integrated tightly with LSST's build technologies (Eups and Scons).
This choice allows our build system to evolve independently of the Stack build environment, and can even be accomodate non-Eups based build envionments.

The interface layer that bridges the software build system (``buillsstsw.sh``) to the documentation build system (``ltd-mason``) is a Manifest file, formatted as YAML.
Note that this YAML manifest is the sole input to ``ltd-mason``, besides a security key configuration files. 

A minimal example of the manifest:

.. literalinclude:: _static/manifest.yaml
   :language: yaml

The fields are:

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

   *FIXME: is this necessary since the information is available in ltd-keeper?*

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

.. _ltd-mason-build:

Documentation build process
---------------------------

Given the input file, ``ltd-mason`` runs the following process to build a software product's HTML documentation:

1. Clone the product's documentation repo and checkout the appropriate Git reference (based on  the YAML ``doc_repo`` key).

2. Link the `doc/` directories of each installed package (in :file:`lsstsw/install/`) to the cloned product documentation repository (see :ref:`doc-source-pkg-organization`).

   In the product documentation repository, the package doc links are:

   .. code-block:: text

      <product_doc_repo>/
         # ...
         <package_name>/
            # link to contents of <package_repo>/doc/
            # except _static/
         _static/
            # ...
            <package_name>/ -> <package_repo>/doc/_static/

3. Run a Sphinx build of the complete product documentation with :command:`sphinx-build`.

The result is a build static HTML site.
The next section describes how ``ltd-mason`` publishes this documentation to the web..

.. _ltd-mason-publishing:

Documentation publishing process
--------------------------------

TODO

.. _ltd-keeper:

The `ltd-keeper` microservice for managing documentation lifecycles and version discovery
=========================================================================================

``ltd-keeper`` is a backend microservice that has a database of available documentation versions, a RESTful API so that these documentation versions can be managed and discovered, and hooks into Cloud resources (AWS S3 and Route 53, Fastly, Slack and GitHub).

The source is available on GitHub at https://github.com/lsst-sqre/ltd-keeper.
User and DevOps documentation for ``ltd-keeper`` is available at https://ltd-keeper.lsst.io. 

.. _ltd-keeper-resources:

`ltd-keeper` API resources and concepts
---------------------------------------

As a RESTful application, ``ltd-keeper`` makes resources available through URL endpoints that can be acted upon with HTTP methods.

.. _ltd-keeper-products:

Products
^^^^^^^^

Products, ``/products/`` are the root resource.
A product corresponds to a software projects (such as ``lsst_apps`` or qserv) or a pure documentation project, such as a technical note or design document.

An administrator creates a new Product with `POST /products/ <khttp://ltd-keeper.lsst.io/en/tickets-dm-4950/products.html#post--v1-products->`_ and retrieves information about a single product with `GET /v1/products/(slug) <http://ltd-keeper.lsst.io/en/tickets-dm-4950/products.html#get--v1-products-(slug)>`_.
A listing of all products is obtained with `http://ltd-keeper.lsst.io/en/tickets-dm-4950/products.html#get--v1-products- <http://ltd-keeper.lsst.io/en/tickets-dm-4950/products.html#get--v1-products->`_.

See the `/products/ resource documentation <http://ltd-keeper.lsst.io/en/tickets-dm-4950/products.html>`_ for a full listing of the methods and metadata associated with a Product.

.. _ltd-keeper-builds:

Builds
^^^^^^

Builds are discrete, immutable uploads of a Product's documentation created with ``ltd-mason``.

Builds are created with a `POST /v1/products/(slug)/builds/ <http://ltd-keeper.lsst.io/en/tickets-dm-4950/products.html#post--v1-products-(slug)-builds->`_.

See the `/builds/ resource documentation <http://ltd-keeper.lsst.io/en/tickets-dm-4950/builds.html>`_ for a full listing of the methods and metadata associated with a Build.

.. _ltd-keeper-editions:

Editions
^^^^^^^^

Editions are documentation published to the end-user with consistent URLs corresponding to a semantic version such as a release ('v1'), the HEAD of development ('latest') or even a ticket branch ('tickets-dm-nnnn').

Editions are lightweight pointers to Builds.
An Edition is updated by re-pointing to a different Build using the `POST /v1/editions/(int: id)/rebuild <http://ltd-keeper.lsst.io/en/tickets-dm-4950/editions.html#post--v1-editions-(int-id)-rebuild>`_ method.
When an Edition is re-built, no files are moved.
Instead ``ltd-keeper`` modified the Varnish cache layer provided by Fastly to re-route URLs for an edition to a new build in the S3 bucket.
See :ref:`s3-hosting` for more information.

See the `/editions/ resource documentation <http://ltd-keeper.lsst.io/en/tickets-dm-4950/editions.html>`_ for a full listing of the methods and metadata associated with an Edition.

..
  Periodic maintenance tasks
  --------------------------
  
  Ancillary to the ``ltd-keeper`` web app that serves the RESTful API would be worker tasks that are triggered periodically to maintain the documentation.
  Celery can be used to mange these tasks.
  
  One such task would examine the ``date_last_modified`` for each of all ``branch``-type versions of documentation, and delete any version that has not been updated within a set time period.

.. _s3-hosting:

Serving multiple documentation products and editions from S3 with Fastly
========================================================================

.. _hosting-service:

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
