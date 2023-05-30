require "spec"
require "ecr"
require "./support/tempfile"
require "../src/lucky_template"
require "../src/spec"

include LuckyTemplate::Spec

record GitAuthor,
  name : String,
  email : String

class ShardYml
  include LuckyTemplate::Fileable

  @name : String
  @authors = [] of GitAuthor

  def initialize(@name, @authors)
  end

  def to_file(io : IO) : Nil
    to_s(io)
  end

  ECR.def_to_s "#{__DIR__}/fixtures/shard.yml.ecr"
end
