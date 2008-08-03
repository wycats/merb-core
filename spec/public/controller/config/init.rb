puts Merb::Controller._session_cookie_domain

Merb::Config.use do |c|
  c[:session_cookie_domain] = "specs.merbivore.com"
end
