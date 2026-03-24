require File.expand_path('../../spec_helper', __FILE__)
require 'cocoapods_mangle/context'

describe CocoapodsMangle::Context do
  let(:pod_target_a1) { instance_double('pod target A1', label: 'PodA1') }
  let(:pod_target_a2) { instance_double('pod target A2', label: 'PodA2') }
  let(:pod_target_b1) { instance_double('pod target B1', label: 'PodB1') }
  let(:pod_target_c1) { instance_double('pod target C1', label: 'PodC1') }
  let(:aggregate_targets) do
    [
      instance_double('aggregate target A', label: 'Pods-A', user_targets: [instance_double('target A', name: 'A')], pod_targets: [pod_target_a1, pod_target_a2]),
      instance_double('aggregate target B', label: 'Pods-B', user_targets: [instance_double('target B', name: 'B')], pod_targets: [pod_target_b1, pod_target_a1]),
      instance_double('aggregate target C', label: 'Pods-C', user_targets: [instance_double('target C', name: 'C')], pod_targets: [pod_target_c1])
    ]
  end
  let(:installer) { instance_double('installer', aggregate_targets: aggregate_targets) }
  let(:options) { {} }
  let(:subject) { CocoapodsMangle::Context.new(installer, options) }

  context '.xcconfig_path' do
    before do
      allow(installer).to receive_message_chain(:sandbox, :target_support_files_root).and_return( Pathname.new('/support_files') )
      allow(installer).to receive_message_chain(:sandbox, :root, :parent).and_return( Pathname.new('/parent') )
    end

    context 'No options' do
      it 'gives the default xcconfig path' do
        expect(subject.xcconfig_path).to eq("/support_files/#{CocoapodsMangle::NAME}.xcconfig")
      end
    end

    context 'User provided xcconfig path' do
      let(:options) { { xcconfig_path: 'path/to/mangle.xcconfig' } }
      it 'gives the user xcconfig path, relative to the project' do
        expect(subject.xcconfig_path).to eq("/parent/#{options[:xcconfig_path]}")
      end
    end
  end

  context '.mangle_prefix' do
    context 'No options' do
      before do
        allow(aggregate_targets.first).to receive_message_chain(:user_project, :path).and_return('path/to/Project.xcodeproj')
      end

      it 'gives the project name as the prefix' do
        expect(subject.mangle_prefix).to eq('Project_')
      end
    end

    context 'No options with space in project name' do
      before do
        allow(aggregate_targets.first).to receive_message_chain(:user_project, :path).and_return('path/to/Project Name.xcodeproj')
      end

      it 'gives the project name with underscores as the prefix' do
        expect(subject.mangle_prefix).to eq('Project_Name_')
      end
    end

    context 'User provided prefix' do
      let(:options) { { mangle_prefix: 'Prefix_' } }

      it 'gives the user prefix' do
        expect(subject.mangle_prefix).to eq(options[:mangle_prefix])
      end
    end
  end

  context '.pods_project_path' do
    let(:pods_project) { instance_double('pods project', path: 'path/to/Pods.xcodeproj') }

    before do
      allow(installer).to receive(:pods_project).and_return(pods_project)
    end

    it 'gives the project path' do
      expect(subject.pods_project_path).to eq(pods_project.path)
    end
  end

  context '.pod_target_labels' do
    context 'No options' do
      it 'gives all unique pod targets across aggregate targets' do
        expect(subject.pod_target_labels).to eq(['PodA1', 'PodA2', 'PodB1', 'PodC1'])
      end
    end

    context 'With targets' do
      let(:options) { { targets: ['A', 'B'] } }
      it 'gives only pod targets from requested aggregate targets' do
        expect(subject.pod_target_labels).to eq(['PodA1', 'PodA2', 'PodB1'])
      end
    end
  end

  context '.pod_xcconfig_paths' do
    let(:pods_project) { instance_double('pods project', path: 'path/to/Pods.xcodeproj') }
    let(:pod_target) { double('target') }
    let(:debug_build_configuration) { double('debug') }
    let(:release_build_configuration) { double('release') }

    before do
      allow(installer).to receive(:pods_project).and_return(pods_project)
      allow(pods_project).to receive(:targets).and_return([pod_target])
      build_configurations = [debug_build_configuration, release_build_configuration]
      allow(pod_target).to receive(:build_configurations).and_return(build_configurations)
      build_configurations.each do |config|
        allow(config).to receive_message_chain(:base_configuration_reference, :real_path).and_return('path/to/pod.xcconfig')
      end
    end

    it 'gives the pod xcconfigs' do
      expect(subject.pod_xcconfig_paths).to eq(['path/to/pod.xcconfig'])
    end
  end

  context '.specs_checksum' do
    let(:gem_summary) { "#{CocoapodsMangle::NAME}=#{CocoapodsMangle::VERSION}" }
    let(:spec_A) { instance_double('Spec A', checksum: 'checksum_A') }
    let(:spec_B) { instance_double('Spec B', checksum: 'checksum_B') }
    let(:options) { { targets: ['A'] } }

    before do
      allow(aggregate_targets.first).to receive(:specs).and_return([spec_A, spec_B])
    end

    it 'gives the checksum' do
      summary = "#{gem_summary},checksum_A,checksum_B"
      expect(subject.specs_checksum).to eq(Digest::SHA1.hexdigest(summary))
    end
  end
end
