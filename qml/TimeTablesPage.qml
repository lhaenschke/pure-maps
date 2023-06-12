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
    property int selectedTime: 0

    Column {
        id: column
        width: page.width

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: poi.address ? poi.address : ""
            truncMode: truncModes.none
            verticalAlignment: Text.AlignTop
            visible: text
            wrapMode: Text.WordWrap
        }

        Spacer {
            height: styler.themePaddingMedium
        }

        ComboBoxPL {
            id: timeRangeComboBox
            label: app.tr("Time-Range")
            model: [ "0:00", "1:00", "2:00", "3:00", "4:00", "5:00", "6:00", "7:00", "8:00", "9:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00" ]
            property var values: [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 ]
            currentIndex: 3
            Component.onCompleted: {
                selectedTime = parseInt(Qt.formatTime(new Date(),"hh"))
                timeRangeComboBox.currentIndex = timeRangeComboBox.values.indexOf(selectedTime);
            }
            onCurrentIndexChanged: {
                var index = timeRangeComboBox.currentIndex;
                selectedTime = timeRangeComboBox.values[index];
            }   
        }

        ListItemLabel {
            text: ""
            truncMode: truncModes.none
            visible: true
            wrapMode: Text.WordWrap
        }

        ButtonPL {
            anchors.horizontalCenter: parent.horizontalCenter
            preferredWidth: styler.themeButtonWidthLarge
            text: app.tr("Search")
            onClicked: {
                py.call_sync("poor.app.timetables.search", [poi.coordinate.latitude, poi.coordinate.longitude, selectedTime]);
                list.fillModel();
            }
        }

        Spacer {
            height: styler.themePaddingMedium
        }

        SectionHeaderPL {
            text: app.tr("Timetables")
        }
        
        Repeater {
            id: list
            width: parent.width
            delegate: ListItemPL {
                id: listItem
                contentHeight: narrativeLabel.height

                LabelPL {
                    id: narrativeLabel
                    anchors.leftMargin: styler.themePaddingMedium
                    anchors.right: parent.right
                    anchors.rightMargin: styler.themeHorizontalPageMargin
                    color: styler.themePrimaryColor
                    height: implicitHeight + styler.themePaddingSmall
                    text: model['type']
                    verticalAlignment: Text.AlignTop
                    wrapMode: Text.WordWrap
                }

                onClicked: {
                    console.log("Clicked");
                }

            }

            model: ListModel {}

            property int activeItem: -1

            function fillModel() {
                model.clear();
                py.call("poor.app.timetables.get_trains", [], function(results) {
                    results.forEach( function (p) { model.append(p); });
                    
                    for (var i = 0; i < 3; i++) {
                        console.log(model[i]['name']);
                    }

                });
            }
            
        }

    }
}
