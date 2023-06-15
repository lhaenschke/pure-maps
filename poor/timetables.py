# -*- coding: utf-8 -*-

# Copyright (C) 2014 Osmo Salomaa
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""Managing search for timetables."""

import poor
import http.client
import json
from datetime import datetime
import xml.etree.ElementTree as ET
import urllib.parse

from poor.i18n import _

__all__ = ("TimetableManager",)

class TimetableManager:

    """Managing search for timetables."""

    def __init__(self):
        """Initialize a :class:`TimetableManager` instance."""
        self._clientID = poor.key.get("DBTRAININFORMATION_CLIENT")
        self._clientSecret = poor.key.get("DBTRAININFORMATION_SECRET")
        self.trains = []

    def search(self, latitude: str, longitude: str, hour: int):
        eva_number = self.__get_eva_number_coor__(latitude, longitude)
        
        xml_root = ET.fromstring(self.__get_timetable_str(eva_number, hour))
        self.trains = []

        for train in xml_root.iter('s'):
            train_type = train.find('tl').attrib.get('c')
            
            name = train.find('dp').attrib.get('l') if train.find('dp') != None else train.find('ar').attrib.get('l')
            if name is None:
                name = ""

            train_id = train.attrib.get('id')
            dep_time = train.find('dp').attrib.get('pt') if train.find('dp') != None else train.find('ar').attrib.get('pt')
            track = train.find('dp').attrib.get('pp') if train.find('dp') != None else train.find('ar').attrib.get('pp')
            next_stops = train.find('dp').attrib.get('ppth') if train.find('dp') != None else train.find('ar').attrib.get('ppth')
            
            self.trains.append(Traininformation(
                train_type = train_type,
                name = name,
                train_id = train_id,
                dep_time = dep_time,
                track = track,
                next_stops = next_stops,
                dest_arr_time = None,
                dest_track = ""
            ))

        self.trains = sorted(self.trains, key=lambda x: x.dep_time)

    def load_destination_informations(self, train_id: str, dest_name: str, hour: int):
        print(train_id, dest_name, hour)
        (dest_arr_time, dest_track) = (None, "")
        for i in range(3):
            (dest_arr_time, dest_track) = self.__get_time_from_destination__(train_id, dest_name, hour + i)    
            if dest_arr_time is not None:
                for i in range(len(self.trains)):
                    if self.trains[i].id == train_id:
                        self.trains[i].dest_arr_time = dest_arr_time
                        self.trains[i].dest_track = dest_track
                        break

    def get_trains(self):
        return [dict(
            type=train.type,
            name=train.name,
            train_id=train.id,
            dep_time_hh=train.dep_time[6:8],
            dep_time_mm=train.dep_time[8:],
            track=train.track,
            destination=train.next_stops.split('|')[-1],
            dest_arr_time_hh=train.dest_arr_time[6:8] if train.dest_arr_time is not None else "",
            dest_arr_time_mm=train.dest_arr_time[8:] if train.dest_arr_time is not None else "",
            next_stops=train.next_stops,
            dest_track=train.dest_track,
        ) for train in self.trains]


    def __get_time_from_destination__(self, train_id: str, dest_name: str, min_hour: int) -> str:
        eva_number = self.__get_eva_number_dest_name__(dest_name)
        
        xml_root = ET.fromstring(self.__get_timetable_str(eva_number, min_hour))
        for train in xml_root.iter('s'):
            if train.attrib.get('id')[:30] == train_id[:30]:
                return (train.find('ar').attrib.get('pt'), train.find('dp').attrib.get('pp') if train.find('dp') != None else train.find('ar').attrib.get('pp'))

        return (None, "")

    
    def __get_eva_number_coor__(self, latitude: str, longitude: str) -> str:
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")

        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/vnd.de.db.ris+json"
            }

        conn.request("GET", "".join((
            "/db-api-marketplace/apis/ris-stations/v1/stop-places/by-position",
            "?latitude={}".format(latitude),
            "&longitude={}".format(longitude),
            "&groupBy=SALES&limit=1",
        )), "", headers)

        res = conn.getresponse()
        data = res.read()
        json_data = json.loads(data.decode('utf-8'))

        return json_data['stopPlaces'][0]['evaNumber']

    def __get_eva_number_dest_name__(self, dest_name: str) -> str:
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")

        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/vnd.de.db.ris+json"
            }

        conn.request("GET", "".join((
            "/db-api-marketplace/apis/ris-stations/v1/stop-places/by-name/{}".format(urllib.parse.quote(dest_name).replace('/', '%2F'))
        )), "", headers)

        res = conn.getresponse()
        data = res.read()
        json_data = json.loads(data.decode('utf-8'))

        return json_data['stopPlaces'][0]['evaNumber']

    def __get_timetable_str(self, eva_number: str, hour: int) -> str:
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")
        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/xml"
            }

        conn.request("GET", "".join((
            "/db-api-marketplace/apis/timetables/v1/plan/",
            "{}/".format(eva_number),
            "{}/".format(datetime.today().strftime('%Y%m%d')[2:]),
            "{}".format(hour),
        )), "", headers)

        res = conn.getresponse()
        data = res.read()

        return data.decode("utf-8")

class Traininformation:

        """Store train-informations"""

        def __init__(self, train_type: str, name: str, train_id: str, dep_time: str, track: str, next_stops: str, dest_arr_time: str, dest_track: str):
            self.type = train_type
            self.name = name
            self.id = train_id
            self.dep_time = dep_time
            self.track = track
            self.next_stops = next_stops
            self.dest_arr_time = dest_arr_time
            self.dest_track = dest_track