:tocdepth: 1

Introduction
============

LSST Data Management is adopting a new ecosystem for documenting software.
Rather than using a wiki, which is divorced from the codebase, we are tightly integrating code and documentation.
We use Sphinx_ to generate static documentation websites derived from text and images that live in the code's Git repository, and mine the Python docstrings and C++ comments to automatically build API references.
The advantages of this architecture are many: developers can update both code and docs in the development branch, documentation is intrinsically versioned in step with the code, and since the docs are static files built by a Python-based system we have copious opportunities to provide bespoke tooling and automation to the doc platform.

Read the Docs
-------------

A key role for automation is to continuously deploy the documentation.
Whenever commits are pushed to GitHub, documentation should be re-built and served to the web.
This improves developer efficiency, and promotes documentation to being a first class product of our engineering team.

`Read the Docs`_ has made continuous deployment of documentation trivial for open source projects that use Sphinx_.
Through a `GitHub Service Hook`_, `Read the Docs`_ is notified when a Sphinx_-based project has new commits.
`Read the Docs`_ then clones the Git repository, builds the Sphinx_ project (i.e., ``make html``) and deploys the HTML product.
This platform is successfully used a large number of major Python packages, such as `Astropy`_.

LSST would also use `Read the Docs`_ to deploy documentation if not for complications involved in automatically building our software stack as a prerequisite for automatically generating the API reference documentation.
Numpydoc_ is a Sphinx_ extension that inspects Python docstrings to generate accurate and well-organized API references.
To accomplish this docstring inspection, Numpydoc_ must be able to *import* the code being documented from within Python.
In other words, generating documentation requires that the software being documented be built and installed.
Naturally, `Read the Docs`_ accomplishes this by running a Python package's ``setup.py install`` command, which installs the package's dependencies, triggers builds of any C extensions, and finally installs the Python package itself.

Since LSST uses Scons and Eups rather than Python's standard Setuptools/Distutils (i.e., a ``setup.py`` file) in its build process, standard tools such as `Read the Docs`_ do not know how to build LSST software.
We are compelled, then, to build an equivalent of the `Read the Docs`_ service to build and deploy documentation for LSST's Eups and Scons-based software projects.

User stories
------------

To lay the ground work for designing an LSST adaptation of `Read the Docs`_, let us imagine how the platform should work for the two key stakeholders: DM developers and readers.

Developer user story
^^^^^^^^^^^^^^^^^^^^

A developer works on a ticket branch for a specific package in the LSST Stack.
The ticket work impacts the documentation, so the developer also changes the C++ doxygen comments and Python docstrings, along with with reStructuredText-formatted content in the package's user guide, located in the :file:`/doc/` directory.
As is already standard practice, the developer verifies that the code passes all tests by running that package's branch against the rest of the Stack using `DM's Jenkins server <https://ci.lsst.codes/job/stack-os-matrix/build?delay=0sec>`_.
At the same time that the Stack is being built and tested, the Jenkins will also trigger a build of the documentation site for the product the developer is building (Science Pipelines, Qserv, etc.).
This version of the product's docs will feature the ticket branch version of the docs being developed alongside master branch versions of other packages' docs.
When the docs are published, they appear at a well-known URL such as ``pipelines.lsst.io/tickets-wxyv``.
The build system also sends a HipChat message with the URL of the development docs, allowing the developer to find and browse the new doc build quickly.

The HipChat message might also indicate a documentation build error, with a link to the Sphinx_ build log.
This error might be due to an error in Sphinx_\ 's configuration, a syntax error in the docstrings or reStructuredText content, or a CI testing failure of the tutorials and examples in the documentation against this version of the code.
Now, before ticket branch is merged, the developer knows to fix these build issues, or update example code to the latest software version.

As part of the code review, the developer can link to the new docs.
The developer can demonstrate, and the reviewer can verify, that the documentation adequately covers the updated functionality of the Stack.

Once the ticket branch is approved and merged to ``master``, the build system with again trigger a documentation build, and latest version of the product's documentation, which is seen by default, will be published automatically.

In conclusion, by integrating doc builds with developer builds, the documentation will be built more reliably (by identifying build errors), will be more accurate (by running the example code against the latest software), and be up-to-date (by making documentation readily available in the code review process).

Reader user story
^^^^^^^^^^^^^^^^^

As part of our community and marketing, the documentation sites for our software products become the *homepages* for those products on the Internet.
Any discussion about LSST Science Pipelines will link to ``http://pipelines.lsst.io``, for example.

Being the product's homepage, the documentation needs serve many roles for many audiences.
New visitors will want to quickly grasp what the product does and *feels like* through feature overviews and tutorials.
New *users* will want to be able to quickly install the product and get hands-on experience with low-buy-in tutorials.
Experienced users will come back to the documentation frequently to read advanced tutorials, guides for specific functionality, and API references to build their own tools on top of the product.
Thus unlike DM's previous documentation experience, which was divided between a Confluence wiki and a doxygen-generated API reference and user guide, readers need a tightly curated documentation experience that guides them from interested party, to new user, to power user and developer.

By default, a reader viewing ``http://pipelines.lsst.io`` will be redirected to ``http://pipelines.lsst.io/latest`` and be able to read about the latest (i.e., ``master`` branch) version of the product since this is *probably* what a new visitor will interested in.
For those already invested in the product who are running a released version of the production for their science project will instead want to see documentation for that release.
A UI component in the documentation site allows the reader to select and be redirected to that version of the documentation.
The same UI component can be used in web pages that index web sites for various DM projects.

LSST the Docs: a microservice architecture
==========================================

This document describes our implementation of a continuous documentation distribution service that accommodates the LSST Stack's Eups-based package architecture.
We call this system *LSST the Docs*, or LTD.

The LSST the Docs is implemented as a collection of new and adapted *microservices*.
A microservice architecture provides isolation of implementation details.
For example, the service that builds the software stack needs to know about Eups, but isolates that complexity from the services that build the documentation and track published versions of the documentation.
The microservices communicate with each other through well-specified interfaces.
This architecture provides efficiency to the development team in that each component can be developed and maintained independently.

The diagram below describes the components of LSST the Docs, and how they interface with each the.

.. figure:: /_static/ltd_arch.svg

   Architecture of LSST the Docs (LTD).

Stack build phase on Jenkins with `buildlsstsw.sh`
--------------------------------------------------

Documentation builds begin on LSST's Jenkins system, ``ci.lsst.io``.
As is already the case, a user triggers a build of the LSST Stack by entering what Eups product should be built (e.g., `lsst_apps``) along with specific development branches (e.g., ``tickets/DM-9999``) to pull from.
Jenkins triggers the ``buildlsstsw.sh`` script, which in turn runs lsstsw's rebuild command to clone the Stack repositories, then build and test the Stack itself via Eups and Scons commands.
This *existing service* does two useful things for the documentation build.
First, the Stack is built and installed (such that it is importable as a Python package) with the full checked-out source available on a file system.
Second, the ``scons`` command produces Doxygen XML artifacts for each package.

Documentation build phase with `ltd-mason`
------------------------------------------

When the build is complete, ``buildlsstsw.sh`` calls ``ltd-mason``, which also runs on Jenkins.
The role of ``ltd-mason`` is to combine documentation sources from each package's locally cloned Git repository and run Sphinx_\ 's ``sphinx-build`` command to compile a static documentation website.
The interface between ``buildlsstsw.sh`` and ``ltd-mason`` is a well-specified YAML-encoded stream that tells ``ltd-mason`` about the documentation project that the user is building, what version of the documentation is being built, and where each cloned package repository can be found on the Jenkins file system.
In this way, ``ltd-mason`` is fully isolated from any dependency on Eups or Scons (and likewise, the LSST Stack is isolated from any dependency on Sphinx and related Python tools).

Documentation site publishing phase with `ltd-mason` and `ltd-keeper`
---------------------------------------------------------------------

Next, the built resources must be published to a static web server.
An S3 bucket is an ideal server for static websites.
In LSST the Docs' microservice architecture, the ``ltd-keeper`` service that is responsible for tracking the versions of the documentation that are published.
``ltd-keeper`` consists of a relational database that is exposed through a REST API.

Thus when ``ltd-mason`` completes a build, it sends a ``POST products/<product>/versions/<slug>`` REST request to ``ltd-keeper``.
``ltd-keeper`` persists the new or updated documentation version information to its database and provisions an S3 bucket for it, if necessary.
``ltd-keeper`` responds to the REST request with information about the S3 bucket that ``ltd-mason`` should upload to.

Documentation maintenance and discovery via the `ltd-keeper` API
----------------------------------------------------------------

Once documentation is published, there will be several consumers of information about the available versions of documentation.
The ``ltd-keeper`` API and internal code is designed to accommodate these use cases, such as:

- React components in DM documentation and websites will send ``GET products/<product>/versions`` requests to ``ltd-keeper`` to populate lists of available documentation.
- A tag cleanup service will send a ``DELETE products/<product>/versions/<slug>`` to remove old developer documentation versions.

.. _doc-source:

Structure of documentation repositories and sources
===================================================

Documentation repositories
--------------------------

Documentation exists in two strata:in the repositories of individual Stack packages, and in the product's doc repo.

The role of documentation embedded in packages is to document/teach the APIs and tasks that are maintained in that specific package.
Co-locating documentation in the code's Git repository ensures that documentation is versioned in step with the code itself.
The documentation for a package should also be independently buildable by a developer, locally.
Although broken cross-package links are inevitable with local builds, such local builds are critical for the productivity of documentation writers.

The product's doc repo is a Sphinx project produces the coherent documentation structure for a Stack product itself, such as ``lsst_apps`` or ``qserv``.
It establishes the overall table of contents that links into package documentation, and also contains its own content that applies at a stack product level.
The product doc repo, in fact, is the lone Sphinx project seen by the Sphinx builder; content from each package is linked at compile time into the umbrella documentation repo.

The product's doc repo is not distributed Eups to end-users, so it is not an Eups package.
Instead, Eups tags for releases are mapped to branch names in the product doc repo.

Package documentation organization
----------------------------------

To effect the integration of package documentation content into the umbrella documentation repo, each package must follow the following layout:

.. code-block:: text

   <package_name>/
      ...
      doc/
         Makefile
         conf.py
         index.rst
         <package_name>/
            index.rst
            ...
         _static/
            <package_name>/
               <image files>...

The role of the :file:`doc/Makefile`, :file:`doc/conf.py` and :file:`doc/index.rst` files are solely to allow local builds.
Builds of the package documentation repository will only link in content under the :file:`doc/<package_name>/` and :file:`doc/_static/<package_name>/` directories.

.. _sconsutils-modifications:

Overview of the Jenkins-hosted build system
===========================================

How Jenkins builds and tests the stack
--------------------------------------

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

.. _ltd-mason:

The `ltd-mason` microservice for building and publishing Sphinx documentation
=============================================================================

``ltd-mason`` builds Sphinx documentation on Jenkins after an LSST Stack product is built.

The source is available on GitHub at https://github.com/lsst-sqre/ltd-mason.

.. _ltd-mason-yaml:

The `buildlsstsw.sh` - `ltd-mason` manifest YAML interface
----------------------------------------------------------

The manifest is a YAML-encoded stream or file produced by ``buildlsstsw.sh`` and taken as input to the :command:`ltd-mason` command line application.

A minimal example of the manifest:

.. literalinclude:: _static/manifest.yaml
   :language: yaml

The fields are:

refs
   This is the set of branches or tags that a user entered upon triggering a Jenkins build of the software.
   E.g. ``[tickets/DM-XXXX, tickets/DM-YYYY]``.
   This field defines the *version slug* of the published documentation.

doc_repo
   Information about the product documentation repository.

   - ``url`` is a Git repository URL
   - ``ref`` is a Git ref (commit, branch or tag) of the product documentation repository to checkout.

packages
   The objects in the ``packages`` field refer to Stack packages.
   Keys are package names (as defined by the name of their Git repositories), and values are dictionaries with the following fields:

   - ``dirname`` is the path of the *installed* package in ``lsstsw/install/``
   - ``url`` is the package's Git URL.
   - ``ref`` is the Git reference (branch, commit or tag) for the package as it was built by Jenkins.

Documentation build process
---------------------------

TODO

Documentation publishing process
--------------------------------

TODO

.. _web-hosting:

Web hosting and organization of documentation versions
======================================================

.. _hosting-service:

Hosting infrastructure
----------------------

Since Sphinx_ generates static files, there is no need to have a live webserver (such as Nginx or Apache) running a web application involved in hosting.
Instead we can can use a static file server.
Our preference is to use a commodity cloud file host, such as Amazon S3 or GitHub pages, since those are far more reliable and have less downtime than any resources that LSST DM can provide in house at this time.
GitHub Pages has the advantage of being free with an automatically-configured CDN.
However, S3 is more flexible and fits better with our team's DevOps experience.

.. _directory-structure:

Hosting versions in sub-directories
-----------------------------------

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

.. _ltd-keeper:

The `ltd-keeper` microservice for managing documentation lifecycles and version discovery
=========================================================================================

``ltd-keeper`` is a backend microservice that has a database of available documentation versions, a RESTful API so that these documentation versions can be managed and discovered, and finally a set of service workers that maintain the documentation resources.

Database schema
---------------

There are two database tables, although additional tables may be useful for user accounts and other configuration details.

projects
^^^^^^^^

Information about software products.

``eups_package``
   Name of the top-level Eups package for the software product (e.g., ``lsst_apps``.

``name``
   Human-friendly name for the software product.

``bucket``
   S3 bucket identifier where documentation for this project is contained.

``domain``
   Domain where documentation is hosted (e.g., ``pipelines.lsst.io`` or ``qserv.lsst.io``).

versions
^^^^^^^^

Information about published versions of documentation for products.

``project``
   Foreign key to the project for this documentation.

``kind``
   ``master``, ``branch`` or ``eups_tag``.

``name``
   URL-safe name of this version; also the directory where the documentation is stored inside the bucket.

``date_created``
   Date when this version of the documentation was first published.

``date_last_modified``
   Most recent date when this version of the documentation was updated (through a new Jenkins build).

``builder``
   For ``branch``-type documentation, this field will correspond to the GitHub user who triggered the Jenkins build.

RESTFul API
-----------

Products API
^^^^^^^^^^^^

- ``POST products/<product>`` --- Create a new documentation product. Message body is JSON.
- ``PATCH products/<product>`` --- Partial update to metadata about a product. Message body is JSON.
- ``GET products/<product>`` --- Get information about a software product. JSON with row from ``products`` table.
- ``GET products/<product>/versions`` --- Shortcut to list all available versions. This would be used by a version selection UI component.
- ``DELETE products/<product>`` --- Delete a software product (also deletes its documentation on S3).

Version API
^^^^^^^^^^^

- ``POST products/<product>/versions/<slug>`` --- Create a new version. The message body is JSON with information to create a new row in the ``versions`` database. The documentation file upload itself is done by ``ltd-mason``.
- ``PATCH products/<product>/versions/<slug>`` --- Partial update to metadata about a version. Message body is JSON. For example, updating the ``date_last_modified``.
- ``GET products/<product>/versions/<slug>`` --- Get all metadata about a version.
- ``DELETE products/<product>/versions/<slug>`` --- Delete a version of the documentation. Deletes both the DB record and the documentation on S3.


Periodic maintenance tasks
--------------------------

Ancillary to the ``ltd-keeper`` web app that serves the RESTFul API would be worker tasks that are triggered periodically to maintain the documentation.
Celery can be used to mange these tasks.

One such task would examine the ``date_last_modified`` for each of all ``branch``-type versions of documentation, and delete any version that has not been updated within a set time period.

Other aspects (a wishlist)
--------------------------

- Users / API keys / authentication.
- Integration with HipChat to message a developer the URL of their build documentation.
- Providing access to build logs from Jenkins to identify issues.
- Admin Web dashboard that consumes the API.
- Full text search through ElasticSearch. This could be part of a larger DM documentation search system, however.

.. _Sphinx: http://sphinx-doc.org
.. _Read the Docs: http://readthedocs.org
.. _GitHub Service Hook: https://developer.github.com/webhooks/#service-hooks
.. _Astropy: http://docs.astropy.org
.. _Numpydoc: https://github.com/numpy/numpydoc
.. _sconsUtils: https://github.com/lsst/sconsUtils
.. _Breathe: http://breathe.readthedocs.org/en/latest/
.. _lsstsw: https://github.com/lsst/lsstsw
