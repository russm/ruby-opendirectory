#!/usr/bin/ruby

require 'yaml'

# find a user
puts [ "READ", "dsRecTypeStandard:Users", "dsAttrTypeStandard:RecordName=russm" ].to_yaml

# find some users (josh, raylene)
puts [ "READ", "dsRecTypeStandard:Users", "dsAttrTypeStandard:RealName~re" ].to_yaml

# find someone by unique_id
puts [ "READ", "dsRecTypeStandard:Users", "dsAttrTypeStandard:UniqueID=1000" ].to_yaml

# create a user
puts [ "CREATE", "dsRecTypeStandard:Users", "russm-test", { "dsAttrTypeStandard:Password" => "Pa5sWoRd", "dsAttrTypeStandard:UniqueID" => "2099", "dsAttrTypeStandard:FirstName" => "Rusty", "dsAttrTypeStandard:LastName" => "Tester" } ].to_yaml

# update some attributes
puts [ "UPDATE", "dsRecTypeStandard:Users", { :record_name => "russm-test", :unique_id => "2099" }, { "dsAttrTypeStandard:JobTitle" => "Technical Lead", "dsAttrTypeStandard:Company" => "Blue Fish Productions" } ].to_yaml

# find the newly created record
puts [ "READ", "dsRecTypeStandard:Users", "dsAttrTypeStandard:RecordName=russm-test" ].to_yaml

# find all records
puts [ "READ", "dsRecTypeStandard:Users", nil, "dsAttrTypeStandard:UniqueID", "dsAttrTypeStandard:RealName" ].to_yaml

# delete the new record
puts [ "DELETE", "dsRecTypeStandard:Users", "russm-test" ].to_yaml
