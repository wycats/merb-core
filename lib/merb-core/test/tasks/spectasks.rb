desc "Run all specs"
Spec::Rake::SpecTask.new('specs') do |t|
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.spec_files = Dir['spec/**/*_spec.rb'].sort
end

desc "Run all model specs"
Spec::Rake::SpecTask.new('model_specs') do |t|
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.spec_files = Dir['spec/models/**/*_spec.rb'].sort
end

desc "Run all controller specs"
Spec::Rake::SpecTask.new('controller_specs') do |t|
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.spec_files = Dir['spec/controllers/**/*_spec.rb'].sort
end

desc "Run a specific spec with TASK=xxxx"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.libs = ['lib', 'server/lib' ]
  t.spec_files = ["spec/#{ENV['TASK']}_spec.rb"]
end

desc "Run all specs output html"
Spec::Rake::SpecTask.new('specs_html') do |t|
  t.spec_opts = ["--format", "html"]
  t.libs = ['lib', 'server/lib' ]
  t.spec_files = Dir['spec/**/*_spec.rb'].sort
end

desc "RCov"
Spec::Rake::SpecTask.new('rcov') do |t|
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.spec_files = Dir['spec/**/*_spec.rb'].sort
  t.libs = ['lib', 'server/lib' ]
  t.rcov = true
end