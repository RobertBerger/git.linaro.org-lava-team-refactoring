#!/bin/bash

local_common_file_path="$0"
local_common_parent_dir=$(cd $(dirname ${local_common_file_path}); pwd)
source "${local_common_parent_dir}/common2.sh"

output_test_result "$@"
