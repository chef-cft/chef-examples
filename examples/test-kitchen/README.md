# Test Kitchen

Examples directory with different sample usage scenarios for configuring Test Kitchen.

## Example Kitchen Files

The `example-kitchen-files` folder contains sample YAML configuration files for Test Kitchen that adhere to the CHEF corporate standard for instance tags.  These standards are trivial to remove, extend, or override so they are included to show more complete examples.
[See Detailed Information](example-kitchen-files/README.md)

## Data Bag Examples

The `data-bag-usage` directory includes a cookbook example with different ways of using data bags with Test Kitchen.
* __Default data_bag location__ - The default kitchen suite in the cookbook looks in the location `test/integration/databags` since it is not otherwise specified for data_bag content.  The contents of the `default` databag located at `test/integration/data_bags/default` is consumed by the `default.rb` recipe of the cookbook.
* __Alternative data_bag location__ - The `alt-databag-location` suite specifies an alternate path location in YAML configuration via provisioner configuration for `data_bags_path` under the test suite.  The `default.rb` picks consumes this data, triggered by the presence of attribute `kitchen_suite_action` with value `alt-data-bag-location`, specified in the kitchen YAML configuration.
