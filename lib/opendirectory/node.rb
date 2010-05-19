class ODNode
  def self.node_with_config config = { :node_name => "/Local/Default" }
    error = Pointer.new_with_type('@')
    if config[:session_options].nil?
      session = ODSession.defaultSession
    else
      session = ODSession.sessionWithOptions config[:session_options], error:error
      error[0].barf unless session
    end
    node = self.nodeWithSession session, name:config[:node_name], error:error
    error[0].barf unless node
    if config[:node_auth_name] then
      ok = node.setCredentialsWithRecordType nil, recordName:config[:node_auth_name], password:config[:node_auth_password], error:error
      error[0].barf unless ok
    end
    node
  end
end
