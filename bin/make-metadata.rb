#!/usr/bin/env ruby

@repo = ARGV[0]

unless File.directory?(@repo)
  raise "Usage: #$0 [repo-dir]"
end

Dir.chdir(@repo)

if File.exist?('metadata.tex')
  default_metadata = open('metadata.tex') do |io| io.read end
else
  default_metadata = ''
end

def update_metadata(meta_path, date)
  md = open(meta_path) do |io| io.read end
  md.sub!(/\\moddate\{\d\d\d\d-\d\d-\d\d\}/, "\\moddate{#{date}}")
  open(meta_path, 'w') do |io| io.write(md) end
end

Dir.each_child('.') do |subdir|
  next if subdir.start_with?('.')
  next unless File.directory?(subdir)
  IO.popen([
    'git', 'log', '--format=format:%cs', '-n', '1', subdir
  ]) do |io|
    date = io.read.chomp

    meta_path = File.join(subdir, 'metadata.tex')
    if File.exist?(meta_path)
      update_metadata(meta_path, date)
    else
      open(meta_path, 'w') do |wio|
        wio.puts(default_metadata)
        wio.puts("\\moddate{#{date}}")
      end
    end
  end
end
