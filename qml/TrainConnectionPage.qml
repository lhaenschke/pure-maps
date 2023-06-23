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
            height: searchFieldLabel.height

            LabelPL {
                id: searchFieldLabel
                text: app.tr('Destination: ')
                width: searchRow.width / 2
            }

        }

        TextFieldPL {
            id: searchField
            width: parent.width / 2
            placeholderText: app.tr("Search Target")
            onTextChanged: {
                var newText = searchField.text.trim();
                if (newText.length > 0) {
                    py.call("poor.app.trainconnections.get_suggestions", [poi.coordinate.latitude, poi.coordinate.longitude, newText], function(results) {
                        results.forEach( function(p) { console.log(p); });
                    });
                } else {
                    // Clear model to empty search
                }
            }
            Keys.onReturnPressed: {
                searchField.fokus = false;
            }
        }

        // SearchFieldPL {
        //     id: searchField
        //     width: parent.width / 2
        //     placeholderText: app.tr("Search Target")
        //     property string prevText: ""
            // onTextChanged: {
            //     var newText = searchField.text.trim();
            //     if (newText.length > 0) {
            //         py.call("poor.app.trainconnections.get_suggestions", [poi.coordinate.latitude, poi.coordinate.longitude, newText], function(results) {
            //             results.forEach( function(p) { console.log(p); });
            //         });
            //     } else {
            //         // Clear model to empty search
            //     }
            // }
            // Keys.onReturnPressed: {
            //     searchField.fokus = false;
            // }
        // }

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
