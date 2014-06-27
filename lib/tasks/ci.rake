namespace :ci do
  task :build do
    ENV['RAILS_ENV'] = 'development'; Rake::Task['db:drop'].invoke rescue nil
    ENV['RAILS_ENV'] = 'test'; Rake::Task['db:drop'].invoke rescue nil
    ENV['RAILS_ENV'] = nil

    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke

    Rake::Task['db:test:prepare'].invoke

    # `COVERAGE=on bin/rake ci:setup:rspec spec`
    # `COVERAGE=on bin/rspec spec`

    Rake::Task['test'].invoke
    system "bin/spec spec"
  end
end
