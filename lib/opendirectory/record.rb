class ODRecord
  include OpenDirectory::Constants
  RECORD_TYPE_ATTRIBUTES = {
    RecordTypeUsers => [AttributeTypeUniqueID, AttributeTypeRecordName, AttributeTypeFirstName, AttributeTypeLastName, AttributeTypeEMailAddress, AttributeTypeJobTitle, AttributeTypeDepartment, AttributeTypeCompany, AttributeTypeStreet, AttributeTypeCity, AttributeTypeState, AttributeTypePostalCode, AttributeTypeCountry, AttributeTypeMobileNumber, AttributeTypePhoneNumber, AttributeTypeFaxNumber]
  }

  def self.find_in_node node, record_type, attribute, match_type, query_values, return_attributes
    validate_record_type record_type
    error = Pointer.new_with_type('@')
    return_attributes ||= RECORD_TYPE_ATTRIBUTES[record_type]
    if [attribute, match_type] == [AttributeTypeRecordName, MatchEqualTo] then
      return_attributes = [return_attributes] unless return_attributes.is_a? Array
      result = ODRecord.find_in_node_by_record_name node, record_type, query_values, return_attributes
      results = result.nil? ? [] : [result]
    else
      query = ODQuery.queryWithNode node, forRecordTypes: record_type, attribute: attribute, matchType: match_type, queryValues: query_values, returnAttributes: return_attributes, maximumResults:0, error:error
      error[0].barf unless query
      results = query.resultsAllowingPartial false, error:error
      error[0].barf unless results
    end
    results
  end

  def self.find_in_node_by_record_name node, record_type, record_name, attributes
    validate_record_type record_type
    raise "attributes should be an array, but is #{attributes.inspect}" unless attributes.is_a? Array
    error = Pointer.new_with_type('@')
    record = node.recordWithRecordType record_type, name:record_name, attributes:attributes, error:error
    error[0].barf unless error[0].nil?
    record
  end

  def self.create_in_node node, record_type, record_name, attributes
    validate_record_type record_type
    attributes = clean_hash attributes

    # validate we've got enough info to create the record
    # XXX this is currently specific to RecordTypeUsers
    unique_id = attributes[AttributeTypeUniqueID] = attributes[AttributeTypeUniqueID]
    password = attributes.delete(AttributeTypePassword)
    raise "create requires a numeric #{AttributeTypeUniqueID} attribute, had #{unique_id.inspect}" unless /^\d+$/.match(unique_id)
    raise "create requires a non-empty #{AttributeTypePassword} attribute" unless password

    # ensure both record_name and unique_id are unique
    # XXX this is currently specific to RecordTypeUsers
    # XXX we're racy here!
    same_record_name = find_in_node node, record_type, AttributeTypeRecordName, MatchEqualTo, record_name, AttributeTypeRecordName
    same_unique_id = find_in_node node, record_type, AttributeTypeUniqueID, MatchEqualTo, unique_id, AttributeTypeRecordName
    raise "can't create - that record_name (#{record_name}) is already in use" unless same_record_name.empty?
    raise "can't create - that unique_id (#{unique_id}) is already in use" unless same_unique_id.empty?

    # munge up additional required attributes
    # XXX this is currently specific to RecordTypeUsers
    attributes[AttributeTypeFullName] = "#{attributes[AttributeTypeFirstName]} #{attributes[AttributeTypeLastName]}".strip
    attributes[AttributeTypeFullName] = record_name if attributes[AttributeTypeFullName].empty?

    attributes.each_pair do |k,v|
      # attribute dictionary values must all be arrays
      attributes[k] = [v]
    end

    error = Pointer.new_with_type('@')
    record = node.createRecordWithRecordType record_type, name:record_name, attributes:attributes, error:error
    error[0].barf unless record
    ok = record.changePassword nil, toPassword:password, error:error
    error[0].barf unless ok
    record
  end

  def self.update_in_node node, record_type, match, attributes
    validate_record_type record_type
    attributes = clean_hash attributes

    # validate the match info
    # XXX this is currently specific to RecordTypeUsers
    record_name = match[:record_name]
    unique_id = match[:unique_id].to_s
    raise "update requires a record_name to match" unless record_name
    raise "update requires a unique_id to match" unless /^\d+$/.match(unique_id)

    # complain if we're trying to update attributes that should be immutable
    # XXX this is currently specific to RecordTypeUsers
    [AttributeTypeRecordName, AttributeTypeUniqueID].each do |immutable_attribute|
      raise "update can't update the #{immutable_attribute}" if attributes[immutable_attribute]
    end

    # deal with attributes that need specific updating
    password = attributes.delete(AttributeTypePassword)
    if attributes.key?(AttributeTypeFirstName) or attributes.key?(AttributeTypeLastName) then
      raise "both firstname and lastname must be set together" unless attributes.key?(AttributeTypeFirstName) and attributes.key?(AttributeTypeLastName)
      attributes[AttributeTypeFullName] = "#{attributes[AttributeTypeFirstName]} #{attributes[AttributeTypeLastName]}".strip
    end

    error = Pointer.new_with_type('@')
    record = find_in_node_by_record_name node, record_type, record_name, [AttributeTypeStandardOnly]
    record_unique_id = record.valuesForAttribute AttributeTypeUniqueID, error:error
    error[0].barf unless record_unique_id
    raise "record #{record_name} does not match unique_id #{unique_id}" unless record_unique_id[0] == unique_id
    attributes.each_pair do |k,v|
      ok = record.setValue v, forAttribute:k, error:error
      error[0].barf unless ok
    end
    if password then
      ok = record.changePassword nil, toPassword:password, error:error
      error[0].barf unless ok
    end
    ok = record.synchronizeAndReturnError error
    error[0].barf unless ok
    record
  end

  def self.delete_in_node node, record_type, record_name
    record = find_in_node_by_record_name node, record_type, record_name, []
    raise "couldn't find record #{record_name} to delete" unless record
    error = Pointer.new_with_type('@')
    ok = record.deleteRecordAndReturnError error
    error[0].barf unless ok
    true
  end

  def to_hash
    inspectify
    { :record_name => @record_name, :record_type => @record_type, :attributes => @attributes }
  end

  def inspectify
    @record_name = recordName
    @record_type = recordType
    @attributes = {}
    recordDetailsForAttributes(nil, error:nil).each_pair do |k,v|
      next if k.eql? AttributeTypeRecordName
      next unless RECORD_TYPE_ATTRIBUTES[@record_type].include? k
      @attributes[k] = v[0]
    end
    self
  end

  def self.validate_record_type record_type
    raise "unsupported record_type: is #{record_type} but should be in [#{RECORD_TYPE_ATTRIBUTES.keys.sort.join ","}]" unless RECORD_TYPE_ATTRIBUTES.keys.include? record_type
  end

  # XXX this seems suboptimal - should I be moduling this into Hash or something?
  def self.clean_hash hash
    result = {}
    hash.each_pair do |k,v|
      v = v[0] if v.is_a? Array
      v = v.to_s.strip
      result[k] = v unless v.empty?
    end
    result
  end

end
