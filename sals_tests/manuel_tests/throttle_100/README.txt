hi there,

run the following steps to reproduce the "hi" bug (a data validation bug):
1. execute manuel_test_throttle100.sh
2. see the PCRF_DATA_USAGE_STREAM window - for msisdn 4912345678903 the Time is wrongly set to 1974 (i would have expected the record to be rejected as hi is not a valid date). bad_events.log wasnt filled.

