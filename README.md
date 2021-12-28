![Bike GPS header](https://user-images.githubusercontent.com/69430023/147602595-f3ca8048-dd54-4b7c-86f3-bce8300a63ea.png)


# Bike GPS

Bike GPS is an Open-Source Mobile Cross-Platform Bike Navigation System for iOS and Android developed using Dart and Flutter.

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
The Bike GPS app includes a parser for .gpx files and is specifically made to allow for easy addition of additional parsers for other file types.

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
