require "osdn/repository/uploader/version"
require "thor"

module Osdn
  module Repository
    module Uploader

      class Command < ::Thor

        desc "upload ", "Upload files under repository"
        option :project
        option :repository
        def upload
          p options
        end
      end
    end
  end
end
