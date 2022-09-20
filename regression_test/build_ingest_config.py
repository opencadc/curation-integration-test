# -*- coding: utf-8 -*-

"""
Build a config that has task type == INGEST
resource_id sc2repo
use_local_files == False

All tests use the proxy cert.
"""
import logging
import sys
from caom2pipe import manage_composable as mc

collection = sys.argv[1]

print(f'::: modify config for ingest')
config = mc.Config()
config.get_executors()
config.netrc_file = None
config.proxy_file_name = 'cadcproxy.pem'
config.task_types = [mc.TaskType.INGEST]
config.use_local_files = False
config.logging_level = logging.INFO
config.features.supports_latest_client = True
config.features.support_decompression = True
if collection == 'dao':
    config.tap_id = 'ivo://cadc.nrc.ca/ad'
if collection == 'vlass':
    config.features.supports_latest_client = False
    config.features.supports_decompression = False
config.tap_id = 'ivo://cadc.nrc.ca/global/luskan'
config.resource_id = 'ivo://cadc.nrc.ca/ams'
mc.Config.write_to_file(config)

sys.exit(0)
