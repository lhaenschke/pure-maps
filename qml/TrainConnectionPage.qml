/* -*- coding: utf-8-unix -*-
 *
 * Copyright (C) 2018 lhaenschke
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
import "."
import "platform"

PagePL {
    id: page
    title: app.tr("Connections for ") + poi.title

    property var  poi
    property var  selectedStation
    property int  connectionRows: 1

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
            text: poi.address ? app.tr('From:\n') + poi.address : ""
            truncMode: truncModes.none
            verticalAlignment: Text.AlignTop
            wrapMode: Text.WordWrap
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: app.tr('To:')
            truncMode: truncModes.none
            verticalAlignment: Text.AlignTop
            wrapMode: Text.WordWrap
        }

        ButtonPL {
            id: pickDestinationButton
            anchors.horizontalCenter: parent.horizontalCenter
            preferredWidth: page.width - (2 * styler.themeHorizontalPageMargin)
            text: app.tr("Choose Destination")
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
            enabled: false
            text: app.tr("Search")
            onClicked: {
                searchButton.enabled = false;
                searchButton.text = app.tr("Loading");
                
                connectionRepeater.model.clear();

                py.call("poor.app.trainconnections.search_connections", [poi.coordinate.latitude, poi.coordinate.longitude, selectedStation['eva'], selectedStation['name']], function(results) {
                    searchButton.enabled = true;
                    searchButton.text = app.tr("Search");
                    
                    results.forEach( function (p) { 
                        var dict = {};
                        for (var i = 0; i < p.length; i++) {
                            const key = 'con' + i;
                            dict[key] = p[i];
                            dict['count'] = count;
                        }

                        if (parseInt(dict['count']) > 1) {
                            connectionRows = 4;
                            console.log('Test 0: ', dict['con0']['name']);
                            console.log('Test 1: ', dict['con1']['name']);
                        } else {
                            connectionRows = 1;
                        }
                        connectionRepeater.model.append(dict);
                    });
                    
                });

            }
        }

        Spacer {
            height: styler.themePaddingLarge
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: app.tr('The times indicated are timetable times, not real-time')
            truncMode: truncModes.none
            visible: connectionRepeater.model.count > 0
            verticalAlignment: Text.AlignTop
        } 

        Spacer {
            height: styler.themePaddingMedium
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
                width: parent.width / 4
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Time")
            }

            LabelPL {
                id: nameDestinationHeader
                width: parent.width - (timeHeader.width + changesHeader.width)
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Trains")
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

            model: ListModel {}

            delegate: ListItemPL {
                id: listItem
                width: page.width
                contentHeight: connectionColumn.height

                Column {
                    id: connectionColumn
                    width: page.width

                    Spacer {
                        height: styler.themePaddingLarge
                    }

                    // Grid {
                    //     id: firstRow
                    //     columns: 2
                    //     rows: 1
                    //     anchors.left: parent.left
                    //     anchors.leftMargin: 8
                    //     anchors.right: parent.right
                    //     anchors.rightMargin: 8

                    //     LabelPL {
                    //         id: dpTimeLabel
                    //         width: parent.width / 6
                    //         horizontalAlignment: Text.AlignLeft
                    //         // text: model['con0']['dp_time_hh'] + ":" + model['con0']['dp_time_mm']
                    //         text: "42:42"
                    //     }

                    //     LabelPL {
                    //         id: dpStationLabel
                    //         width: parent.width - (dpTimeLabel.width + 2 * styler.themeHorizontalPageMargin)
                    //         horizontalAlignment: Text.AlignLeft
                    //         text: model['con0']['destination']
                    //         text: "Velbert-Langenberg"
                    //     }

                    // }

                    Grid {
                        id: secoundRow
                        columns: 3
                        rows: 1
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8

                        LabelPL {
                            id: arTimeLabel
                            width: parent.width / 4
                            horizontalAlignment: Text.AlignLeft
                            text: "42:42 - 42:42 (100 min)"
                        }

                        LabelPL {
                            id: arStationLabel
                            width: parent.width - (arTimeLabel.width + changesLabel.width + styler.themeHorizontalPageMargin)
                            horizontalAlignment: Text.AlignLeft
                            text: "Bus S6, S9"
                        }

                        LabelPL {
                            id: changesLabel
                            width: parent.width / 8
                            horizontalAlignment: Text.AlignRight
                            // text: model['con0']['dp_track']
                            text: "1 changes"
                        }

                    }

                    // Grid {
                    //     id: thirdRow
                    //     columns: 2
                    //     rows: 1
                    //     anchors.left: parent.left
                    //     anchors.leftMargin: 8
                    //     anchors.right: parent.right
                    //     anchors.rightMargin: 8

                    //     LabelPL {
                    //         id: diffTimeLabel
                    //         width: parent.width / 6
                    //         horizontalAlignment: Text.AlignLeft
                    //         // text: model['con0']['dp_time_hh'] + ":" + model['con0']['dp_time_mm']
                    //         text: "30 min"
                    //     }

                    //     LabelPL {
                    //         id: namesLabel
                    //         width: parent.width - diffTimeLabel.width
                    //         horizontalAlignment: Text.AlignLeft
                    //         // text: model['con0']['destination']
                    //         text: "Velbert-Langenberg"
                    //     }

                    // }

                    Spacer {
                        height: styler.themePaddingLarge
                    }

                    // Rectangle {
                    //     height: 1
                    //     anchors.left: parent.left
                    //     anchors.leftMargin: styler.themeHorizontalPageMargin
                    //     anchors.right: parent.right
                    //     anchors.rightMargin: styler.themeHorizontalPageMargin
                    //     color: "gray"
                    // }

                }

                onClicked: {
                    console.log('Count: ', model['count']);
                    console.log('Test: ', model['con1']['name']);
                }

            }

        }

    }

    function getTransferTime(ar_time_hh, ar_time_mm, dp_time_hh, dp_time_mm) {
        var diff_minutes = Math.abs(parseInt(ar_time_mm) - parseInt(dp_time_mm));
        var hour_diff = Math.abs(parseInt(ar_time_hh) - parseInt(dp_time_hh))

        if (hour_diff > 0) {
            diff_minutes = Math.abs(diff_minutes - 60);
        }
        
        return diff_minutes

    }

    function destinationCallback(data) {
        selectedStation = data;
        pickDestinationButton.text = selectedStation['name'];
        searchButton.enabled = true;
    }

}
