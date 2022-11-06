# frozen_string_literal: true

require "mail_tools/util"

require "tempfile"

require_relative "../mail_tools_test"

module MailTools
  class ConfigTest < MailToolsTest
    include Util

    def setup
      @default = { "foo" => "bar", "bar" => { "foo" => "foo" } }
      @override = { "foo" => "foo" }
      @env = object_apply({ foo: :foo, bar: :bar, test_foo: :test_foo, test_bar: :test_bar }, :to_s, values: true)
      @env = object_apply(@env, :upcase)
    end

    def override_default_file
      file = Tempfile.new("overrides-default.yaml")
      file.write(@override.to_yaml)
      file.flush
      begin
        yield file
      ensure
        file.close
      end
    end

    test "config has default values" do
      config = Config.new(default: @default)
      @default.each_pair { |k, v| assert_equal v, config[k] }
    end

    test "config has file value" do
      override_default_file do |file|
        config = Config.new(files: [file.path])
        assert_equal @override["foo"], config["foo"]
      end
    end

    test "files override default" do
      override_default_file do |file|
        config = Config.new(default: @default, files: [file.path])
        refute_equal @default["foo"], config["foo"]
        assert_equal @override["foo"], config["foo"]
      end
    end

    test "files override each other" do
      file0 = Tempfile.new("override0.yaml")
      file1 = Tempfile.new("override1.yaml")
      file2 = Tempfile.new("override2.yaml")
      files = [file2, file1, file0]
      file0.write({ a: 0, b: 0, c: 0 }.to_yaml)
      file1.write({ b: 1, c: 1 }.to_yaml)
      file2.write({ c: 2 }.to_yaml)
      files.each(&:flush)

      config = Config.new(files: files.map(&:path))
      assert_equal 0, config["a"]
      assert_equal 1, config["b"]
      assert_equal 2, config["c"]

      files.each(&:close)
    end
    
    test "config contains env with correct prefix" do
      config = Config.new(env_prefix: :test, env: @env)
      assert_equal @env["TEST_FOO"], config["foo"]
      assert_equal @env["TEST_BAR"], config["bar"]
      refute_equal @env["FOO"], config["foo"]
      refute_equal @env["BAR"], config["bar"]
    end

    test "config applies environment map" do
      config = Config.new(env: @env,
                          env_map: { foo: :foobar })
      refute config["foo"]
      assert_equal "foo", config["foobar"]
    end

    test "Environment variables override default" do
      config = Config.new(default: @default, env: @env, env_prefix: :test)
      refute_equal @default["foo"], config["foo"]
      assert_equal @env["TEST_FOO"], config["foo"]
    end
    
    test "missing returns missing keys" do
      config = Config.new(default: @default)
      test = { test: [:foo, { bar: %i[foo bar] }] }
      missing = config.missing(:foobar, *@default.keys, **test)
      assert missing.respond_to?(:include?)
      @default.each_key { |k| refute missing.include?(k.to_s) }
      assert missing.include?("foobar")
      assert missing.include?(object_apply(test, :to_s, values: true))
    end
  end
end
