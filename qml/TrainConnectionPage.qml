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
    title: app.tr("Details")

    property var connectionDict

    Column {
        id: column
        width: page.width

        Rectangle {
            height: 2
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            color: "gray"
        }

        LabelPL {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            text: connectionDict['con0']['type'] + connectionDict['con0']['name']
            font.pixelSize: styler.themeFontSizeLarge
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            height: 2
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            color: "gray"
        }

        Spacer {
            height: styler.themePaddingMedium
        }

        Grid {
            id: headerGrid
            columns: 3
            rows: 1
            spacing: styler.themePaddingMedium
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin

            LabelPL {
                id: depTimeHeader
                width: page.width / 8
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Time")
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

        LabelPL {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            text: app.tr('The times indicated are timetable times, not real-time')
        } 

    }

}