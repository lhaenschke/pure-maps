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
    title: app.tr("Timetables for") + poi.title

    pageMenu: PageMenuPL {
        PageMenuItemPL {
            enabled: page.active
            iconName: styler.iconEdit
            text: app.tr("Reload")
            onClicked: {
                
            }
        }
    }

    property bool active: false
    property var  poi

    Column {
        id: column
        width: page.width

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: poi.poiType ? poi.poiType : ""
            truncMode: truncModes.none
            verticalAlignment: Text.AlignTop
            visible: text
            wrapMode: Text.WordWrap
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            font.pixelSize: styler.themeFontSizeSmall
            height: implicitHeight + styler.themePaddingMedium
            text: hasCoordinate ? app.tr("Latitude: %1", poi.coordinate.latitude) + "\n" +
                                  app.tr("Longitude: %2", poi.coordinate.longitude) : ""
            truncMode: truncModes.none
            verticalAlignment: Text.AlignTop
            visible: text
            wrapMode: Text.WordWrap
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            font.pixelSize: styler.themeFontSizeSmall
            height: implicitHeight + styler.themePaddingMedium
            text: hasCoordinate ? app.tr("Plus code: %1",
                                         py.call_sync("poor.util.format_location_olc",
                                                      [poi.coordinate.longitude,
                                                       poi.coordinate.latitude])) : ""
            truncMode: truncModes.none
            verticalAlignment: Text.AlignTop
            visible: text
            wrapMode: Text.WordWrap
        }

        Spacer {
            height: styler.themePaddingMedium
        }

        SectionHeaderPL {
            height: implicitHeight + styler.themePaddingMedium
            text: poi.address || poi.postcode ? app.tr("Address") : ""
            visible: text
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: poi.address ? poi.address : ""
            truncMode: truncModes.none
            verticalAlignment: Text.AlignTop
            visible: text
            wrapMode: Text.WordWrap
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: poi.postcode ? app.tr("Postal code: %1", poi.postcode) : ""
            truncMode: truncModes.none
            verticalAlignment: Text.AlignTop
            visible: text
            wrapMode: Text.WordWrap
        }
        
    }
}
