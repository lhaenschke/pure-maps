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
            text: ""
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
            visible: timetableHeader.text

            LabelPL {
                id: depTimeHeader
                width: headerRow.width / 6
                horizontalAlignment: Text.AlignLeft
                text: app.tr("    Time")
            }

            LabelPL {
                id: nameHeader
                width: headerRow.width / 6
                horizontalAlignment: Text.AlignLeft
                text: app.tr("   Name")
            }

            LabelPL {
                id: directionHeader
                width: headerRow.width / 2
                horizontalAlignment: Text.AlignLeft
                text: app.tr("  Direction")
            }

            LabelPL {
                id: trackItem
                width: headerRow.width / 6
                horizontalAlignment: Text.AlignRight
                text: app.tr("Track  ")
            }

        }        

        Repeater {
            id: list
            width: page.width
            
            delegate: ListItemPL {
                id: listItem
                contentHeight: listColumn.height
                
                property bool isVisible: false

                Column {
                    id: listColumn
                    width: page.width

                    Row {
                        id: row
                        height: Math.max(depTimeItem.height, nameItem.height, directionItem.height, trackItem.height) + 10
                        width: parent.width

                        LabelPL {
                            id: depTimeItem
                            width: row.width / 6
                            horizontalAlignment: Text.AlignLeft
                            text: "  " + model['dep_time_hh'] + ":" + model['dep_time_mm']
                        }

                        LabelPL {
                            id: nameItem
                            width: row.width / 6
                            horizontalAlignment: Text.AlignLeft
                            text: " " + model['type'] + " " + model['name']
                        }

                        LabelPL {
                            id: directionItem
                            width: row.width / 2
                            horizontalAlignment: Text.AlignLeft
                            text: model['destination']
                        }

                        LabelPL {
                            id: trackItem
                            width: row.width / 6
                            horizontalAlignment: Text.AlignRight
                            text: model['track'] + "    "
                        }

                    }

                    ListItemLabel {
                        color: styler.themeHighlightColor
                        height: implicitHeight
                        text: ""
                    }

                    Repeater {
                        id: infoList
                        width: page.width

                        delegate: ListItemPL {
                            id: infoListItem
                            contentHeight: infoRow.height
                            width: page.width

                            Row {
                                id: infoRow
                                height: Math.max(infoDepTimeItem.height, infoNameItem.height, infoDirectionItem.height, infoTrackItem.height) + 10
                                width: parent.width

                                LabelPL {
                                    id: infoDepTimeItem
                                    width: infoRow.width / 6
                                    horizontalAlignment: Text.AlignLeft
                                    text: (model['dep_time_hh'] ? model['dep_time_hh'] + ":" + model['dep_time_mm'] : "")
                                }

                                LabelPL {
                                    id: infoNameItem
                                    width: infoRow.width / 6
                                    horizontalAlignment: Text.AlignLeft
                                    text: model['type'] + " " + model['name']
                                }

                                LabelPL {
                                    id: infoDirectionItem
                                    width: infoRow.width / 2
                                    horizontalAlignment: Text.AlignLeft
                                    text: model['destination']
                                }

                                LabelPL {
                                    id: infoTrackItem
                                    width: infoRow.width / 6
                                    horizontalAlignment: Text.AlignRight
                                    text: model['track'] + " "
                                }

                            }

                            onClicked: {
                                if (model['dep_time_hh'] == "") {
                                    py.call("poor.app.timetables.load_destination_informations", [model['train_id'], model['destination'], selectedTime], function(result) {
                                        var arr = result.split('|');
                                        model['dep_time_hh'] = arr[0];
                                        model['dep_time_mm'] = arr[1];
                                        model['track'] = arr[2];
                                    });
                                }
                            }

                        }

                        model: ListModel {}

                        function fillInfoModel(type, name, next_stops, id) {
                            infoList.model.clear()

                            var arr = next_stops.split('|');
                            for (var i = 0; i < arr.length; i++) {
                                var dict = {
                                    "type": type,
                                    "name": name,
                                    "train_id": id,
                                    "dep_time_hh": "",
                                    "dep_time_mm": "",
                                    "destination": arr[i],
                                    "track": ""
                                };
                                infoList.model.append(dict);
                            }

                        }

                        function clearInfoModel() {
                            infoList.model.clear()
                        }

                    }

                    ListItemLabel {
                        color: styler.themeHighlightColor
                        height: implicitHeight
                        text: ""
                        visible: true
                    }

                    Rectangle {
                        id: listSeperator
                        width: page.width
                        height: 1
                        color: "gray"
                    }

                }

                onClicked: {
                    isVisible = !isVisible;
                    
                    if (isVisible) {
                        infoList.fillInfoModel(model['type'], model['name'], model['next_stops'], model['train_id']);
                    } else {
                        infoList.clearInfoModel();
                    }

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

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight
            visible: list.isVisible
            text: app.tr('Press on stop to load further information information')
            horizontalAlignment: Text.AlignHCenter
        }

    }

}
