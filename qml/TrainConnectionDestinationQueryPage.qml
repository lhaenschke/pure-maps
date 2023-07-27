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

PageListPL {
    id: page
    title: app.tr("Search Destination")

    property string lastQuery: ""
    property string latitude: ""
    property string longitude: ""
    property var    callback
    property var    searchField: undefined
    property bool   showCache: true

    model: showCache ? chacheModel : queryModel

    delegate: ListItemPL {
        id: listItem
        contentHeight: column.height

        Column {
            id: column
            width: page.width

            Spacer {
                height: styler.themePaddingLarge / 2
            }

            ListItemLabel {
                color: listItem.highlighted ? styler.themeHighlightColor : styler.themePrimaryColor
                height: implicitHeight + styler.themePaddingMedium
                text: searchField.length > 0 ? location.name : model['name']
                verticalAlignment: Text.AlignVCenter
            }

            Spacer {
                height: styler.themePaddingLarge / 2
            }

            Rectangle {
                height: 1
                width: column.width
                anchors.left: parent.left
                anchors.leftMargin: 8
                color: "gray"
            }

        }

        onClicked: {
            if (searchField.length > 0) {
                py.call_sync("poor.app.history.add_kpt_location", [location.name, location.latitude, location.longitude]);
                callback(location);
            } else {
                callback(TrainConnection.getCacheLocation(model['latitude'], model['longitude'], model['name']));
            }
    
            app.pages.pop();

        }

    }

    headerExtra: Component {
        SearchFieldPL {
            id: searchField
            placeholderText: app.tr("Search")
            property string prevText: ""
            onTextChanged: {
                var newText = searchField.text.trim();
                if (newText.length > 0) showCache = false;
                if (newText === lastQuery) return;
                queryModel.request = TrainConnection.createLocationRequest(newText);
                lastQuery = newText;
            }

            Component.onCompleted: page.searchField = searchField;
        }
    }

    KPT.LocationQueryModel {
        id: queryModel
        manager: Manager
    }

    ListModel {
        id: chacheModel
    }

    onPageStatusActivating: {
        const kpt_locations = py.evaluate("poor.app.history.kpt_locations");
        kpt_locations.forEach( function(x) { chacheModel.append(x); } );
    }

}