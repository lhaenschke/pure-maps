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
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingSmall
            text: ""
        }

        ButtonPL {
            id: searchButton
            anchors.horizontalCenter: parent.horizontalCenter
            preferredWidth: styler.themeButtonWidthLarge
            text: app.tr("Search")
            onClicked: {
                searchButton.text = app.tr("Loading");
                py.call_sync("poor.app.timetables.search", [poi.coordinate.latitude, poi.coordinate.longitude, selectedTime]);
                list.fillModel();
            }
        }

        Spacer {
            height: styler.themePaddingLarge
        }

        SectionHeaderPL {
            id: timetableHeader
            anchors.horizontalCenter: parent.horizontalCenter
            text: "timetableHeader"
            visible: text
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight
            text: ""
        }

        Row {
            id: headerRow
            height: Math.max(depTimeHeader.height, nameHeader.height, directionHeader.height, trackItem.height)
            width: parent.width

            property real itemWidth: width / 4

            LabelPL {
                id: depTimeHeader
                width: headerRow.itemWidth
                horizontalAlignment: Text.AlignLeft
                text: app.tr("  Dep. Time")
            }

            LabelPL {
                id: nameHeader
                width: headerRow.itemWidth
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Type/Name")
            }

            LabelPL {
                id: directionHeader
                width: headerRow.itemWidth + styler.themePaddingMedium
                horizontalAlignment: Text.AlignLeft
                text: app.tr("Direction")
            }

            LabelPL {
                id: trackItem
                width: headerRow.itemWidth - styler.themePaddingMedium
                horizontalAlignment: Text.AlignRight
                text: app.tr("Track   ")
            }

        }        
        
        Spacer {
            height: styler.themePaddingSmall
        }

        Repeater {
            id: list
            width: parent.width
            
            delegate: ListItemPL {
                id: listItem
                contentHeight: itemContentHeight
                
                property var itemContentHeight: row.height + infoLabel.height + listSpacer.height
                property bool isVisible: false
                property string nextStopsText: ""

                Row {
                    id: row
                    height: Math.max(depTimeItem.height, nameItem.height, directionItem.height, trackItem.height) + 10
                    width: parent.width

                    property real itemWidth: width / 4

                    LabelPL {
                        id: depTimeItem
                        width: row.itemWidth
                        horizontalAlignment: Text.AlignLeft
                        text: model['dep_time_hh'] + ":" + model['dep_time_mm']
                    }

                    LabelPL {
                        id: nameItem
                        width: row.itemWidth
                        horizontalAlignment: Text.AlignLeft
                        text: model['type'] + " " + model['name']
                    }

                    LabelPL {
                        id: directionItem
                        width: row.itemWidth + styler.themePaddingMedium
                        horizontalAlignment: Text.AlignLeft
                        text: " " + model['destination']
                    }

                    LabelPL {
                        id: trackItem
                        width: row.itemWidth - styler.themePaddingMedium
                        horizontalAlignment: Text.AlignRight
                        text: model['track']
                    }

                }

                ListItemLabel {
                    id: infoLabel
                    color: styler.themeHighlightColor
                    height: implicitHeight
                    text: nextStopsText
                    visible: text
                    anchors.top: row.bottom
                }

                Spacer {
                    id: listSpacer
                    height: styler.themePaddingMedium
                    anchors.top: infoLabel.bottom
                }

                onClicked: {
                    isVisible = !isVisible;
                    nextStopsText = "";

                    if (isVisible) {
                        var arr = model['next_stops'].split('|');
                        for (var i = 0; i < arr.length; i++) {
                            arr[i] = arr [i] + '\n';
                            nextStopsText += arr[i];
                        }

                        py.call("poor.app.timetables.load_destination_informations", [model['train_id'], model['destination'], selectedTime], function(result) {
                            var arr = result.split('|');
                            console.log(arr[0]);
                            console.log(arr[1]);
                        });
                    }

                    // testText = " " + model['destination'] + model['dest_arr_time_hh'] + ":" + model['dest_arr_time_mm'];

                    
                    
                }

            }

            model: ListModel {}

            function fillModel() {
                model.clear();
                py.call("poor.app.timetables.get_trains", [], function(results) {
                    results.forEach( function (p) { model.append(p); });
                    searchButton.text = "Search";
                    timetableHeader.text = app.tr('Timetables for ') + Qt.formatDateTime(new Date(), "dd.MM.yyyy") + " at " + selectedTime + ":00";
                });
            }
            
        }

    }

}
