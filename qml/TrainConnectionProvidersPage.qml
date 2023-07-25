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
            text: app.tr("Select the providers relevant for your area")
            truncMode: truncModes.none
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        Spacer {
            height: styler.themePaddingLarge
        }

        Repeater {
            id: repeater
            model: backendModel
            
            delegate: ListItemPL {
                contentHeight: repeaterColumn.height

                Column {
                    id: repeaterColumn
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
                                TrainConnection.setBackendEnable(model.identifier, false);
                            }
                        }
                    }

                    Spacer {
                        height: styler.themePaddingLarge / 2
                    }

                }

            }

        }

    }

    onPageStatusActivating: {
        const kpt_backends = py.evaluate("poor.app.history.kpt_backends");
        kpt_backends.forEach( function(x) { TrainConnection.setBackendEnable(x, true); } );
    }

    onAccepted: {
        app.pages.pop();
    }

    KPT.BackendModel {
        id: backendModel
        manager: Manager
    }

}