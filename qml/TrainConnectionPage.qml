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

    property var poi
    property var showResults: false

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
                onTextChanged: {
                    console.log('test')
                    var newText = searchField.text.trim();
                    searchResultList.model.clear();
                    showResults = false;
                    if (newText.length > 0) {
                        py.call("poor.app.trainconnections.get_suggestions", [poi.coordinate.latitude, poi.coordinate.longitude, newText], function(results) {
                            results.forEach( function(p) { searchResultList.model.append(p); });
                            showResults = (model.count > 0);
                        });
                    }
                }
                Keys.onReturnPressed: {
                    searchField.fokus = false;
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
                    searchField.text = model['name']
                    showResults = false;
                }

            }

            model: ListModel {}

        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: app.tr('The times indicated are timetable times, not real-time')
            truncMode: truncModes.none
            visible: showResults
            verticalAlignment: Text.AlignTop
        } 

        Spacer {
            height: styler.themePaddingMedium
        }

        // Connection informations

    }

}
