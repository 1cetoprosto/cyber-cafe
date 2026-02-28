fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios prod

```sh
[bundle exec] fastlane ios prod
```

Deploy PROD to TestFlight (Scheme: TrackMyCafe Prod)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Deploy BETA to TestFlight (Scheme: TrackMyCafe Beta)

### ios dev

```sh
[bundle exec] fastlane ios dev
```

Deploy DEV to TestFlight (Scheme: TrackMyCafe Dev)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
