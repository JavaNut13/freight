# Freight

_Automatic Docker Deployment_

The aim of Freight is to ship a set of **unrelated** applications to the same server, each one running in isolation in a Docker container. The configuration for one server should be able to be moved to another to easily deploy the same set of applications on a different server - making migrating between providers or upgrading the host OS trivial.

The workflow for deploying or updating an application should be something like:

+ In the project:
  + Make some fixes/ features/ bugs
  + Commit, tag and push to a git repo
+ In the config repo:
  + Edit or add the config of the project with the new tag
  + Push the change to the server(s)
  + Freight automatically checks the version numbers and updates applications that have a new tag


## Current usage:

    freight <version store> <app config...>

`version store`: File that stores the currently deployed version of each app.
  Will be created if it does not exist. Should be consistent between deployments

`app config`: File or files that contain config for applications. These are bash
files, with a DSL-like syntax for defining apps:

    my-server() {
      url=https://example.com/my_git_repo
      version=3.1.4
    }
    app my-server

The apps and files will be processed/ loaded in order.

> NOTE: All config files are bash scripts, this makes the tool easy to develop
but poses a security hole. Don't put untrusted content in your config or
verion files!
