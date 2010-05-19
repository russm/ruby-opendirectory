class NSError
  def barf
    error_hash = self.userInfo.merge "domain" => self.domain, "code" => self.code
    raise error_hash.to_yaml
  end
end
