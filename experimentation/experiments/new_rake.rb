#!/usr/bin/env ruby
Thread.current[:rake_namespace] = ""
require "set"
class RakeTask
  TASKS = Hash.new {|h,k| h[k] = {:blocks => [], :deps => []}}
  CALLED_TASKS = Set.new
  
  def self.call(task_name)
    return if CALLED_TASKS.include?(task_name.to_sym)
    CALLED_TASKS << task_name.to_s
    task = TASKS[task_name.to_s]
    unless task
      puts "Unknown task #{task_name}"
      return
    end
    if task.is_a?(Proc)
      task.call
    else
      task[:deps].each {|t| call(t)}
      task[:blocks].each {|b| b.call }
    end
  end
end

def task(name_or_hash, &blk)
  if name_or_hash.is_a?(Symbol) || name_or_hash.is_a?(String)
    name = name_or_hash.to_s
  elsif name_or_hash.is_a?(Hash)
    name = name_or_hash.keys.first
    deps = name_or_hash.values.first
  end
  name = [
    (!Thread.current[:rake_namespace].empty? || nil) && 
    Thread.current[:rake_namespace],
    name
  ].compact.join(":")
  rake_task = RakeTask::TASKS[name]
  rake_task[:blocks] << blk
  rake_task[:deps].push(*deps) if deps
end

def namespace(name)
  var = Thread.current[:rake_namespace]
  original = var.dup
  var << ":" unless var.empty?
  var << name.to_s
  yield
  var.replace(original)
end

namespace :sweet do
  task :super do
    puts "Super"
  end

  task :super do
    puts "Super2"
  end
end

task "duper" do
  puts "Duper"
end

task :awesome => :super do
  puts "Awesome"
end

task :cool => [:awesome, :duper] do
  puts "Cool"
end

ARGV.each {|a| RakeTask.call(a) }