require "./spec_helper"

describe LuckyTemplate do
  around_each do |example|
    with_tempfile("lucky_template") do |tempdir|
      Dir.mkdir_p(tempdir)
      Dir.cd(tempdir) do
        example.run
      end
    end
  end

  it "creates a parent folder and returns it" do
    folder = LuckyTemplate.create_parent_folder { }
    folder.should be_a(LuckyTemplate::Folder)
  end

  it "creates empty folder snapshot" do
    folder = LuckyTemplate.create_parent_folder { }
    snapshot = LuckyTemplate.snapshot_files(folder)
    snapshot.should be_empty
  end

  context "creates a parent folder" do
    it "that is locked during creation" do
      folder = LuckyTemplate.create_parent_folder do |parent_dir|
        parent_dir.locked?.should be_true
      end
      folder.locked?.should be_false
    end

    it "with nested folder" do
      folder = LuckyTemplate.create_parent_folder do |parent_dir|
        parent_dir.add_folder("child_dir")
      end
      snapshot = LuckyTemplate.snapshot_files(folder)
      snapshot.keys.should contain("child_dir")
    end

    it "with nested folders" do
      folder = LuckyTemplate.create_parent_folder do |parent_dir|
        parent_dir.add_folder("parent", "child", "grandchild")
      end
      snapshot = LuckyTemplate.snapshot_files(folder)
      snapshot.keys.should contain("parent")
      snapshot.keys.should contain("parent/child")
      snapshot.keys.should contain("parent/child/grandchild")
    end

    context "with file" do
      it "using static content" do
        folder = LuckyTemplate.create_parent_folder do |parent_dir|
          parent_dir.add_file("hello.txt", "static content")
        end
        snapshot = LuckyTemplate.snapshot_files(folder)
        snapshot.keys.should contain("hello.txt")
      end

      it "using inheritance" do
        shard_yml = ShardYml.new("my_shard", [
          GitAuthor.new("John Doe", "john.doe@example.com"),
        ])

        folder = LuckyTemplate.create_parent_folder do |parent_dir|
          parent_dir.add_file("shard.yml", shard_yml)
        end
        snapshot = LuckyTemplate.snapshot_files(folder)
        snapshot.keys.should contain("shard.yml")
      end

      it "using captured block" do
        folder = LuckyTemplate.create_parent_folder do |parent_dir|
          parent_dir.add_file("hello.txt") do |io|
            io << "captured block"
          end
        end
        snapshot = LuckyTemplate.snapshot_files(folder)
        snapshot.keys.should contain("hello.txt")
      end

      it "without value" do
        folder = LuckyTemplate.create_parent_folder do |parent_dir|
          parent_dir.add_file("hello.txt")
        end
        snapshot = LuckyTemplate.snapshot_files(folder)
        snapshot.keys.should contain("hello.txt")
      end
    end

    it "and writes to disk" do
      folder = LuckyTemplate.create_parent_folder do |parent_dir|
        parent_dir.add_file("hello.txt")
      end
      path = Path[FileUtils.pwd]
      LuckyTemplate.write!(path, folder)
      folder.should be_valid_at(path)
    end
  end

  it "writes folder to disk" do
    path = Path[FileUtils.pwd]
    folder = LuckyTemplate.write!(path) do |parent_dir|
      parent_dir.add_file("hello.txt")
    end
    folder.should be_valid_at(path)
  end

  context "fails" do
    it "to validate file on disk" do
      path = Path[FileUtils.pwd]
      folder = LuckyTemplate.write!(path) do |parent_dir|
        parent_dir.add_file("hello.txt")
      end
      File.delete(path / "hello.txt")
      folder.should_not be_valid_at(path)
    end

    it "to validate folder on disk" do
      path = Path[FileUtils.pwd]
      folder = LuckyTemplate.write!(path) do |parent_dir|
        parent_dir.add_folder("yoyo")
      end
      Dir.delete(path / "yoyo")
      folder.should_not be_valid_at(path)
    end
  end
end
