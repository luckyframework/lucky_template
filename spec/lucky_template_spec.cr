require "./spec_helper"

describe LuckyTemplate do
  around_each do |example|
    with_tempfile("tmp") do |tmp|
      Dir.mkdir_p(tmp)
      Dir.cd(tmp) do
        example.run
      end
    end
  end

  describe ".create_folder" do
    context "without block" do
      it "returns a folder" do
        LuckyTemplate.create_folder.should be_a(LuckyTemplate::Folder)
      end

      it "returned folder is not locked" do
        LuckyTemplate.create_folder.locked?.should be_false
      end
    end

    context "with block" do
      it "yields a folder and returns the folder" do
        returned_folder = LuckyTemplate.create_folder do |folder|
          folder.should be_a(LuckyTemplate::Folder)
        end
        returned_folder.should be_a(LuckyTemplate::Folder)
      end

      it "yielded folder is locked, but returned folder is not locked" do
        returned_folder = LuckyTemplate.create_folder do |folder|
          folder.locked?.should be_true
        end
        returned_folder.locked?.should be_false
      end
    end
  end

  describe ".write!" do
    context "without block" do
      it "writes folder to disk" do
        folder = LuckyTemplate.create_folder
        LuckyTemplate.write!(Path["."], folder)
      end

      it "writes folder with file to disk" do
        folder = LuckyTemplate.create_folder do |dir|
          dir.add_file(".keep")
        end
        LuckyTemplate.write!(Path["."], folder)
      end

      it "raises if folder is locked" do
        LuckyTemplate.create_folder do |folder|
          expect_raises(LuckyTemplate::Error) do
            LuckyTemplate.write!(Path["."], folder)
          end
        end
      end

      it "raises if location is not an existing folder" do
        folder = LuckyTemplate.create_folder do |dir|
          dir.add_file(".keep")
        end
        File.touch(Path["./folder"])
        expect_raises(File::AlreadyExistsError) do
          LuckyTemplate.write!(Path["./folder"], folder)
        end
      end
    end

    context "with block" do
      it "writes folder to disk" do
        LuckyTemplate.write!(Path["."]) { }
      end
    end
  end

  describe ".snapshot" do
    it "returns a snapshot" do
      folder = LuckyTemplate.create_folder
      LuckyTemplate.snapshot(folder).should be_a(LuckyTemplate::Snapshot)
    end

    it "raises if folder is locked" do
      LuckyTemplate.create_folder do |folder|
        expect_raises(LuckyTemplate::Error) do
          LuckyTemplate.snapshot(folder)
        end
      end
    end

    it "returns same snapshot if no changes are made to folder" do
      folder = LuckyTemplate.create_folder do |dir|
        dir.add_file(".keep")
      end
      snap1 = LuckyTemplate.snapshot(folder)
      snap2 = LuckyTemplate.snapshot(folder)
      snap2.should eq(snap1)
    end

    it "returns different snapshot if changes are made to folder" do
      folder = LuckyTemplate.create_folder do |dir|
        dir.add_file(".keep")
      end
      snap1 = LuckyTemplate.snapshot(folder)
      folder.add_file("README.md")
      snap2 = LuckyTemplate.snapshot(folder)
      snap2.should_not eq(snap1)
    end
  end

  describe ".validate!" do
    pending "WIP"
  end

  describe ".validate?" do
    pending "WIP"
  end

  describe "Folder" do
    describe "#add_file" do
      pending "WIP"
    end

    describe "#add_folder" do
      pending "WIP"
    end

    describe "#insert_folder" do
      pending "WIP"
    end

    describe "#locked?" do
      pending "WIP"
    end

    describe "#empty?" do
      pending "WIP"
    end
  end
end

#describe LuckyTemplate do
  #around_each do |example|
    #with_tempfile("lucky_template") do |tempdir|
      #Dir.mkdir_p(tempdir)
      #Dir.cd(tempdir) do
        #example.run
      #end
    #end
  #end

  #it "creates a folder and returns it" do
    #folder = LuckyTemplate.create_folder { }
    #folder.should be_a(LuckyTemplate::Folder)
  #end

  #it "creates empty folder snapshot" do
    #folder = LuckyTemplate.create_folder { }
    #snapshot = LuckyTemplate.snapshot(folder)
    #snapshot.should be_empty
  #end

  #context "creates a folder" do
    #it "that is locked during creation" do
      #folder = LuckyTemplate.create_folder do |dir|
        #dir.locked?.should be_true
      #end
      #folder.locked?.should be_false
    #end

    #it "with nested folder" do
      #folder = LuckyTemplate.create_folder do |dir|
        #dir.add_folder("child_dir")
      #end
      #snapshot = LuckyTemplate.snapshot(folder)
      #snapshot.keys.should contain("child_dir")
    #end

    #it "with nested folders" do
      #folder = LuckyTemplate.create_folder do |dir|
        #dir.add_folder("parent", "child", "grandchild")
      #end
      #snapshot = LuckyTemplate.snapshot(folder)
      #snapshot.keys.should contain("parent")
      #snapshot.keys.should contain("parent/child")
      #snapshot.keys.should contain("parent/child/grandchild")
    #end

    #context "with file" do
      #it "using static content" do
        #folder = LuckyTemplate.create_folder do |dir|
          #dir.add_file("hello.txt", "static content")
        #end
        #snapshot = LuckyTemplate.snapshot(folder)
        #snapshot.keys.should contain("hello.txt")
      #end

      #it "using inheritance" do
        #shard_yml = ShardYml.new("my_shard", [
          #GitAuthor.new("John Doe", "john.doe@example.com"),
        #])

        #folder = LuckyTemplate.create_folder do |dir|
          #dir.add_file("shard.yml", shard_yml)
        #end
        #snapshot = LuckyTemplate.snapshot(folder)
        #snapshot.keys.should contain("shard.yml")
      #end

      #it "using captured block" do
        #folder = LuckyTemplate.create_folder do |dir|
          #dir.add_file("hello.txt") do |io|
            #io << "captured block"
          #end
        #end
        #snapshot = LuckyTemplate.snapshot(folder)
        #snapshot.keys.should contain("hello.txt")
      #end

      #it "without value" do
        #folder = LuckyTemplate.create_folder do |dir|
          #dir.add_file("hello.txt")
        #end
        #snapshot = LuckyTemplate.snapshot(folder)
        #snapshot.keys.should contain("hello.txt")
      #end
    #end

    #it "and writes to disk" do
      #folder = LuckyTemplate.create_folder do |dir|
        #dir.add_file("hello.txt")
      #end
      #path = Path[FileUtils.pwd]
      #LuckyTemplate.write!(path, folder)
      #folder.should be_valid_at(path)
    #end
  #end

  #it "writes folder to disk" do
    #path = Path[FileUtils.pwd]
    #folder = LuckyTemplate.write!(path) do |dir|
      #dir.add_file("hello.txt")
    #end
    #folder.should be_valid_at(path)
  #end

  #context "fails" do
    #it "to validate file on disk" do
      #path = Path[FileUtils.pwd]
      #folder = LuckyTemplate.write!(path) do |dir|
        #dir.add_file("hello.txt")
      #end
      #File.delete(path / "hello.txt")
      #folder.should_not be_valid_at(path)
    #end

    #it "to validate folder on disk" do
      #path = Path[FileUtils.pwd]
      #folder = LuckyTemplate.write!(path) do |dir|
        #dir.add_folder("yoyo")
      #end
      #Dir.delete(path / "yoyo")
      #folder.should_not be_valid_at(path)
    #end
  #end
#end
