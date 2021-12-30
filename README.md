![Bike GPS header](https://user-images.githubusercontent.com/69430023/147602595-f3ca8048-dd54-4b7c-86f3-bce8300a63ea.png)

# Bike GPS

[![contributors](https://img.shields.io/github/contributors/patrick-mahnkopf/bike-gps)](https://github.com/patrick-mahnkopf/bike-gps/graphs/contributors)
[![forks](https://img.shields.io/github/forks/patrick-mahnkopf/bike-gps)](https://github.com/patrick-mahnkopf/bike-gps/network/members)
[![stars](https://img.shields.io/github/stars/patrick-mahnkopf/bike-gps)](https://github.com/patrick-mahnkopf/bike-gps/stargazers)
[![license](https://img.shields.io/github/license/patrick-mahnkopf/bike-gps)](./LICENSE)
[![issues](https://img.shields.io/github/issues/patrick-mahnkopf/bike-gps)](https://github.com/patrick-mahnkopf/bike-gps/issues)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=patrick-mahnkopf_bike-gps&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=patrick-mahnkopf_bike-gps)

Bike GPS is an Open-Source Mobile Cross-Platform Bike Navigation System for iOS and Android, developed using Dart and Flutter.  
It is powered by [OpenStreetMap](https://www.openstreetmap.org/), [Flutter Mapbox GL](https://github.com/flutter-mapbox-gl/maps), [OpenMapTiles](https://github.com/openmaptiles/openmaptiles), and [Openrouteservice](https://github.com/GIScience/openrouteservice).

## Functionality

### Maps
The app uses [OpenStreetMap](https://www.openstreetmap.org/) data served from a tile server to display its map.

<div>
  <h3>Address Search</h3>
The app includes a search interface that will find addresses, places, and tours available on the device.

<img src="https://user-images.githubusercontent.com/69430023/147603123-ca972797-7f6e-4323-ad2c-eb6e3e4e510a.png" alt="Bike GPS Search View">
</div>
  
### Navigation
The app includes functionality to navigate using tour files, as well as to the tours on-the-fly with routing based on the OSM map data.

![image](https://user-images.githubusercontent.com/69430023/147603247-aff88a1b-ef48-4bcc-a2ed-9a59fcd9a05b.png)

### GPX
The app includes a parser for .gpx files and is specifically made to allow for easy addition of further parsers for other file types.

### Tour Enhancement
The app will automatically generate navigation and turn information for the free navigation and for tour files that do not include such data.

### Alternative Tours
Upon selecting a tour, the app will automatically display alternative tours, which can be switched to by simply tapping them on the map.

![Alternative Tours](https://user-images.githubusercontent.com/69430023/147603164-0bd73cc7-b07e-41f3-a1e4-c3ab1f7375e3.png)

### Road book
The road book features height information for all tours, as well as surface information for all parts of the tour for tour files including that data.
The road book also displays all turns of the tour, with a description of the location and a textual explanation of the turn.

![Road book](https://user-images.githubusercontent.com/69430023/147603184-c887e9d1-9e03-4712-8a20-f84866493e91.png)

### Mobile Intent Handling
The app supports "Open with..." and "Share" functionality on mobile devices for tour files, as well as zip collections of tour files.

## Development Setup

### Flutter Prerequisites

- Install the [Flutter SDK version 2.0.0](https://docs.flutter.dev/development/tools/sdk/releases) from the stable channel
- See the [official Flutter documentation](https://docs.flutter.dev/get-started/install) for setup guidance

- Clone the repository:

```
git clone https://github.com/patrick-mahnkopf/bike-gps.git
```

- Download the dependency packages with:

```
flutter pub get
```

#### Tile server prerequisites

- This project uses [Flutter Mapbox GL](https://github.com/flutter-mapbox-gl/maps), so the tiles have to be served either by [mapbox](https://docs.mapbox.com/api/maps/vector-tiles/), or by setting up a service such as [OpenMapTiles](https://github.com/openmaptiles/openmaptiles) on a server
- You can use something like [OSM Bright](https://github.com/mapbox/osm-bright) as a starting point for the maps

#### Route server prerequisites

- For the free navigation and tour enhancement features a route server has to be set up. You can use [Openrouteservice](https://github.com/GIScience/openrouteservice) for that

#### Tokens, style and API URI setup

- A few tokens are expected in separate files in the `./assets/tokens` directory. Make sure that the folder stays listed in the .gitignore to prevent uploading any sensitive data
- You will need the following:
  - A `vector_style_string.txt` containing the URI of the tile server endpoint holding the vector `style.json`
  - A `raster_style_string.txt` containing the URI of the raster style JSON pointing to the tile server's raster endpoint
  - A `mapbox_access_token.txt` containing your [private Mapbox access token](https://github.com/flutter-mapbox-gl/maps#private-mapbox-access-token) to allow Flutter Mapbox GL to download the underlying Android/iOS SDKs
  - A `route_service_url.txt` containing the URI of the route server endpoint. Use the `/ors/v2/directions/cycling-mountain/gpx` endpoint when running Openrouteservice
  - A `route_service_status_url.txt` containing the URI of the route server's status endpoint. Use the `/ors/v2/health` endpoint when running Openrouteservice
  - A `log_server_values.txt` containing the URI of a log server endpoint, the username, and the password for that server, each in a separate line
