require "osdn/repository/uploader/version"
require "thor"
require "osdn-client"
require "find"

module Osdn
  module Repository
    module Uploader

      class Command < ::Thor

        desc "upload ", "Upload files under repository"
        option :project
        option :repository
        def upload
          OSDNClient.configure do |config|
            config.access_token = ""
          end
          api = OSDNClient::ProjectApi.new
          proj_info = api.get_project("cutter")
          p proj_info
          packages = api.list_packages("cutter")

          packages.each do |package|
            p package
            package.releases.each do |release|
              p release
              release_info = api.get_release("cutter", package.id, release.id)
              p release_info.files
            end
          end

          project_name = options[:project]
          package_ids = {}
          Dir.glob("#{options[:repository]}/*").each do |dir|
            p dir
            path = Pathname.new(dir)
            package_name = path.basename.to_s
            p package_name
            prefix = "#{options[:repository]}/#{package_name}/"
            p "Create package: #{package_name}"
            package = api.create_package(project_name, package_name, visibility: true)
            release_ids = {}
            package_ids[package_name] = 1 #package.id
            Find.find(prefix).each do |file_path|
              next if prefix == file_path
              path = Pathname.new(file_path)
              release_name = path.sub(/#{prefix}/, '')
              p file_path
              if path.directory?
                next if release_name.to_s == "."
                unless release_ids.has_key?(release_name.to_s)
                  p "Create release: #{release_name.to_s}"
                  release = api.create_release(project_name, package.id, release_name.to_s, visibility: true)
                  release_ids[release_name.to_s] = release.id
                end
              end
            end
            Find.find(prefix).each do |file_path|
              next if prefix == file_path
              path = Pathname.new(file_path)
              relative_path = path.sub(/#{prefix}/, '')
              release_name = relative_path.dirname
              unless path.directory?
                if release_ids.has_key?(release_name.to_s)
                  p release_name.to_s
                  p "Create release file: <#{release_name.to_s}> #{path.basename}"
                  path.open do |file|
                    release_id = release_ids[release_name.to_s]
                    finfo = api.create_release_file(project_name, package.id, release_id, file, visibility: true)
                    p finfo.id
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
