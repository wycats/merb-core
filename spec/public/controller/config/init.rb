Merb::Config.use do |c|
  c[:default_cookie_domain] = "specs.merbivore.com"
  c[:session_id_key]        = "some_meaningless_id_key"
  c[:session_secret_key]    = "some_super_hyper_secret_key"
  c[:session_expiry]        = Merb::Const::WEEK * 4
end
