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
                fillModel();
            }
        }

        Spacer {
            height: styler.themePaddingMedium
        }

        currentIndex: -1

        delegate: ListItemPL {
            id: listItem
            contentHeight: titleItem.height + detailsItem.height + textItem.height + spacer.height*2

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
                text: (model.title ? model.title : app.tr("Unnamed point")) + (model.bookmarked ? " ☆" : "") + (model.shortlisted ? " ☰" : "")
                verticalAlignment: Text.AlignTop
            }

            ListItemLabel {
                id: detailsItem
                anchors.leftMargin: page.searchField.textLeftMargin
                anchors.top: titleItem.bottom
                color: listItem.highlighted ? styler.themeSecondaryHighlightColor : styler.themeSecondaryColor
                font.pixelSize: styler.themeFontSizeSmall
                height: text ? implicitHeight + styler.themePaddingSmall : 0
                text: {
                    if (model.poiType && model.address) return model.poiType + ", " + model.address;
                    if (model.poiType) return model.poiType;
                    return model.address;
                }
                verticalAlignment: Text.AlignTop
                wrapMode: Text.WordWrap
            }

            ListItemLabel {
                id: textItem
                anchors.leftMargin: page.searchField.textLeftMargin
                anchors.top: detailsItem.bottom
                anchors.topMargin: styler.themePaddingSmall
                color: listItem.highlighted ? styler.themeSecondaryHighlightColor : styler.themeSecondaryColor
                font.pixelSize: styler.themeFontSizeExtraSmall
                height: text ? implicitHeight : 0
                maximumLineCount: 1
                text: model.text
                truncMode: truncModes.elide
                verticalAlignment: Text.AlignTop
            }

            // menu: ContextMenuPL {
            //     id: contextMenu
            //     ContextMenuItemPL {
            //         iconName: styler.iconAbout
            //         text: app.tr("View")
            //         onClicked: {
            //             var poi = pois.getById(model.poiId);
            //             if (!poi) return;
            //             app.push(Qt.resolvedUrl("PoiInfoPage.qml"),
            //                     {"active": true, "poi": poi});
            //         }
            //     }
            //     ContextMenuItemPL {
            //         iconName: styler.iconEdit
            //         text: app.tr("Edit")
            //         onClicked: {
            //             var poi = pois.getById(model.poiId);
            //             if (!poi) return;
            //             var dialog = app.push(Qt.resolvedUrl("PoiEditPage.qml"),
            //                                 {"poi": poi});
            //             dialog.accepted.connect(function() {
            //                 pois.update(dialog.poi);
            //             })
            //         }
            //     }
            //     ContextMenuItemPL {
            //         iconName: styler.iconDelete
            //         text: app.tr("Remove")
            //         onClicked: {
            //             pois.remove(model.poiId);
            //         }
            //     }
            // }

            // onClicked: {
            //     var p = pois.getById(model.poiId);
            //     if (!p) {
            //         // poi got missing, let's refill
            //         fillModel(lastQuery);
            //         return;
            //     }
            //     app.stateId = "pois";
            //     pois.show(p, true);
            //     map.setCenter(
            //                 p.coordinate.longitude,
            //                 p.coordinate.latitude);
            //     app.hideMenu(app.tr("Bookmarks"));
            // }

        }

        model: ListModel {}

        placeholderEnabled: pois.pois.length === 0
        placeholderText: app.tr("An unknown problem has occurred. Possibly no connection to the Internet could be established or the station could not be found.")

        Component.onCompleted: {
            fillModel();
        }

        function fillModel() {
            var data = py.call_sync("poor.util.format_location_olc", [poi.coordinate.longitude, poi.coordinate.latitude])) : "";
            page.model.clear();
            data.forEach(function (p) { page.model.append(p); });
        }

    }
}
