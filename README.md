# integration_test
Provides skeleton necessary to run all the unit and integration tests for the repositories in this organization, using the scripts run_unit_test.sh and run_int_test.sh. The ROOT_DIR definition in each of the scripts may need to be changed. The scripts assume Docker.

There are test cases which require .netrc files or proxy certificates, to be provided separately.

|                      | cadcproxy.pem  |  test_netrc |
|----------------------|:--------------:|:-----------:|
| augment              |  x             |             | 
| client_ingest_modify |  x             |             | 
| failures             |                |    x        |
| ingest_modify        |                |    x        |
| ingest_modify_local  |                |    x        |
| scrape               |                |             |    
| scrape_modify        |                |             |    
| store_ingest_modify  |                |    x        |
| todo_parameter       |                |             | 
| visit                |  x             |             |
