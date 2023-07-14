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

PageListPL {
    id: page
    title: app.tr("Search Destination")

    currentIndex: -1

    delegate: ListItemPL {
        id: listItem
        contentHeight: titleItem.height + spacer.height*2

        Spacer {
            id: spacer
            height: styler.themePaddingLarge/2
        }

        ListItemLabel {
            id: titleItem
            anchors.leftMargin: page.searchField.textLeftMargin
            anchors.top: spacer.bottom
            color: listItem.highlighted ? styler.themeHighlightColor : styler.themePrimaryColor
            height: implicitHeight + styler.themePaddingSmall
            text: {
                if (model['status'] == 200) {
                    return model['name'];
                } else {
                    return "";
                }
            }
            verticalAlignment: Text.AlignTop
        }

        onClicked: {
            console.log('Test');
        }

    }

    headerExtra: Component {
        SearchFieldPL {
            id: searchField
            placeholderText: app.tr("Search")
            onTextChanged: {
                var newText = searchField.text.trim().toLowerCase();
                if (newText === lastQuery) return;
                fillModel(newText);
                lastQuery = newText;
            }

            Component.onCompleted: page.searchField = searchField;
        }
    }

    model: ListModel {}

    placeholderEnabled: pois.pois.length === 0
    placeholderText: app.tr("No points of bookmarks defined yet. You can bookmark locations using map and search.")

    property var    searchField: undefined
    property string lastQuery: ""
    property string latitude: ""
    property string longitude: ""

    Component.onCompleted: {
        fillModel('Complete');
    }

    function fillModel(query) {
        py.call("poor.app.trainconnections.get_suggestions", [query, latitude, longitude], function(results) {
            page.model.clear();
            results.forEach( function(p) { page.model.append(p); });
        });
    }

}