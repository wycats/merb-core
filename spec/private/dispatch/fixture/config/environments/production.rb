puts "Loaded PRODUCTION Environment..."
Merb::Config.use { |c|
  c[:exception_details] = false
  c[:reload_classes] = false
}