# Android samples for Citymapper Navigation SDK

These samples demonstrate Citymapper SDK integration on Android

## SDK Access
See [Citymapper Enterprise APIs](https://citymapper.com/enterprise) to obtain an API key

# Samples

## journey_planner_views
A simple but full-featured journey planner, featuring search, route details,
and walk and cycle navigation. Implemented using views, not Compose

## navigation_module_compose
Turn-by-turn bicycle directions with voice guidance.
Implemented using only the Navigation SDK, without any SDK-provided UI

# Configuration

To build and run the samples, some variables must be set in `~/.gradle/gradle.properties`:

```
CITYMAPPER_API_KEY=[your API key]
GOOGLE_MAP_API_KEY=[your google map key]
GOOGLE_PLACES_API_KEY=[your google places key]
```
