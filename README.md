CEP-Testing
===========

CEP Engine Testing

This folder contains the scripts used to unit / component test the CEP engine with the postpaid throttle 100 events.

run_test.sh is the main script that gets called. This then goes through the local directory and looks for ^tc.*_data_setup.sh scripts and executes the sequentially.

tc1_data_setup.sh - this contains the design requirement, the input data, the expected output data as well as explanations for the test and its setup. This focuses on testing the filter conditions as defined in the model xml.

tc2_data_setup.sh - this is the 2nd test case - this focuses on the 48 hour aggregation of quota usage data.

tc3_data_setup.sh - this checks that the join with the recurring lookup works correctly.
