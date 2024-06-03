# Vaporiser

A Swift mock server backed by Vapor for general purpose XCUI Testing Built using Swift and Vapor framework, ensuring seamless integration and high performance.

## Installation

Add package dependency:
```
dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.92.5"),
],
```

Simple usage example can be viewed [here](https://github.com/AdevintaSpain/Vaporiser/blob/main/Example/ExampleUITests/ExampleUITests.swift)

1. Async start the server:

```
try server.start()
```

2. Add mocks using

```
server.store(
    mock: MockData(
        path: "path/mock/responds/to",
        payload: Data,
        method: HTTPMethod
    )
)
```

3. Stop server on `tearDown`

```
server.stop()
```

## Notes

Example project uses [this server](https://alexwohlbruck.github.io/cat-facts/docs/endpoints/facts.html), which is being mocked in the XCUI tests.

This project is not meant to exemplify architecture, rather to examplify a basic feature of the mock server used in XCUI tests.
