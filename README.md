# Pact cli Buildkite Plugin

A Buildkite Plugin which provides utility functions to allow publishing and verifying pacts as well as recording deploments.

## Examples

### Publish pacts and trigger provider re-verification in 'pr' pipeline

```yml
steps:
  - label: 'Run unit tests to generate pacts'
    commands: npm run test
    plugins:
      - tapendium/tap-build-artifact#v1.1.0:
          type: upload
          artifacts-path: pacts/**
      - tapendium/pact-cli#v1.0.0:
          pacticipant: service-name
```

### Publish pacts and record deployment in 'merge' pipeline

```yml
steps:
  - label: 'Publish pacts and record deployment'
    plugins:
      - envato/no-command#v0.1.0: ~
      - tapendium/tap-build-artifact#v1.1.0:
          type: download
          artifacts-path: pacts/**
      - tapendium/pact-cli#v1.0.0:
          pacticipant: service-name
```

### Override default settings

```yml
steps:
  - label: 'Run unit tests to generate pacts'
    commands: npm run test
    plugins:
      - tapendium/tap-build-artifact#v1.1.0:
          type: upload
          artifacts-path: pacts/**
      - tapendium/pact-cli#v1.0.0:
          pacticipant: service-name
          action: merge #valid values: pr or merge
          environment: test #default production
          main-branch: master #default is main
          pacts-path: /some/path
          version: someversion123 #default git commit

```
