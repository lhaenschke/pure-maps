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
    title: app.tr("Timetables for ") + poi.title

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
            enabled: PublicTransport.start.name
            text: app.tr("Search")
            onClicked: {
                departureModel.request = PublicTransport.createStopoverRequest();
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
            visible: departureRepeater.count > 0

            LabelPL {
                id: depTimeHeader
                width: parent.width / 5.3
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Time")
            }

            LabelPL {
                width: parent.width - (depTimeHeader.width + trackHeader.width)
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Line")
            }

            LabelPL {
                id: trackHeader
                width: parent.width / 8.5
                horizontalAlignment: Text.AlignRight
                text: app.tr("Track")
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
            visible: departureRepeater.count > 0
        } 

        Repeater {
            id: departureRepeater
            width: page.width
            
            model: departureModel

            delegate: ListItemPL {
                id: listItem
                width: page.width
                contentHeight: listColumn.height
                
                readonly property bool cancelled: departure.disruptionEffect == KPT.Disruption.NoService

                Column {
                    id: listColumn
                    width: page.width

                    Spacer {
                        height: styler.themePaddingLarge
                    }

                    Grid {
                        id: trainsGrid
                        columns: 4
                        rows: 1
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8

                        LabelPL {
                            id: depTimeLabel
                            width: parent.width / 5
                            horizontalAlignment: Text.AlignLeft
                            text: departure.scheduledDepartureTime.toLocaleTimeString(Locale.ShortFormat)
                            font.strikeout: cancelled
                        }

                        LabelPL {
                            id: depDelayLabel
                            width: parent.width / 1.3
                            horizontalAlignment: Text.AlignLeft
                            text: departure.hasExpectedDepartureTime ? " + " + departure.departureDelay : ""
                            color: departure.hasExpectedDepartureTime && lastJourney.departureDelay > 3 ? "red" : "green"
                            font.strikeout: cancelled
                        }

                        LabelPL {
                            width: parent.width - (depTimeLabel.width + depDelayLabel.width + trackLabel.width + 16)
                            horizontalAlignment: Text.AlignLeft
                            text: departure.route.line.name + " -> " + departure.route.direction
                            truncMode: truncModes.elide
                            font.strikeout: cancelled
                        }

                        LabelPL {
                            id: trackLabel
                            width: parent.width / 8.5
                            horizontalAlignment: Text.AlignRight
                            text: departure.scheduledPlatform
                            font.strikeout: cancelled
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

            }
            
        }

    }

    KPT.StopoverQueryModel {
        id: departureModel
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

    function startCallback(data) {
        PublicTransport.start = data;
    }

}
