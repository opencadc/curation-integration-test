# -*- coding: utf-8 -*-

"""
1. Find the name of a file to test with.
2. Get that file
3. Update the config.yml to say task types are 'scrape' and 'modify'
4. Run
5. Delete record from sc2
6. Insert on sc2
7. Update on sc2
"""
import io
import logging
import os
import sys
from astropy.table import Table
from cadcutils import net
from cadctap import CadcTapClient
from caom2repo import CAOM2RepoClient
from caom2pipe import client_composable as clc
from caom2pipe import manage_composable as mc
from does_collection_clean_up import question

collection = sys.argv[1].upper()
tap_resource_id = 'ivo://cadc.nrc.ca/argus'
caom_resource_id = 'ivo://cadc.nrc.ca/ams'
if collection == 'NEOSSAT':
    service = 'shared'
    archive = 'NEOSSAT'
    collection = 'NEOSS'
elif collection == 'GEM':
    service = 'gemini'
    archive = 'GEMINI'
    tap_resource_id = 'ivo://cadc.nrc.ca/ams/gemini'
    caom_resource_id = 'ivo://cadc.nrc.ca/ams'
elif collection == 'VLASS':
    service = 'cirada'
    tap_resource_id = 'ivo://cadc.nrc.ca/ams/cirada'
    archive = 'VLASS'
elif collection == 'WALLABY':
    tap_resource_id = 'ivo://cadc.nrc.ca/sc2tap'
    service = 'shared'
    archive = 'WALLABY'
elif collection == 'BRITE':
    caom_resource_id = 'ivo://cadc.nrc.ca/sc2repo'
    tap_resource_id = 'ivo://cadc.nrc.ca/sc2tap'
    service = 'shared'
    archive = 'BRITE-Constellation'
else:
    service = collection.lower()
    archive = collection
proxy_fqn = '/usr/src/app/cadcproxy.pem'
subject = net.Subject(certificate=proxy_fqn)
if tap_resource_id is None:
    ops_client = CadcTapClient(subject, resource_id=f'ivo://cadc.nrc.ca/ams/{service}')
    caom_client = CAOM2RepoClient(subject, resource_id=caom_resource_id)
else:
    ops_client = CadcTapClient(subject, resource_id=tap_resource_id)
    caom_client = CAOM2RepoClient(subject, resource_id=caom_resource_id)
cleans_up = question(collection.lower())

print(':::1 - Find the name of a file to test with.')
query_clause="AND A.uri LIKE '%.fits%'"
if collection == 'BRITE':
    query_clause="AND A.uri LIKE '%.orig'"

ops_query = f"""SELECT TOP 1 O.observationID, A.uri
FROM caom2.Observation AS O
JOIN caom2.Plane AS P ON O.obsID = P.obsID
JOIN caom2.Artifact AS A ON P.planeID = A.planeID
WHERE O.collection = '{archive}'
{query_clause}
"""

ops_buffer = io.StringIO()
ops_client.query(ops_query, output_file=ops_buffer, data_only=True, response_format='csv')
ops_table = Table.read(ops_buffer.getvalue().split('\n'), format='csv')
if len(ops_table) == 1:
    obs_id = ops_table[0]['observationID']
    uri = ops_table[0]['uri']
    ignore_scheme, ignore_path, f_name = mc.decompose_uri(uri)
    print(f':::Looking for {obs_id} and {f_name}')
else:
    print(f':::No observation records found for collection {archive} from service {service}')
    sys.exit(-1)

obs = caom_client.read(archive, obs_id)
obs_fqn = f'/usr/src/app/expected.{obs_id}.xml'
mc.write_obs_to_file(obs, obs_fqn)

print(f':::2 - Get {f_name}')
config = mc.Config()
config.get_executors()
clients = clc.ClientCollection(config)
metrics = mc.Metrics(config)
data_location = '/usr/src/app'
if cleans_up:
    data_location = '/data'
    for ii in ['/data/success', '/data/failure', '/data']:
        with os.scandir(ii) as it:
            for jj in it:
                if not jj.is_dir():
                    os.unlink(os.path.join(ii, jj))
if collection == 'GEM':
    uri = uri.replace('gemini:GEM/', 'gemini:GEMINI/')
clients.data_client.get(data_location, uri)

print(':::3 - Update config.yml to say task types are scrape and modify, and use local files.')
config.task_types = [mc.TaskType.SCRAPE, mc.TaskType.MODIFY]
config.use_local_files = True
config.logging_level = logging.INFO
config.data_sources = [data_location]
mc.Config.write_to_file(config)

print(':::4 - Run the application.')
sys.exit(0)
