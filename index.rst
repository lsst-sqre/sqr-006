:tocdepth: 1

Introduction
============

LSST Data Management is adopting a new ecosystem for documenting software.
Rather than using a wiki, which is divorced from the codebase, we are tightly integrating code and documentation.
We use Sphinx_ to generate static documentation websites derived from text and images that live in the code's Git repository, and mine the Python docstrings and C++ comments to automatically build API references.
The advantages of this architecture are many: developers can update both code and docs in the development branch, documentation is intrinsically versioned in step with the code, and since the docs are static files built by a Python-based system we have copious opportunities to provide bespoke tooling and automation to the doc platform.

Read the Docs
-------------

A key role for automation is continuously documentation deployment.
Whenever commits are pushed to GitHub, documentation should be re-built and served to the web.
`Read the Docs`_ has made continuous deployment of documentation services trivial to open source projects that use Sphinx_.
Through a `GitHub Service Hook`_, `Read the Docs`_ is notified when a Sphinx_-based project has new commits.
`Read the Docs`_ then clones the Git repository, builds the Sphinx_ project (i.e., ``make html``) and deploys the HTML product.
This platform is successfully used a large number of major Python packages, such as `Astropy`_.

LSST would also use `Read the Docs`_ to deploy documentation if not for complications involved in automatically building code API reference documentation.
Numpydoc_ is a Sphinx_ extension that inspects Python docstrings to generate accurate and well-organized API references.
To accomplish this docstring inspection, Numpydoc_ must be able to *import* the code being documented from within Python.
In other words, generating documentation requires that the software being documented be built and installed.
Naturally, `Read the Docs`_ accomplishes this by running a Python package's ``setup.py install`` command, which installs a Package's dependencies, triggers builds of any C extensions, and finally installs the Python package itself.

Since LSST does uses Scons and Eups rather than Python's standard Setuptools/Distutils (i.e., a ``setup.py`` file) in its build process, standard tools such as `Read the Docs`_ do not know how to build LSST software.
We are compelled, then, to build an equivalent of the `Read the Docs`_ service to build and deploy documentation for LSST's Eups and Scons-based software projects.

Components of the documentation deployment service
--------------------------------------------------

This document describes the design and implementation of a `Read the Docs`_-style service to continuously deploy software documentation for LSST.
Implementing this service requires both building new tools and adding to our existing build infrastructure at multiple levels.
The key components are outlined here and expanded upon further in this technical note.

:ref:`Documentation repositories <doc-source>`
   The LSST Stack is a conglomerate of Git repositories (Eups packages) that are developed and versioned independently, yet built together.
   The documentation must also follow this model.

   Documentation sources exist at two levels:

   1. Individual package's Git repositories. The these repositories, a :file:`doc/` directory contains a Sphinx_ project with reStructuredText pages (and associated images, Jupyter Notebooks and example docs) that document and teach that package. Those pages also have stubs for API reference documentation that are built through Numpydoc_ and Breathe_/Doxygen. These Sphinx projects should be buildable in a standalone state.

   2. An umbrella Sphinx project that itself contains documentation for the software as a whole (installation guides, release notes, quick start guides and tutorials), but also has hooks into the documentation of individual packages.
      This umbrella Sphinx project should be an Eups package itself so that it can be versioned with stack releases.
      When this umbrella Sphinx project is built it incorporates content from each packages :file:`doc/` directory.
      For science pipelines this umbrella doc repository is http://github.com/lsst-sqre/pipelines_docs.

:ref:`Scons and sconsUtils <sconsUtils-modifications>`
   Scons is the build tool for the LSST Stack, with sconsUtils_ containing Stack-specific customizations.
   sconsUtils_ is modified in two ways to accommodate documentation builds:

   1. Have Doxygen generate XML output that can be used by Breathe_ to generate a C++ API reference (Breathe_ bridges Doxygen XML to Sphinx_)
   2. Addition of a ``sphinx`` target to the Scons build so that developers can trigger a Sphinx build for an individual Stack package.

:ref:`lsstsw <lsstsw-modifications>`
   lsstsw_ is the build system used by Jenkins for building and continuously integrating our software.
   lsstsw_ has also been co-opted by developers as a useful local development tool.

:ref:`Jenkins <jenkins-modifications>`
   TODO

:ref:`Documentation web hosting and versioning <web-hosting>`
   Sphinx_ generates static files, which makes hosting trivial, reliable, and highly performant.
   We can use Amazon S3 to serve the docs, possibly in conjunction with a CDN to improve page loading for users located across the globe.

   Multiple versions of the docs must be served simultaneously for each release, the bleeding-edge master version, and developer's builds.
   Like `Read the Docs`_ we accommodate this requirement simply by serving each version its own well-defined sub-directory.
   The root URL redirects to either the latest development version of the documentation, or the documentation for the latest release (at our choosing).

:ref:`Doc-tender microservice <doc-tender>`
   Although the documentation is served as static files, there is still a need for a backend microservice.
   It has two roles:

   1. Provide a REST API for discovering available versions of docs. Thus a React component, for example, can be embedded in the docs or a DM doc landing page that allows a user to select what version of the docs they want to see.
   2. Deleting expired ticket branch builds.

.. _doc-source:

Structure of our documentation repositories and sources
=======================================================

TODO.
Structure of Sphinx package repositories and how they can be integrated at build-time with the umbrella Sphinx project.
Dicussion of requirements to build the C++ and Python API references.

.. _sconsutils-modifications:

Modifications to sconsUtils
===========================

TODO.
How doxygen XML is built; and addition of a build target for Sphinx.

.. _lsstsw-modifications:

Modifications to lsstsw
=======================

TODO.
There should be an lsstsw script that triggers the overall build process for both local developers and Jenkins.

.. _jenkins-modifications:

Jenkins automation
==================

TODO.
Discussion of affordances in the existing LSST DM Jenkins CI infrastructure to trigger a doc build, copy results to the web host, and add the documentation record to the doc-tender's database.

.. _web-hosting:

Web hosting and organization of documentation versions
======================================================

TODO.

.. _hosting-service:

Hosting infrastructure
----------------------

S3.

.. _directory-structure:

Hosting versions in sub-directories
-----------------------------------

Directory structure.

.. _doc-tender:

Doc-tender microservice for managing documentation lifecycles and version discovery
===================================================================================

TODO.

.. _Sphinx: http://sphinx-doc.org
.. _Read the Docs: http://readthedocs.org
.. _GitHub Service Hook: https://developer.github.com/webhooks/#service-hooks
.. _Astropy: http://docs.astropy.org
.. _Numpydoc: https://github.com/numpy/numpydoc
.. _sconsUtils: https://github.com/lsst/sconsUtils
.. _Breathe: http://breathe.readthedocs.org/en/latest/
.. _lsstsw: https://github.com/lsst/lsstsw
