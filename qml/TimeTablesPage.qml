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

    property var poi
    property int selectedTime: 0
    property int selectedFilter: 0
    property bool showFilterSelector: false

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
                text: Qt.formatDate(TrainConnection.departureDate, Qt.DefaultLocaleShortDate)
                onClicked: {
                    var dialog = app.push(Qt.resolvedUrl("../qml/platform/DatePickerDialogPL.qml"), {
                        "date": TrainConnection.departureDate,
                        "title": app.tr("Select date")
                    });
                    dialog.accepted.connect(function() {
                        if (dialog.date < new Date()) {
                            TrainConnection.departureDate = new Date();
                        } else {
                            TrainConnection.departureDate = dialog.date;
                        }
                        
                    });
                }
            }

            ButtonPL {
                id: todayButton
                preferredWidth: page.width - (pickDateButton.width + 2 * styler.themeHorizontalPageMargin + styler.themePaddingSmall)
                text: app.tr('Today')
                onClicked: {
                    TrainConnection.departureDate = new Date();
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
                text: Qt.formatTime(TrainConnection.departureTime, Qt.DefaultLocaleShortDate)
                onClicked: {
                    var dialog = app.push(Qt.resolvedUrl("../qml/platform/TimePickerDialogPL.qml"), {
                        "hour": TrainConnection.departureTime.getHours(),
                        "minute": TrainConnection.departureTime.getMinutes(),
                        "title": app.tr("Select time")
                    });
                    dialog.accepted.connect(function() {
                        var time = new Date();
                        time.setHours(dialog.hour);
                        time.setMinutes(dialog.minute);
                        time.setSeconds(0);
                        if (time < new Date()) {
                            TrainConnection.departureTime = new Date();
                        } else {
                            TrainConnection.departureTime = time;
                        }
                    });
                }
            }

            ButtonPL {
                id: nowButton
                preferredWidth: page.width - (pickTimeButton.width + 2 * styler.themeHorizontalPageMargin + styler.themePaddingSmall)
                text: app.tr('Now')
                onClicked: {
                    TrainConnection.departureTime = new Date();
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
            enabled: TrainConnection.start.name
            text: app.tr("Search")
            onClicked: {
                departureModel.request = TrainConnection.createStopoverRequest();
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
            visible: true

            LabelPL {
                id: depTimeHeader
                width: parent.width / 6.5
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Time")
            }

            LabelPL {
                id: nameHeader
                width: parent.width / 7
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Name")
            }

            LabelPL {
                width: parent.width - (depTimeHeader.width + nameHeader.width + trackHeader.width)
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Direction")
            }

            LabelPL {
                id: trackHeader
                width: parent.width / 8
                horizontalAlignment: Text.AlignRight
                text: app.tr("Track")
            }
        }     

        Rectangle {
            height: 1
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            color: "gray"
        } 

        Repeater {
            id: list
            width: page.width
            
            model: departureModel

            delegate: ListItemPL {
                id: listItem
                width: page.width
                contentHeight: listColumn.height
                
                property bool isVisible: false

                Column {
                    id: listColumn
                    width: page.width

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
                            width: parent.width / 6.5
                            horizontalAlignment: Text.AlignLeft
                            text: departure.scheduledDepartureTime.toLocaleTimeString(Locale.ShortFormat)
                        }

                        LabelPL {
                            id: nameLabel
                            width: parent.width / 7
                            horizontalAlignment: Text.AlignLeft
                            text: departure.route.line.name
                            truncMode: truncModes.elide
                        }

                        LabelPL {
                            width: parent.width - (depTimeLabel.width + nameLabel.width + trackLabel.width)
                            horizontalAlignment: Text.AlignLeft
                            text: departure.route.direction
                            truncMode: truncModes.elide
                        }

                        LabelPL {
                            id: trackLabel
                            width: parent.width / 8
                            horizontalAlignment: Text.AlignRight
                            text: departure.scheduledPlatform
                        }
                    }

                    Spacer {
                        height: styler.themePaddingLarge
                    }

                    Rectangle {
                        height: 1
                        anchors.left: parent.left
                        anchors.leftMargin: styler.themeHorizontalPageMargin
                        anchors.right: parent.right
                        anchors.rightMargin: styler.themeHorizontalPageMargin
                        color: "gray"
                    }

                    // Repeater {
                    //     id: infoList
                    //     width: page.width

                    //     delegate: ListItemPL {
                    //         id: infoListItem
                    //         width: page.width
                    //         contentHeight: furtherInfoGrid.height

                    //         Grid {
                    //             id: furtherInfoGrid
                    //             columns: 4
                    //             rows: 1
                    //             spacing: styler.themePaddingMedium
                    //             anchors.left: parent.left
                    //             anchors.right: parent.right

                    //             LabelPL {
                    //                 id: depTimeLabel
                    //                 width: page.width / 8
                    //                 height: implicitHeight + styler.themePaddingMedium
                    //                 horizontalAlignment: Text.AlignLeft
                    //                 text: (model['dp_time_hh'] ? model['dp_time_hh'] + ":" + model['dp_time_mm'] : "")
                    //             }

                    //             LabelPL {
                    //                 id: nameLabel
                    //                 width: page.width / 6
                    //                 height: implicitHeight + styler.themePaddingMedium
                    //                 horizontalAlignment: Text.AlignLeft
                    //                 text: model['type'] + " " + model['name']
                    //             }

                    //             LabelPL {
                    //                 id: directionLabel
                    //                 width: page.width / 2.35
                    //                 height: implicitHeight + styler.themePaddingMedium
                    //                 horizontalAlignment: Text.AlignLeft
                    //                 text: model['destination']
                    //             }

                    //             LabelPL {
                    //                 id: trackLabel
                    //                 width: page.width / 8
                    //                 height: implicitHeight + styler.themePaddingMedium
                    //                 horizontalAlignment: Text.AlignRight
                    //                 text: model['dp_track']
                    //             }
                    //         }

                    //         onClicked: {
                    //             if (model['dp_time_hh'] == "") {
                    //                 py.call("poor.app.timetables.load_destination_informations", [model['train_id'], model['destination'], selectedTime], function(result) {
                    //                     var arr = result.split('|');
                    //                     model['dp_time_hh'] = arr[0];
                    //                     model['dp_time_mm'] = arr[1];
                    //                     model['dp_track'] = arr[2];
                    //                 });
                    //             }
                    //         }

                    //     }

                    //     model: ListModel {}

                    //     function fillInfoModel(type, name, next_stops, id) {
                    //         infoList.model.clear();

                    //         var arr = next_stops.split('|');
                    //         for (var i = 0; i < arr.length; i++) {
                    //             var dict = {
                    //                 "type": type,
                    //                 "name": name,
                    //                 "train_id": id,
                    //                 "dp_time_hh": "",
                    //                 "dp_time_mm": "",
                    //                 "dp_track": "",
                    //                 "destination": arr[i]
                    //             };
                    //             infoList.model.append(dict);
                    //         }

                    //     }

                    //     function clearInfoModel() {
                    //         infoList.model.clear();
                    //     }

                    // }

                    // ListItemLabel {
                    //     color: styler.themeHighlightColor
                    //     height: implicitHeight
                    //     text: ""
                    //     visible: true
                    // }

                }

                onClicked: {
                    isVisible = !isVisible;
                    
                    if (isVisible) {
                        infoList.fillInfoModel(model['type'], model['name'], model['dp_stops'], model['train_id']);
                    } else {
                        infoList.clearInfoModel();
                    }

                }

            }

            // function fillModel() {
            //     model.clear();
            //     py.call("poor.app.timetables.get_trains", [], function(results) {
            //         results.forEach( function (p) { model.append(p); });
            //         if (model.count > 0) {
            //             showFilterSelector = true;
            //         } else {
            //             showFilterSelector = false;
            //         }
            //         searchButton.text = "Search";
            //         searchButton.enabled = true;
            //         timetableHeader.text = app.tr('Timetables for ') + Qt.formatDateTime(new Date(), "dd.MM.yyyy") + " at " + selectedTime + ":00";
            //     });
            // }

            // function filterModel() {
            //     model.clear();
            //     py.call("poor.app.timetables.get_trains", [], function(results) {
            //         results.forEach( function (p) {
            //             switch(selectedFilter) {
            //             case 1:
            //                 if (p['type'].toLowerCase().includes('S'.toLowerCase()) || p['type'].toLowerCase().includes('R'.toLowerCase())) {
            //                     model.append(p); 
            //                 }
            //                 break;
            //             case 2:
            //                 if (!p['type'].toLowerCase().includes('S'.toLowerCase()) && !p['type'].toLowerCase().includes('R'.toLowerCase())) {
            //                     model.append(p); 
            //                 }
            //                 break;
            //             default:
            //                 model.append(p);
            //         }
            //         });
            //     });
            // }
            
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight
            visible: list.model.count > 0
            text: app.tr('Press on destination to load further informations')
            horizontalAlignment: Text.AlignHCenter
        }

    }

    KPT.StopoverQueryModel {
        id: departureModel
        manager: Manager
    }

    onPageStatusActivating: {
        const kpt_backends = py.evaluate("poor.app.history.kpt_backends");
        kpt_backends.forEach( function(x) { TrainConnection.setBackendEnable(x, true); } );

        TrainConnection.startLocationRequest(poi.coordinate.latitude, poi.coordinate.longitude, poi.title);
    }

    function startCallback(data) {
        TrainConnection.start = data;
    }

}
