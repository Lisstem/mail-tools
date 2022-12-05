# frozen_string_literal: true

require "tempfile"

require_relative "../../mail_tools_test"

module MailTools
  module Util
    module ConfigTest
      include Methods

      def setup
        super

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
    end

    class ConfigParallelTest < MailToolsTest
      include ConfigTest

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

      test "missing return empty array if nothing is missing" do
        config = Config.new(default: @default)
        missing = config.missing(:foo, bar: :foo)
        assert_equal [], missing
      end

      test "missing? returns true if options are missing" do
        config = Config.new(default: @default)
        assert config.missing?(:test)
        assert config.missing?(test: :test)
      end

      test "missing? returns false if no options are missing" do
        config = Config.new(default: @default)
        refute config.missing?(:foo, bar: :foo)
      end

      test "missing paths returns missing paths" do
        config = Config.new(default: @default)
        expected = ["test_bar", ["test_foo", "bar"], ["test_foo", "foo"]]
        assert_equal expected, config.missing_paths(:test_bar, test_foo: [:bar, :foo])
      end

      test "missing paths test 2" do
        config = Config.new
        assert_equal ["bar", ["foo", "bar"]], config.missing_paths(:bar, foo: :bar)
      end

      test "merge adds options to config" do
        config = Config.new
        test2 = { test: { test: 2 } }
        config.merge({ test: "foo", test2: })
        assert_equal "foo", config["test"]
        assert_equal object_apply(test2, :to_s), config["test2"]
      end

      test "merge overrides existing option" do
        config = Config.new(default: @default)
        key = @default.keys.first
        value = "#{@default[key]}_new"
        config.merge({ key => value })
        refute_equal object_apply(@default[key], :to_s), config[key.to_s]
        assert_equal value, config[key.to_s]
      end

      test "create creates empty config" do
        config = Config.create("foo")
        assert_equal 0, config.count
      end

      test "create raises error if options is missing" do
        required = [:bar, { foo: :bar }]
        assert_raises(MailTools::Error) do
          Config.create("foo", required:)
        end
      end
    end

    class ConfigMockTest < MailToolsMockTest
      include ConfigTest

      test "prompt for missing prompts for each missing path" do
        paths = [{ foo: :bar }, :bar]
        input = mock
        input.expects(:gets).twice.returns(*paths.map(&:to_s))
        output = mock
        output.stubs(:print)
        config = Config.new
        config.prompt_for_missing(paths, input:, output:)
        assert_equal "bar", config["bar"]
        assert_equal "{:foo=>:bar}", config.dig("foo", "bar")
      end

      test "prompt for missing uses getpass for password" do
        paths = [:password, { test: :password, foo: { bar: :password } }]
        input = mock
        input.expects(:getpass).times(3).returns(*(0..2).to_a.map(&:to_s))
        output = mock
        output.stubs(:print)
        config = Config.new
        config.prompt_for_missing(paths, input:, output:)
        assert_equal "0", config["password"]
        assert_equal "1", config.dig("test", "password")
        assert_equal "2", config.dig("foo", "bar", "password")
      end

      test "create prompts for missing options" do
        required = [:bar, { foo: :bar }]
        input = mock
        input.expects(:gets).twice.returns(*required.map(&:to_s))
        output = mock
        output.stubs(:print)
        config = Config.create("Foo", prompt: true, input:, output:, required:)
        assert_equal "bar", config["bar"]
        assert_equal "{:foo=>:bar}", config.dig("foo", "bar")
      end
    end
  end
end
