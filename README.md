# Pact cli Buildkite Plugin

A Buildkite Plugin which provides utility functions to allow publishing and verifying pacts as well as recording deploments.

## Prerequisites

**Pact Broker Credentials**

When interacting with the Pact broker the following environment variables are required to be defined:

- PACT_BROKER_USERNAME: pact-user
- PACT_BROKER_PASSWORD: pact-broker-password
- PACT_BROKER_BASE_URL: pact-broker.example.com

**Buildkite GraphQL API token**

The Buildkite Graphql API is used to determine PR pipelines to run when pact verification is needed. The following environment variable is expected to be defined:

- BUILDKITE_GRAPHQL_API_TOKEN

## Examples

### Publish pacts and trigger provider re-verification in 'pr' pipeline

```yml
steps:
  - label: 'Run unit tests to generate pacts'
    commands: npm run test
    env:
      PACT_BROKER_USERNAME: pact-user
      PACT_BROKER_PASSWORD: pact-broker-password
      PACT_BROKER_BASE_URL: pact-broker.example.com
      BUILDKITE_GRAPHQL_API_TOKEN: bk-api-graphql-token
    plugins:
      - tapendium/tap-build-artifact#v1.1.0:
          type: upload
          artifacts-path: pacts/**
      - tapendium/pact-cli#v0.4.0:
          pacticipant: service-name
```

### Publish pacts and record deployment in 'merge' pipeline

```yml
steps:
  - label: 'Publish pacts and record deployment'
    env:
      PACT_BROKER_USERNAME: pact-user
      PACT_BROKER_PASSWORD: pact-broker-password
      PACT_BROKER_BASE_URL: pact-broker.example.com
      BUILDKITE_GRAPHQL_API_TOKEN: bk-api-graphql-token
    plugins:
      - envato/no-command#v0.1.0: ~
      - tapendium/tap-build-artifact#v1.1.0:
          type: download
          artifacts-path: pacts/**
      - tapendium/pact-cli#v0.4.0:
          pacticipant: service-name
```

### Skip publishing of pacts in 'pr' or 'merge' pipeline

```yml
steps:
  - label: 'Publish pacts but do not verify providers'
    commands: npm run test
    env:
      PACT_BROKER_USERNAME: pact-user
      PACT_BROKER_PASSWORD: pact-broker-password
      PACT_BROKER_BASE_URL: pact-broker.example.com
      BUILDKITE_GRAPHQL_API_TOKEN: bk-api-graphql-token
    plugins:
      - tapendium/tap-build-artifact#v1.1.0:
          type: upload
          artifacts-path: pacts/**
      - tapendium/pact-cli#v0.4.0:
          pacticipant: service-name
          skip-publish: true
```

### Skip verification of pacts in 'pr' pipeline

```yml
steps:
  - label: 'Publish pacts but do not verify providers'
    commands: npm run test
    env:
      PACT_BROKER_USERNAME: pact-user
      PACT_BROKER_PASSWORD: pact-broker-password
      PACT_BROKER_BASE_URL: pact-broker.example.com
      BUILDKITE_GRAPHQL_API_TOKEN: bk-api-graphql-token
    plugins:
      - tapendium/tap-build-artifact#v1.1.0:
          type: upload
          artifacts-path: pacts/**
      - tapendium/pact-cli#v0.4.0:
          pacticipant: service-name
          skip-verify: true
```

### Override default settings

```yml
steps:
  - label: 'Run unit tests to generate pacts'
    commands: npm run test
    env:
      PACT_BROKER_USERNAME: pact-user
      PACT_BROKER_PASSWORD: pact-broker-password
      PACT_BROKER_BASE_URL: pact-broker.example.com
      BUILDKITE_GRAPHQL_API_TOKEN: bk-api-graphql-token
    plugins:
      - tapendium/tap-build-artifact#v1.1.0:
          type: upload
          artifacts-path: pacts/**
      - tapendium/pact-cli#v0.4.0:
          pacticipant: service-name
          action: merge #valid values: pr or merge
          environment: test #default - production
          main-branch: master #default - main
          pacts-path: /some/path
          version: someversion123 #default - git commit
```
