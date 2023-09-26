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

DialogPL {
    id: page
    title: app.tr("Providers")
    acceptText: app.tr("Save")

    Column {
        id: column
        width: page.width

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: app.tr("Select the providers relevant for your area:")
            font.pixelSize: styler.themeFontSizeMedium
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            height: 1
            width: page.width - 16
            anchors.left: parent.left
            anchors.leftMargin: 8
            color: "gray"
        }

        Spacer {
            height: styler.themePaddingMedium
        }

        Repeater {
            model: backendModel
            
            delegate: ListItemPL {
                contentHeight: backendColumn.height

                Column {
                    id: backendColumn
                    width: page.width

                    TextSwitchPL {
                        checked: model.backendEnabled
                        description: model.description
                        text: model.name
                        onCheckedChanged: { 
                            if (checked) {
                                py.call_sync("poor.app.history.add_kpt_backend", [model.identifier]);
                            } else {
                                py.call_sync("poor.app.history.remove_kpt_backend", [model.identifier]);
                                PublicTransport.setBackendEnable(model.identifier, false);
                            }
                        }
                    }

                    Spacer {
                        height: styler.themePaddingLarge / 2
                    }

                }

            }

        }

        Spacer {
            height: styler.themePaddingLarge
        }

        Rectangle {
            height: 2
            width: page.width - 16
            anchors.left: parent.left
            anchors.leftMargin: 8
            color: "gray"
        }

        ListItemLabel {
            color: styler.themeHighlightColor
            height: implicitHeight + styler.themePaddingMedium
            text: app.tr("KPublicTransport Attributions:")
            truncMode: truncModes.none
            font.pixelSize: styler.themeFontSizeLarge
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
        }

        Repeater {
            model: Manager.attributions

            delegate: ListItemPL {
                contentHeight: attributionColumn.height

                Column {
                    id: attributionColumn
                    width: page.width

                    Spacer {
                        height: styler.themePaddingLarge / 2
                    }

                    ListItemLabel {
                        height: implicitHeight + styler.themePaddingLarge
                        font.pixelSize: styler.themeFontSizeMedium
                        text: modelData.name
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }

                    ListItemLabel {
                        height: implicitHeight + styler.themePaddingMedium
                        text: 'Url: <a href="' + modelData.url + '">Attribution</a>'
                        visible: !modelData.hasLicense
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }

                    ListItemLabel {
                        height: implicitHeight + styler.themePaddingMedium
                        text: modelData.license
                        visible: modelData.hasLicense
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }

                    ListItemLabel {
                        height: implicitHeight + styler.themePaddingMedium
                        text: 'License-Url: <a href="' + modelData.licenseUrl + '">License</a>'
                        visible: modelData.hasLicense
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }

                    Spacer {
                        height: styler.themePaddingLarge / 2
                    }

                    Rectangle {
                        height: 1
                        width: page.width - 16
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        color: "gray"
                    }

                }

            }

        }

    }

    onPageStatusActivating: {
        const kpt_backends = py.evaluate("poor.app.history.kpt_backends");
        kpt_backends.forEach( function(x) { PublicTransport.setBackendEnable(x, true); } );
    }

    onAccepted: {
        app.pages.pop();
    }

    KPT.BackendModel {
        id: backendModel
        manager: Manager
    }

}