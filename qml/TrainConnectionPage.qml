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

    property var  connectionDict
    property bool hasTransfer

    Column {
        id: column
        width: page.width

        Rectangle {
            height: 2
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            color: "gray"
        }

        LabelPL {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            text: connectionDict['con0']['type'] + " " + connectionDict['con0']['name'] + " -> " + connectionDict['con0']['destination']
            font.pixelSize: styler.themeFontSizeLarge
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            height: 1
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
            id: headerOneGrid
            columns: 3
            rows: 1
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin

            LabelPL {
                id: timeOneHeader
                width: page.width / 7
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Time")
            }

            LabelPL {
                id: directionOneHeader
                width: page.width - (2 * styler.themeHorizontalPageMargin + timeOneHeader.width + trackOneHeader.width)
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Station")
            }

            LabelPL {
                id: trackOneHeader
                width: page.width / 4
                horizontalAlignment: Text.AlignRight
                text: app.tr("Track")
            }
        } 

        Rectangle {
            height: 1
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
            id: dpOneGrid
            columns: 3
            rows: 1
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin

            LabelPL {
                id: dpTimeOneLabel
                width: page.width / 7
                horizontalAlignment: Text.AlignLeft
                text: connectionDict['con0']['dp_time_hh'] + ":" + connectionDict['con0']['dp_time_mm']
            }

            LabelPL {
                id: dpDirectionOneLabel
                width: page.width - (2 * styler.themeHorizontalPageMargin + dpTimeOneLabel.width + dpTrackOneLabel.width)
                horizontalAlignment: Text.AlignLeft
                text: connectionDict['con0']['start']
            }

            LabelPL {
                id: dpTrackOneLabel
                width: page.width / 4
                horizontalAlignment: Text.AlignRight
                text: connectionDict['con0']['dp_track']
            }
        } 

        Spacer {
            height: styler.themePaddingLarge
        }

        Grid {
            id: arOneGrid
            columns: 3
            rows: 1
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin

            LabelPL {
                id: arTimeOneLabel
                width: page.width / 7
                horizontalAlignment: Text.AlignLeft
                text: connectionDict['con0']['ar_time_hh'] + ":" + connectionDict['con0']['ar_time_mm']
            }

            LabelPL {
                id: arDirectionOneLabel
                width: page.width - (2 * styler.themeHorizontalPageMargin + arTimeOneLabel.width + arTrackOneLabel.width)
                horizontalAlignment: Text.AlignLeft
                text: connectionDict['con0']['target']
            }

            LabelPL {
                id: arTrackOneLabel
                width: page.width / 4
                horizontalAlignment: Text.AlignRight
                text: connectionDict['con0']['ar_track']
            }
        } 

        Spacer {
            height: styler.themePaddingMedium
        }

        Rectangle {
            height: 2
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            color: "gray"
        }

        Spacer {
            height: styler.themePaddingLarge
        }

        LabelPL {
            visible: hasTransfer
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            text: getTimeDifference(connectionDict['con0']['ar_time_hh'], connectionDict['con0']['ar_time_mm'], connectionDict['con1']['dp_time_hh'], connectionDict['con1']['dp_time_mm']) + " minutes transfer"
            font.pixelSize: styler.themeFontSizeMedium
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        } 

        Spacer {
            visible: hasTransfer
            height: styler.themePaddingLarge
        }

        Rectangle {
            visible: hasTransfer
            height: 2
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            color: "gray"
        }

        LabelPL {
            visible: hasTransfer
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            text: connectionDict['con1']['type'] + " " + connectionDict['con1']['name'] + " -> " + connectionDict['con1']['destination']
            font.pixelSize: styler.themeFontSizeLarge
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            visible: hasTransfer
            height: 1
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            color: "gray"
        }

        Spacer {
            visible: hasTransfer
            height: styler.themePaddingMedium
        }

        Grid {
            id: headerTwoGrid
            visible: hasTransfer
            columns: 3
            rows: 1
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin

            LabelPL {
                id: timeTwoHeader
                width: page.width / 7
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Time")
            }

            LabelPL {
                id: directionTwoHeader
                width: page.width - (2 * styler.themeHorizontalPageMargin + timeTwoHeader.width + trackTwoHeader.width)
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Direction")
            }

            LabelPL {
                id: trackTwoHeader
                width: page.width / 4
                horizontalAlignment: Text.AlignRight
                text: app.tr("Track")
            }
        } 

        Rectangle {
            visible: hasTransfer
            height: 1
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin
            color: "gray"
        }

        Spacer {
            visible: hasTransfer
            height: styler.themePaddingMedium
        }

        Grid {
            id: dpTwoGrid
            visible: hasTransfer
            columns: 3
            rows: 1
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin

            LabelPL {
                id: dpTimeTwoLabel
                width: page.width / 7
                horizontalAlignment: Text.AlignLeft
                text: connectionDict['con1']['dp_time_hh'] + ":" + connectionDict['con1']['dp_time_mm']
            }

            LabelPL {
                id: dpDirectionTwoLabel
                width: page.width - (2 * styler.themeHorizontalPageMargin + dpTimeTwoLabel.width + dpTrackTwoLabel.width)
                horizontalAlignment: Text.AlignLeft
                text: connectionDict['con1']['start']
            }

            LabelPL {
                id: dpTrackTwoLabel
                width: page.width / 4
                horizontalAlignment: Text.AlignRight
                text: connectionDict['con1']['dp_track']
            }
        } 

        Spacer {
            visible: hasTransfer
            height: styler.themePaddingLarge
        }

        Grid {
            id: arTwoGrid
            visible: hasTransfer
            columns: 3
            rows: 1
            anchors.left: parent.left
            anchors.leftMargin: styler.themeHorizontalPageMargin
            anchors.right: parent.right
            anchors.rightMargin: styler.themeHorizontalPageMargin

            LabelPL {
                id: arTimeTwoLabel
                width: page.width / 7
                horizontalAlignment: Text.AlignLeft
                text: connectionDict['con1']['ar_time_hh'] + ":" + connectionDict['con1']['ar_time_mm']
            }

            LabelPL {
                id: arDirectionTwoLabel
                width: page.width - (2 * styler.themeHorizontalPageMargin + arTimeTwoLabel.width + arTrackTwoLabel.width)
                horizontalAlignment: Text.AlignLeft
                text: connectionDict['con1']['target']
            }

            LabelPL {
                id: arTrackTwoLabel
                width: page.width / 4
                horizontalAlignment: Text.AlignRight
                text: connectionDict['con1']['ar_track']
            }
        } 

        Spacer {
            visible: hasTransfer
            height: styler.themePaddingMedium
        }

        Rectangle {
            visible: hasTransfer
            height: 2
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            color: "gray"
        }

        Spacer {
            height: styler.themePaddingMedium
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: app.tr('The times indicated are timetable times, not real-time')
            truncMode: truncModes.none
            verticalAlignment: Text.AlignTop
        } 

    }

    function getTimeDifference(time_one_hh, time_one_mm, time_two_hh, time_two_mm) {
        var diff_minutes = Math.abs(parseInt(time_one_mm) - parseInt(time_two_mm));
        var hour_diff = Math.abs(parseInt(time_one_hh) - parseInt(time_two_hh));

        if (hour_diff > 0) {
            diff_minutes = Math.abs(diff_minutes - 60);
        }

        return diff_minutes;

    }

}