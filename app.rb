require 'gems'
require 'csv'
require 'json'
require 'concurrent'

gem_list = []
pool = Concurrent::FixedThreadPool.new(5)
lock = Mutex.new
repo_regex = /https?:\/\/github.com\/([\w-]*)\/([\w-]*)\/?/

CSV.foreach('./rubygems_list.csv') do |gem_name|
  sleep 0.5
  pool.post do
    begin
      gem_info = Gems.info gem_name[0]
      repo_user = ''
      repo_name = ''

      if gem_info 
        if !gem_info['homepage_uri'].nil? && (match = gem_info['homepage_uri'].match(repo_regex))  
          repo_user, repo_name = match.captures
        elsif !gem_info['source_code_uri'].nil? && (match = gem_info['source_code_uri'].match(repo_regex))
          repo_user, repo_name = match.captures
        elsif !gem_info['project_uri'].nil? && (match = gem_info['project_uri'].match(repo_regex))
          repo_user, repo_name = match.captures
        elsif !gem_info['gem_uri'].nil? && (match = gem_info['gem_uri'].match(repo_regex))
          repo_user, repo_name = match.captures
        end
      else
        puts "Error: #{gem_name}"
      end

      if !repo_user.empty? && !repo_name.empty?
        lock.synchronize {
          gem_list << {
            'gem_name'    => gem_name,
            'repo_user'   => repo_user,
            'repo_name'   => repo_name
          }
          puts "#{gem_name} ... DONE **** #{gem_list.length} in the array"
        }
      end
    rescue => error
      puts error
    end
  end
end

pool.shutdown
pool.wait_for_termination

File.open('./gems.json', 'w') do |f|
  f.write(gem_list.to_json)
end
