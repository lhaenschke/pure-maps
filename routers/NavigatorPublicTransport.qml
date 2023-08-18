/* -*- coding: utf-8-unix -*-
 *
 * Copyright (C) 2023 lhaenschke
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtPositioning 5.4
import org.puremaps 1.0
import org.kde.kpublictransport 1.0

Item {
    id: navigatorPublicTransport

    property bool loadedKPTBackends: false

    function findPublicTransportRoute(args, callback) {
        const origin      = args[0][0];
        const destination = args[0][1];

        // Enable KPT-Backends
        if (!loadedKPTBackends) {
            const kpt_backends = py.evaluate("poor.app.history.kpt_backends");
            kpt_backends.forEach(x => { TrainConnection.setBackendEnable(x, true); });
            loadedKPTBackends = true;
        }

        var fromStops = [];
        var toStops = [];

        for (var i = 0; i < 2; i++) {
            var counter = 0;
            getNearbyStopsFromLocation(origin).forEach(x => {
                TrainConnection.loadLocationFromCoorAndName(x['y'], x['x'], x['title'], counter++);
                fromStops.push({"PoiLocation": x});
            });

            getNearbyStopsFromLocation(destination).forEach(x => {
                TrainConnection.loadLocationFromCoorAndName(x['y'], x['x'], x['title'], counter++);
                toStops.push({"PoiLocation": x});
            });
        }

        var lcounter = 0;
        locationRepeater.setRepeater(function () {
            console.log("Location-Counter: ", lcounter);
            if (TrainConnection.loadingLocationIsFinished() || lcounter++ >= 5) {
                locationRepeater.stopRepeater();
                
                // Location is Loaded

                for (var i = 0; i < fromStops.length; i++) {
                    fromStops[i].KptLocation = TrainConnection.getLocation(i);
                    console.log("From: ", JSON.stringify(TrainConnection.getLocation(i)));
                }

                for (var i = 0; i < toStops.length; i++) {
                    toStops[i].KptLocation = TrainConnection.getLocation(i + fromStops.length);
                    console.log("To: ", JSON.stringify(TrainConnection.getLocation(i + fromStops.length)));
                }

                var counter = 0;
                fromStops.forEach(from => {
                    toStops.forEach(to => {
                        TrainConnection.loadJourney(from.KptLocation, to.KptLocation, counter++);
                    });
                });
                
                var jcounter = 0;
                journeyRepeater.setRepeater(function () {
                    if (TrainConnection.loadingJourneyIsFinished() || jcounter++ >= 10) {
                        journeyRepeater.stopRepeater();

                        var journeys = [];
                        var counter = 0;
                        fromStops.forEach(from => {
                            toStops.forEach(to => {
                                journeys.push({"From": from, "To": to, "DepTime": TrainConnection.getDepartureTime(counter), "ArrTime": TrainConnection.getArrivalTime(counter), "Index": counter++});
                            });
                        });

                        journeys.sort(function(a, b) {
                            const keyA = a.ArrTime;
                            const keyB = b.ArrTime;

                            if (keyA < keyB) return -1;
                            if (keyA > keyB) return 1;
                            return 0;
                        });

                        if (journeys.length > 0) {
                            const selectedJourney = journeys[0];
                            selectedJourney.Journey = TrainConnection.getJourney(selectedJourney.Index);
                            console.log("To: ", JSON.stringify(TrainConnection.getJourney(selectedJourney.Index)));

                            if (selectedJourney.Journey && selectedJourney.Journey.sections.length > 0) {

                                const argsOrigin = [[origin, {
                                    "arrived": 0,
                                    "destination": 1,
                                    "text": selectedJourney.Journey.sections[0].departure.stopPoint.name, 
                                    "x": selectedJourney.Journey.sections[0].departure.stopPoint.longitude, 
                                    "y": selectedJourney.Journey.sections[0].departure.stopPoint.latitude
                                }], args[1]];

                                const argsDestination = [[{
                                    "arrived": 0,
                                    "destination": 0,
                                    "text": selectedJourney.Journey.sections[selectedJourney.Journey.sections.length - 1].arrival.stopPoint.name, 
                                    "x": selectedJourney.Journey.sections[selectedJourney.Journey.sections.length - 1].arrival.stopPoint.longitude, 
                                    "y": selectedJourney.Journey.sections[selectedJourney.Journey.sections.length - 1].arrival.stopPoint.latitude
                                }, destination], args[1]];

                                var publicTransportManeuvers = []; var publicTransportX = []; var publicTransportY = []
                                selectedJourney.Journey.sections.forEach(x => {
                                    switch (x.mode) {
                                        case 0:
                                            callback({"error": "Journey error", "message": "Journey error"});
                                            return;
                                        case 1:
                                            publicTransportManeuvers.push({
                                                "duration": 0,
                                                "icon": "continue",
                                                "narrative": app.tr("Move to track %1").arg(x.scheduledDeparturePlatform),
                                                "sign": {},
                                                "travel_type": "foot",
                                                "verbal_post": "",
                                                "verbal_pre": app.tr("Move to track %1").arg(x.scheduledDeparturePlatform),
                                                "x": x.from.longitude,
                                                "y": x.from.latitude
                                            });
                                            publicTransportManeuvers.push({
                                                "duration": x.duration,
                                                "icon": "arrive",
                                                "narrative": app.tr("Get on public transport %1 -> %2").arg(x.route.line.name).arg(x.route.direction),
                                                "sign": {},
                                                "travel_type": "transit",
                                                "verbal_post": "",
                                                "verbal_pre": app.tr("Get on public transport %1 -> %2").arg(x.route.line.name).arg(x.route.direction),
                                                "x": x.from.longitude,
                                                "y": x.from.latitude
                                            });
                                            publicTransportX.push(x.from.longitude); publicTransportY.push(x.from.latitude);
                                            publicTransportManeuvers.push({
                                                "duration": 0,
                                                "icon": "depart",
                                                "narrative": app.tr("Get off public transport at %1").arg(x.to.name),
                                                "sign": {},
                                                "travel_type": "foot",
                                                "verbal_post": "",
                                                "verbal_pre": app.tr("Get off public transport at %1").arg(x.to.name),
                                                "x": x.to.longitude,
                                                "y": x.to.latitude
                                            });
                                            publicTransportX.push(x.to.longitude); publicTransportY.push(x.to.latitude);
                                            break;
                                        case 2:
                                        case 4:
                                        case 8:
                                            publicTransportManeuvers.push({
                                                "duration": x.duration,
                                                "icon": "continue",
                                                "narrative": app.tr("Transfer between public transport"),
                                                "sign": {},
                                                "travel_type": "foot",
                                                "verbal_post": "",
                                                "verbal_pre": "",
                                                "x": x.to.longitude,
                                                "y": x.to.latitude
                                            });
                                            publicTransportX.push(x.to.longitude); publicTransportY.push(x.to.latitude);
                                            break;
                                        default:
                                            callback({"error": "Unkown journey error", "message": "Unkown journey error"});
                                            return;
                                    }    
                                });
                                
                                app.conf.set("routers.osmscout.type", "pedestrian");

                                var routeOrigin = py.call_sync("poor.app.router.route", argsOrigin);
                                if (Array.isArray(routeOrigin) && routeOrigin.length > 0)
                                    routeOrigin = routeOrigin[0];

                                var routeDestination = py.call_sync("poor.app.router.route", argsDestination);
                                if (Array.isArray(routeDestination) && routeDestination.length > 0)
                                    routeDestination = routeDestination[0];

                                const route = {
                                    "language": routeOrigin.language,
                                    "location_indexes": [
                                        routeOrigin.location_indexes[0] + routeDestination.location_indexes[0],
                                        routeOrigin.location_indexes[routeOrigin.location_indexes.length - 1] + routeDestination.location_indexes[routeDestination.location_indexes.length - 1] + publicTransportX.length
                                    ],
                                    "locations": [
                                        routeOrigin.locations[0],
                                        routeDestination.locations[routeDestination.locations.length -1]
                                    ],
                                    "maneuvers": routeOrigin.maneuvers.concat(publicTransportManeuvers, routeDestination.maneuvers),
                                    "mode": routeOrigin.mode,
                                    "optimized": routeOrigin.optimized,
                                    "provider": routeOrigin.provider,
                                    "x": routeOrigin.x.concat(publicTransportX, routeDestination.x),
                                    "y": routeOrigin.y.concat(publicTransportY, routeDestination.y)

                                };

                                app.conf.set("routers.osmscout.type", "transit");

                                callback(route);

                            }

                        } else {
                            callback({"error": "No journey was found. Please try again.", "message": "No journey was found. Please try again."});
                        }
                    }

                }, 1000);

            }

        }, 1000);

    }

    function getNearbyStopsFromLocation(location) {
        var arr = [];
        
        var results = py.call_sync("poor.app.guide.nearby", ["Bus Stops", "", [location['x'], location['y']], 1000]);
        arr.push(...results);
        
        var results = py.call_sync("poor.app.guide.nearby", ["Railway Platforms", "", [location['x'], location['y']], 1000]);
        arr.push(...results);
        
        var results = py.call_sync("poor.app.guide.nearby", ["Railway Stations", "", [location['x'], location['y']], 1000]);
        arr.push(...results);

        arr.sort(function(a, b) {
            const keyA = calculateDistance(a['y'], a['x'], location['y'], location['x']);
            const keyB = calculateDistance(b['y'], b['x'], location['y'], location['x']);

            if (keyA < keyB) return -1;
            if (keyA > keyB) return 1;
            return 0;
        });

        return arr.slice(0, 3);
    }

    function calculateDistance(lat1, lon1, lat2, lon2) {
        // Haversine formula (http://www.movable-type.co.uk/scripts/latlong.html)
        const R = 6371e3; // metres
        const φ1 = lat1 * Math.PI/180; // φ, λ in radians
        const φ2 = lat2 * Math.PI/180;
        const Δφ = (lat2-lat1) * Math.PI/180;
        const Δλ = (lon2-lon1) * Math.PI/180;

        const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
                  Math.cos(φ1)   * Math.cos(φ2)   *
                  Math.sin(Δλ/2) * Math.sin(Δλ/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

        return R * c; // in metres
    }

    Timer {
        id: locationRepeater
        property var callback: 0
        function setRepeater(cb, delayTime) {
            locationRepeater.interval = delayTime;
            locationRepeater.repeat = true;
            callback = cb;
            locationRepeater.triggered.connect(callback);
            locationRepeater.start();
        }
        function stopRepeater() {
            locationRepeater.triggered.disconnect(callback);
            locationRepeater.stop();
        }
    }

    Timer {
        id: journeyRepeater
        property var callback: 0
        function setRepeater(cb, delayTime) {
            journeyRepeater.interval = delayTime;
            journeyRepeater.repeat = true;
            callback = cb;
            journeyRepeater.triggered.connect(callback);
            journeyRepeater.start();
        }
        function stopRepeater() {
            journeyRepeater.triggered.disconnect(callback);
            journeyRepeater.stop();
        }
    }

}