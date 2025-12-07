require_relative 'spec_helper'

RSpec.describe INatChannel::Config do
  describe '.config' do
    it 'читает конфигурацию' do
      config = described_class.config
      expect(config[:base_query][:project_id]).to eq(99999)
    end
  end

  describe '.parse_options' do
    it 'возвращает пустой hash для пустого ARGV' do
      original_argv = ARGV.dup
      ARGV.clear
      options = described_class.send(:parse_options)
      expect(options).to eq({})
      ARGV.replace(original_argv)
    end

    it 'парсит -c опцию' do
      # ✅ СОЗДАЕМ РЕАЛЬНЫЙ ФАЙЛ test.yaml!
      test_yaml_path = 'spec/tmp/test.yaml'
      FileUtils.mkdir_p('spec/tmp')
      File.write(test_yaml_path, '{}')
      
      original_argv = ARGV.dup
      ARGV.replace(['-c', test_yaml_path])
      options = described_class.send(:parse_options)
      expect(options[:config]).to eq(test_yaml_path)
      
      ARGV.replace(original_argv)
      File.delete(test_yaml_path) rescue nil
    end
  end
end
