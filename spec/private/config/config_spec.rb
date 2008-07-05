require File.dirname(__FILE__) + '/spec_helper'

describe Merb::Config do
  before do
    Merb::Config.setup
  end

  it "should be able to yield the configuration via #use" do
    res = nil
    Merb::Config.use {|c| res = c}
    res.should == Merb::Config.defaults
  end

  it "should be able to get a configuration key" do
    Merb::Config[:host].should == "0.0.0.0"
  end

  it "should be able to set a configuration key" do
    Merb::Config[:bar] = "Hello"
    Merb::Config[:bar].should == "Hello"
  end

  it "should be able to #delete a configuration key" do
    Merb::Config[:bar] = "Hello"
    Merb::Config[:bar].should == "Hello"
    Merb::Config.delete(:bar)
    Merb::Config[:bar].should == nil
  end

  it "should be able to #fetch a key that does exist" do
    Merb::Config.fetch(:host, "192.168.2.1").should == "0.0.0.0"
  end

  it "should be able to #fetch a key that does exist" do
    Merb::Config.fetch(:bar, "heylo").should == "heylo"
  end

  it "should be able to dump to YAML" do
    Merb::Config.to_yaml.should == Merb::Config.instance_variable_get("@configuration").to_yaml
  end

  it "should support -u to set the user to run Merb as" do
    Merb::Config.parse_args(["-u", "tester"])
    Merb::Config[:user].should == "tester"
  end

  it "should support -G to set the group to run Merb as" do
    Merb::Config.parse_args(["-G", "tester"])
    Merb::Config[:group].should == "tester"
  end

  it "should support -d to daemonize Merb" do
    Merb::Config.parse_args(["-d"])
    Merb::Config[:daemonize].should == true
  end

  it "should support -c to set the number of cluster nodes" do
    Merb::Config.parse_args(["-c", "4"])
    Merb::Config[:cluster].should == "4"
  end

  it "should support -p to set the port number" do
    Merb::Config.parse_args(["-p", "6000"])
    Merb::Config[:port].should == "6000"
  end

  it "should support -o to set the socket filename" do
    Merb::Config.parse_args(["-o", "merb.2.sock"])
    Merb::Config[:socket_file].should == "merb.2.sock"
  end

  it "should support --socket-file to set the socket filename" do
    Merb::Config.parse_args(["--socket-file", "app.thin.0.sock"])
    Merb::Config[:socket_file].should == "app.thin.0.sock" # 0 is default socket #
  end

  it "should support -s to set the socket number" do
    Merb::Config.parse_args(["-s", "0"])
    Merb::Config[:socket].should == "0"
  end

  it "should support --socket to set the socket number" do
    Merb::Config.parse_args(["--socket", "3"])
    Merb::Config[:socket].should == "3"
  end

  it "should support -P to set the PIDfile" do
    Merb::Config.parse_args(["-P", "pidfile"])
    Merb::Config[:pid_file].should == "pidfile"
  end

  it "should have server return PIDfile setting as is with no cluster nodes" do
    Merb::Config.parse_args(["-P", "pidfile", "-p", "6000"])
    Merb::Server.pid_file(6000).should == "pidfile"
    Merb::Server.pid_files.should == ["pidfile"]
  end

  it "should support setting of PIDfile with cluster nodes" do
    Merb::Config.parse_args(["-P", "/tmp/merb.pidfile", "-c", "2", "-p", "6000"])
    Merb::Server.pid_file(6000).should == "/tmp/merb.6000.pidfile"
    Merb::Server.pid_file(6001).should == "/tmp/merb.6001.pidfile"

    Dir.should_receive(:[]).with("/tmp/merb.*.pidfile")
    Merb::Server.pid_files
  end

  it "should support default PIDfile setting" do
    Merb::Config.parse_args(["-p", "6000"])
    Merb::Server.pid_file(6000).should == Merb.log_path / "merb.6000.pid"

    Dir.should_receive(:[]).with(Merb.log_path / "merb.*.pid")
    Merb::Server.pid_files
  end

  it "should support -h to set the hostname" do
    Merb::Config.parse_args(["-h", "hostname"])
    Merb::Config[:host].should == "hostname"
  end

  it "should support -i to specify loading IRB" do
    Merb::Config.parse_args(["-i"])
    Merb::Config[:adapter].should == "irb"
  end

  it "should support -l to specify the log level" do
    Merb::Config.parse_args(["-l", "debug"])
    Merb::Config[:log_level].should == :debug
  end

  it "should support -L to specify the location of the log file" do
    Merb::Config.parse_args(["-L", "log_file"])
    Merb::Config[:log_file].should == "log_file"
  end

  it "should support -r to specify a runner" do
    Merb::Config.parse_args(["-r", "foo_runner"])
    Merb::Config[:runner_code].should == "foo_runner"
    Merb::Config[:adapter].should == "runner"
  end

  it "should support -R to specify a rackup file" do
    Merb::Config.parse_args(["-R", "config.ru"])
    Merb::Config[:rackup].should == "config.ru"
  end

  it "should support -K for a graceful kill" do
    Merb::Server.should_receive(:kill).with("all", 1)
    Merb.start(["-K", "all"])
  end

  it "should support -k for a hard kill" do
    Merb::Server.should_receive(:kill).with("all", 9)
    Merb.start(["-k", "all"])
  end

  it "should support -X off to turn off the mutex" do
    Merb::Config.parse_args(["-X", "off"])
    Merb::Config[:use_mutex].should == false
  end

  it "should support -X on to turn off the mutex" do
    Merb::Config.parse_args(["-X", "on"])
    Merb::Config[:use_mutex].should == true
  end

  it "should take Merb.disable into account" do
    Merb::Config[:disabled_components].should == []
    Merb::Config[:disabled_components] << :foo
    Merb.disable(:bar)
    Merb.disable(:buz, :fux)
    Merb::Config[:disabled_components].should == [:foo, :bar, :buz, :fux]
    Merb.disabled?(:foo).should == true
    Merb.disabled?(:foo, :buz).should == true
  end

  it "should take Merb.testing? into account" do
    $TESTING.should == true
    Merb::Config[:testing].should be_nil
    Merb.should be_testing
    $TESTING = false
    Merb.should_not be_testing
    Merb::Config[:testing] = true
    Merb.should be_testing
    $TESTING = true; Merb::Config[:testing] = false # reset
  end

  it "supports -V to turn on verbose mode" do
    Merb::Config[:verbose] = false
    Merb::Config.parse_args(["-V"])
    Merb::Config[:verbose].should be(true)
  end

  it "supports --verbose to turn on verbose mode" do
    Merb::Config[:verbose] = false
    Merb::Config.parse_args(["--verbose"])
    Merb::Config[:verbose].should be(true)
  end

  it "has verbose mode turned off by default" do
    Merb::Config[:verbose].should be(false)
  end
end
