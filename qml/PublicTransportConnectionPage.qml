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
    title: app.tr("Train Connections")

    property var  poi
    property bool loaded: false

    Column {
        id: column
        width: page.width

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingLarge
            text: app.tr('Start:')
            truncMode: truncModes.none
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }

        ButtonPL {
            id: pickStartButton
            anchors.horizontalCenter: parent.horizontalCenter
            preferredWidth: page.width - (2 * styler.themeHorizontalPageMargin)
            text: PublicTransport.start.name ? PublicTransport.start.name : app.tr("Choose Start")
            onClicked: {
                app.push(Qt.resolvedUrl("PublicTransportStationQueryPage.qml"), {
                    "latitude": poi.coordinate.latitude,
                    "longitude": poi.coordinate.longitude,
                    "callback": page.startCallback
                });
            }
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingLarge
            text: app.tr('Destination:')
            truncMode: truncModes.none
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }

        ButtonPL {
            id: pickDestinationButton
            anchors.horizontalCenter: parent.horizontalCenter
            preferredWidth: page.width - (2 * styler.themeHorizontalPageMargin)
            text: PublicTransport.destination.name ? PublicTransport.destination.name : app.tr("Choose Destination")
            onClicked: {
                app.push(Qt.resolvedUrl("PublicTransportStationQueryPage.qml"), {
                    "latitude": poi.coordinate.latitude,
                    "longitude": poi.coordinate.longitude,
                    "callback": page.destinationCallback
                });
            }
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingLarge
            text: app.tr('Date:')
            truncMode: truncModes.none
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            spacing: styler.themePaddingSmall

            ButtonPL {
                id: pickDateButton
                preferredWidth: styler.themeButtonWidthLarge - (2 * styler.themeHorizontalPageMargin)
                text: Qt.formatDate(PublicTransport.departureDate, Qt.DefaultLocaleShortDate)
                onClicked: {
                    var dialog = app.push(Qt.resolvedUrl("../qml/platform/DatePickerDialogPL.qml"), {
                        "date": PublicTransport.departureDate,
                        "title": app.tr("Select date")
                    });
                    dialog.accepted.connect(function() {
                        if (dialog.date < new Date()) {
                            PublicTransport.departureDate = new Date();
                        } else {
                            PublicTransport.departureDate = dialog.date;
                        }
                        
                    });
                }
            }

            ButtonPL {
                id: todayButton
                preferredWidth: page.width - (pickDateButton.width + 2 * styler.themeHorizontalPageMargin + styler.themePaddingSmall)
                text: app.tr('Today')
                onClicked: {
                    PublicTransport.departureDate = new Date();
                }
            }

        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingLarge
            text: app.tr('Time:')
            truncMode: truncModes.none
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            spacing: styler.themePaddingSmall

            ButtonPL {
                id: pickTimeButton
                preferredWidth: styler.themeButtonWidthLarge - (2 * styler.themeHorizontalPageMargin)
                text: Qt.formatTime(PublicTransport.departureTime, Qt.DefaultLocaleShortDate)
                onClicked: {
                    var dialog = app.push(Qt.resolvedUrl("../qml/platform/TimePickerDialogPL.qml"), {
                        "hour": PublicTransport.departureTime.getHours(),
                        "minute": PublicTransport.departureTime.getMinutes(),
                        "title": app.tr("Select time")
                    });
                    dialog.accepted.connect(function() {
                        var time = new Date();
                        time.setHours(dialog.hour);
                        time.setMinutes(dialog.minute);
                        time.setSeconds(0);
                        if (time < new Date()) {
                            PublicTransport.departureTime = new Date();
                        } else {
                            PublicTransport.departureTime = time;
                        }
                    });
                }
            }

            ButtonPL {
                id: nowButton
                preferredWidth: page.width - (pickTimeButton.width + 2 * styler.themeHorizontalPageMargin + styler.themePaddingSmall)
                text: app.tr('Now')
                onClicked: {
                    PublicTransport.departureTime = new Date();
                }
            }

        }

        Spacer {
            height: styler.themePaddingLarge
        }

        ButtonPL {
            id: searchButton
            anchors.horizontalCenter: parent.horizontalCenter
            preferredWidth: styler.themeButtonWidthLarge
            enabled: PublicTransport.destination.name && PublicTransport.start.name
            text: app.tr("Search")
            onClicked: {
                connectionModel.request = PublicTransport.createJourneyRequest();
            }
        }

        Spacer {
            height: styler.themePaddingLarge
        }

        Grid {
            id: headerGrid
            columns: 4
            rows: 1
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            visible: connectionRepeater.count > 0

            LabelPL {
                id: timeHeader
                width: parent.width / 5.8
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Time")
            }

            LabelPL {
                id: delayHeader
                width: parent.width / 11
                horizontalAlignment: Text.AlignLeft
                text: ""
            }

            LabelPL {
                width: parent.width - (timeHeader.width + delayHeader.width + changesHeader.width)
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
            visible: connectionRepeater.count > 0
        }

        Repeater {
            id: connectionRepeater
            width: page.width

            model: connectionModel

            delegate: ListItemPL {
                id: listItem
                width: page.width
                contentHeight: connectionColumn.height

                readonly property var  firstJourney: journey.sections[0]
                readonly property var  lastJourney:  journey.sections[journey.sections.length - 1]
                readonly property bool connectionIsCancelled: journey.disruptionEffect == KPT.Disruption.NoService

                Column {
                    id: connectionColumn
                    width: page.width

                    Spacer {
                        height: styler.themePaddingLarge
                    }

                    Grid {
                        id: firstRow
                        columns: 3
                        rows: 1
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8

                        LabelPL {
                            id: firstTimeLabel
                            width: parent.width / 5.8
                            horizontalAlignment: Text.AlignLeft
                            text: firstJourney.scheduledDepartureTime.toLocaleTimeString(Locale.ShortFormat)
                            font.strikeout: connectionIsCancelled
                        }

                        LabelPL {
                            id: firstDelayLabel
                            width: parent.width / 11
                            horizontalAlignment: Text.AlignLeft
                            text: firstJourney.hasExpectedDepartureTime ? "+" + firstJourney.departureDelay : ""
                            color: firstJourney.departureDelay > 3 ? "red" : "green"
                            font.strikeout: connectionIsCancelled
                        }

                        LabelPL {
                            width: parent.width - (firstTimeLabel.width + firstDelayLabel.width + 16)
                            horizontalAlignment: Text.AlignLeft
                            text: firstJourney.from.name
                            font.strikeout: connectionIsCancelled
                        }

                    }

                    Grid {
                        id: secoundRow
                        columns: 3
                        rows: 1
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8

                        LabelPL {
                            id: lastTimeLabel
                            width: parent.width / 5.8
                            horizontalAlignment: Text.AlignLeft
                            text: lastJourney.scheduledArrivalTime.toLocaleTimeString(Locale.ShortFormat)
                            font.strikeout: connectionIsCancelled
                        }

                        LabelPL {
                            id: lastDelayLabel
                            width: parent.width / 11
                            horizontalAlignment: Text.AlignLeft
                            text: lastJourney.hasExpectedDepartureTime ? "+" + lastJourney.departureDelay : ""
                            color: lastJourney.departureDelay > 3 ? "red" : "green"
                            font.strikeout: connectionIsCancelled
                        }

                        LabelPL {
                            width: parent.width - (lastTimeLabel.width + lastDelayLabel.width + 16)
                            horizontalAlignment: Text.AlignLeft
                            text: lastJourney.to.name
                            font.strikeout: connectionIsCancelled
                            truncMode: truncModes.elide
                        }

                    }

                    Grid {
                        id: thirdRow
                        columns: 4
                        rows: 1
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8

                        LabelPL {
                            id: durationLabel
                            width: parent.width / 5.8
                            horizontalAlignment: Text.AlignLeft
                            text: "(" + (journey.duration / 60) + " min)"
                            font.strikeout: connectionIsCancelled
                        }

                        LabelPL {
                            id: delayPlaceholderLabel
                            width: parent.width / 11
                            horizontalAlignment: Text.AlignLeft
                            text: ""
                        }

                        Row {
                            spacing: styler.themePaddingSmall
                            width: parent.width - (durationLabel.width + delayPlaceholderLabel.width + changesLabel.width + 16)

                            Repeater {
                                model: journey.sections

                                LabelPL {
                                    height: durationLabel.height
                                    text: modelData.route.line.name
                                    font.strikeout: connectionIsCancelled
                                }
                            }
                        }

                        LabelPL {
                            id: changesLabel
                            width: parent.width / 8
                            horizontalAlignment: Text.AlignRight
                            text: journey.numberOfChanges + " changes"
                            font.strikeout: connectionIsCancelled
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
                    if (!connectionIsCancelled) {
                        app.push(Qt.resolvedUrl("PublicTransportConnectionDetailsPage.qml"), {
                            "journey": journey
                        });
                    }
                }

            }

        }

    }

    KPT.JourneyQueryModel {
        id: connectionModel
        manager: Manager
    }

    onPageStatusActivating: {
        if (!loaded) {
            const kpt_backends = py.evaluate("poor.app.history.kpt_backends");
            kpt_backends.forEach( function(x) { PublicTransport.setBackendEnable(x, true); } );
            PublicTransport.setStartLocation(poi.coordinate.latitude, poi.coordinate.longitude, poi.title);
            loaded = true;
        }
        
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
        PublicTransport.start = data;
    }

    function destinationCallback(data) {
        PublicTransport.destination = data;
    }

    function dateCallback(data) {
        PublicTransport.departureDate = data;
    }

    function timeCallback(data) {
        PublicTransport.departureTime = data;
    }

}
