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

        Row {
            id: searchRow
            width: parent.width
            height: Math.max(searchFieldLabel.height, searchField.height)

            LabelPL {
                id: searchFieldLabel
                text: app.tr('    Destination: ')
                width: searchRow.width / 4.5
                verticalAlignment: Text.AlignVCenter
                height: searchField.height
            }

            TextFieldPL {
                id: searchField
                width: parent.width - searchFieldLabel.width
                placeholderText: app.tr("Search Target")
                property string lastText: ""
                onTextChanged: {
                    var newText = searchField.text.trim();
                    if (Math.abs(newText.length - lastText.length) <= 1) {
                        if (newText.length > 0) {
                            searchResultList.model.clear();
                            showResults = false;
                            py.call("poor.app.trainconnections.get_suggestions", [poi.coordinate.latitude, poi.coordinate.longitude, newText], function(results) {
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
                        searchButtonEnabled = true
                    }
                }
                Keys.onReturnPressed: {
                    searchField.fokus = false;
                    searchResultList.model.clear();
                    showResults = false;
                    searchButtonEnabled = true
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
                    selectedStation = model;
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
                console.log('Startkoordinaten: ', poi.coordinate.latitude, poi.coordinate.longitude);
                console.log('Zielname: ', selectedStation['name']);
                console.log('Eva: ', selectedStation['eva']);
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

        // Connection informations

    }

}
