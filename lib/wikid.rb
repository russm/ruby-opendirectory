require 'xmlrpc/client'

# shut up about the SSL verification, thanks!
class Net::HTTP
  alias_method :old_initialize, :initialize
  def initialize(*args)
    old_initialize(*args)
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
end

class Wikid
  def initialize url, name, password
    @client = XMLRPC::Client.new2 url
    ok, result = @client.call2 'login', name, password
    raise result unless ok
    raise "wikid login failed: #{result.inspect}" unless result['success']
    @session_id = result['session_id']
  end
  def set_user_settings user, settings
    ok, result = @client.call2 'settings.setUserSettings', @session_id, "users/#{user}", settings
    raise result unless ok
    return result
  end
end
