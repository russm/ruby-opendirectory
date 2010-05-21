#!/usr/local/bin/macruby

# reads a sequence of YAML documents on stdin, writes YAML documents to
# stdout. each input document is a list, with the command first
# followed by data for the current request. output documents are a list
# of results for READ, or a single hash for others.
#
# find the user with RecordName "russm" (there will be zero or one), return just the UniqueID
# [ "READ", "dsRecTypeStandard:Users", "dsAttrTypeStandard:RecordName=russm", "dsAttrTypeStandard:UniqueID" ]
#
# find the user with "dsAttrTypeStandard:Country=AU", return all standard attributes
# [ "READ", "dsRecTypeStandard:Users", "dsAttrTypeStandard:Country=AU", "dsAttributesStandardAll" ]
# [ "READ", "dsRecTypeStandard:Users", "dsAttrTypeStandard:Country=AU" ]
#
# find all users, return full name, email, company
# [ "READ", "dsRecTypeStandard:Users", nil, "dsAttrTypeStandard:RealName", "dsAttrTypeStandard:EMailAddress", "dsAttrTypeStandard:Company" ]
#
# update a user.
# [ "UPDATE", "dsRecTypeStandard:Users", { :record_name => "russm", :unique_id => "1025" }, { "dsAttrTypeStandard:Password" => "supersekrit", "dsAttrTypeStandard:JobTitle" => "Technical Lead", "dsAttrTypeStandard:Company" => "Blue Fish Productions" } ]
#
# create a minimal user
# [ "CREATE", "dsRecTypeStandard:Users", "russm", { "dsAttrTypeStandard:Password" => "supersekrit", "dsAttrTypeStandard:UniqueID" => "2099", "dsAttrTypeStandard:FirstName" => "Rusty", "dsAttrTypeStandard:LastName" => "Tester" } ]
#
# delete a user
# [ "DELETE", "dsRecTypeStandard:Users", "russm-test" ]

# push the app /lib/ directory to the search path
$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'opendirectory'
require 'yaml'

module OpenDirectory
  class Tool
    include OpenDirectory::Constants
    MATCHES = {
      "!" => MatchAny,
      "=" => MatchEqualTo,
      "^" => MatchBeginsWith,
      "~" => MatchContains,
      "$" => MatchEndsWith,
      "<" => MatchLessThan,
      ">" => MatchGreaterThan
    }

    def initialize config = nil, stdin = STDIN, stdout = STDOUT, stderr = STDERR
      @config, @stdin, @stdout, @stderr = config, stdin, stdout, stderr
      @error = Pointer.new_with_type('@')
      @node = ODNode.node_with_config @config
    end

    def read_document io
      yaml = ""
      @stdin.each_line do |line|
        yaml << line
        break if line.eql? "...\n"
      end
      obj = YAML.load yaml
    end

    def run
      # XXX surely this can be done with YAML.each_document or something, somehow?
      while true do
        obj = read_document @stdin
        raise "request is not an array: #{obj.inspect}" unless obj.is_a? Array
        verb = obj.shift
        raise "unimplemented verb: #{verb}" unless self.respond_to? "do_verb_#{verb}".to_sym
        record_type = obj.shift
        raise "unsupported record type: #{record_type}" unless NSODRecord::RECORD_TYPE_ATTRIBUTES.keys.include? record_type
        result = self.send("do_verb_#{verb}".to_sym, record_type, obj)
        @stdout.puts result.to_yaml
        @stdout.puts "..."
      end
    end

    def do_verb_READ record_type, args
      text_query = args.shift.to_s
      query = text_query.match %r"^(.*?)([#{MATCHES.keys.join}])(.*)$"
      if query then
        attribute, match_type, query_value = query[1], MATCHES[query[2]], query[3]
      else
        attribute, match_type, query_value = AttributeTypeRecordName, MatchAny, nil
      end
      records = ODRecord.find_in_node @node, record_type, attribute, match_type, query_value, nil
      results = records.map do |record|
        record.to_hash
      end
      results
    end

    def do_verb_UPDATE record_type, args
      match, attributes = args
      record = ODRecord.update_in_node @node, record_type, match, attributes
      record.to_hash
    end

    def do_verb_CREATE record_type, args
      record_name, attributes = args
      record = ODRecord.create_in_node @node, record_type, record_name, attributes
      record.to_hash
    end

    def do_verb_DELETE record_type, args
      record_name = args[0]
      result = ODRecord.delete_in_node @node, record_type, record_name
      { :record_name => record_name, :record_type => record_type, :deleted => result }
    end

  end
end

etc_dir = File.join(File.dirname(__FILE__), '..', 'etc')
config_file = File.join(etc_dir, 'config.yml')
config_file_local = File.join(etc_dir, 'config.local.yml')
config = YAML.load_file(config_file)
config = YAML.load_file(config_file_local) if File.exists?(config_file_local)

app = OpenDirectory::Tool.new config
app.run
