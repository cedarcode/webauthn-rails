namespace :webauthn_rails do
  desc "Install Webauhtn Rails into the app"
  task :install do
    if Rails.root.join("config/importmap.rb").exist?
      system "#{RbConfig.ruby} ./bin/rails app:template LOCATION=#{File.expand_path("../../install/with_importmap.rb",  __dir__)}"
    else
      puts "You must be running importmap-rails (config/importmap.rb) to use this gem."
    end
  end
end
