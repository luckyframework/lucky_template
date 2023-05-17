require "./spec_helper"
require "ecr"

module LuckyTemplateSpec
  class ShardYml
    include LuckyTemplate::Fileable

    @name : String
    @authors = [] of Hash(String, String)

    def initialize(@name, @authors)
    end

    def to_file(io : IO) : Nil
      to_s(io)
    end

    ECR.def_to_s "#{__DIR__}/fixtures/shard.yml.ecr"
  end
end

describe LuckyTemplate do
  around_each do |example|
    with_tempfile("lucky_template") do |tempdir|
      Dir.mkdir_p(tempdir)
      Dir.cd(tempdir) do
        example.run
      end
    end
  end

  it "creates separate folder and writes to disk" do
    cwd = Path.new(FileUtils.pwd)

    f = LuckyTemplate.create_folder("src") do |folder|
      folder.add_file("example.txt", nil)
    end
    LuckyTemplate.write!(cwd, f)

    File.exists?(cwd.join("src", "example.txt")).should eq(true)
  end

  it "writes folder to disk" do
    cwd = Path.new(FileUtils.pwd)

    LuckyTemplate.write!(cwd.join("src")) do |folder|
      folder.add_file("example2.txt", nil)
    end

    File.exists?(cwd.join("src", "example2.txt")).should eq(true)
  end

  it "writes folder to disk with template file", tags: "only" do
    cwd = Path.new(FileUtils.pwd)

    LuckyTemplate.write!(cwd.join("src")) do |folder|
      shard = LuckyTemplateSpec::ShardYml.new("my_shard", [
        { "fullname" => "John Doe", "email" => "john.doe@example.com" }
      ])

      folder.add_file("shard.yml", shard)
    end

    shard_yml_path = cwd.join("src", "shard.yml")

    File.exists?(shard_yml_path).should eq(true)
    File.read(shard_yml_path).should eq(<<-YML)
    name: my_shard
    version: 0.1.0

    authors:
      - John Doe john.doe@example.com

    crystal: ">= 1.0.0"

    license: MIT\n
    YML
  end
end
