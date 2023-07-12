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
    title: app.tr("Timetables for ") + poi.title

    property var  poi
    property bool showResults: false
    property bool searchButtonEnabled: false
    property var  selectedStation
    property int  connectionRows: 1

    Column {
        id: column
        width: page.width

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: poi.address ? app.tr('Start-Station: ') + poi.address : ""
            truncMode: truncModes.none
            verticalAlignment: Text.AlignTop
            wrapMode: Text.WordWrap
        }

        Grid {
            id: searchGrid
            columns: 4
            rows: 1
            spacing: styler.themePaddingMedium
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin

            LabelPL {
                id: searchFieldLabel
                text: app.tr('Destination: ')
                width: page.width / 6
                verticalAlignment: Text.AlignVCenter
                height: searchField.height
            }

            TextFieldPL {
                id: searchField
                width: (page.width - searchFieldLabel.width) - (2* styler.themeHorizontalPageMargin)
                placeholderText: app.tr("Search Target")
                property string lastText: ""
                onTextChanged: {
                    var newText = searchField.text.trim();
                    if (Math.abs(newText.length - lastText.length) <= 1) {
                        if (newText.length > 0) {
                            searchResultList.model.clear();
                            showResults = false;
                            py.call("poor.app.trainconnections.get_suggestions", [newText, poi.coordinate.latitude, poi.coordinate.longitude], function(results) {
                                searchResultList.model.clear();
                                results.forEach( function(p) { searchResultList.model.append(p); });
                                showResults = (searchResultList.model.count > 0);
                            });
                        } else {
                            searchResultList.model.clear();
                            showResults = false;
                        }
                        lastText = newText;
                    } else {
                        searchResultList.model.clear();
                        showResults = false;
                        searchButtonEnabled = true;
                    }
                }
                Keys.onReturnPressed: {
                    searchField.fokus = false;
                    searchResultList.model.clear();
                    showResults = false;
                    searchButtonEnabled = true;
                }
            }

        }

        Repeater {
            id: searchResultList
            width: page.width
            visible: showResults
            
            delegate: ListItemPL {
                id: listItem
                contentHeight: listColumn.height
                
                property bool isVisible: false

                Column {
                    id: listColumn
                    width: page.width

                    ListItemLabel {
                        height: implicitHeight
                        text: ""
                        visible: true
                    }

                    ListItemLabel {
                        color: styler.themeHighlightColor
                        height: implicitHeight
                        text: model['name']
                    }

                    ListItemLabel {
                        height: implicitHeight
                        text: ""
                        visible: true
                    }

                    Rectangle {
                        id: listSeperator
                        width: page.width - 20
                        height: 1
                        color: "gray"
                    }

                }

                onClicked: {
                    selectedStation = [model['name'], model['eva']];
                    console.log("SelectedStation: ", selectedStation);
                    searchField.text = model['name'];
                }

            }

            model: ListModel {}

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
            enabled: searchButtonEnabled
            text: app.tr("Search")
            onClicked: {
                searchButtonEnabled = false;
                searchButton.text = app.tr("Loading");

                searchResultList.model.clear();
                showResults = false;
                searchButtonEnabled = true;

                connectionRepeater.model = ListModel {};

                py.call("poor.app.trainconnections.search_connections", [poi.coordinate.latitude, poi.coordinate.longitude, selectedStation[1], selectedStation[0]], function(results) {
                    searchButton.enabled = true;
                    searchButton.text = app.tr("Search");
                    
                    results.forEach( function (p) { 
                        var dict = {};
                        for (var i = 0; i < p.length; i++) {
                            const key = 'con' + i;
                            dict[key] = p[i];
                            dict['count'] = i + 1;
                        }
                        if (parseInt(dict['count']) > 1) {
                            connectionRows = 4;
                            console.log('Name (con1): ', dict['con1']['name']);
                            console.log('Type (con1): ', dict['con1']['type']);
                        } else {
                            connectionRows = 1;
                        }
                        connectionRepeater.model.append(dict);
                    });
                    
                });

            }
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: app.tr('The times indicated are timetable times, not real-time')
            truncMode: truncModes.none
            visible: false
            verticalAlignment: Text.AlignTop
        } 

        Spacer {
            height: styler.themePaddingMedium
        }

        Grid {
            id: headerGrid
            columns: 4
            rows: 1
            spacing: styler.themePaddingMedium
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            visible: connectionRepeater.model.count > 0

            LabelPL {
                id: depTimeHeader
                width: page.width / 8
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Time")
            }

            LabelPL {
                id: nameHeader
                width: page.width / 6
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Name")
            }

            LabelPL {
                id: directionHeader
                width: page.width / 2.35
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Direction")
            }

            LabelPL {
                id: trackItem
                width: page.width / 8
                horizontalAlignment: Text.AlignRight
                text: app.tr("Track")
            }
        }

        Rectangle {
            id: listSeperator
            width: page.width - 20
            height: 1
            color: "gray"
            visible: connectionRepeater.model.count > 0
        }

        Repeater {
            id: connectionRepeater
            width: page.width
            visible: model.count > 0

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

                    Grid {
                        id: connectionGrid
                        columns: 1
                        rows: connectionRows
                        spacing: styler.themePaddingMedium
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8

                        Grid {
                            id: connectionOneGrid
                            columns: 4
                            rows: 1
                            spacing: styler.themePaddingMedium
                            anchors.leftMargin: 0
                            anchors.rightMargin: 0

                            LabelPL {
                                id: depTimeLabel
                                width: page.width / 8
                                horizontalAlignment: Text.AlignLeft
                                text: model['con0']['dp_time_hh'] + ":" + model['con0']['dp_time_mm']
                            }

                            LabelPL {
                                id: nameLabel
                                width: page.width / 6
                                horizontalAlignment: Text.AlignLeft
                                text: model['con0']['type'] + " " + model['con0']['name']
                            }

                            LabelPL {
                                id: directionLabel
                                width: page.width / 2.35
                                horizontalAlignment: Text.AlignLeft
                                text: model['con0']['destination']
                            }

                            LabelPL {
                                id: trackLabel
                                width: page.width / 8
                                horizontalAlignment: Text.AlignRight
                                text: model['con0']['dp_track']
                            }
                        }

                        Grid {
                            id: tranferNameGrid
                            columns: 1
                            rows: 1
                            spacing: styler.themePaddingMedium
                            visible: connectionRows > 1

                            LabelPL {
                                id: transferNameLabel
                                 width: page.width
                                horizontalAlignment: Text.AlignLeft
                                text: app.tr('    Transfer-Station: ') + model['con0']['transfer']
                            }
                        }

                        Grid {
                            id: tranferTimeGrid
                            columns: 1
                            rows: 1
                            spacing: styler.themePaddingMedium
                            visible: connectionRows > 1

                            LabelPL {
                                id: transferTimeLabel
                                width: page.width
                                horizontalAlignment: Text.AlignLeft
                                text: model['con1'] ? app.tr('    Transfer-Time: ') + page.getTransferTime(model['con0']['ar_time_hh'], model['con0']['ar_time_mm'], model['con1']['dp_time_hh'], model['con1']['dp_time_mm']) + app.tr(' Minutes') : "Kein con1"
                            }
                        }

                        Grid {
                            id: connectionTwoGrid
                            columns: 4
                            rows: 2
                            spacing: styler.themePaddingMedium
                            anchors.leftMargin: 0
                            anchors.rightMargin: 0
                            visible: connectionRows > 1

                            LabelPL {
                                id: depTimeTwoLabel
                                width: page.width / 8
                                horizontalAlignment: Text.AlignLeft
                                text: model['con1'] ? model['con1']['dp_time_hh'] + ":" + model['con1']['dp_time_mm'] : "Kein con1"
                            }

                            LabelPL {
                                id: nameTwoLabel
                                width: page.width / 6
                                horizontalAlignment: Text.AlignLeft
                                text: model['con1'] ? model['con1']['type'] + " " + model['con1']['name'] : "Kein con1"
                            }

                            LabelPL {
                                id: directionTwoLabel
                                width: page.width / 2.35
                                horizontalAlignment: Text.AlignLeft
                                text: model['con1'] ? model['con1']['destination'] : "Kein con1"
                            }

                            LabelPL {
                                id: trackTwoLabel
                                width: page.width / 8
                                horizontalAlignment: Text.AlignRight
                                text: model['con1'] ? model['con1']['dp_track'] : "Kein con1"
                            }

                        }

                    }

                    Spacer {
                        height: styler.themePaddingLarge
                    }

                    Rectangle {
                        id: listSeperator
                        width: page.width - 20
                        height: 1
                        color: "gray"
                    }

                }

            }

            model: ListModel {}

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

}
