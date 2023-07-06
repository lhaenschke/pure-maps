# -*- coding: utf-8 -*-

# Copyright (C) 2023 lhaenschke
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

import http.client
import json
from datetime import datetime
from datetime import timedelta
import xml.etree.ElementTree as ET
import urllib.parse

import poor
from poor.i18n import _

__all__ = ("TimetableManager",)

class TimetableManager:
    """ Managing search for timetables. """

    def __init__(self):
        """ Initialize a :class:`TimetableManager` instance. """

        self._clientID = poor.key.get("DBTRAININFORMATION_CLIENT")
        self._clientSecret = poor.key.get("DBTRAININFORMATION_SECRET")
        self._trains = []
        self._timetable_cache = dict()
        self._eva_chache = dict()

    def search(self, latitude: str, longitude: str, hour: int):
        """ Trigger the timetable search for coordinates and hour. """

        # Get EVA-Number of railway station by coordinates
        (status, eva_number) = self._get_eva_number_coor(latitude, longitude)
        if status != 200:
            # Response: Error; Return string with error code and reason
            return "".join((str(status), '|', eva_number))
        
        # Load the trains
        self._trains = self._get_train_dict(eva_number, datetime.today().strftime('%Y%m%d')[2:], hour, "dp")
        if len(self._trains) > 0 and self._trains[0].get('status') != None:
            # Response: Error; Return string with error code and reason
            return "".join((str(self._trains[0].get('status')), '|', self._trains[0].get('reason')))
        
        # Return string with success code
        return "".join((str(200), '|'))

    def load_destination_informations(self, train_id: str, destination_name: str, hour: int):
        """ Returns further information of a given destination. """

        # Search for ar-information today and up to five hours in the future 
        today = datetime.today()
        (ar_time, ar_track) = (None, "")
        for i in range(6):
            # Search for arrive information
            (ar_time, ar_track) = self._get_further_destination_information(train_id, destination_name, today.strftime('%Y%m%d')[2:], hour + i)

            # Return informations if informations are found and belong to corresponding train_id
            if ar_time is not None:
                for train in self._trains:
                    # The train_ids differ in the last digits on different stations, only use first 25 digits
                    if train.get('train_id')[:25] == train_id[:25]:
                        return "".join((ar_time[6:8], '|', ar_time[8:], '|', ar_track))

        # Search for ar-information tomorrow up to 3:00 
        tomorrow = today + timedelta(days=1)
        hour = 0
        for i in range(4):
            # Search for arrive information
            (ar_time, ar_track) = self._get_further_destination_information(train_id, destination_name, tomorrow.strftime('%Y%m%d')[2:], hour + i)

            # Return informations if informations are found and belong to corresponding train_id
            if ar_time is not None:
                for train in self._trains:
                    if train.get('train_id')[:25] == train_id[:25]:
                        return "".join((ar_time[6:8], '|', ar_time[8:], '|', ar_track))

    def get_trains(self):
        """ Return the train-array. """

        return self._trains

    def clear_cache(self):
        """ Clear all caches. """

        self._timetable_cache.clear()
        self._eva_chache.clear()

    def _get_eva_number_coor(self, latitude: str, longitude: str):
        """ Returns the EVA-Number by coordinates. """

        # Search for EVA-Number in cache
        cache_key = "".join((str(latitude), str(longitude)))
        if cache_key in self._eva_chache.keys():
            # Found in cache
            return (200, self._eva_chache.get(cache_key))

        # Initialize base HTTPSConnection object
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")

        # Specify the requested headers
        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/vnd.de.db.ris+json"
            }


        # Send the get request to API
        conn.request("GET", "".join((
            "/db-api-marketplace/apis/ris-stations/v1/stop-places/by-position",
            "?latitude={}".format(latitude),
            "&longitude={}".format(longitude),
            "&groupBy=SALES&limit=1",
        )), "", headers)

        # Get response
        res = conn.getresponse()

        # Validate response
        if res.status == 200:
            # Response: Okay; Read data from response
            json_data = json.loads(res.read().decode('utf-8'))
            eva_number = json_data['stopPlaces'][0]['evaNumber']
            
            # Save EVA-Number in cache and return it
            self._eva_chache[cache_key] = eva_number
            return (res.status, eva_number)
        else:
            # Response: Error; Return array with error code and reason
            return (res.status, res.reason)

    def _get_eva_number_name(self, name: str):
        """ Returns the EVA-Number by name. """

        # Search for EVA-Number in cache
        cache_key = name
        if cache_key in self._eva_chache.keys():
            return (200, self._eva_chache.get(cache_key))
    
        # Initialize base HTTPSConnection object
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")

        # Specify the requested headers
        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/vnd.de.db.ris+json"
            }

        # Send the get request to API
        conn.request("GET", "".join((
            # Enter query in url-format and replace '/' in the query with '%2F' (e.g. Köln Messe/Deutz)
            "/db-api-marketplace/apis/ris-stations/v1/stop-places/by-name/{}".format(urllib.parse.quote(name).replace('/', '%2F'))
        )), "", headers)

        # Get response
        res = conn.getresponse()

        # Validate response
        if res.status == 200:
            # Response: Okay; Read data from response
            json_data = json.loads(res.read().decode('utf-8'))
            eva_number = json_data['stopPlaces'][0]['evaNumber']

            # Save EVA-Number in cache and return it
            self._eva_chache[cache_key] = eva_number
            return (res.status, eva_number)
        else:
            # Response: Error; Return array with error code and reason
            return (res.status, res.reason)

    def _get_timetable_str(self, eva_number: str, date: str, hour: int):
        """ Load suggestions from DB-API based on query and latitude/longitude. """

        # Search for timetable in cache
        cache_key = "".join((str(eva_number), str(date), str(hour)))
        if cache_key in self._timetable_cache.keys():
            return (200, self._timetable_cache.get(cache_key))
        
        # Initialize base HTTPSConnection object
        conn = http.client.HTTPSConnection("apis.deutschebahn.com")
        
        # Specify the requested headers
        headers = {
            'DB-Api-Key': self._clientSecret,
            'DB-Client-Id': self._clientID,
            'Accept': "application/xml"
            }

        # Send the get request to API
        conn.request("GET", "".join((
            "/db-api-marketplace/apis/timetables/v1/plan/",
            "{}/".format(eva_number),
            "{}/".format(date),
            "{:02d}".format(hour),
        )), "", headers)

        # Get response
        res = conn.getresponse()

        # Validate response
        if res.status == 200:
            # Response: Okay; Read data from response
            timetable_str = res.read().decode("utf-8")

            # Save timetable in cache and return it
            self._timetable_cache[cache_key] = timetable_str
            return (res.status, timetable_str)
        else:
            # Response: Error; Return array with error code and reason
            return (res.status, res.reason)
    
    def _get_train_dict(self, eva_number: str, date: str, hour: int, key: str):
        """ Return a Array of Dicts with the corresponding train-values. """

        # Get timetable by EVA-Number
        (status, result) = self._get_timetable_str(eva_number, date, hour)
        if status != 200:
            # Response: Error; Return array with error code and reason
            return [dict(status = status, reason = result)]

        # Initialize XML-Object from timetable string
        xml_root = ET.fromstring(result)
        trains = []

        # Get every train that departs from or arrives at given station, depending on key
        for train in xml_root.iter('s'):
            # When looking for arrive key, check if train arrives and not just start from station and vice versa
            if train.find(key) != None:
                # Read the information if possible, otherwise use default value
                train_type = train.find('tl').attrib.get('c')   if train.find('tl').attrib.get('c')   != None else ""
                name       = train.find(key).attrib.get('l')    if train.find(key).attrib.get('l')    != None else ""
                train_id   = train.attrib.get('id')             if train.attrib.get('id')             != None else ""
                time       = train.find(key).attrib.get('pt')   if train.find(key).attrib.get('pt')   != None else ""
                track      = train.find(key).attrib.get('pp')   if train.find(key).attrib.get('pp')   != None else ""
                stops      = train.find(key).attrib.get('ppth') if train.find(key).attrib.get('ppth') != None else ""

                # Creates a dictionary and initialize it with some of its values
                train_dict = dict(
                    type        = train_type,
                    name        = name,
                    train_id    = train_id,
                    destination = stops.split('|')[-1] if stops != "" else "",
                )
                # Add the remaining values by the key
                train_dict["".join((key, "_time_hh"))] = time[6:8] if len(time) > 9 else ""
                train_dict["".join((key, "_time_mm"))] = time[8:]  if len(time) > 9 else ""
                train_dict["".join((key, "_track"))]   = track
                train_dict["".join((key, "_stops"))]   = stops

                # Append the dictionary to the array
                trains.append(train_dict)

        # Sort trains by time; First by minutes then by hours (inner sort then outer sort)
        trains = sorted(trains, key=lambda x: x.get("".join((key, "_time_mm"))))
        trains = sorted(trains, key=lambda x: x.get("".join((key, "_time_hh"))))
        return trains

    def _get_further_destination_information(self, train_id: str, destination_name: str, date: str, hour: int):
        """ Returns arrive-time and -track of the destination. """

        # Get EVA-Number of railway station by name
        (status, eva_number) = self._get_eva_number_name(destination_name)
        if status != 200:
            # Response: Error; Return None
            return (None, "")

        # Get timetable by EVA-Number
        (status, timetable_xml_str) = self._get_timetable_str(eva_number, date, hour)
        if status != 200:
            # Response: Error; Return None
            return (None, "")
        
        # Initialize XML-Object from timetable string
        xml_root = ET.fromstring(timetable_xml_str)
        
        # Search for corresponding train in destination
        for train in xml_root.iter('s'):
            if train.attrib.get('id')[:25] == train_id[:25]:
                if train.find('ar') != None:
                    # Match found; Return (time, track)
                    return (train.find('ar').attrib.get('pt'), train.find('ar').attrib.get('pp'))

        return (None, "")