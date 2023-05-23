require "spec"
require "file_utils"
require "ecr"
require "../src/lucky_template"

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

SPEC_TEMPFILE_PATH    = File.join(Dir.tempdir, "cr-spec-#{Random.new.hex(4)}")
SPEC_TEMPFILE_CLEANUP = ENV["SPEC_TEMPFILE_CLEANUP"]? != "0"

def with_tempfile(*paths, file = __FILE__, &)
  calling_spec = File.basename(file).rchop("_spec.cr")
  paths = paths.map { |path| File.join(SPEC_TEMPFILE_PATH, calling_spec, path) }
  FileUtils.mkdir_p(File.join(SPEC_TEMPFILE_PATH, calling_spec))

  begin
    yield *paths
  ensure
    if SPEC_TEMPFILE_CLEANUP
      paths.each do |path|
        rm_rf(path) if File.exists?(path)
      end
    end
  end
end

private def rm_rf(path : String) : Nil
  if Dir.exists?(path) && !File.symlink?(path)
    Dir.each_child(path) do |entry|
      src = File.join(path, entry)
      rm_rf(src)
    end
    Dir.delete(path)
  else
    begin
      File.delete(path)
    rescue File::AccessDeniedError
      # To be able to delete read-only files (e.g. ones under .git/) on Windows.
      File.chmod(path, 0o666)
      File.delete(path)
    end
  end
end

if SPEC_TEMPFILE_CLEANUP
  at_exit do
    rm_rf(SPEC_TEMPFILE_PATH) if Dir.exists?(SPEC_TEMPFILE_PATH)
  end
end
