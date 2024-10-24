# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.2] - 2024-10-24

- Update dependencies.

## [0.3.1] - 2023-11-12

- Update dependencies.

## [0.3.0] - 2023-08-25

- **BREAKING:** Return entire response from setup/3 and setup_await/2, this changes the return type.
- Fixed issues for certain websocket servers that return extra data in the upgrade/setup phase (ws://echo.websocket.events/.ws)
- Fixed defaults for non-TLS connections, was causing `:badarg` with `:gen_tcp`
- Updated some dependencies

## [0.2.4] - 2023-06-12

- Rolled back fix from 0.2.3
- Fixed some issues with websocket state

## [0.2.3] - 2023-06-12

- Fixed some issues with websocket state

## [0.2.2] - 2023-05-12

- Added some guards
- Fixed some specs
- Updated some docs

## [0.2.1] - 2023-04-07

- Handle errors a bit better by issuing :stop
- Fixed docs, dialyzer errors, and some specs

## [0.2.0] - 2023-03-19

### Breaking

- Change Wind.Stream to Wind.Client to keep namespace for future functionality.

## [0.1.0] - 2023-03-17

- Initial implementation
    - includes basic tools to build websocket clients, more to come...
