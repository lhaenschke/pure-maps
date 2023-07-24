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
import org.kde.kpublictransport 1.0 as KPT
import "."
import "platform"

PagePL {
    id: page
    title: app.tr("Trainconnections")

    property var poi

    // pageMenu: PageMenuPL {
    //     PageMenuItemPL {
    //         enabled: page.active
    //         text: useAPI ? app.tr('Press toe use API-Mode') : app.tr('Press to use Scraping-Mode')
    //         onClicked: {
    //             useAPI = !useAPI
    //         }
    //     }
    // }

    Column {
        id: column
        width: page.width

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: app.tr('Start:')
            truncMode: truncModes.none
            verticalAlignment: Text.AlignTop
            wrapMode: Text.WordWrap
        }

        ButtonPL {
            id: pickStartButton
            anchors.horizontalCenter: parent.horizontalCenter
            preferredWidth: page.width - (2 * styler.themeHorizontalPageMargin)
            text: TrainConnection.start.name ? TrainConnection.start.name : app.tr("Choose Start")
            onClicked: {
                app.push(Qt.resolvedUrl("TrainConnectionDestinationQueryPage.qml"), {
                    "latitude": poi.coordinate.latitude,
                    "longitude": poi.coordinate.longitude,
                    "callback": page.startCallback
                });
            }
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: app.tr('Destination:')
            truncMode: truncModes.none
            verticalAlignment: Text.AlignTop
            wrapMode: Text.WordWrap
        }

        ButtonPL {
            id: pickDestinationButton
            anchors.horizontalCenter: parent.horizontalCenter
            preferredWidth: page.width - (2 * styler.themeHorizontalPageMargin)
            text: TrainConnection.destination.name ? TrainConnection.destination.name : app.tr("Choose Destination")
            onClicked: {
                app.push(Qt.resolvedUrl("TrainConnectionDestinationQueryPage.qml"), {
                    "latitude": poi.coordinate.latitude,
                    "longitude": poi.coordinate.longitude,
                    "callback": page.destinationCallback
                });
            }
        }
        
        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight
            text: ""
        }

        ButtonPL {
            id: searchButton
            anchors.horizontalCenter: parent.horizontalCenter
            preferredWidth: styler.themeButtonWidthLarge
            enabled: TrainConnection.destination.name
            text: app.tr("Search")
            onClicked: {
                connectionModel.request = TrainConnection.createJourneyRequest();
            }
        }

        Spacer {
            height: styler.themePaddingLarge
        }

        Grid {
            id: headerGrid
            columns: 3
            rows: 1
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            visible: connectionRepeater.model.count > 0

            LabelPL {
                id: timeHeader
                width: parent.width / 3.5
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Time")
            }

            LabelPL {
                id: nameDestinationHeader
                width: parent.width - (timeHeader.width + changesHeader.width)
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Trains/Buses")
            }

            LabelPL {
                id: changesHeader
                width: parent.width / 8
                horizontalAlignment: Text.AlignRight
                text: app.tr("Changes")
            }
        }

        Rectangle {
            id: listSeperator
            height: 1
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            color: "gray"
            visible: connectionRepeater.model.count > 0
        }

        Repeater {
            id: connectionRepeater
            width: page.width
            visible: model.count > 0

            model: connectionModel

            delegate: ListItemPL {
                id: listItem
                width: page.width
                contentHeight: connectionColumn.height

                readonly property var firstJourney: journey.sections[0]
                readonly property var lastJourney: journey.sections[journey.sections.length - 1]
                readonly property bool cancelled: journey.disruptionEffect == KPT.Disruption.NoService

                Column {
                    id: connectionColumn
                    width: page.width

                    Spacer {
                        height: styler.themePaddingLarge
                    }

                    // ListItemLabel {
                    //     color: listItem.highlighted ? styler.themeHighlightColor : styler.themePrimaryColor
                    //     height: implicitHeight + styler.themePaddingMedium
                    //     text: journey.sections[0].scheduledDepartureTime.toLocaleTimeString(Locale.ShortFormat) + " " + journey.sections[0].from.name
                    //     verticalAlignment: Text.AlignVCenter
                    // }

                    Grid {
                        id: firstRow
                        columns: 3
                        rows: 1
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8

                        LabelPL {
                            id: arTragetTimeLabel
                            width: parent.width / 3.5
                            horizontalAlignment: Text.AlignLeft
                            text: firstJourney.scheduledDepartureTime + " - " + lastJourney.scheduledArrivalTime
                        }

                        LabelPL {
                            id: arStationLabel
                            width: parent.width - (arTimeLabel.width + changesLabel.width + styler.themeHorizontalPageMargin)
                            horizontalAlignment: Text.AlignLeft
                            text: {
                                var str = "";
                                journey.sections.forEach( function(x) { str += x.route.line.name; str += " "; } );
                            }
                        }

                        LabelPL {
                            id: changesLabel
                            width: parent.width / 8
                            horizontalAlignment: Text.AlignRight
                            text: journey.numberOfChanges + " changes"
                        }

                    }

                    Grid {
                        id: secoundRow
                        columns: 1
                        rows: 1
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8

                        LabelPL {
                            id: diffTimeLabel
                            width: parent.width / 3.5
                            horizontalAlignment: Text.AlignLeft
                            text: "(" + model['diff_minutes'] + " min)"
                        }

                    }

                    Spacer {
                        height: styler.themePaddingLarge
                    }

                    Rectangle {
                        height: 1
                        width: listSeperator.width
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        color: "gray"
                    }

                }

                onClicked: {
                }

            }

        }

    }

    KPT.JourneyQueryModel {
        id: connectionModel
        manager: Manager
    }

    onPageStatusActivating: {
        const kpt_backends = py.evaluate("poor.app.history.kpt_backends");
        kpt_backends.forEach( function(x) { TrainConnection.setBackendEnable(x, true); } );

        TrainConnection.startLocationRequest(poi.coordinate.latitude, poi.coordinate.longitude, poi.title);
    }

    function getTimeDifference(time_one_hh, time_one_mm, time_two_hh, time_two_mm) {
        var diff_minutes = Math.abs(parseInt(time_one_mm) - parseInt(time_two_mm));
        var hour_diff = Math.abs(parseInt(time_one_hh) - parseInt(time_two_hh));

        if (hour_diff > 0) {
            diff_minutes = Math.abs(diff_minutes - 60);
        }

        return diff_minutes;

    }

    function startCallback(data) {
        TrainConnection.start = data;
    }

    function destinationCallback(data) {
        TrainConnection.destination = data;
    }

}
