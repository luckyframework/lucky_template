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

  it "writes folder to disk" do
    folder = LuckyTemplate.write!(Path["."]) do |parent_dir|
      parent_dir.add_file("example.txt")
      parent_dir.add_folder("a", "b") do |emails_dir|
        emails_dir.add_file("example2.txt")
      end
    end
    folder.should LuckyTemplate.be_valid_at(Path["."])
  end
end
