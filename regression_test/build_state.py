import os
import sys
from datetime import datetime, timedelta
from caom2pipe import manage_composable as mc

collection = sys.argv[1]
COLLECTION_KEYS = {
        'gem': 'gemini_bookmark',
        'dao': 'dao_timestamp',
        'neossat': 'neossat_timestamp',
        'cfht': 'cfht_timestamp',
        'vlass': 'vlass_timestamp'
}
collection_key = COLLECTION_KEYS.get(collection, f'{collection}_bookmark')

config = mc.Config()
config.get_executors()

tomorrow = datetime.utcnow() + timedelta(days=1)
if collection == 'gem':
    # gemini counts back 14 days for incremental harvesting because
    # that's how their endpoints can work ....
    tomorrow = datetime.utcnow() + timedelta(days=15)

if not os.path.exists(config.state_fqn):
    with open(config.state_fqn, 'w') as f:
        f.write('bookmarks:\n')
        f.write(f'    {collection_key}:\n')
        f.write(f'        last_record: {tomorrow}\n')

state = mc.State(config.state_fqn)
state.save_state(collection_key, tomorrow)

print(f'::: state saved key {collection_key} value {tomorrow}')
sys.exit(0)
