require_relative '../lib/cocoapods_mangle/gem_version'
require_relative '../lib/cocoapods_mangle/context'
require_relative '../lib/cocoapods_mangle/post_install'

# Call this from your Podfile's post_install hook:
#
#   post_install do |installer|
#     mangle_pods(installer, mangle_prefix: 'MyApp_')
#   end
#
# Options:
#   :mangle_prefix  - prefix for mangled symbols (default: project name + '_')
#   :xcconfig_path  - path to mangling xcconfig (default: auto)
#   :targets        - specific user targets to mangle (default: all)
def mangle_pods(installer, options = {})
  context = CocoapodsMangle::Context.new(installer, options)
  post_install = CocoapodsMangle::PostInstall.new(context)
  Pod::UI.titled_section 'Updating mangling' do
    post_install.run!
  end
end
