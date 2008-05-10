desc "Print out the named and anonymous routes"
task :routes => :merb_env do
  seen = []
  unless Merb::Router.named_routes.empty?
    puts "Named Routes"
    Merb::Router.named_routes.each do |name,route|
      puts "  #{name}: #{route}"
      seen << route
    end
  end
  puts "Anonymous Routes"
  (Merb::Router.routes - seen).each do |route|
    puts "  #{route}"
  end
  nil
end