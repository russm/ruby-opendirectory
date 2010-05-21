#!/usr/bin/ruby

require 'yaml'

conn = IO.popen "./bin/odtool.rb", "r+"


def conn.transact request
  STDERR.puts "=> request is #{request.inspect}"
  self.puts request.to_yaml
  self.puts "..."
  STDERR.puts "=> waiting for reply"
  yaml = ""
  self.each_line do |line|
    yaml << line
    break if line.eql? "...\n"
  end
  result = YAML.load yaml
  STDERR.puts "=> reply was #{result.inspect}"
end

# find a user
conn.transact [ "READ", "dsRecTypeStandard:Users", "dsAttrTypeStandard:RecordName=russm" ]

# find some users (josh, raylene)
conn.transact [ "READ", "dsRecTypeStandard:Users", "dsAttrTypeStandard:RealName~re" ]

# find someone by unique_id
conn.transact [ "READ", "dsRecTypeStandard:Users", "dsAttrTypeStandard:UniqueID=1000" ]

# create a user
conn.transact [ "CREATE", "dsRecTypeStandard:Users", "russm-test", { "dsAttrTypeStandard:Password" => "Pa5sWoRd", "dsAttrTypeStandard:UniqueID" => "2099", "dsAttrTypeStandard:FirstName" => "Rusty", "dsAttrTypeStandard:LastName" => "Tester" } ]

# update some attributes
conn.transact [ "UPDATE", "dsRecTypeStandard:Users", { :record_name => "russm-test", :unique_id => "2099" }, { "dsAttrTypeStandard:JobTitle" => "Technical Lead", "dsAttrTypeStandard:Company" => "Blue Fish Productions" } ]

# find the newly created record
conn.transact [ "READ", "dsRecTypeStandard:Users", "dsAttrTypeStandard:RecordName=russm-test" ]

# find all records
conn.transact [ "READ", "dsRecTypeStandard:Users", nil, "dsAttrTypeStandard:UniqueID", "dsAttrTypeStandard:RealName" ]

# delete the new record
conn.transact [ "DELETE", "dsRecTypeStandard:Users", "russm-test" ]
