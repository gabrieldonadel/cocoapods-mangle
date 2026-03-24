module CocoapodsMangle
  # Context for mangling
  class Context
    # Initializes the context for mangling
    # @param  [Pod::Installer] installer
    #         The CocoaPods installer instance from a post_install hook
    # @param  [Hash] options
    # @option options [String] :xcconfig_path
    #                 The path to the mangling xcconfig
    # @option options [String] :mangle_prefix
    #                 The prefix to prepend to mangled symbols
    # @option options [Array<String>] :targets
    #                 The user targets whose dependencies should be mangled
    def initialize(installer, options)
      @installer = installer
      @options = options
    end

    # @return [String] The path to the mangle xcconfig
    def xcconfig_path
      return default_xcconfig_path unless @options[:xcconfig_path]
      File.join(@installer.sandbox.root.parent, @options[:xcconfig_path])
    end

    # @return [String] The mangle prefix to be used
    def mangle_prefix
      return default_mangle_prefix unless @options[:mangle_prefix]
      @options[:mangle_prefix]
    end

    # @return [String] The path to pods project
    def pods_project_path
      @installer.pods_project.path
    end

    # @return [Array<String>] The individual pod target labels to be built for mangling
    def pod_target_labels
      selected_aggregate_targets
        .flat_map(&:pod_targets)
        .uniq
        .map(&:label)
    end

    # @return [Array<String>] Paths to all pod xcconfig files which should be updated
    def pod_xcconfig_paths
      pod_xcconfigs = []
      @installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          pod_xcconfigs << config.base_configuration_reference.real_path
        end
      end
      pod_xcconfigs.uniq
    end

    # @return [String] A checksum representing the current state of the target dependencies
    def specs_checksum
      gem_summary = "#{CocoapodsMangle::NAME}=#{CocoapodsMangle::VERSION}"
      specs = selected_aggregate_targets.map(&:specs).flatten.uniq
      specs_summary = specs.map(&:checksum).join(',')
      Digest::SHA1.hexdigest("#{gem_summary},#{specs_summary}")
    end

    private

    def selected_aggregate_targets
      if @options[:targets].nil? || @options[:targets].empty?
        return @installer.aggregate_targets
      end
      @installer.aggregate_targets.reject do |target|
        target_names = target.user_targets.map(&:name)
        (@options[:targets] & target_names).empty?
      end
    end

    def default_xcconfig_path
      xcconfig_dir = @installer.sandbox.target_support_files_root
      xcconfig_filename = "#{CocoapodsMangle::NAME}.xcconfig"
      File.join(xcconfig_dir, xcconfig_filename)
    end

    def default_mangle_prefix
      project_path = selected_aggregate_targets.first.user_project.path
      project_name = File.basename(project_path, '.xcodeproj')
      project_name.tr(' ', '_') + '_'
    end
  end
end
