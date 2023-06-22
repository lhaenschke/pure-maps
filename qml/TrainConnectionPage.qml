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

        SearchFieldPL {
            id: searchField
            placeholderText: app.tr("Search Target")
            property string prevText: ""
            onTextChanged: {
                var newText = searchField.text.trim();
                console.log(newText);
            }

            // Component.onCompleted: page.searchField = searchField;
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
